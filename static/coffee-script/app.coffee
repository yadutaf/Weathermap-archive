Weathermaps = Ember.Application.create()

baseurl = "/wm-api"

###
Models/Controllers
###

ListController = Ember.ArrayController.extend {
  default: 'single'#may be 'single' or 'first'
  value: ''        #active value. *MUST* be valid (ie: in options array)
  candidate: ''    #a value we will try to apply asa it becomes valid, if ever
  options: []      #list of valid options
  
  wish: (value) ->
    if value in @get 'options'
      @set 'value', value
      @set 'candidate', ''
    else
      @set 'value', ''
      @set 'candidate', value
  
  refresh: ->
    value = @get 'value'
    if value
      @set 'candidate', value
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

      refresh: ((cb)->
        @_super()
        url = @get('databaseurl')
        parentValue = @get 'parentValue'
        if parentValue
          $.getJSON url+"/"+name+"s", cb
      )
    }
  else
    ListController.extend {
      databaseurl: baseurl
      refresh: ( ->
        @_super()
        $.getJSON @get('databaseurl')+"/"+name+"s", (data) =>
          @set 'options', data
      )
    }
  controller.create(init)

dateTime =  {
  default: 'first'
  refresh: (->
    @_super (data) =>
      data.sort()
      data.reverse()
      @set 'options', data
  ).observes 'parentValue'
}

Weathermaps.groups = createListController "group"
Weathermaps.maps = createListController "map", "group", {
  refresh: (->
    @_super (data) =>
       @set 'options', data
  ).observes 'parentValue'
}
Weathermaps.dates = createListController "date", "map", dateTime
Weathermaps.times = createListController "time", "date", dateTime

Weathermaps.current = Ember.Object.create {
  groupBinding: "Weathermaps.groups.value"
  mapBinding: "Weathermaps.maps.value"
  dateBinding: "Weathermaps.dates.value"
  timeBinding: "Weathermaps.times.value"
  url: (->
    group = @get 'group'
    map   = @get 'map'
    date  = @get 'date'
    time  = @get 'time'
    if group and map and date and time
      baseurl+"/"+group+"/"+map+"/"+date+"/"+time+".png"
     else
      ""
  ).property('group', 'map', 'date', 'time')
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
  title: (->
    value = @get 'value'
    if value then value else @get 'defaultTitle'
  ).property 'value'
  
  select: (e) ->
    $(e.target).parents('.open').removeClass('open')
    @set 'value', e.context
    return false
  
}

createMenu = (name) ->
  menu = MainMenuView.extend {
    templateName: name+'list'
    valueBinding: 'Weathermaps.'+name+'s.value'
    optionsBinding: 'Weathermaps.'+name+'s.options'
  }

Weathermaps.GroupListView = createMenu('group')
Weathermaps.MapListView = createMenu('map')
Weathermaps.DateListView = createMenu('date')
Weathermaps.TimeListView = createMenu('time')

Weathermaps.GroupListView.reopen {
  active: true
  defaultTitle: 'Group name'
}

Weathermaps.MapListView.reopen {
  groupBinding: 'Weathermaps.groups.value'
  defaultTitle: 'Map name'

  active: (->
    return if @get('group').length then true else false
   ).property 'group'
}

Weathermaps.DateListView.reopen {
  groupBinding: 'Weathermaps.groups.value'
  mapBinding:   'Weathermaps.maps.value'
  defaultTitle: 'Date'

  active: (->
    return if @get('map').length then true else false
   ).property 'map'
}

Weathermaps.TimeListView.reopen {
  groupBinding: 'Weathermaps.groups.value'
  mapBinding:   'Weathermaps.maps.value'
  dateBinding:  'Weathermaps.dates.value'
  defaultTitle: 'Time'

  active: (->
    return if @get('date').length then true else false
   ).property 'date'
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
  Weathermaps.groups.refresh()
  Weathermaps.main.appendTo 'body'
  Weathermaps.routeManager.start()
  Weathermaps.current.set 'lock', false

