'use strict';

/* global require, module */
require('coffee-script/register');
var mm = require('./src/menu.coffee');
var cm = require('./src/calendar_hall.coffee');

/**
 * Main interface for Iroh. 
 * mm = menu manager, for all dining hall menus
 * cm = calendar manager, for all dining hall events
 */
module.exports = {
  ALL_LOCATIONS : mm.all_locations(),
  ALL_MEALS     : mm.all_meals(),

  DATE_RANGE    : cm.date_range,

  get_calendar_data  : function (location) {
    return cm.getJSON(location);
  }, 

  getJSON     : function (location) {
    return cm.getJSON(location);
  }, 

  get_menus   : function (meals, locations) {
    return mm.get_menus(meals, locations);
  },

  get_events  : function (locations, dates) {
    return cm.get_events(locations, dates);
  },

  caldb : require('./data/calendars.json')
};