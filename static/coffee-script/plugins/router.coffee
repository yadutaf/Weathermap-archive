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

#depends on: core 

###
app router
###

createMapChunkRouter = (name, next) ->
  #if needed, link to next level
  ChunkRouter = if next
    Em.LayoutState.extend {
      next: next
      nexts: Em.LayoutState.create {
        viewClass: Em.View.extend {}
      }
    }
  else
    Em.LayoutState
  #create instance
  ChunkRouter.create {
    route: ':'+name
    viewClass: Em.View.extend {}
    enter: (stateManager, transition) ->
      @_super stateManager, transition
      chunk = stateManager.getPath 'params.'+name
      WM[name+'s'].wish chunk
  }

WM.routeManager = Em.RouteManager.create {
  rootView: WM.main
  home: Em.LayoutState.create {
    selector: '.home'
    viewClass: Em.View.extend {
      templateName: 'home'
    }
  }
  map: Em.LayoutState.create {
    route: 'map'
    selector: '.map'
    viewClass: Em.View.extend {
      templateName: 'map'
    }
    #map router
    router: createMapChunkRouter 'group',#group level
            createMapChunkRouter 'map',  #map level
            createMapChunkRouter 'date', #date level
            createMapChunkRouter 'time'  #time level
  }
}

###
Permalink controller
###

WM.permalink = Em.Object.create {
  groupBinding: "WM.groups.value"
  mapBinding: "WM.maps.value"
  dateBinding: "WM.dates.value"
  timeBinding: "WM.times.value"
  selectedBinding: "WM.times.selected"
  _permalinkTimer: null
  _permalink: ->
    @_permalinkTimer = null
    if WM.routeManager.get('location') is null
      null #avoid first call
    else
      group = @get 'group'
      map   = @get 'map'
      date  = @get 'date'
      time  = @get 'time'
      url = "map"
      if group
        url += "/"+group
        if map
          url += "/"+map
          if date
            url+= "/"+date
            if time
              url += "/"+time
      WM.routeManager.set 'location', url
      url

  #urls are both input and output vectors. This timeout
  #helps preventing url flickering. Better ideas are welcome !
  permalink: (->
    if @_permalinkTimer
      clearTimeout @_permalinkTimer
      @_permalinkTimer = null
    @_permalinkTimer = setTimeout (=> @_permalink()), 300
  ).observes('group', 'map', 'date', 'time')
}


###
init
###
$ ->  
  #start router
  WM.routeManager.start()
