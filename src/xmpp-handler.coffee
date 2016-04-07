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
    options =
      explicitArray: false
      mergeAttrs: true

    xml2js metadata.toString(), options, (error, job) =>
      job.metadata.auth = @auth
      delete job.metadata.responseId
      job.rawData = request.getChild('request').getChild('rawData')?.getText()

      @jobManager.do 'request', 'response', job, (error, response) =>
        return if error?
        responseNode = ltx.parse jsontoxml {response}
        @client.send new xmpp.Stanza('iq',
          type: 'result'
          to: request.attrs.from
          from: request.attrs.to
          id: request.attrs.id
        ).cnode responseNode

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

module.exports = XmppHandler
