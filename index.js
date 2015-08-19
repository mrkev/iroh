'use strict';

/* global require, module */
require('coffee-script/register');
var mm = require('./src/menu.coffee');
var cm = require('./src/calendar_hall.coffee');

/**
 * Main interface for Iroh.
 * mm = menu manager, for all dining menus
 * cm = calendar manager, for all dining hall events
 */
module.exports = {
  ALL_LOCATIONS : mm.all_locations(),
  ALL_MEALS     : mm.all_meals(),

  DATE_RANGE    : cm.date_range,

  get_menus   : function (locations, meals) {
    return mm.get_menus(locations, meals);
  },

  get_events  : function (locations, dates) {
    return cm.get_events(locations, dates);
  },

  caldb : require('./data/calendars.json')
};