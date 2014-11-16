rp        = require("request-promise")
Promise   = require("es6-promise").Promise
parsecal  = require("icalendar").parse_calendar

###
# Iroh
# Dining module for RedAPI.
###
class Iroh
  
  ##
  # @param  [caldb]  Map of location_id -> ical_url for calendars to use.
  # @return         The mighty Iroh, constructed and ready to tea.
  constructor : (@caldb) ->
    @interval = 604800000 / 7 # One day
    @data = {}
    @timer = setTimeout(@clear, @interval)

  ##
  # Puts the cache outside for the garbage collector to pickup. 
  clear : ->
    @data = null

  ##
  # Queries and transforms data for specified [location_id]. Saves it in cache.
  # @param  [location_id] Valid location identifier to query.
  # @return Promise -> JSON object for parsed iCalendar data for location,
  query : (location_id) ->
    self = this
    return Promise.resolve(dining: Object.keys(@caldb)) if not location_id
    return Promise.resolve(null) if not self.caldb[location_id]
    
    url = self.caldb[location_id].icalendar
    new Promise((resolve, reject) ->

      rp(url).then (response) ->
        try
          data = icalchurner(response)
          data["coordinates"] = self.caldb[location_id].coordinates \
                              if self.caldb[location_id].coordinates
          self.data[location_id] = data
          resolve data
        catch error
          reject error
        return
      return
    )

  getJSON : (location) ->
    if not @data[location]
      @query location
    else
      Promise.resolve @data[location]


module.exports = new Iroh(require('./calendars.json'))


###
# Utils and the like.
###

icalchurner = (ical) ->
  data = parsecal(ical)

  delete data['calendar']
  console.log(data)

  # Note: Trying to return the data as is wont work. 
  # I'm guessing it does into an infinite loop becasue
  # data contains circular referece ({ calendar: [Circular] ... })
  
  # Get general calendar information
  cal =
    events          : []
    timezone        : data.properties["X-WR-TIMEZONE"][0].value
    name            : data.properties["X-WR-CALNAME"][0].value
    description     : data.properties["X-WR-CALDESC"][0].value
    updated         : (new Date()).valueOf();
    # method        : data.properties["METHOD"][0].value

  
  # Loop through and get event's info
  i = data.components.VEVENT.length - 1

  while i >= 0
    vevt = data.components.VEVENT[i].properties
    evt =
      start         : Date.parse(vevt.DTSTART[0].value)
      end           : Date.parse(vevt.DTEND[0].value)
      description   : vevt.DESCRIPTION[0].value
      status        : vevt.STATUS[0].value
      summary       : vevt.SUMMARY[0].value
      # timestamp   : vevt.DTSTAMP[0].value
      # uid         : vevt.UID[0].value
      # updated     : vevt.CREATED[0].value
      # modified    : vevt['LAST-MODIFIED'][0].value
      # location    : vevt.LOCATION[0].value
      # revisions   : parseInt(vevt.SEQUENCE[0].value)
      # transparent : vevt.TRANSP[0].value
    
    if vevt.RRULE
      rrule = vevt.RRULE[0].value
      evt.rrule = frequency: rrule.FREQ
      evt.rrule.weekdays = rrule.BYDAY                    if rrule.BYDAY
      evt.rrule.end = Date.parse(format_yo(rrule.UNTIL))  if rrule.UNTIL
      evt.rrule.count = parseInt(rrule.COUNT)             if rrule.COUNT
    
    if vevt.EXDATE
      evt.rexcept = Date.parse(vevt.EXDATE[0].value.toString()) 
    
    cal.events[i] = evt
    i--
  
  return cal

format_yo = (a) ->
  a.substr(0, 4) + "-" + 
  a.substr(4, 2) + "-" + 
  ((if (a.length > 12) then \
    a.substr(6, 5) + ":" + 
         a.substr(11, 2) + ":" + 
         a.substr(13)       \
    else a.substr(6)))
