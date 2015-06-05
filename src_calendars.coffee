require 'datejs'
rp        = require("request-promise")
Promise   = require("es6-promise").Promise
parsecal  = require("icalendar").parse_calendar
RRule     = require('rrule').RRule
timespan  = require('timespan')

dow = ["MO", "TU", "WE", "TH", "FR", "SA", "SU"]

rruleday = {
  "MO":RRule.MO
  "TU":RRule.TU
  "WE":RRule.WE
  "TH":RRule.TH
  "FR":RRule.FR
  "SA":RRule.SA
  "SU":RRule.SU
}

typeIsArray = Array.isArray || ( value ) ->
  return {}.toString.call( value ) is '[object Array]'

##
# Iroh
# Dining module for RedAPI.
# 
# .interval: how often the cache gets cleared. (Default: 1 day)
# .data: raw cache data. Format not ensured to be compatible between versions.
##
class Iroh
  
  ##
  # @param  [caldb]  Map of location_id -> ical_url for calendars to use.
  # @return         The mighty Iroh, constructed and ready to tea.
  constructor : (@caldb) ->
    @interval = 86400000 # ms in one day
    @data = {}
    @_timer = setTimeout(@clear, @interval)

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
    curr_loc = self.caldb[location_id]
    # return list of dining ids if no location_id is specified
    return Promise.resolve(dining: Object.keys(@caldb)) if not location_id
    # return null if location_id not recognized
    return Promise.resolve(null) if not curr_loc
    
    url = curr_loc.icalendar
    new Promise((resolve, reject) ->

      rp(url).then((response) ->
        try
          data = icalchurner(response)
          data['location_id'] = location_id
          data["coordinates"] = curr_loc.coordinates if curr_loc.coordinates
          self.data[location_id] = data
          resolve data
        catch error
          reject error
        return
      
      ).catch((err) -> 
        error = new Error "Couldn't load calendar #{location_id}. Error: #{err}"
        error.name = err.name
        throw error
      )
    ) 
    

  ##
  # Cache-concious version of .query
  getJSON : (location) ->
    if @data[location]
      # if we have a cache, resolve to that
      Promise.resolve @data[location]
    else
      @query location


  ##
  # Creates date_range objects
  # @return a date_range
  date_range : (start, end) ->

    start = Date.parse start # Start date
    end   = Date.parse end   # End date
    
    return {
      s : start,
      e : end
      _type : 'date_range'
    }


  ## 
  # Gets all events in the specified (locations, days) ranges.
  #
  # @param locations    array of locations to query for
  # @return             Promise to massive object. lol.
  get_events : (locations, days) ->
    self = this

    ## Setup our date ranges

    # Single day -> Array of days
    if not typeIsArray(days) and days._type is undefined
      days = [days]
    
    # Array of days -> Array of date ranges
    if typeIsArray(days)
      days = days.map (d) -> 
        date_range =
          s : start_of(Date.parse d)
          e : (Date.parse d).add(1).days()
        return date_range
      
      console.log 'for each day, get the thing'
      return Promise.resolve([])

    # Date range -> Array of date ranges
    if days._type is 'date_range'
      days = [days]


    ## Get our calendars

    locations = locations.map (loc) -> self.getJSON(loc)
    results = {}

    return Promise.all(locations).then((res) ->
      
      res.forEach (loc) ->
        
        events = loc.events
        loc_id = loc.location_id
  
        rendered = []
        days.forEach (range) -> 
          try
            rendered = rendered.concat(render_calendar events, range.s, range.e)
          catch e
            console.trace e

  
        results[loc_id] = rendered
      
      return results
    )

    .catch (err) ->
      console.trace err


module.exports = new Iroh(require('./calendars.json'))




########################## Utils and helper functions ##########################

