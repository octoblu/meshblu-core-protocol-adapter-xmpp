_       = require 'lodash'
Connect = require './connect'
Redis   = require 'ioredis'
RedisNS = require '@octoblu/redis-ns'

describe 'on: message', ->
  beforeEach ->
    @firehose = new RedisNS 'messages', new Redis 'localhost', dropBufferSupport: true

  beforeEach 'on connect', (done) ->
    @connect = new Connect
    @connect.connect (error, things) =>
      return done error if error?
      {@sut,@connection,@device,@jobManager} = things
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
    return # promises

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
