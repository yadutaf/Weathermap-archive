# Weathermap-Archive
      
  Insanely small and simple application to archive and view your weathermaps (or any periodically generated images).
  This is an simple solution to get an overview of your networks usage evolution along the time. Most of the time,
  you MRTG will provide you with individual link usage over the time while a weathermap will give you an instant overview.
  But sometimes, you need to get a global view of your network along the time.
  
  I got the original idea when I was working for the IXP of Lyon (http://www.rezopole.net). We had a minor outage and I 
  really missed a proper archiving system.
  
  As a demo, I archive all weathermaps from OVH, a French Hosting compagny. http://ovh.jtlebi.fr/

## Installation

  This applications uses 2 modules.
  
  * Archiving engine
  * Web Interface / REST API
  

  Get the code 
    
    git clone https://github.com/jtlebi/Weathermap-archive.git
  
  Create a folder to hold the weathermaps
    
    $ mkdir -p /path/to/archive
  
  Adapt the example script in /path/to/code/bin/ovh.sh and add a rule to your cron

    $ vim /etc/crontab
    
    ```
    */5 * * * * root /path/to/code/bin/ovh.sh #run every 5 minutes
    ```
    
    Please not that it is highly recommended to create a dedicated unpriviledged user !
  
  Copy and edit conguration file
    
    $ cp /path/to/code/config/config.json.dist /path/to/code/config/config.json
  
  Install dependancies and Run it (tm) !
    
    $ cd /path/to/code/
    $ bin/run.sh

  Next step :
    
    * create a dedicated unpriviledged user
    * hook git pull to "bin/build.sh" to always be up to date
    * create a "watch script" for auto update in dev mode

## Features

 * Periodically archive weathermaps via a cron script
 * Intuitively navigate among archived images
 * Automatically updates displayed image to always be up to date
 * Provide an easy API
 * Provide a simple and intutive interface to navigate the archived weathermaps
 * 2 level of categorizations
   * top level group (organizations, units)
   * map name

## Roadmap/History

 * version 0.2 => "Let's REST a little, tidy it"
   * [DONE] module/file separation of client side app.coffee
   * [WIP] migrate file structure to a database
   * [WIP] build script (compile less and coffee files)
   * [TODO] plugin loader
   * [WISH] support multiple storage backend on the server side
   * [WISH] menu update push to reduce load
 * version 0.1 => "Where the trip begins"
   * [DONE] basic Read-Only API
   * [DONE] intuitive bare-bones ember.js interface

## API

  The provided API is a simple wrapper around the filesystem with some bonus security checks :). It aims to ease
  building any application relying in the archived data.
  All request are GET only and the answers are JSON.
  
  * GET /wm-api/groups => get a list a groups for which we have archives
  * GET /wm-api/:groupname/maps => get a list of available maps for this group
  * GET /wm-api/:groupname/:mapname/dates => get list of archived days
  * GET /wm-api/:groupname/:mapname/:date/times => get a list of archived time for this date
  * GET /wm-api/:groupname/:mapname/:date/:time.png => get a given map
  * GET /wm/ => static app files (Not really an API)

### API reqest format
  
  All API are GET only. Any parameter that would be appended afer a question mark
  are ignored. All valid parameters are included in the route. You may customize
  route chunks starting with a colon. 

### API answers format
  
  Groups, maps and dates API return a valid JSON array containing the complete list
  of valid values in the current context. Result should not be cached for too long
  as they may change very often.
  
  Times API will return a hashmap of the form
  
  
  ``` js
  {
    TIME: 
    {
      type: TYPE
      field1:...
      field2:...
      ...
      fieldn:...
    }
  }
  ```
  
  Where TIME is of the form '..h..'. The only mandatory field is the TYPE fieled
  which indicates which render to use.

## Contribute

  Starting with the 0.2 branch, the application is clearly separated into modules
  stored in 'static/js/app' folder. Modules can belong in either of 2 categories :
  
  * core => main application file needed to actually see something (plugin api, render api, router)
  * plugins => optional modules (actual renderer, player, <YOUR PLUGIN HERE>, ...)
  

### Module struccture

  Each module starts with the copyright block followed by a depency line. This
  line helps to build the import in the index.html file.
  
  From the module, you can freely access (bind) anything from the modules you depend on.
  Please note that the whole application is namespaced under 'WM' and Ember should be used
  from 'Em'.
  
  If your module require a template to be dynamically injected in the application
  we provide a simple helper "WM.api.registerTemplate(templateName, templateSource)"
  
  /!\ Please note that *All* variable in you module are globale. It is *your* responsability to namespace them /!\

### MyPlugin example
  
  ``` coffee
  #depends on: core 
  
  ###
  myPlugin Template
  ###
  
  myPluginTemplateSource = '<p>My plugin version is {{version}}</p>'
  myPluginTemplateName   = "MyPlugin"
  
  ###
  myPlugin View
  ###
  
  WM.MyPluginView = Em.View.create {
    templateName: myPluginTemplateName
    #...
  }
  
  ###
  myPlugin Init
  ###
  
  $ -> 
    WM.api.registerTemplate myPluginTemplateName, myPluginTemplateSource
    WM.Player.appendTo '#selector' #append template
  ```
 
## Dependancies

  This application would not have been possible without some amazing external projects. Here is small list of these
  
  * Node.js > 0.6
  * Restify
  * Connect.js
  * Ember.js
  * Bootstrap

## License 

(The MIT License)

Copyright jtlebi.fr &lt;admin@jtlebi.fr&gt; and other contributors.

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

