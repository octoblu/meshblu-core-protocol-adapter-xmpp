_       = require 'lodash'
Connect = require './connect'
redis   = require 'ioredis'
RedisNS = require '@octoblu/redis-ns'

describe 'on: message', ->
  beforeEach (done) ->
    client = new RedisNS 'ns', redis.createClient()
    client.del 'request:queue', done

  beforeEach ->
    @firehose = new RedisNS 'messages', redis.createClient()

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
    @connection.on 'message', (@message) =>
      done()
    message = {
      metadata:
        route: [
          to: 'someone'
          from: 'another'
          type: 'message.boo'
        ]
      rawData: '{"nonce": "nonce"}'
    }
    @firehose.publish 'masseuse', JSON.stringify message

  it 'should have a message', ->
    expectedMessage =
      metadata:
        route: [
          to: 'someone'
          from: 'another'
          type: 'message.boo'
        ]
      data: nonce: 'nonce'

    expect(@message).to.deep.equal expectedMessage
