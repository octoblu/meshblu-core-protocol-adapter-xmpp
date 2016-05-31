_       = require 'lodash'
Connect = require './connect'
redis   = require 'ioredis'
RedisNS = require '@octoblu/redis-ns'

describe 'on: whoami', ->
  beforeEach (done) ->
    client = new RedisNS 'ns', redis.createClient(dropBufferSupport: true)
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
    @connection.whoami (error, @whoami) =>
      done()

    @jobManager.getRequest ['request'], (error, @request) =>
      return callback error if error?

      response =
        metadata:
          responseId: @request.metadata.responseId
          code: 200
        data:
          uuid: 'some-uuid'

      @jobManager.createResponse 'response', response, =>

  it 'should have the correct request', ->
    expect(@request.metadata.jobType).to.equal 'GetDevice'
    expect(@request.metadata.toUuid).to.equal 'masseuse'

  it 'should get a whoami', ->
    expect(@whoami).to.deep.equal uuid: 'some-uuid'
