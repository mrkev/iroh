fs = require('fs')
rp = require('request-promise')
Promise = require("es6-promise").Promise
cals = require('./calendars.json')

require 'datejs'

###
The API_KEY is from a Google Developers Console project.
It is a Public API access key.
Explanation of parameters:
  https://developers.google.com/apis-explorer/#s/calendar/v3/calendar.events.list
###

FRONT_URL = 'https://www.googleapis.com/calendar/v3/calendars/'
END_URL = '/events?singleEvents=true&orderBy=startTime' +
          '&maxResults=10&fields=items(summary%2Cstart%2Cend)%2Csummary' +
          "&timeMin=#{Date.today().toISOString()}"

###
post:
  Promise resolving to object:
  {
    'dining_halls' : list of getInfo(diningHall) for each dining hall
    'cafes'        : list of getInfo(cafes) for each cafes
  }
  Done for every calendar
  Each list will be sorted by name
###
getLocInfo
fs.readFile './api_key', (err,API_KEY) ->
  return console.log(err) if err
  END_URL += "&key=#{API_KEY}"

  return new Promise (resolve, reject) ->
    Promise.all(getInfo id, loc for own id, loc of cals).then((result) ->

      # sort the lists in result by name
      result.sort (a,b) -> return a.name < b.name ? -1 : 1

      # partition into diningHalls vs Cafes
      diningHalls = []
      cafes = []
      partition = (x) ->
        if x.is_dining_hall then diningHalls.push x else cafes.push x
      partition x for x in result

      resolve {
        'dining_halls' : diningHalls,
        'cafes'        : cafes,
      }
    )

# pre: d is Date object
# post: (h|hh):mm (am|pm)
getTime = (d) -> d.toString('H:mm tt').toLowerCase()

###
pre:
  id  : the id of the location
  loc : object with these attributes:
    cal_id         : a Google Calendar calendarId
    name           : name of the location
    is_dining_hall : if true, this location is a dining hall, else cafe
post:
  Promise resolving to object:
  {
    id             : id of the place
    name           : user-friendly name
    open_text      : user-friendly text of open status
    is_open        : boolean of is open
    is_almost_open : boolean of is closed, but opens within 2 hours
    is_dining_hall : if true, this location is a dining hall, else cafe
  }
###
getInfo = (id, loc) ->
  calId = loc.cal_id
  name = loc.name
  category = if loc.is_dining_hall then "dining_halls" else "cafes"

  url = FRONT_URL + calId + END_URL
  return new Promise (resolve, reject) ->
    rp(url).then((response) ->
      response = JSON.parse(response)

      events = response.items # list of events

      now = new Date()

      # vars set by getOpenText
      openText = ''
      isOpen = false
      isAlmostOpen = false
      prevEnd = null

      # pre: e is Google Calendar event
      # post: sets status, isOpen, isAlmostOpen
      getOpenText = (e) ->
        # event summary contains closed -> not an open event
        if e.summary.search(/closed/i) < 0
          start = Date.parse(e.start.dateTime)
          # if status not set yet, or this event continues the previous event
          if !openText or !prevEnd or start.equals(prevEnd)
            end = Date.parse(e.end.dateTime)
            prevEnd = end
            if now >= start && now < end
              # we are in this event, so set it to be open until the end
              isOpen = true
              openText = "open until #{getTime(end)}"
            else if now < start
              # we are before this event, so set it as closed until the start
              dayDiff = start.getDay() - now.getDay()
              if dayDiff is 0
                if start.getHours() - now.getHours() <= 2
                  isAlmostOpen = true
                openText = "opens at #{getTime(start)}"
              else if dayDiff is 1
                openText = "closed until tomorrow, #{getTime(start)}"
              else
                openText = "closed until #{start.toString('dddd')}, #{getTime(start)}"

      # run getOpenText over all the events
      getOpenText event for event in events
      # if no status was found, just set it to closed
      openText = 'closed' unless openText

      resolve {
        "id"             : id,
        "name"           : name,
        "open_text"      : openText,
        "is_open"        : isOpen,
        "is_almost_open" : isAlmostOpen,
        "is_dining_hall" : loc.is_dining_hall
      }
    )
