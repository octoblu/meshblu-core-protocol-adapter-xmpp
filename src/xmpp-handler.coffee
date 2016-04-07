_         = require 'lodash'
async     = require 'async'
debug     = require('debug')('meshblu-core-protocol-adapter-xmpp:xmpp-handler')
xmpp      = require 'node-xmpp-server'
ltx       = require 'ltx'
jsontoxml = require 'jsontoxml'
xml2js    = require('xml2js').parseString

class XmppHandler
  constructor: ({@client, @jobManager}) ->
  initialize: =>
    @client.on 'authenticate', @onAuthenticate
    @client.on 'stanza', @onStanza

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

      if response.metadata.code == 204
        return callback null, opts
      callback false

  # internals
  _sendError: ({request, response}) =>
    responseNode = ltx.parse jsontoxml {response}
    @client.send(new xmpp.Stanza('iq',
      type: 'error'
      to: request.attrs.from
      from: request.attrs.to
      id: request.attrs.id
    )
    .cnode(request.getChild('request')).up()
    .c('error').attr('type', 'cancel')
      .c('remote-server-timeout').attr('xmlns', 'urn:ietf:params:xml:ns:xmpp-stanzas').up()
      .c('text').attr('xmlns', 'urn:ietf:params:xml:ns:xmpp-stanzas').attr('xml:lang', 'en-US')
        .t('Gateway Timeout').up()
      .c('response').attr('xmlns', 'meshblu-xmpp:job-manager:response')
        .c('metadata')
          .c('code')
            .t('504'))

  _sendResponse: ({request, response}) =>
    responseNode = ltx.parse jsontoxml {response}
    @client.send new xmpp.Stanza('iq',
      type: 'result'
      to: request.attrs.from
      from: request.attrs.to
      id: request.attrs.id
    ).cnode responseNode

module.exports = XmppHandler
