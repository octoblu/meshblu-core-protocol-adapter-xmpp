_           = require 'lodash'
async       = require 'async'
uuid        = require 'uuid'
redis       = require 'ioredis'
RedisNS     = require '@octoblu/redis-ns'
JobManager  = require 'meshblu-core-job-manager'
Server      = require '../src/server'
MeshbluXmpp = require 'meshblu-xmpp'

class Connect
  constructor: ({@redisUri}={}) ->
    @jobManager = new JobManager
      client: new RedisNS 'ns', redis.createClient(@redisUri)
      timeoutSeconds: 1

  connect: (callback) =>
    async.series [
      @startServer
      @createConnection
      @authenticateConnection
    ], (error) =>
      return callback error if error?
      callback null,
        sut: @sut
        connection: @connection
        device: {uuid: 'masseuse', token: 'assassin'}
        jobManager: new JobManager
          client: new RedisNS 'ns', redis.createClient(@redisId)
          timeoutSeconds: 1

  shutItDown: (callback) =>
    @connection.close()

    async.series [
      async.apply @sut.stop
    ], callback

  startServer: (callback) =>
    @sut = new Server
      port: 0xcafe
      jobTimeoutSeconds: 1
      jobLogQueue: 'sample-rate:1.00'
      jobLogSampleRate: '0.00'
      maxConnections: 100
      jobLogRedisUri: 'redis://localhost:6379'
      redisUri: 'redis://localhost:6379'
      namespace: 'ns'

    @sut.run callback

  createConnection: (callback) =>
    @connection = new MeshbluXmpp
      hostname: 'localhost'
      port: 0xcafe
      uuid: 'masseuse'
      token: 'assassin'
      protocol: 'http'

    @connection.connect =>
    callback()

  authenticateConnection: (callback) =>
    @jobManager.getRequest ['request'], (error, @request) =>
      return callback error if error?

      response =
        metadata:
          responseId: @request.metadata.responseId
          code: 204

      @jobManager.createResponse 'response', response, callback

module.exports = Connect
