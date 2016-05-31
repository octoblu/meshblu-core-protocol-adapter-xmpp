_       = require 'lodash'
Connect = require './connect'
redis   = require 'ioredis'
RedisNS = require '@octoblu/redis-ns'
redis   = require 'ioredis'
RedisNS = require '@octoblu/redis-ns'

describe 'on: authenticate', ->
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

  it 'should exist', ->
    expect(@connection).to.exist
