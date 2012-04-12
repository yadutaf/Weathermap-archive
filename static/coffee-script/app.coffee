Weathermaps = Ember.Application.create()

baseurl = "/wm-api"

###
Models/Controllers
###

ListController = Ember.ArrayController.extend {
  value: ''
  options: []

  select: (value) ->
    if value in options
      @set 'value', value
      return true
    else
      return false

}

Weathermaps.groups = ListController.create {
  refresh: (->
    $.getJSON baseurl+"/groups", (data) =>
      @set 'options', data
      #if we have only one value, auto-select it
      if data.length is 1
        @set 'value', data[0]
  )
}

Weathermaps.maps = ListController.create {
  groupBinding: 'Weathermaps.groups.value'
  
  refresh: (->
    @set 'value', ""#on group change, reset active value
    group = @get 'group'
    if not group
      @set 'options', []
    else
      $.getJSON baseurl+"/"+group+"/maps", (data) =>
        @set 'options', data
        #if we have only one value, auto-select it
        if data.length is 1
          @set 'value', data[0]
  ).observes("group")
}

Weathermaps.dates = ListController.create {
  groupBinding: 'Weathermaps.groups.value'
  mapBinding:   'Weathermaps.maps.value'
  
  refresh: (->
    @set 'value', ""#on map change, reset active value
    group = @get 'group'
    map = @get 'map'
    if not map
      @set 'options', []
    else
      $.getJSON baseurl+"/"+group+"/"+map+"/dates", (data) =>
        data.sort()
        data.reverse()
        @set 'options', data
        #auto-select the most recent
        if data.length >= 1
          @set 'value', data[0]
  ).observes("map")
}

Weathermaps.times = ListController.create {
  groupBinding: 'Weathermaps.groups.value'
  mapBinding:   'Weathermaps.maps.value'
  dateBinding:  'Weathermaps.dates.value'
  
  refresh: (->
    @set 'value', ""#on map change, reset active value
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
        #auto-select the most recent
        if data.length >= 1
          @set 'value', data[0]
  ).observes("date")
}

Weathermaps.current = Ember.Object.create {
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
  }
}

###
init
###
$ ->
  Weathermaps.groups.refresh()
  Weathermaps.main.appendTo 'body'
  Weathermaps.routeManager.start()
