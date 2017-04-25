_       = require 'lodash'
Connect = require './connect'
RedisNS = require '@octoblu/redis-ns'
xml2js  = require('xml2js').parseString

describe 'on: status', ->
  beforeEach 'on connect', (done) ->
    @workerFunc = sinon.stub()
    @connect = new Connect {@workerFunc}
    @connect.connect (error, things) =>
      return done error if error?
      {@sut,@connection,@device,@jobManager} = things
      done()

  afterEach (done) ->
    @connect.shutItDown done

  describe 'when the job responds with a 200', ->
    beforeEach (done) ->
      @workerFunc.onFirstCall().yields null,
        metadata:
          code: 200
        data:
          online: true

      @connection.status (error, @status) => done error

    it 'should have the correct jobType', ->
      request = @workerFunc.firstCall.args[0]
      expect(request.metadata.jobType).to.equal 'GetStatus'

    it 'should get a status', ->
      expect(@status).to.deep.equal online: true

  describe 'when the job responds with a 504', ->
    beforeEach (done) ->
      @workerFunc.onFirstCall().yields null,
        metadata:
          code: 504

      @connection.status (@error) => done()

    it 'should have the correct jobType', ->
      request = @workerFunc.firstCall.args[0]
      expect(request.metadata.jobType).to.equal 'GetStatus'

    it 'should yield a "Gateway Timeout" error', ->
      expect(=> throw @error).to.throw 'Gateway Timeout'

    it 'should respond with an XMPP "remote-server-timeout"', (done) ->
      xml2js @error.response, explicitArray: false, (error, response) =>
        return done error if error?
        expect(response.error).to.contain.keys 'remote-server-timeout'
        done()

  describe 'when the job responds with a 500', ->
    beforeEach (done) ->
      @workerFunc.onFirstCall().yields null,
        metadata:
          code: 500
      @connection.status (@error) =>
        done()

    it 'should have the correct jobType', ->
      request = @workerFunc.firstCall.args[0]
      expect(request.metadata.jobType).to.equal 'GetStatus'

    it 'should yield a "Internal Server Error" error', ->
      expect(=> throw @error).to.throw 'Internal Server Error'

    it 'should respond with an XMPP "internal-server-error"', (done) ->
      xml2js @error.response, explicitArray: false, (error, response) =>
        return done error if error?
        expect(response.error).to.contain.keys 'internal-server-error'
        done()
