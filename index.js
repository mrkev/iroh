'use strict';

/* global require, module */
require('coffee-script/register');
var mm = require('./src/menu_hall.coffee');
var cm = require('./src/calendar_hall.coffee');


/**
 * Main interface for Iroh. 
 * mm = menu manager, for all dining hall menus
 * cm = calendar manager, for all dining hall events
 */
module.exports = {
  ALL_LOCATIONS : mm.all_locations(),
  ALL_MEALS     : mm.all_meals(),

  DIM_LOCATIONS : mm.dim_locations(),
  DIM_MEALS     : mm.dim_meals(),

  DATE_RANGE    : cm.date_range,

  get_calendar_data  : function (location) {
    return cm.getJSON(location);
  }, 

  getJSON     : function (location) {
    return cm.getJSON(location);
  }, 

  get_menus   : function (meals, locations, key_dim, do_refresh) {
    return mm.get_menus(meals, locations, key_dim, do_refresh);
  },

  get_events  : function (locations, dates) {
    return cm.get_events(locations, dates);
  },

  caldb : require('./data/calendars.json')
};