##
# Churns the calendar from a convulted iCalendar file to a JSON object with the
# information we care about
# @return JSON object
icalchurner = (ical) ->
  
  try
    data = parsecal(ical)
  catch error
    console.log('bro')
    console.trace error
    return null

  delete data['calendar']

  # Note: Trying to return the data as is wont work. 
  # I'm guessing it goes into an infinite loop becasue
  # data contains circular referece ({ calendar: [Circular] ... })
  
  # Get general calendar information
  cal =
    events          : []
    timezone        : data.properties["X-WR-TIMEZONE"][0].value
    name            : data.properties["X-WR-CALNAME"][0].value
    description     : data.properties["X-WR-CALDESC"][0].value
    updated         : (new Date()).valueOf()
    # method        : data.properties["METHOD"][0].value

  
  # Loop through and get event's info
  i = data.components.VEVENT.length - 1

  while i >= 0
    vevt = data.components.VEVENT[i].properties
    evt  =
      start         : Date.parse(vevt.DTSTART[0].value)
      end           : Date.parse(vevt.DTEND[0].value)
      summary       : vevt.SUMMARY[0].value
      # status        : vevt.STATUS[0].value
      # description   : vevt.DESCRIPTION[0].value
      # timestamp   : vevt.DTSTAMP[0].value
      # uid         : vevt.UID[0].value
      # updated     : vevt.CREATED[0].value
      # modified    : vevt['LAST-MODIFIED'][0].value
      # location    : vevt.LOCATION[0].value
      # revisions   : parseInt(vevt.SEQUENCE[0].value)
      # transparent : vevt.TRANSP[0].value
    
    if vevt.RRULE
      rrule              = vevt.RRULE[0].value
      evt.rrule          = frequency: rrule.FREQ
      evt.rrule.weekdays = rrule.BYDAY.split(",")                if rrule.BYDAY
      evt.rrule.end      = Date.parse(format_yo(rrule.UNTIL))    if rrule.UNTIL
      evt.rrule.count    = parseInt(rrule.COUNT)                 if rrule.COUNT
    
    if vevt.EXDATE
      evt.rexcept = Date.parse(vevt.EXDATE[0].value.toString()) 
    
    cal.events[i] = evt
    i--
  
  return cal

##
# Magic function to format date strings from the iCalendar format into a 
# structure Date.parse() can understand.
format_yo = (a) ->
  a.substr(0, 4) + "-" + 
  a.substr(4, 2) + "-" + 
  ((if (a.length > 12) then \
    a.substr(6, 5) + ":" + 
         a.substr(11, 2) + ":" + 
         a.substr(13)       \
    else a.substr(6)))


##
# Renders JSON from iCalendar (aka. a list of random events and rules) into
# events happening on a date range (aka. usuable stuff).
# @param[cal]     JSON vCalendar source
# @param[s]       start date to render
# @param[t]       end date to render
# @return         List of events between [start] and [end] rendered from  
#                 source [cal].
render_calendar = (cal, s, t) ->

  results = []

  # console.log "wanna do between", 
  #   s.toISOString().slice(0, 10), "-", t.toISOString().slice(0, 10)
  # console.log "will loop over #{cal.length} rules for cal"
  
  i = 0

  for x, index in cal

    if x.rrule and not x.rrule.end
      # console.log 'this rrule goes forever'
      x.rrule.end = new Date(t.getTime()).add(7).days()

    # End of the length we care about 
    x.death = if x.rrule then x.rrule.end else x.end

    # >> If null, probably eternally repeating event. Not sure though. check.
    #    Make it unreachably in the future.
    if not x.death
      # console.log 'gonna give it a new x.death'
      x.death = new Date(t.getTime()).add(1).days()

    # console.log "#{x.death} and #{Object.prototype.toString.call(x.death)}"

    # Filter only the entries that would affect our range.
    if s.isBefore(new Date(x.death)) and t.isAfter(new Date(x.start))
      
      # We don't care if its for a weekday outside our range.
      # if x.rrule? and x.rrule.weekdays? and x.rrule.frequency? \
      #   and x.rrule.weekdays.indexOf(dow[start.getDay()]) < 0
      #   console.log 'nope'
      #   continue

      # Here we have all rules and events for the days we care about... maybe.
      
      # console.log "#{index}. st: " + x.start.toISOString(), 
      #   " - ed:" + x.rrule.end.toISOString()

      delta_h = timespan.fromDates(x.start, x.end).totalHours()

      if x.rrule
        
        byweekday = undefined
        
        if x.rrule.weekdays
          byweekday = x.rrule.weekdays.map (x)-> return rruleday[x]

        for_rrule = {
            freq:       RRule.WEEKLY, # Change.
            dtstart:    x.start,
            until:      x.rrule.end,
            count:      x.rrule.count
        }

        if byweekday
          for_rrule.byweekday = byweekday
        
        if x.rrule.count
          for_rrule.count = x.rrule.count
        
        rule = new RRule(for_rrule)

        evres = rule.between(s, t).forEach (r) ->

          end = new Date(r.getTime()).add(delta_h).hours()

          results.push {
            summary : x.summary
            start : new Date(r.getTime())
            end   : new Date(end.getTime())
          }
          
      else 
        results.push x
      
  return results

##
# Floors a date to the lowest midnight
start_of = (date) -> date.setHours(0,0,0,0)


