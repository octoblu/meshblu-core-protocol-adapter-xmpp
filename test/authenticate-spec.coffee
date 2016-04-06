_       = require 'lodash'
Connect = require './connect'

describe 'on: authenticate', ->
  beforeEach 'on connect', (done) ->
    @connect = new Connect
    @connect.connect (error, things) =>
      return done error if error?
      {@sut,@connection,@device,@jobManager} = things
      done()

  afterEach (done) ->
    @sut.server.end done
    # @connect.shutItDown done

  it 'should exist', ->
    expect(@connection).to.exist
