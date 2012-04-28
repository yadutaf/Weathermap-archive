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

WM = Em.Application.create()

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

ListController = Em.ArrayController.extend {
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
    
    #reset data before update
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
      parentValueBinding: 'WM.'+parentName+'s.value'
      parentUrlBinding: 'WM.'+parentName+'s.databaseurl'
      databaseurl: (->
        @get('parentUrl')+"/"+@get('parentValue')
      ).property('parentValue', 'parentUrl')

      load: ((parentChanged, cb)->
        @_super(parentChanged)
        parentValue = @get 'parentValue'
        if parentValue
          $.getJSON @get('databaseurl')+"/"+name+"s", (data)->
            cb(data)
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
    }
  controller.create(init)

WM.groups = createListController "group"
WM.maps = createListController "map", "group", {
  load: ((parentChanged)->
    @_super true, (data) =>
      if not data.compareArrays(@get 'options')
        @set 'options', data
      @_timeout = setTimeout (=> @load(false)), 60*60*1000#1 hour
  )
  _load: (-> @load true).observes 'parentValue'
}

WM.dates = createListController "date", "map", {
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
WM.times = createListController "time", "date", {
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

###
Views
###

# Main view. Nothing special here. Mostly a "hook"
WM.main = Em.View.create {
  templateName: 'main'
}

MainMenuView = Em.View.extend {
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
    valueBinding: 'WM.'+name+'s.value'
    optionsBinding: 'WM.'+name+'s.options'
  }
  
  if activeRule == true
    ext.active = true
  else if activeRule.length
    ext.active = (->
      return if @get(activeRule) and @get(activeRule).length then true else false
    ).property activeRule
  
  menu.create ext

WM.GroupListView = createMenu 'group', true, {
  defaultTitle: 'Group name'
}

WM.MapListView = createMenu 'map', 'group', {
  groupBinding: 'WM.groups.value'
  defaultTitle: 'Map name'
}

WM.DateListView = createMenu 'date', 'map', {
  groupBinding: 'WM.groups.value'
  mapBinding:   'WM.maps.value'
  defaultTitle: 'Date'
}

WM.TimeListView = createMenu 'time', 'date', {
  groupBinding: 'WM.groups.value'
  mapBinding:   'WM.maps.value'
  dateBinding:  'WM.dates.value'
  defaultTitle: 'Time'
}

###
init
###

$ ->
  #application re-start
  $.ajaxSetup { headers: {'accept-version': "~0.2"}}
  WM.groups.load()
  
  #load views
  WM.main.appendTo 'body'
  WM.GroupListView.appendTo '#list-menu'
  WM.MapListView.appendTo '#list-menu'
  WM.DateListView.appendTo '#list-menu'
  WM.TimeListView.appendTo '#list-menu'
