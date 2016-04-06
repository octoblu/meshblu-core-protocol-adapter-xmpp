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
    @connect.shutItDown done

  beforeEach ->
    request =
      metadata:
        uuid: 'to-uuid'
        token: 'to-ken'
      data: {}

  it 'should', ->

  #   @connection.send 'authenticate', request
  #
  # it 'should create a request', (done) ->
  #   @jobManager.getRequest ['request'], (error,request) =>
  #     return done error if error?
  #     return done new Error('Request timeout') unless request?
  #     expect(request.metadata.jobType).to.deep.equal 'Authenticate'
  #     done()
  #
  # describe 'when the dispatcher responds', ->
  #   beforeEach (done) ->
  #     @connection.once 'authenticate', (@response) => done()
  #
  #     @jobManager.getRequest ['request'], (error,request) =>
  #       return done error if error?
  #       return done new Error('Request timeout') unless request?
  #       @responseId = request.metadata.responseId
  #       response =
  #         metadata:
  #           responseId: request.metadata.responseId
  #           code: 204
  #         data:
  #           uuid: 'OHM MY!! WATT HAPPENED?? VOLTS'
  #       @jobManager.createResponse 'response', response, (error) =>
  #         return done error if error?
  #
  #   it 'should yield the response', ->
  #     expect(@response).to.deep.equal
  #       metadata:
  #         responseId: @responseId
  #         code: 204
  #       rawData: '{"uuid":"OHM MY!! WATT HAPPENED?? VOLTS"}'
