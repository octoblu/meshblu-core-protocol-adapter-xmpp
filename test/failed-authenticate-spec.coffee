_           = require 'lodash'
Connect     = require './connect'
MeshbluXmpp = require 'meshblu-xmpp'
redis       = require 'ioredis'
RedisNS     = require '@octoblu/redis-ns'

describe 'on: failed authenticate', ->
  beforeEach (done) ->
    client = new RedisNS 'ns', redis.createClient()
    client.del 'request:queue', done

  beforeEach 'on connect', (done) ->
    @connect = new Connect
    @connect.connect (error, things) =>
      return done error if error?
      {@sut,@connection,@device,@jobManager} = things
      done()

  afterEach (done) ->
    @connect.shutItDown done

  beforeEach (done) ->
    badClient = new MeshbluXmpp
      hostname: 'localhost'
      port: 0xcafe
      uuid: 'nothing'
      token: 'idunno'

    badClient.connect (@error) =>
      done()

    @jobManager.getRequest ['request'], (error, request) =>
      return callback error if error?

      response =
        metadata:
          responseId: request.metadata.responseId
          code: 403

      @jobManager.createResponse 'response', response, =>

  it 'should have an error', ->
    expect(@error).to.exist
