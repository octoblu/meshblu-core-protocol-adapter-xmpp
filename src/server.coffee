_                     = require 'lodash'
colors                = require 'colors'
redis                 = require 'ioredis'
RedisNS               = require '@octoblu/redis-ns'
debug                 = require('debug')('meshblu-core-protocol-adapter-xmpp:server')
RedisPooledJobManager = require 'meshblu-core-redis-pooled-job-manager'
PackageJSON           = require '../package.json'
xmpp                  = require 'node-xmpp-server'
XmppHandler           = require './xmpp-handler'

class Server
  constructor: (options)->
    {@disableLogging, @port, @aliasServerUri} = options
    {@redisUri, @namespace, @jobTimeoutSeconds} = options
    {@maxConnections} = options
    {@jobLogRedisUri, @jobLogQueue, @jobLogSampleRate} = options
    @panic 'missing @jobLogQueue', 2 unless @jobLogQueue?
    @panic 'missing @jobLogRedisUri', 2 unless @jobLogRedisUri?
    @panic 'missing @jobLogSampleRate', 2 unless @jobLogSampleRate?

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

    # @server.on 'error', @panic

    # @jobManager = new RedisPooledJobManager {
    #   jobLogIndexPrefix: 'metric:meshblu-core-protocol-adapter-coap'
    #   jobLogType: 'meshblu-core-protocol-adapter-coap:request'
    #   @jobTimeoutSeconds
    #   @jobLogQueue
    #   @jobLogRedisUri
    #   @jobLogSampleRate
    #   @maxConnections
    #   @redisUri
    #   @namespace
    # }

    @server.on 'connection', (client) =>
      client.on 'authenticate', (opts, callback) =>
        return callback null, opts

    @server.on 'listening', callback

  stop: (callback) =>
    @server.end callback

  onConnection: (client) =>
    xmppHandler = new XmppHandler {client, @jobManager}
    xmppHandler.initialize()

module.exports = Server
