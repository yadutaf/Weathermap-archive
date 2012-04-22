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

###
API:
  * GET /wm-api/group => get a list a groups for which we have archives
  * GET /wm-api/:groupname/maps => get a list of available maps for this group
  * GET /wm-api/:groupname/:mapname/dates => get list of archived days
  * GET /wm-api/:groupname/:mapname/:date/times => get list of archived times + their meta informations
  * GET /wm-api/*.png => get a given static PNG map
  * GET /wm/ => static app files
###

Restify = require 'restify'
Fs = require 'fs'
version = '0.1.0a.1'

module.exports = (Server, config) ->
  createStaticServer = require('../lib/staticServer') Server
  
  #actual controllers
  api = {
    getGroups: (req, res, next) ->
      Fs.parsedir config.weathermapsDir, (err, files) =>
        if not files.directories
          res.send new Restify.ResourceNotFoundError("No groups were found")
        else
          res.send 200, files.directories
        next()
    
    getMaps: (req, res, next) ->
      Fs.parsedir config.weathermapsDir+"/"+req.params.groupname, (err, files) =>
        if not files or not files.directories
          res.send new Restify.ResourceNotFoundError("No maps were found for group "+req.params.groupname)
        else
          res.send 200, files.directories
        next()
    
    getDates: (req, res, next) ->
      Fs.parsedir config.weathermapsDir+"/"+req.params.groupname+"/"+req.params.mapname, (err, files) =>
        if not files or not files.directories
          res.send new Restify.ResourceNotFoundError("No dates were found for group "+req.params.groupname)
        else
          res.send 200, files.directories
        next()
    
    getTimes: (req, res, next) ->
      Fs.parsedir config.weathermapsDir+"/"+req.params.groupname+"/"+req.params.mapname+"/"+req.params.date, (err, files) =>
        if files and files.files
          ret = {}
          files.files.forEach (file) =>
            return if not file.endsWith ".png"
            time = file.slice 0, -4
            ret[time] = {
              type: 'image'
              url: "/wm-api/"+req.params.groupname+"/"+req.params.mapname+"/"+req.params.date+"/"+time+".png"
            }
          if ret != {}
            res.send 200, ret
            return next()
        res.send new Restify.ResourceNotFoundError("No times were found for group "+req.params.groupname+" at date "+req.params.date)
        next()
    
    getDefault: (req, res, next) ->
      res.statusCode = 301
      res.setHeader 'Location', '/wm/index.html'
      res.end 'Redirecting to /wm/index.html'
      return
  }

  #server definition
  Server.get {path: '/', version: version}, api.getDefault
  Server.get {path: '/wm-api/groups', version: version}, api.getGroups
  Server.get {path: '/wm-api/:groupname/maps', version: version}, api.getMaps
  Server.get {path: '/wm-api/:groupname/:mapname/dates', version: version}, api.getDates
  Server.get {path: '/wm-api/:groupname/:mapname/:date/times', version: version}, api.getTimes
  
  #static files
  createStaticServer "application file", config.staticFilesDir, "wm", '', version
  createStaticServer "map", config.weathermapsDir, "wm-api", "png", version