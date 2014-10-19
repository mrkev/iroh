var rp 			= require('request-promise');
var Promise 	= require('es6-promise').Promise;
var parsecal 	= require('icalendar').parse_calendar;
var ob			= require('obender').ob;

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
		cal = {
			timezone : data.properties['X-WR-TIMEZONE'][0].value,
			events : [],
			name : data.properties['X-WR-CALNAME'][0].value,
			description : data.properties["X-WR-CALDESC"][0].value,
			method : data.properties.METHOD[0].value
		}


		// Loop through and get event's info
		for (var i = data.components.VEVENT.length - 1; i >= 0; i--) {
			vevt = data.components.VEVENT[i].properties
			evt = {
				start	 			: Date.parse(vevt.DTSTART[0].value),
				end		   		: Date.parse(vevt.DTEND[0].value),
				rrule     	: vevt.RRULE ? vevt.RRULE[0].value : undefined,
				rexcept			: vevt.EXDATE ? vevt.EXDATE[0].value : undefined,
				// timestamp		: vevt.DTSTAMP[0].value,
				// uid 				: vevt.UID[0].value,
				// updated 		: vevt.CREATED[0].value,
				// modified		: vevt['LAST-MODIFIED'][0].value,
				description : vevt.DESCRIPTION[0].value,
				// location		: vevt.LOCATION[0].value,
				// revisions		: parseInt(vevt.SEQUENCE[0].value),
				status			: vevt.STATUS[0].value,
				// summary			: vevt.SUMMARY[0].value,
				// transparent : vevt.TRANSP[0].value
			}

			if (evt.rrule) {
				evt.rrule = {
					weekdays	: evt.rrule.BYDAY,
					frequency : evt.rrule.FREQ,
					end				: Date.parse(evt.rrule.UNTIL)
				}
			}
			
			cal.events[i] = evt
		};

		return cal;
	};

	var workiCal = function (ical) {
		
	}


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

	return new DiningCalendarSource(require('./cals.json'));
})();


// module.exports.query('okenshields').then(console.dir)

// workiCal(response.body));



