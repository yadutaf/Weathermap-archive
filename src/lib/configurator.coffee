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

# This file abstracts config files load. Only JSON is supported at the moment
# but it allows comments to be included to ease the configuration. We also 
# watch the file so that it is automagically reloaded every time a change is done
# Each time config is reloaded, a callback will be called for 
# further processing

Fs = require 'fs'

parse = (blob) ->
  # Remove commnts to get *valid* json
  blob = blob.replace(/\*([^*]|[\r\n]|(\*+([^*/]|[\r\n])))*\*+/gm,"").replace(/#.*/g,"").replace(/\/\/.*/g,"")
  # Try to parse it
  try
    config = JSON.parse blob
  catch e
    console.error "There is a syntax error in your config file. Not reloading !"
    console.error e.message
    false

loadFile = (path, cb, sync=false) ->
  if sync
    data = Fs.readFileSync path
    cb parse data.toString()
  else
    Fs.readFile path, (err, data) ->
      cb parse data.toString() if not err else cb false

module.exports = (path, cb) ->
  Fs.watchFile path, (c, p) =>
    if c.mtime < p.mtime #reload only if modified
      loadFile path, cb
  loadFile path, cb, true

