_       = require 'lodash'
Connect = require './connect'
MeshbluXmpp = require 'meshblu-xmpp'

describe 'on: authenticate', ->
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
