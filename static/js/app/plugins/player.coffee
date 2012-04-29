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
Template
###

playerTemplateName = "WM-player"
playerTemplateSource = '
  {{#if date}}
  <div class="btn-group pull-left">
    <a {{bindAttr class="disablePrevDate btn"}} {{action "movePrevDate"}}>
      <i class="icon-fast-backward"></i>
    </a>
    <a {{bindAttr class="disablePrev btn"}} {{action "movePrev"}}>
      <i class="icon-step-backward"></i>
    </a>
    <a {{bindAttr class="disablePlayPause btn"}} {{action "playPause"}}>
      <i {{bindAttr class="statusButtonClass"}}></i>
    </a>
    <a {{bindAttr class="disableNext btn"}} {{action "moveNext"}}>
      <i class="icon-step-forward"></i>
    </a>
    <a {{bindAttr class="disableNextDate btn"}} {{action "moveNextDate"}}>
      <i class="icon-fast-forward"></i>
    </a>
  </div>
  {{/if}}'

###
Player View
###

WM.Player = Em.View.create {
  templateName: playerTemplateName
  timeBinding: Em.Binding.oneWay 'WM.times.value'
  dateBinding: Em.Binding.oneWay 'WM.dates.value'
  timesBinding: Em.Binding.oneWay 'WM.times.options'
  datesBinding: Em.Binding.oneWay 'WM.dates.options'
  
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
      WM.dates.wish @get('dates')[j-1]
  
  moveNext: ->
    return if @get 'isLast'
    i = @get('times').indexOf @get 'time'
    if i
      WM.times.wish @get('times')[i-1]
    else
      WM.times.wish @get('times').last()#FIXME
      @moveNextDate()
  
  movePrevDate: ->
    return if @get 'isFirst'
    j = @get('dates').indexOf @get 'date'
    if j < @get('dates').length-1
      WM.dates.wish @get('dates')[j+1]
  
  movePrev: ->
    return if @get 'isFirst'
    i = @get('times').indexOf @get 'time'
    if i < @get('times').length-1
      WM.times.wish @get('times')[i+1]
    else
      WM.times.wish @get('times')[0]#FIXME
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
Init
###

$ -> 
  WM.api.registerTemplate playerTemplateName, playerTemplateSource
  WM.Player.appendTo '.navbar-inner .container' #append template
  