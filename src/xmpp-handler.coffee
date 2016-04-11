_         = require 'lodash'
async     = require 'async'
debug     = require('debug')('meshblu-core-protocol-adapter-xmpp:xmpp-handler')
http      = require 'http'
xmpp      = require 'node-xmpp-server'
ltx       = require 'ltx'
jsontoxml = require 'jsontoxml'
xml2js    = require('xml2js').parseString
http2xmpp = require './helpers/http2xmpp'

class XmppHandler
  constructor: ({@client, @jobManager, @hydrantManagerFactory}) ->
  initialize: =>
    @client.on 'authenticate', @onAuthenticate
    @client.on 'stanza', @onStanza
    @client.on 'close', @onClose

  onClose: =>
    @firehose?.close()

  onFirehose: (callback) =>
    @firehose = @hydrantManagerFactory.build()
    @firehose.on 'message', @onMessage
    @firehose.connect uuid: @auth.uuid, callback

  onMessage: (message) =>
    if message.metadata?.route?
      route = message.metadata?.route
      delete message.metadata.route
      message.metadata.route ?= []
      _.each route, (hop) =>
        message.metadata.route.push {
          name: 'hop'
          attrs:
            to: hop.to
            from: hop.from
            type: hop.type
        }

    metadataNode = ltx.parse jsontoxml {metadata: message.metadata}
    rawDataNode = ltx.parse jsontoxml {'raw-data': message.rawData}

    @client.send new xmpp.Stanza('message',
      to: "#{@auth.uuid}@meshblu.octoblu.com"
      from: 'meshblu.octoblu.com'
      type: 'normal'
    ).cnode(metadataNode).up().cnode(rawDataNode)

  onStanza: (request) =>
    metadata = request.getChild('request').getChild('metadata')

    xml2js metadata.toString(), explicitArray: false, (error, job) =>
      job.metadata.auth = @auth
      delete job.metadata.responseId
      job.rawData = request.getChild('request').getChild('rawData')?.getText()

      @jobManager.do 'request', 'response', job, (error, response) =>
        return if error?
        return @_sendError {request, response} unless response.metadata.code < 400
        return @_sendResponse {request, response}

  # API endpoints
  onAuthenticate: (opts, callback) =>
    {username, password} = opts
    @auth =
      uuid: username
      token: password

    request =
      metadata:
        auth: @auth
        jobType: 'Authenticate'

    @jobManager.do 'request', 'response', request, (error, response) =>
      return callback error if error?
      return callback false unless response? # replace with error

      if response.metadata.code != 204
        return callback false

      @onFirehose (error) =>
        return callback error if error?
        callback null, opts

  # internals
  _sendError: ({request, response}) =>
    code = response.metadata.code

    @client.send(new xmpp.Stanza('iq',
      type: 'error'
      to: request.attrs.from
      from: request.attrs.to
      id: request.attrs.id
    )
    .cnode(request.getChild('request')).up()
    .c('error').attr('type', 'cancel')
      .c(http2xmpp code).attr('xmlns', 'urn:ietf:params:xml:ns:xmpp-stanzas').up()
      .c('text').attr('xmlns', 'urn:ietf:params:xml:ns:xmpp-stanzas').attr('xml:lang', 'en-US')
        .t(http.STATUS_CODES[code]).up()
      .c('response').attr('xmlns', 'meshblu-xmpp:job-manager:response')
        .c('metadata')
          .c('code')
            .t(code))

  _sendResponse: ({request, response}) =>
    responseNode = ltx.parse jsontoxml {response}
    @client.send new xmpp.Stanza('iq',
      type: 'result'
      to: request.attrs.from
      from: request.attrs.to
      id: request.attrs.id
    ).cnode responseNode

module.exports = XmppHandler
