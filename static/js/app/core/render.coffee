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

#depends on: core; router

###
Renders are expected to :
* be of View type
* be stored in js file './render/name.js'
* be namespaced as 'WM.render.name'
* register there source handlebar code via "registerTemplate"
* having a templateName of the form "map-render-name"
* handle themeselves their updates. Em provides enough tools !
###

WM.render = Em.Object.create {
  selectedBinding: 'WM.times.selected'
  currentStateBinding: 'WM.routeManager.currentState'
  renderEngines: []
  currentType: ''
  views: {}
  
  registerTemplate: (name, source) ->
    WM.api.registerTemplate 'map-render-'+name, source
  
  #re-inits the render on route switches to get the image back (was detached from DOM)
  initRender: (->
    state = @get 'currentState'
    current = @get 'currentType'
    
    return if not current.length
    
    while state
      if state.name and state.name == "map"
        if current.length
          WM.render.views[current].remove()
          WM.render.views[current].appendTo '#map-render'
        return
      else
        state = state.parentState
  ).observes 'currentState'
  
  refreshRender: (->
    selected = @get 'selected'
    prevType = @get 'currentType'
    
    #did the render type change ?
    if not selected or selected.type == prevType
      return
      
    #if type changed -> unload render engine and load the new one
    if WM.render.views[prevType]
      WM.render.views[prevType].remove()
    @set 'currentType', selected.type
    
    #if we do not know yet the render engine, load it
    engines = @get 'renderEngines'
    if selected.type not in @get 'renderEngines'
      engines.push selected.type
      @set 'renderEngines', engines
      $.getScript basedir+'/plugins/render/'+selected.type+'.js', ->
        WM.render.views[selected.type].appendTo '#map-render'
    else
      WM.render.views[selected.type].appendTo '#map-render'
    return ""
  ).observes 'selected'
}