STATUS_CODES =
  500: 'internal-server-error'
  504: 'remote-server-timeout'

http2xmpp = (code) ->
  STATUS_CODES[code]

module.exports = http2xmpp
