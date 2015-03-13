'use strict';
/* global require, module */
require('coffee-script/register');
var mm = require('./src_menus.coffee');
var cm = require('./src_calendars.coffee');

module.exports = {
  ALL_LOCATIONS : mm.all_locations(),
  ALL_MEALS     : mm.all_meals(),
  DIM_LOCATIONS : mm.dim_locations(),
  DIM_MEALS     : mm.dim_meals(),

  get_calendar_data  : function (location) {
    return cm.getJSON(location);
  }, 

  getJSON : function (location) {
    return cm.getJSON(location);
  }, 

  get_menus  : function (meals, locations, key_dim, do_refresh) {
    return mm.get_menus(meals, locations, key_dim, do_refresh);
  },

  caldb : require('./calendars.json')
};