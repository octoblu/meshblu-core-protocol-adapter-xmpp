_           = require 'lodash'
async       = require 'async'
UUID        = require 'uuid'
Redis       = require 'ioredis'
RedisNS     = require '@octoblu/redis-ns'
Server      = require '../src/server'
MeshbluXmpp = require 'meshblu-xmpp'
{ JobManagerResponder } = require 'meshblu-core-job-manager'

class Connect
  constructor: ({@redisUri, @workerFunc}={}) ->
    queueId = UUID.v4()
    @requestQueueName = "test:request:queue:#{queueId}"
    @responseQueueName = "test:response:queue:#{queueId}"
    @namespace = 'ns'
    @redisUri = 'redis://localhost'

    @jobManager = new JobManagerResponder {
      @namespace
      @redisUri
      maxConnections: 1
      jobTimeoutSeconds: 10
      queueTimeoutSeconds: 10
      jobLogSampleRate: 0
      @requestQueueName
      @responseQueueName
      workerFunc: @_workerFunc
    }

  connect: (callback) =>
    async.series [
      @startJobManager
      @startServer
      @createConnection
    ], (error) =>
      return callback error if error?

      callback null, {
        @sut
        @connection
        @jobManager
        device: {uuid: 'masseuse', token: 'assassin'}
      }
      return # promises

  shutItDown: (callback) =>
    @connection.close()
    @jobManager.stop =>
      @sut.stop callback

  startJobManager: (callback) =>
    @jobManager.start callback

  startServer: (callback) =>
    @sut = new Server {
      port: 0xcafe
      jobTimeoutSeconds: 10
      jobLogQueue: 'sample-rate:1.00'
      jobLogSampleRate: '0.00'
      maxConnections: 100
      jobLogRedisUri: @redisUri
      redisUri: @redisUri
      cacheRedisUri: @redisUri
      firehoseRedisUri: @redisUri
      namespace: @namespace
      firehoseNamespace: 'messages'
      @requestQueueName
      @responseQueueName
    }

    @sut.run callback

  createConnection: (callback) =>
    @connection = new MeshbluXmpp
      hostname: 'localhost'
      port: 0xcafe
      uuid: 'masseuse'
      token: 'assassin'

    @connection.connect callback

  _workerFunc: (request, callback) =>
    if _.get(request, 'metadata.jobType') == 'Authenticate' && _.get(request, 'metadata.auth.uuid') == 'masseuse'
      return callback null, metadata: code: 204

    @workerFunc request, callback

module.exports = Connect
