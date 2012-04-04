Restify = require('restify')
Logger = require('bunyan')

# Main Application

Server = Restify.createServer {
  name: "WeatherMap viewer",
}

Server.use Restify.acceptParser Server.acceptable
Server.use Restify.authorizationParser()
Server.use Restify.dateParser()
Server.use Restify.queryParser()
Server.use Restify.urlEncodedBodyParser()

Server.head '/wm/:id', -> (req, res, next)
  res.send {hello: req.params.id}
  return next()

#Server.on 'after', -> (req, res, name)
#  req.log.info '%s just finished: %d.', name, res.code

Server.on 'NotFound', -> (req, res)
  res.send 404, req.url + ' was not found'

Server.listen 3008, -> ()
#  log.info 'listening: %s', server.url



