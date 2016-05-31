_       = require 'lodash'
Connect = require './connect'
redis   = require 'ioredis'
RedisNS = require '@octoblu/redis-ns'
xml2js  = require('xml2js').parseString

describe 'on: status', ->
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

  describe 'when the job responds with a 200', ->
    beforeEach (done) ->
      @connection.status (error, @status) =>
        done error

      @jobManager.getRequest ['request'], (error, @request) =>
        return callback error if error?

        response =
          metadata:
            responseId: @request.metadata.responseId
            code: 200
          data:
            online: true

        @jobManager.createResponse 'response', response, =>

    it 'should have the correct jobType', ->
      expect(@request.metadata.jobType).to.equal 'GetStatus'

    it 'should get a status', ->
      expect(@status).to.deep.equal online: true

  describe 'when the job responds with a 504', ->
    beforeEach (done) ->
      @connection.status (@error) =>
        done()

      @jobManager.getRequest ['request'], (error, @request) =>
        return callback error if error?

        response =
          metadata:
            responseId: @request.metadata.responseId
            code: 504

        @jobManager.createResponse 'response', response, =>

    it 'should have the correct jobType', ->
      expect(@request.metadata.jobType).to.equal 'GetStatus'

    it 'should yield a "Gateway Timeout" error', ->
      expect(=> throw @error).to.throw 'Gateway Timeout'

    it 'should respond with an XMPP "remote-server-timeout"', (done) ->
      xml2js @error.response, explicitArray: false, (error, response) =>
        return done error if error?
        expect(response.error).to.contain.keys 'remote-server-timeout'
        done()

  describe 'when the job responds with a 500', ->
    beforeEach (done) ->
      @connection.status (@error) =>
        done()

      @jobManager.getRequest ['request'], (error, @request) =>
        return callback error if error?

        response =
          metadata:
            responseId: @request.metadata.responseId
            code: 500

        @jobManager.createResponse 'response', response, =>

    it 'should have the correct jobType', ->
      expect(@request.metadata.jobType).to.equal 'GetStatus'

    it 'should yield a "Internal Server Error" error', ->
      expect(=> throw @error).to.throw 'Internal Server Error'

    it 'should respond with an XMPP "internal-server-error"', (done) ->
      xml2js @error.response, explicitArray: false, (error, response) =>
        return done error if error?
        expect(response.error).to.contain.keys 'internal-server-error'
        done()
