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
Path = require 'path'

require './lib/response'

# Configuration
staticFilesDir = Path.join __dirname,"../static/"
weathermapsDir = "/home/weathermaps/"

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

###
TODO:
  * return main file
  * return main file on right start page ?
  * config file
  * throttle
  * version API
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
  * GET /wm-maps/*.png => get a given picture
  * GET /wm/ => static app files
###

Server.get '/wm-api/groups', (req, res, next) ->
  res.respond 200, 'Found', data
  next()

Server.get '/wm-api/:groupname/maps', (req, res, next) ->
  res.respond 200, 'Found', data
  next()

Server.get '/wm-api/:groupname/:mapname/dates', (req, res, next) ->
  res.respond 200, 'Found', data
  next()

Server.get '/wm-api/:groupname/:mapname/:dates/:times', (req, res, next) ->
  res.respond 200, 'Found', data
  next()

# Application static files
createStaticServer "application file", staticFilesDir, "wm"

# Weathermaps files
createStaticServer "map", weathermapsDir, "wm-maps", "png"

#Server.on 'after', -> (req, res, name)
#  req.log.info '%s just finished: %d.', name, res.code

#Server.on 'NotFound', (req, res) ->
#  console.log res
#  res.respond 404, req.url + ' was not found'

Server.listen 3008, () ->
  log.info 'listening: %s', Server.url



