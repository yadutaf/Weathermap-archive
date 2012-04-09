var Weathermaps, baseurl;

Weathermaps = Ember.Application.create();

baseurl = "/wm-api";

/*
Models/Controllers
*/

Weathermaps.groups = Em.ArrayController.create({
  value: '',
  options: [],
  refresh: (function() {
    var _this = this;
    return $.getJSON(baseurl + "/groups", function(data) {
      console.log(data);
      _this.set('options', data);
      if (data.length === 1) return _this.set('value', data[0]);
    });
  })
});

Weathermaps.maps = Em.ArrayController.create({
  value: '',
  options: [],
  groupBinding: 'Weathermaps.groups.value',
  refresh: (function() {
    var group,
      _this = this;
    this.set('value', "");
    group = this.get('group');
    if (!group) {
      return this.set('options', []);
    } else {
      return $.getJSON(baseurl + "/" + group + "/maps", function(data) {
        console.log(data);
        _this.set('options', data);
        if (data.length === 1) return _this.set('value', data[0]);
      });
    }
  }).observes("group")
});

Weathermaps.dates = Em.ArrayController.create({
  value: '',
  options: [],
  groupBinding: 'Weathermaps.groups.value',
  mapBinding: 'Weathermaps.maps.value',
  refresh: (function() {
    var group, map,
      _this = this;
    this.set('value', "");
    group = this.get('group');
    map = this.get('map');
    if (!map) {
      return this.set('options', []);
    } else {
      return $.getJSON(baseurl + "/" + group + "/" + map + "/dates", function(data) {
        console.log(data);
        data.sort();
        data.reverse();
        _this.set('options', data);
        if (data.length > 1) return _this.set('value', data[0]);
      });
    }
  }).observes("map")
});

Weathermaps.times = Em.ArrayController.create({
  value: '',
  options: [],
  groupBinding: 'Weathermaps.groups.value',
  mapBinding: 'Weathermaps.maps.value',
  dateBinding: 'Weathermaps.dates.value',
  refresh: (function() {
    var date, group, map,
      _this = this;
    this.set('value', "");
    group = this.get('group');
    map = this.get('map');
    date = this.get('date');
    if (!date) {
      return this.set('options', []);
    } else {
      return $.getJSON(baseurl + "/" + group + "/" + map + "/" + date + "/times", function(data) {
        console.log(data);
        data.sort();
        data.reverse();
        _this.set('options', data);
        if (data.length > 1) return _this.set('value', data[0]);
      });
    }
  }).observes("date")
});

Weathermaps.current = Ember.Object.create({
  groupBinding: "Weathermaps.groups.value",
  mapBinding: "Weathermaps.maps.value",
  dateBinding: "Weathermaps.dates.value",
  timeBinding: "Weathermaps.times.value",
  url: (function() {
    var date, group, map, time;
    group = this.get('group');
    map = this.get('map');
    date = this.get('date');
    time = this.get('time');
    if (group && map && date && time) {
      return baseurl + "/" + group + "/" + map + "/" + date + "/" + time + ".png";
    } else {
      return "";
    }
  }).property('group', 'map', 'date', 'time')
});

/*
Views
*/

Weathermaps.GroupListView = Ember.View.extend({
  templateName: 'grouplist',
  active: true,
  valueBinding: 'Weathermaps.groups.value',
  optionsBinding: 'Weathermaps.groups.options',
  title: (function() {
    var value;
    value = this.get('value');
    if (value) {
      return value;
    } else {
      return 'Group name';
    }
  }).property('value'),
  select: function(e) {
    return this.set('value', e.context);
  }
});

Weathermaps.MapListView = Ember.View.extend({
  templateName: 'maplist',
  groupBinding: 'Weathermaps.groups.value',
  active: (function() {
    if (this.get('group').length) {
      return true;
    } else {
      return false;
    }
  }).property('group'),
  valueBinding: 'Weathermaps.maps.value',
  optionsBinding: 'Weathermaps.maps.options',
  title: (function() {
    var value;
    value = this.get('value');
    if (value) {
      return value;
    } else {
      return 'Map name';
    }
  }).property('value'),
  select: function(e) {
    return this.set('value', e.context);
  }
});

Weathermaps.DateListView = Ember.View.extend({
  templateName: 'datelist',
  groupBinding: 'Weathermaps.groups.value',
  mapBinding: 'Weathermaps.maps.value',
  active: (function() {
    if (this.get('map').length) {
      return true;
    } else {
      return false;
    }
  }).property('map'),
  valueBinding: 'Weathermaps.dates.value',
  optionsBinding: 'Weathermaps.dates.options',
  title: (function() {
    var value;
    value = this.get('value');
    if (value) {
      return value;
    } else {
      return 'Date';
    }
  }).property('value'),
  select: function(e) {
    return this.set('value', e.context);
  }
});

Weathermaps.TimeListView = Ember.View.extend({
  templateName: 'datelist',
  groupBinding: 'Weathermaps.groups.value',
  mapBinding: 'Weathermaps.maps.value',
  dateBinding: 'Weathermaps.dates.value',
  active: (function() {
    if (this.get('date').length) {
      return true;
    } else {
      return false;
    }
  }).property('date'),
  valueBinding: 'Weathermaps.times.value',
  optionsBinding: 'Weathermaps.times.options',
  title: (function() {
    var value;
    value = this.get('value');
    if (value) {
      return value;
    } else {
      return 'Time';
    }
  }).property('value'),
  select: function(e) {
    return this.set('value', e.context);
  }
});

Weathermaps.groups.refresh();
