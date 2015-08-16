require 'datejs'
timespan = require('timespan')
parsecal = require("icalendar").parse_calendar
RRule    = require('rrule').RRule

rruleday =
  "MO" : RRule.MO
  "TU" : RRule.TU
  "WE" : RRule.WE
  "TH" : RRule.TH
  "FR" : RRule.FR
  "SA" : RRule.SA
  "SU" : RRule.SU

mx = module.exports

Array::peek = ->
  @map (x) ->
    console.log " - #{x}"
    x

##
# Floors a date to the lowest midnight
module.exports.start_of_day = (date) ->
  new Date(date.getTime()).setHours(0,0,0,0)

##
# Creates date_range objects
# @return a date_range
module.exports.date_range = (obj) -> switch typeof obj
  when 'string'

    # 'date | date-date | xxx' -> ['date', 'date-date', 'xxx']
    obj.split('|').map (range) ->

      # -> [['date'], ['date', 'date'], ['xxx']]
      range.split('-').map (date) ->

        # -> [[date], [date, date], [null]]
        Date.parse date

      # -> [[date], [date, date], []]
      .filter (x) -> !!x

    # -> [[date], [date, date]]
    .filter (x) -> x.length > 0

    # -> [{s..e}, {s..e}]
    .map (range) ->
      switch range.length
        when 1
          start : module.exports.start_of_day(range[0])
          end   : module.exports.start_of_day(range[0].add(1).days())
        when 2
          start : module.exports.start_of_day(range[0])
          end   : module.exports.start_of_day(range[1].add(1).days())
        else
          null

    .filter (x) -> !!x

  when 'number'
    [
      start : module.exports.start_of_day(new Date obj)
      end   : module.exports.start_of_day((new Date obj).add(1).days())
    ]

  when 'object'
    if obj.start and obj.end then obj else []

  else
    []







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
# Churns the calendar from a convulted iCalendar file to a JSON object with the
# information we care about
# @return JSON object
module.exports.icalchurner = (ical) ->

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
      # status      : vevt.STATUS[0].value
      # description : vevt.DESCRIPTION[0].value
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
      evt.rrule.weekdays = rrule.BYDAY.split(",")                       if rrule.BYDAY
      evt.rrule.end      = Date.parse(mx.format_yo(rrule.UNTIL)) if rrule.UNTIL
      evt.rrule.count    = parseInt(rrule.COUNT)                        if rrule.COUNT

    if vevt.EXDATE
      evt.rexcept = Date.parse(vevt.EXDATE[0].value.toString())

    cal.events[i] = evt
    i--

  return cal


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