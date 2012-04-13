Weathermaps = Ember.Application.create()

baseurl = "/wm-api"

###
Models/Controllers
###

ListController = Ember.ArrayController.extend {
  default: 'single'#may be 'single' or 'first'
  value: ''
  options: []

  _autoSelect: (() ->
    options = @get 'options'
    #if we have a selected value
    if @get('value') in options
      return
    #if we have only one value in single mode, auto-select it
    else if options.length is 1 and @get('default') is 'single'
      @set 'value', options[0]
    #if we have more than 1 value in 'first' mode, auto-select it
    else if options.length >= 1 and @get('default') is 'first'
      @set 'value', options[0]
    else
      @set 'value', ''
  ).observes('options', 'default')
}

Weathermaps.groups = ListController.create {
  refresh: ( ->
    $.getJSON baseurl+"/groups", (data) =>
      @set 'options', data
  )
}

Weathermaps.maps = ListController.create {
  groupBinding: 'Weathermaps.groups.value'
  
  refresh: (->
    group = @get 'group'
    if not group
      @set 'options', []
    else
      $.getJSON baseurl+"/"+group+"/maps", (data) =>
        @set 'options', data
  ).observes("group")
}

Weathermaps.dates = ListController.create {
  default: 'first'
  groupBinding: 'Weathermaps.groups.value'
  mapBinding:   'Weathermaps.maps.value'
  
  refresh: (->
    group = @get 'group'
    map = @get 'map'
    if not map
      @set 'options', []
    else
      $.getJSON baseurl+"/"+group+"/"+map+"/dates", (data) =>
        data.sort()
        data.reverse()
        @set 'options', data
  ).observes("map")
}

Weathermaps.times = ListController.create {
  default: 'first'
  groupBinding: 'Weathermaps.groups.value'
  mapBinding:   'Weathermaps.maps.value'
  dateBinding:  'Weathermaps.dates.value'
  
  refresh: (->
    group = @get 'group'
    map = @get 'map'
    date = @get 'date'
    if not date
      @set 'options', []
    else
      $.getJSON baseurl+"/"+group+"/"+map+"/"+date+"/times", (data) =>
        data.sort()
        data.reverse()
        @set 'options', data
  ).observes("date")
}

Weathermaps.current = Ember.Object.create {
  lock: true
  groupBinding: "Weathermaps.groups.value"
  mapBinding: "Weathermaps.maps.value"
  dateBinding: "Weathermaps.dates.value"
  timeBinding: "Weathermaps.times.value"
  url: (->
    group = @get('group')
    map = @get('map')
    date = @get('date')
    time = @get('time')
    if group and map and date and time
      baseurl+"/"+group+"/"+map+"/"+date+"/"+time+".png"
     else
      ""
  ).property('group', 'map', 'date', 'time')
  permalink: (->
    if @get 'lock'
      return false
    if Weathermaps.routeManager
      group = @get('group')
      map = @get('map')
      date = @get('date')
      time = @get('time')
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
      return url
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
        enter: (stateManager, transition) ->
          @_super stateManager, transition
          Weathermaps.current.set 'lock', false
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
      Weathermaps.current.set 'lock', true
      chunk = stateManager.getPath 'params.'+name
      Weathermaps.current.set name, chunk
      if not next
        Weathermaps.current.set 'lock', false
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
