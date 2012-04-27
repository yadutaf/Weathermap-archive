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

Weathermaps = Ember.Application.create()

baseurl = "/wm-api"

###
Utils
###

keys = (obj) ->
  key for key, value of obj

Array.prototype.last = ->
  @[@length-1]

###
Models/Controllers
###

ListController = Ember.ArrayController.extend {
  default: 'single'#may be 'single' or 'first'
  value: ''        #active value. *MUST* be valid (ie: in options array)
  candidate: ''    #a value we will try to apply asa it becomes valid, if ever
  options: []      #list of valid options
  
  _timeout: null   #auto-update timer
  
  wish: (value) ->
    if value in @get 'options'
      @set 'value', value
      @set 'candidate', ''
    else
      @set 'value', ''
      @set 'candidate', value
  
  load: (parentChanged)->
    #clear auto-update timer
    clearTimeout @_timeout if @_timeout
    @_timeout = null
    
    #reset data befor update
    value = @get 'value'
    if value
      @set 'candidate', value
    if parentChanged
      @set 'value', ''
      @set 'options', []

  _autoSelect: (() ->
    options = @get 'options'
    value = @get 'value'
    def = @get 'default'
    #if we have no options
    if options.length is 0
      if value.length
        @set 'candidate', value
        @set 'value', ''
      return
    #if we have a selected value
    if value in options
      return
    if value.length is 0 and @get('candidate') in options
      @set 'value', @get 'candidate'
      @set 'candidate', ""
      return
    #if we have only one value in single mode, auto-select it
    if options.length is 1 and def is 'single'
      @set 'value', options[0]
      @set 'candidate', ""
    #if we have more than 1 value in 'first' mode, auto-select it
    else if options.length >= 1 and def is 'first'
      @set 'value', options[0]
      @set 'candidate', ''
    else#keep value in candidate until a manual selection is operated
      @set 'candidate', value
      @set 'value', ''
  ).observes('options', 'default')
}

createListController = (name, parentName, init) ->
  if 'Object' is typeof parentName
    init = parentName
  init = init || {}

  controller = if parentName
    ListController.extend {
      parentValueBinding: 'Weathermaps.'+parentName+'s.value'
      parentUrlBinding: 'Weathermaps.'+parentName+'s.databaseurl'
      databaseurl: (->
        @get('parentUrl')+"/"+@get('parentValue')
      ).property('parentValue', 'parentUrl')

      load: ((parentChanged, cb)->
        @_super(parentChanged)
        parentValue = @get 'parentValue'
        if parentValue
          $.getJSON @get('databaseurl')+"/"+name+"s", cb
      )
    }
  else
    ListController.extend {
      databaseurl: baseurl
      load: ((parentChanged) ->
        @_super(parentChanged)
        $.getJSON @get('databaseurl')+"/"+name+"s", (data) =>
          if not data.compareArrays(@get 'options')
            @set 'options', data
          @_timeout = setTimeout (=> @load(false)), 60*60*1000#1 hour
      )
      _load: (-> @load true).observes 'parentValue'
    }
  controller.create(init)

Weathermaps.groups = createListController "group"
Weathermaps.maps = createListController "map", "group", {
  load: ((parentChanged)->
    @_super true, (data) =>
      if not data.compareArrays(@get 'options')
        @set 'options', data
      @_timeout = setTimeout (=> @load(false)), 60*60*1000#1 hour
  )
  _load: (-> @load true).observes 'parentValue'
}
Weathermaps.dates = createListController "date", "map", {
  default: 'first'
  load: ((parentChanged)->
    @_super true, (data) =>
      data.sort()
      data.reverse()
      if not data.compareArrays(@get 'options')
        @set 'options', data
      @_timeout = setTimeout (=> @load(false)), 10*60*1000#10 min
  )
  _load: (-> @load true).observes 'parentValue'
}
Weathermaps.times = createListController "time", "date", {
  default: 'first'
  cache: {}
  selected: (->
    @get('cache')[@get 'value']
  ).property 'value'
  load: ((parentChanged)->  
    @_super parentChanged, (data) =>
      k = keys data
      k.sort()
      k.reverse()
      if not k.compareArrays(@get 'options')
        @set 'options', k
        @set 'cache', data
      @_timeout = setTimeout (=> @load(false)), 60*1000#1 min
  )
  _load: (-> @load true).observes 'parentValue'
}

