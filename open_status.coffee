fs = require('fs')
rp = require('request-promise')
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

fs.readFile './api_key', (err,API_KEY) ->
  return console.log(err) if err
  END_URL += "&key=#{API_KEY}"
  getInfo info.cal_id for own loc, info of cals

# HELPERS

# pre: d is Date object
# post: (h|hh):mm (am|pm)
getTime = (d) -> d.toString('H:mm tt').toLowerCase()

# pre: a Google Calendar calendarId
# post: prints open status (text, isOpen, isAlmostOpen) of the location
getInfo = (calId) ->
  url = FRONT_URL + calId + END_URL
  console.log(url)
  rp(url).then((response) ->
    response = JSON.parse(response)

    events = response.items # list of events

    now = new Date()

    # vars set by getStatus
    status = ''
    isOpen = false
    isAlmostOpen = false
    prevEnd = null

    # pre: e is Google Calendar event
    # post: sets status, isOpen, isAlmostOpen
    getStatus = (e) ->
      # event summary contains closed -> not an open event
      if e.summary.search(/closed/i) < 0
        start = Date.parse(e.start.dateTime)
        # if status not set yet, or this event continues the previous event
        if !status or !prevEnd or start.equals(prevEnd)
          end = Date.parse(e.end.dateTime)
          prevEnd = end
          if now >= start && now < end
            # we are in this event, so set it to be open until the end
            isOpen = true
            status = "open until #{getTime(end)}"
          else if now < start
            # we are before this event, so set it as closed until the start
            dayDiff = start.getDay() - now.getDay()
            if dayDiff is 0
              if start.getHours() - now.getHours() <= 2
                isAlmostOpen = true
              status = "opens at #{getTime(start)}"
            else if dayDiff is 1
              status = "closed until tomorrow, #{getTime(start)}"
            else
              status = "closed until #{start.toString('dddd')}, #{getTime(start)}"

    # run getStatus over all the events
    getStatus event for event in events
    # if no status was found, just set it to closed
    status = 'closed' unless status

    console.log(status)
    console.log(isOpen)
    console.log(isAlmostOpen)
  )
