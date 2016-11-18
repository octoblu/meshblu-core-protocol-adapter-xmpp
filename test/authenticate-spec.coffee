_       = require 'lodash'
Connect = require './connect'
RedisNS = require '@octoblu/redis-ns'
RedisNS = require '@octoblu/redis-ns'

describe 'on: authenticate', ->
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
