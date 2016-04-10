fs = require 'fs'
{parseString} = require 'xml2js'
xml = fs.readFileSync 'tmp/example-message.xml', 'utf8'
console.log xml

parseString xml, (error, json) =>
  console.log json
