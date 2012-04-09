Weathermaps = Ember.Application.create()

baseurl = "/wm-api"

###
Models/Controllers
###

Weathermaps.groups = Em.ArrayController.create {
  value: ''
  options: []
  
  refresh: (->
    $.getJSON baseurl+"/groups", (data) =>
      console.log data
      @set 'options', data
      #if we have only one value, auto-select it
      if data.length is 1
        @set 'value', data[0]
  )
}

Weathermaps.maps = Em.ArrayController.create {
  value: ''
  options: []
  groupBinding: 'Weathermaps.groups.value'
  
  refresh: (->
    @set 'value', ""#on group change, reset active value
    group = @get 'group'
    if not group
      @set 'options', []
    else
      $.getJSON baseurl+"/"+group+"/maps", (data) =>
        console.log data
        @set 'options', data
        #if we have only one value, auto-select it
        if data.length is 1
          @set 'value', data[0]
  ).observes("group")
}

Weathermaps.dates = Em.ArrayController.create {
  value: ''
  options: []
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
        console.log data
        data.sort()
        data.reverse()
        @set 'options', data
        #auto-select the most recent
        if data.length >= 1
          @set 'value', data[0]
  ).observes("map")
}

Weathermaps.times = Em.ArrayController.create {
  value: ''
  options: []
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
        console.log data
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

Weathermaps.GroupListView = Ember.View.extend {
  templateName: 'grouplist'
  active: true #always visible
  
  valueBinding: 'Weathermaps.groups.value'
  optionsBinding: 'Weathermaps.groups.options'
  
  title: (->
    value = @get 'value'
    if value then value else 'Group name'
  ).property 'value'
  
  select: (e) ->
    @set 'value', e.context
  
}

Weathermaps.MapListView = Ember.View.extend {
  templateName: 'maplist'
  groupBinding: 'Weathermaps.groups.value'
  active: (->
    return if @get('group').length then true else false
   ).property 'group'
  
  valueBinding: 'Weathermaps.maps.value'
  optionsBinding: 'Weathermaps.maps.options'
  
  title: (->
    value = @get 'value'
    if value then value else 'Map name'
  ).property('value')
  
  select: (e) ->
    @set 'value', e.context
  
}

Weathermaps.DateListView = Ember.View.extend {
  templateName: 'datelist'
  groupBinding: 'Weathermaps.groups.value'
  mapBinding:   'Weathermaps.maps.value'
  active: (->
    return if @get('map').length then true else false
   ).property 'map'
  
  valueBinding: 'Weathermaps.dates.value'
  optionsBinding: 'Weathermaps.dates.options'
  
  title: (->
    value = @get 'value'
    if value then value else 'Date'
  ).property('value')
  
  select: (e) ->
    @set 'value', e.context
  
}

Weathermaps.TimeListView = Ember.View.extend {
  templateName: 'datelist'
  groupBinding: 'Weathermaps.groups.value'
  mapBinding:   'Weathermaps.maps.value'
  dateBinding:  'Weathermaps.dates.value'
  active: (->
    return if @get('date').length then true else false
   ).property 'date'
  
  valueBinding: 'Weathermaps.times.value'
  optionsBinding: 'Weathermaps.times.options'
  
  title: (->
    value = @get 'value'
    if value then value else 'Time'
  ).property('value')
  
  select: (e) ->
    @set 'value', e.context
  
}

#init
Weathermaps.groups.refresh()

