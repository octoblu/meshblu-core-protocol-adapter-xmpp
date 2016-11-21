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
    jobLogger = new JobLogger
      client: new Redis @jobLogRedisUri, dropBufferSupport: true
      indexPrefix: 'metric:meshblu-core-protocol-adapter-xmpp'
      type: 'meshblu-core-protocol-adapter-xmpp:request'
      jobLogQueue: @jobLogQueue

    @jobManager = new JobManagerRequester {
      @namespace
      @redisUri
      maxConnections: 2
      @jobTimeoutSeconds
      @jobLogSampleRate
      @requestQueueName
      @responseQueueName
      queueTimeoutSeconds: @jobTimeoutSeconds
    }

    @jobManager.once 'error', (error) =>
      @panic 'fatal job manager error', 1, error

    @jobManager._do = @jobManager.do
    @jobManager.do = (request, callback) =>
      @jobManager._do request, (error, response) =>
        jobLogger.log { error, request, response }, (jobLoggerError) =>
          return callback jobLoggerError if jobLoggerError?
          callback error, response

    @jobManager.start (error) =>
      return callback error if error?

      uuidAliasClient = new RedisNS 'uuid-alias', new Redis @cacheRedisUri, dropBufferSupport: true
      uuidAliasResolver = new UuidAliasResolver client: uuidAliasClient
      hydrantClient = new RedisNS @firehoseNamespace, new Redis @firehoseRedisUri, dropBufferSupport: true
      @hydrant = new MultiHydrantFactory {client: hydrantClient, uuidAliasResolver}
      @hydrant.connect (error) =>
        return callback(error) if error?

        @server = new xmpp.C2S.TCPServer
          domain: 'meshblu.octoblu.com'
          port: @port

        @server.on 'error', (error) =>
          @panic 'fatal server error', 1, error

        @server.on 'connection', @onConnection
        @server.on 'listening', callback

  stop: (callback) =>
    @jobManager.stop =>
      @server.end callback

  onConnection: (client) =>
    xmppHandler = new XmppHandler {client, @jobManager, @hydrant}
    xmppHandler.initialize()

module.exports = Server
