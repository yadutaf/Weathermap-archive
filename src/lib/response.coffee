###
# Copyright jtlebi.fr <admin@jtlebi.fr> and other contributors.
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to permit
# persons to whom the Software is furnished to do so, subject to the
# following conditions:
#
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
# OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN
# NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
# DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
# OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE
# USE OR OTHER DEALINGS IN THE SOFTWARE.
###

# This file adds a method on 'http' module to improve answers standardisation

http = require 'http'
assert = require 'assert'

http.ServerResponse.prototype.respond = (code, message, data) ->
  message = message || ""

  if 'undefined' == typeof data && 'object' == typeof message
    data = message
    message = ""

  answer = {
    code: code,
    message: message,
    data: data
  }

  body = JSON.stringify answer

  assert.equal this._headersent, undefined
  this.writeHead code, message, {
    'Content-Length': body.length,
    'Content-Type': 'application/json'
  }

  this.end body


http.ServerResponse.prototype.respondId = (code, message, id) ->
  message = message || ""
  this.respond code, message, {'_id': id}
