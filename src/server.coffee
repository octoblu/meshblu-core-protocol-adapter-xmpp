_                       = require 'lodash'
colors                  = require 'colors'
Redis                   = require 'ioredis'
RedisNS                 = require '@octoblu/redis-ns'
debug                   = require('debug')('meshblu-core-protocol-adapter-xmpp:server')
MultiHydrantFactory     = require 'meshblu-core-manager-hydrant/multi'
UuidAliasResolver       = require 'meshblu-uuid-alias-resolver'
PackageJSON             = require '../package.json'
xmpp                    = require 'node-xmpp-server'
XmppHandler             = require './xmpp-handler'
JobLogger               = require 'job-logger'
{ JobManagerRequester } = require 'meshblu-core-job-manager'

class Server
  constructor: (options)->
    {
      @disableLogging
      @port
      @aliasServerUri
      @redisUri
      @cacheRedisUri
      @firehoseRedisUri
      @namespace
      @jobTimeoutSeconds
      @maxConnections
      @firehoseNamespace
      @jobLogRedisUri
      @jobLogQueue
      @jobLogSampleRate
      @requestQueueName
      @responseQueueName
    } = options
    @panic 'missing @redisUri', 2 unless @redisUri?
    @panic 'missing @cacheRedisUri', 2 unless @cacheRedisUri?
    @panic 'missing @jobLogQueue', 2 unless @jobLogQueue?
    @panic 'missing @jobLogRedisUri', 2 unless @jobLogRedisUri?
    @panic 'missing @jobLogSampleRate', 2 unless @jobLogSampleRate?
    @panic 'missing @requestQueueName', 2 unless @requestQueueName?
    @panic 'missing @responseQueueName', 2 unless @responseQueueName?

  address: =>
    port: @server.port
    address: @server.address

  panic: (message, exitCode, error) =>
    error ?= new Error('generic error')
    console.error colors.red message
    console.error error?.stack
    process.exit exitCode

  run: (callback) =>
    @server = new xmpp.C2S.TCPServer
      domain: 'meshblu.octoblu.com'
      port: @port

    @server.on 'error', @panic

    client = new RedisNS @namespace, new Redis @redisUri, dropBufferSupport: true
    queueClient = new RedisNS @namespace, new Redis @redisUri, dropBufferSupport: true

    jobLogger = new JobLogger
      client: new Redis @jobLogRedisUri, dropBufferSupport: true
      indexPrefix: 'metric:meshblu-core-protocol-adapter-http'
      type: 'meshblu-core-protocol-adapter-http:request'
      jobLogQueue: @jobLogQueue

    @jobManager = new JobManagerRequester {
      client
      queueClient
      @jobTimeoutSeconds
      @jobLogSampleRate
      @requestQueueName
      @responseQueueName
      queueTimeoutSeconds: @jobTimeoutSeconds
    }

    @jobManager._do = @jobManager.do
    @jobManager.do = (request, callback) =>
      @jobManager._do request, (error, response) =>
        jobLogger.log { error, request, response }, (jobLoggerError) =>
          return callback jobLoggerError if jobLoggerError?
          callback error, response

    queueClient.on 'ready', =>
      @jobManager.startProcessing()

    uuidAliasClient = new RedisNS 'uuid-alias', new Redis @cacheRedisUri, dropBufferSupport: true
    uuidAliasResolver = new UuidAliasResolver client: uuidAliasClient
    hydrantClient = new RedisNS @firehoseNamespace, new Redis @firehoseRedisUri, dropBufferSupport: true
    @hydrant = new MultiHydrantFactory {client: hydrantClient, uuidAliasResolver}
    @hydrant.connect (error) =>
      return callback(error) if error?

    @server.on 'connection', @onConnection
    @server.on 'listening', callback

  stop: (callback) =>
    @server.end callback

  onConnection: (client) =>
    xmppHandler = new XmppHandler {client, @jobManager, @hydrant}
    xmppHandler.initialize()

module.exports = Server
