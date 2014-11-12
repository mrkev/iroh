  'use strict';
/* global require, console, module */
var rp        = require('request-promise');
var Promise   = require('es6-promise').Promise;
var parsecal  = require('icalendar').parse_calendar;
var locdb     = require('./locations.json');

module.exports = (function () {
  function DiningCalendarSource(datasrc) {
    var self = this;
    self.urls = datasrc;
    self.interval = 604800000 / 7; // One day
    self.data = {};
    
    // We will clear the data every day to get fresh, updated info.
    self.timer = setTimeout(self.clear, self.interval);
  }


  DiningCalendarSource.prototype.query = function(location) {
    var self = this;
    if (location === null || 
      location === undefined || 
      location === '') {
      return Promise.resolve({'dining' : Object.keys(this.urls)});
    } 

    var url = self.urls[location];

    return new Promise(function (resolve, reject) {
        
        rp(url)
          .then(function (response) {

            try {
              var data = icalchurner(response);

              if (locdb[location]) data['coordinates'] = locdb[location];

              self.data[location] = data;

              resolve(data);
            }
            catch (error) { reject(error); }

          })
          
          .catch(reject);
    });
    
  };

  var icalchurner = function (ical) {
    var data = parsecal(ical);

    // Note: Trying to return the data as is wont work. 
    // I'm guessing it does into an infinite loop becasue
    // data contains circular referece ({ calendar: [Circular] ... })
    
    // Get general calendar information
    var cal = {
      timezone : data.properties['X-WR-TIMEZONE'][0].value,
      events : [],
      name : data.properties['X-WR-CALNAME'][0].value,
      description : data.properties['X-WR-CALDESC'][0].value,
      method : data.properties.METHOD[0].value
    };


    // Loop through and get event's info
    for (var i = data.components.VEVENT.length - 1; i >= 0; i--) {
      var vevt = data.components.VEVENT[i].properties;
      var evt = {
        start       : Date.parse(vevt.DTSTART[0].value),
        end         : Date.parse(vevt.DTEND[0].value),
        // timestamp    : vevt.DTSTAMP[0].value,
        // uid        : vevt.UID[0].value,
        // updated    : vevt.CREATED[0].value,
        // modified   : vevt['LAST-MODIFIED'][0].value,
        description : vevt.DESCRIPTION[0].value,
        // location   : vevt.LOCATION[0].value,
        // revisions    : parseInt(vevt.SEQUENCE[0].value),
        status      : vevt.STATUS[0].value,
        summary     : vevt.SUMMARY[0].value,
        // transparent : vevt.TRANSP[0].value
      };

      // rrule
      if (vevt.RRULE) {
        var rrule = vevt.RRULE[0].value;

        evt.rrule = {
          frequency : rrule.FREQ,
        };

        if (rrule.BYDAY) evt.rrule.weekdays =  rrule.BYDAY;
        if (rrule.UNTIL) evt.rrule.end      =  Date.parse(format_yo(rrule.UNTIL));
        if (rrule.COUNT) evt.rrule.count    =  parseInt(rrule.COUNT);

      }

      // rexcept
      if (vevt.EXDATE) {
        evt.rexcept = Date.parse(vevt.EXDATE[0].value)
      }
      
      cal.events[i] = evt;
    }

    return cal;
  };

  DiningCalendarSource.prototype.clear = function() {
    this.data = null;
  };

  DiningCalendarSource.prototype.getJSON = function(location) {
    if (this.data[location] === undefined || 
      this.data[location] === null) {

      return this.query(location);

    } else {

      return Promise.resolve(this.data[location]);
    }
  };

  DiningCalendarSource.prototype.getRenderedJSON = function(location) {
    if (this.data[location] === undefined || 
      this.data[location] === null) {

      return this.query(location);

    } else {

      return Promise.resolve(this.data[location]);
    }
  };

  return new DiningCalendarSource(require('./cals.json'));
})();

// 20130827T150000Z -> 2013-08-27T15:00:00Z
var format_yo = function (a) {
  return a.substr(0,  4)  + '-' +
         a.substr(4,  2)  + '-' + 
         ((a.length > 12) ? 
                 a.substr(6,  5) + ':' +
                 a.substr(11, 2) + ':' + 
                 a.substr(13) : a.substr(6));
};

