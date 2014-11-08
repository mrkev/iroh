module.exports = require './iroh.js'

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

  console.log "will loop over #{cal.events.length} events"
  i = 0

  for x in cal.events



    # End of the length we care about 
    death = if x.rrule then x.rrule.end else x.end

    # >> If null, probably eternally repeating event. Not sure though. check.
    #    Make it unreachably in the future.
    if not death
      death = end.add(1).days()

    # console.log "#{death} and #{Object.prototype.toString.call(death)}"

    # Filter only the entries that would affect our range.
    if start.isAfter(x.start) and start.isBefore(death)
      
      # We don't care if its for a weekday outside our range.
      if x.rrule.weekdays.indexOf(dow[start.getDay()]) < 0
        continue

      # Here we have all rules and events for the days we care about... maybe.
      

      if x.rrule
        byweekday = x.rrule.weekdays.split(",").map (x)->
          return rruleday[x]

        rule = new RRule({
            freq: RRule.WEEKLY, # Change.
            byweekday: byweekday,
            dtstart: x.rrule.start,
            until: x.rrule.end
        });

        evres = rule.between(start, end).map (r) ->

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
            start : start
            end   : end
          }
          return 'done'

      else 
        results.push x
      
  return results