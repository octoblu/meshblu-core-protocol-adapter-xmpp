_           = require 'lodash'
async       = require 'async'
UUID        = require 'uuid'
Redis       = require 'ioredis'
RedisNS     = require '@octoblu/redis-ns'
Server      = require '../src/server'
MeshbluXmpp = require 'meshblu-xmpp'
{ JobManagerResponder } = require 'meshblu-core-job-manager'

class Connect
  constructor: ({@redisUri}={}) ->
    queueId = UUID.v4()
    @requestQueueName = "test:request:queue:#{queueId}"
    @responseQueueName = "test:response:queue:#{queueId}"
    @jobManager = new JobManagerResponder {
      client: new RedisNS 'ns', new Redis @redisUri, dropBufferSupport: true
      queueClient: new RedisNS 'ns', new Redis @redisUri, dropBufferSupport: true
      jobTimeoutSeconds: 10
      queueTimeoutSeconds: 10
      jobLogSampleRate: 0
      @requestQueueName
      @responseQueueName
    }

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
        jobManager: new JobManagerResponder {
          client: new RedisNS 'ns', new Redis @redisId, dropBufferSupport: true
          queueClient: new RedisNS 'ns', new Redis @redisId, dropBufferSupport: true
          jobTimeoutSeconds: 10
          queueTimeoutSeconds: 10
          jobLogSampleRate: 0
          @requestQueueName
          @responseQueueName
        }
    return # promises

  shutItDown: (callback) =>
    @connection.close()
    @sut.stop callback

  startServer: (callback) =>
    @sut = new Server {
      port: 0xcafe
      jobTimeoutSeconds: 10
      jobLogQueue: 'sample-rate:1.00'
      jobLogSampleRate: '0.00'
      maxConnections: 100
      jobLogRedisUri: 'redis://localhost:6379'
      redisUri: 'redis://localhost:6379'
      cacheRedisUri: 'redis://localhost:6379'
      firehoseRedisUri: 'redis://localhost:6379'
      namespace: 'ns'
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

    @connection.connect (error) =>
      throw error if error?
    callback()

  authenticateConnection: (callback) =>
    @jobManager.getRequest (error, @request) =>
      return callback error if error?

      return callback new Error 'Invalid Response' unless @request?

      response =
        metadata:
          responseId: @request.metadata.responseId
          code: 204

      @jobManager.createResponse response, callback

module.exports = Connect
