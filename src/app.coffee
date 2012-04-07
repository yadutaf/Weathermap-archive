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
Path = require 'path'
Fs = require 'fs'

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


# Main Application

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

Server = Restify.createServer {
  name: "WeatherMap viewer",
  Logger: log
}

Server.use Connect.logger()
Server.use Restify.acceptParser Server.acceptable
Server.use Restify.authorizationParser()
Server.use Restify.dateParser()
Server.use Restify.queryParser()
Server.use Restify.urlEncodedBodyParser()
Server.use Restify.throttle config.throttle
Server.use Sanitize.sanitize {
    'groupname': /^[a-zA-Z-_0-9]+$/i
    'mapname': /^[a-zA-Z-_0-9]+$/i
    'date': /^\d\d\d\d-\d\d-\d\d$/i
  }

###
TODO:
  * return bad method for paths under the API dir
  * return main file
  * return main file on right start page ?
  * version API
  * doc
  * tests
  * update static servers on config change
###

# Utils

createStaticServer = (objectName, dir, urlbase, urlsuffix='') ->
  urlbase = '/'+urlbase
  urlsuffix = '\.'+urlsuffix+'/' if urlsuffix.length
  staticServer = Connect.static dir
  Server.get urlbase+'/.*'+urlsuffix, (req, res, next) ->
    req.url = req.url.substr urlbase.length  # take off leading /base so that connect locates it correctly
    staticServer req, res, (status) ->
      #TODO: handle status
      res.send new Restify.ResourceNotFoundError("Requested "+objectName+" could not be found")
      next()

###
API:
  * GET /wm-api/group => get a list a groups for which we have archives
  * GET /wm-api/:groupname/maps => get a list of available maps for this group
  * GET /wm-api/:groupname/:mapname/dates => get list of archived days
  * GET /wm-api/:groupname/:mapname/:date/times
  * GET /wm-api/*.png => get a given map
  * GET /wm/ => static app files
###

Server.get '/wm-api/groups', (req, res, next) ->
  Fs.parsedir config.weathermapsDir, (err, files) =>
    if not files.directories
      res.send new Restify.ResourceNotFoundError("No groups were found")
    else
      res.send 200, files.directories
    next()


Server.get '/wm-api/:groupname/maps', (req, res, next) ->
  Fs.parsedir config.weathermapsDir+"/"+req.params.groupname, (err, files) =>
    if not files or not files.directories
      res.send new Restify.ResourceNotFoundError("No maps were found for group "+req.params.groupname)
    else
      res.send 200, files.directories
    next()

Server.get '/wm-api/:groupname/:mapname/dates', (req, res, next) ->
  Fs.parsedir config.weathermapsDir+"/"+req.params.groupname+"/"+req.params.mapname, (err, files) =>
    if not files or not files.directories
      res.send new Restify.ResourceNotFoundError("No dates were found for group "+req.params.groupname)
    else
      res.send 200, files.directories
    next()

Server.get '/wm-api/:groupname/:mapname/:date/times', (req, res, next) ->
  Fs.parsedir config.weathermapsDir+"/"+req.params.groupname+"/"+req.params.mapname+"/"+req.params.date, (err, files) =>
    if files and files.files
      ret = []
      files.files.forEach (file) =>
        return if not file.endsWith ".png"
        ret.push file.slice(0, -4)
      if ret.length
        res.send 200, ret
        return next()
    res.send new Restify.ResourceNotFoundError("No times were found for group "+req.params.groupname+" at date "+req.params.date)
    next()

# Application static files
createStaticServer "application file", config.staticFilesDir, "wm"

# Weathermaps files
createStaticServer "map", config.weathermapsDir, "wm-api", "png"

#Server.on 'after', -> (req, res, name)
#  req.log.info '%s just finished: %d.', name, res.code

#Server.on 'NotFound', (req, res) ->
#  console.log res
#  res.send 404, req.url + ' was not found'

Server.listen config.port, config.ip, () ->
  log.info 'listening: %s', Server.url

