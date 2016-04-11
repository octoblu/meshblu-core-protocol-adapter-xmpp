STATUS_CODES =
  400: {tag: 'bad-request',             type: 'modify'}
  401: {tag: 'forbidden',               type: 'auth'}
  403: {tag: 'forbidden',               type: 'auth'}
  404: {tag: 'item-not-found',          type: 'cancel'}
  422: {tag: 'bad-request',             type: 'modify'}
  500: {tag: 'internal-server-error',   type: 'cancel'}
  502: {tag: 'remote-server-not-found', type: 'cancel'}
  504: {tag: 'remote-server-timeout',   type: 'wait'}

http2xmpp = (code) ->
  STATUS_CODES[code]

module.exports = http2xmpp
