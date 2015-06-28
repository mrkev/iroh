require 'datejs'
timespan = require('timespan')
RRule    = require('rrule').RRule
rruleday =
  "MO" : RRule.MO
  "TU" : RRule.TU
  "WE" : RRule.WE
  "TH" : RRule.TH
  "FR" : RRule.FR
  "SA" : RRule.SA
  "SU" : RRule.SU

##
# Floors a date to the lowest midnight
module.exports.start_of_day = (date) -> date.setHours(0,0,0,0)

##
# Magic function to format date strings from the iCalendar format into a 
# structure Date.parse() can understand.
module.exports.format_yo = (a) ->
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
# @param[cal]     JSON vCalendar source. {start, end [, rrule]}.
# @param[s]       start date to render
# @param[t]       end date to render
# @return         List of events between [start] and [end] rendered from  
#                 source [cal].
module.exports.render_calendar = (cal, s, t) ->

  i = 0
  results = []

  for x, index in cal

    # Infinite RRule. Cut it to one week.
    if x.rrule and not x.rrule.end
      x.rrule.end = new Date(t.getTime()).add(7).days()

    # Latest bounds for this event / series of events.
    x.death = if x.rrule then x.rrule.end else x.end

    # Event with no end? Hmmm. Let's say it ends tomorrow. 
    if not x.death
      x.death = new Date(t.getTime()).add(1).days()

    # Filter only the entries that would affect our range.
    if s.isBefore(new Date(x.death)) and t.isAfter(new Date(x.start))
      
      # Here we have all rules and events for the days we care about... maybe.

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

        for_rrule.byweekday = byweekday if byweekday
        for_rrule.count = x.rrule.count if x.rrule.count
        
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