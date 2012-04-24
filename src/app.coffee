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

Restify = require 'restify'
Connect = require 'connect'
Logger = require 'bunyan'
Sanitize = require './lib/sanitize'
Workarounds = require './lib/workarounds'
Path = require 'path'
Fs = require 'fs'

package = JSON.parse Fs.readFileSync __dirname+'/../package.json'

require './lib/parsedir'
require './lib/utils'

# Configuration
config = {
  staticFilesDir: Path.resolve(__dirname, "../static"),
  ip: "0.0.0.0",
  port: 3008,
  throttle: {
    burst: 100,
    rate: 50,
    ip: true
  }
}
configfilename = Path.resolve __dirname,  "../config/config.json"
configurator = require './lib/configurator'
configurator configfilename, (conf) ->
  return if not conf
  if conf.staticFilesDir
    config.staticFilesDir = Path.resolve __dirname, conf.staticFilesDir
  if conf.weathermapsDir
    config.weathermapsDir = Path.resolve __dirname, conf.weathermapsDir
  if conf.ip
    config.ip = conf.ip
  if conf.port
    config.port = conf.port
  if conf.throttle
    config.throttle = conf.throttle

log = new Logger {
  name: "WeatherMap viewer",
  level: 'trace',
  service: 'weathermap',
  serializers: {
    err: Logger.stdSerializers.err,
    req: Logger.stdSerializers.req,
    res: Restify.bunyan.serializers.response
  }
}

# Main Application

Server = Restify.createServer {
  name: "WeatherMap viewer"
  Logger: log
  version: package.version
}

Server.use Workarounds.forLogger()
Server.use Connect.logger('dev')
Server.use Restify.acceptParser Server.acceptable
Server.use Restify.authorizationParser()
Server.use Restify.dateParser()
Server.use Restify.queryParser()
Server.use Restify.urlEncodedBodyParser()
Server.use Restify.throttle config.throttle
Server.use Sanitize.sanitize {
    'groupname': /^[a-zA-Z-_0-9]+$/i
    'mapname': /^[a-zA-Z-_0-9]+$/i
    'date': /^[a-zA-Z-_0-9]+$/i
#    'date': /^\d\d\d\d-\d\d-\d\d$/i
  }

###
TODO:
  * return bad method for paths under the API dir
  * doc
  * tests
  * update static servers on config change
  * add jsonp support
###

# API

V0_1 = require('./api/v0.1') Server, config

Server.listen config.port, config.ip, () ->
  log.info 'listening: %s', Server.url

