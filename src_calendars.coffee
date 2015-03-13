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
    return Promise.resolve(@data[location_id]) unless @data[location_id] == undefined
    
    url = self.caldb[location_id].icalendar
    new Promise((resolve, reject) ->

      rp(url).then((response) ->
        try
          data = icalchurner(response)
          data["coordinates"] = self.caldb[location_id].coordinates \
                              if self.caldb[location_id].coordinates
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


##
# @param[cal]     JSON vCalendar source
# @param[start]   start date to render
# @param[end]     end date to render
# @return         List of events between [start] and [end] rendered from  
#                 source [cal].
render_calendar = (cal, start, end) ->

  start = Date.parse start # Start date
  end   = Date.parse end   # End date

  # Find rules we might acutally care about
  # 
    
  results = []

  console.log "will loop over #{cal.length} events"
  i = 0

  for x in cal

    # End of the length we care about 
    death = if x.rrule then x.rrule.end else x.end

    # >> If null, probably eternally repeating event. Not sure though. check.
    #    Make it unreachably in the future.
    if not death
      death = end.add(1).days()

    # console.log "#{death} and #{Object.prototype.toString.call(death)}"

    # Filter only the entries that would affect our range.
    if start.isAfter(new Date(x.start)) and start.isBefore(new Date(death))
      
      # We don't care if its for a weekday outside our range.
      if x.rrule? and x.rrule.weekdays? and x.rrule.frequency? and x.rrule.weekdays.indexOf(dow[start.getDay()]) < 0
        continue

      # Here we have all rules and events for the days we care about... maybe.
      
      if x.rrule
        
        byweekday = undefined
        if x.rrule.weekdays
          byweekday = x.rrule.weekdays.split(",").map (x)-> return rruleday[x]

        for_rrule = {
            freq:       RRule.WEEKLY, # Change.
            dtstart:    x.rrule.start,
            until:      x.rrule.end,
            count:      x.rrule.count
        }

        if byweekday
          for_rrule.byweekday = byweekday
        
        if x.rrule.count
          for_rrule.count = x.rrule.count
        
        rule = new RRule(for_rrule);

        evres = rule.between(start, end).map (r) ->

          x.start = new Date(x.start)
          x.end = new Date(x.end)

          start = new Date(
            r.getFullYear(),
            r.getMonth(),
            r.getDay(),
            x.start.getHours(),
            x.start.getMinutes(),
            x.start.getSeconds())

          end = new Date(
            r.getFullYear(),
            r.getMonth(),
            r.getDay(),
            x.end.getHours(),
            x.end.getMinutes(),
            x.end.getSeconds())

          results.push {
            summary : x.summary
            start : Number(start)
            end   : Number(end)
          }
          
          return 'done'

      else 
        results.push x
      
  return results