Weathermaps.current = Ember.Object.create {
  groupBinding: "Weathermaps.groups.value"
  mapBinding: "Weathermaps.maps.value"
  dateBinding: "Weathermaps.dates.value"
  timeBinding: "Weathermaps.times.value"
  selectedBinding: "Weathermaps.times.selected"
  _permalinkTimer: null
  _permalink: ->
    @_permalinkTimer = null
    if Weathermaps.routeManager.get('location') is null
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
      Weathermaps.routeManager.set 'location', url
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
Views
###

# Main view. Nothing special here. Mostly a "hook"
Weathermaps.main = Ember.View.create {
  templateName: 'main'
}

MainMenuView = Ember.View.extend {
  defaultTitle: 'Dropdown'
  templateName: 'menu-list'
  active: false
  title: (->
    value = @get 'value'
    if value then value else @get 'defaultTitle'
  ).property 'value'
  
  select: (e) ->
    $(e.target).parents('.open').removeClass('open')
    @set 'value', e.context
    return false
  
}

createMenu = (name, activeRule, ext) ->
  menu = MainMenuView.extend {
    valueBinding: 'Weathermaps.'+name+'s.value'
    optionsBinding: 'Weathermaps.'+name+'s.options'
  }
  
  if activeRule == true
    ext.active = true
  else if activeRule.length
    ext.active = (->
      return if @get(activeRule).length then true else false
    ).property activeRule
  
  menu.create ext

Weathermaps.GroupListView = createMenu 'group', true, {
  defaultTitle: 'Group name'
}

Weathermaps.MapListView = createMenu 'map', 'group', {
  groupBinding: 'Weathermaps.groups.value'
  defaultTitle: 'Map name'
}

Weathermaps.DateListView = createMenu 'date', 'map', {
  groupBinding: 'Weathermaps.groups.value'
  mapBinding:   'Weathermaps.maps.value'
  defaultTitle: 'Date'
}

Weathermaps.TimeListView = createMenu 'time', 'date', {
  groupBinding: 'Weathermaps.groups.value'
  mapBinding:   'Weathermaps.maps.value'
  dateBinding:  'Weathermaps.dates.value'
  defaultTitle: 'Time'
}

# Player
Weathermaps.Player = Ember.View.extend {
  templateName: 'player'
  timeBinding: 'Weathermaps.times.value'
  dateBinding: 'Weathermaps.dates.value'
  timesBinding: 'Weathermaps.times.options'
  datesBinding: 'Weathermaps.dates.options'
  
  btn: 'btn'
  
  status: 'pause'
  statusButtonClass: (-> 
    'icon-'+ if @get('status') is 'pause' then 'play' else 'pause' 
  ).property 'status'
  
  isLastDate: (->
    if @get('dates')[0] is @get('date') then true else false
  ).property 'date', 'dates'
  
  isLast: (->
    if @get('isLastDate') and @get('times')[0] is @get('time') then true else false
  ).property 'time', 'date', 'times', 'dates'
    
  isFirstDate: (->
    if @get('dates').last() is @get('date') then true else false
  ).property 'date', 'dates'
  
  isFirst: (->
    if @get('isFirstDate') and  @get('times').last() is @get('time') then true else false
  ).property 'time', 'date', 'times', 'dates'
  
  timer: null
  
  #Actions
  playPause: ->
    if 'play' is @get 'status'
      if @timer
        clearTimeout @timer
        @timer=null
      @set 'status', 'pause'
    else
      @set 'status', 'play'
      @loop()
  
  loop: ->
    @moveNext()
    if @get 'isLast'
      @timer = setTimeout (=>@loop()), 60*1000#1min
    else
      @timer = setTimeout (=>@loop()), 1*1000#1 sec
  
  moveNextDate: ->
    return if @get 'isLast'
    j = @get('dates').indexOf @get 'date'
    if j
      Weathermaps.dates.wish @get('dates')[j-1]
  
  moveNext: ->
    return if @get 'isLast'
    i = @get('times').indexOf @get 'time'
    if i
      Weathermaps.times.wish @get('times')[i-1]
    else
      Weathermaps.times.wish @get('times').last()#FIXME
      @moveNextDate()
  
  movePrevDate: ->
    return if @get 'isFirst'
    j = @get('dates').indexOf @get 'date'
    if j < @get('dates').length-1
      Weathermaps.dates.wish @get('dates')[j+1]
  
  movePrev: ->
    return if @get 'isFirst'
    i = @get('times').indexOf @get 'time'
    if i < @get('times').length-1
      Weathermaps.times.wish @get('times')[i+1]
    else
      Weathermaps.times.wish @get('times')[0]#FIXME
      @movePrevDate()
  
  #status
  disablePrevDate: (->
    if not @get('date') or @get('isFirstDate')
      return 'disabled'
  ).property 'date', 'isFirstDate'
  
  disablePrev: (->
    if not @get('time') or @get('isFirst')
      return 'disabled'
  ).property 'time', 'isFirst'
  
  disablePlayPause: (->
    if not @get('time')
      return 'disabled'
  ).property 'time'
  
  disableNext: (->
    if not @get('time') or @get('isLast')
      return 'disabled'
  ).property 'time', 'isFirst' 
  
  disableNextDate: (->
    if not @get('date') or @get('isLastDate')
      return 'disabled'
  ).property 'date', 'isFirstDate' 

}

###
app router
###

createMapChunkRouter = (name, next) ->
  #if needed, link to next level
  ChunkRouter = if next
    Ember.LayoutState.extend {
      next: next
      nexts: Ember.LayoutState.create {
        viewClass: Em.View.extend {}
      }
    }
  else
    Ember.LayoutState
  #create instance
  ChunkRouter.create {
    route: ':'+name
    viewClass: Em.View.extend {}
    enter: (stateManager, transition) ->
      @_super stateManager, transition
      chunk = stateManager.getPath 'params.'+name
      Weathermaps[name+'s'].wish chunk
  }

Weathermaps.routeManager = Ember.RouteManager.create {
  rootView: Weathermaps.main
  home: Ember.LayoutState.create {
    selector: '.home'
    viewClass: Em.View.extend {
      templateName: 'home'
    }
  }
  map: Ember.LayoutState.create {
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
init
###
$ ->
  #application re-start
  $.ajaxSetup { headers: {'accept-version': "~0.1"}}
  Weathermaps.groups.load()
  
  #load views
  Weathermaps.main.appendTo 'body'
  Weathermaps.GroupListView.appendTo '#list-menu'
  Weathermaps.MapListView.appendTo '#list-menu'
  Weathermaps.DateListView.appendTo '#list-menu'
  Weathermaps.TimeListView.appendTo '#list-menu'
  
  #application launch
  Weathermaps.routeManager.start()
