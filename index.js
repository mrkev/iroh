'use strict';

/* global require, module */
require('coffee-script/register');
var mm = require('./src/menu.coffee');
var cm = require('./src/calendar_hall.coffee');
var dm = require('./data/halls.coffee')

/**
 * Main interface for Iroh.
 * mm = menu manager, for all dining menus
 * cm = calendar manager, for all dining hall events
 */
module.exports = {
  ALL_LOCATIONS       : dm.all('eateries'),
  ALL_HALLS           : dm.all('halls'),
  ALL_BRBS            : dm.all('brbs'),
  ALL                 : dm.all(),

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