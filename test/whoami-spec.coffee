_       = require 'lodash'
Connect = require './connect'
RedisNS = require '@octoblu/redis-ns'

describe 'on: whoami', ->
  beforeEach 'on connect', (done) ->
    @workerFunc = sinon.stub()
    @connect = new Connect {@workerFunc}
    @connect.connect (error, things) =>
      return done error if error?
      {@sut,@connection,@device,@jobManager} = things
      done()

  afterEach (done) ->
    @connect.shutItDown done

  beforeEach (done) ->
    @workerFunc.yields null, metadata: {code: 204}, rawData: '{"uuid": "some-uuid"}'
    @connection.whoami (error, @whoami) => done()

  it 'should have the correct request', ->
    request = @workerFunc.firstCall.args[0]
    expect(request.metadata.jobType).to.equal 'GetDevice'
    expect(request.metadata.toUuid).to.equal 'masseuse'

  it 'should get a whoami', ->
    expect(@whoami).to.deep.equal uuid: 'some-uuid'
