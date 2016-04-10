_       = require 'lodash'
Connect = require './connect'
redis   = require 'ioredis'
RedisNS = require '@octoblu/redis-ns'

describe 'on: status', ->
  beforeEach (done) ->
    client = new RedisNS 'ns', redis.createClient()
    client.del 'request:queue', done

  beforeEach 'on connect', (done) ->
    @connect = new Connect
    @connect.connect (error, things) =>
      return done error if error?
      {@sut,@connection,@device,@jobManager} = things
      @connection.connection.on 'online', =>
        done()

  afterEach (done) ->
    @connect.shutItDown done

  beforeEach (done) ->
    @connection.status (error, @status) =>
      done()

    @jobManager.getRequest ['request'], (error, @request) =>
      return callback error if error?

      response =
        metadata:
          responseId: @request.metadata.responseId
          code: 200
        data:
          online: true

      @jobManager.createResponse 'response', response, =>

  it 'should have the correct jobType', ->
    expect(@request.metadata.jobType).to.equal 'GetStatus'

  it 'should get a status', ->
    expect(@status).to.deep.equal online: true
