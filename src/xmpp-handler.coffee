_                                     = require 'lodash'
async                                 = require 'async'
debug                                 = require('debug')('meshblu-core-protocol-adapter-xmpp:xmpp-handler')

class XmppHandler
  constructor: ({@client, @jobManager}) ->
  initialize: =>
    @client.on 'authenticate', @onAuthenticate

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
      if response.metadata.code == 204
        return callback null, opts
      callback false

module.exports = XmppHandler
