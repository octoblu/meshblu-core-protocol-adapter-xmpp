_           = require 'lodash'
Connect     = require './connect'
MeshbluXmpp = require 'meshblu-xmpp'
RedisNS     = require '@octoblu/redis-ns'

describe 'on: failed authenticate', ->
  beforeEach 'on connect', (done) ->
    @workerFunc = sinon.stub()
    @connect = new Connect { @workerFunc }
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

    @workerFunc.onFirstCall().yields null,       
      metadata:
        code: 403

  it 'should have an error', ->
    expect(@error).to.exist
