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

# "Never trust user input" implementation

Restify = require 'restify'

###
  * Returns a plugin that will parse user input "req.params.*" and check that
  * it passes some basic sanity checks (injection, local browsing, ...)
  *
  * In case of success, just pass the control to the next() handler
  * In case of failure, throw an error to the browser
  *
  * @param {Object} rules is an associative array containing "fieldname" => "preg"
  * @return {Function} restify handler.
  * @throws {InvalidArgument} on bad input
###

module.exports.sanitize = (rules) ->
  rules = {} if not rules
  (req, res, next) ->
    for param, value of req.params
      continue if not rules[param]
      continue if rules[param].test value
      return next new Restify.InvalidHeaderError 'Param '+param+' did not pass security check. Go away, *Bad Guy (tm)*'
      break
    next()
