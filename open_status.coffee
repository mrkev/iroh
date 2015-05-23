fs = require('fs')
rp = require("request-promise")

###
The API_KEY is from a Google Developers Console project.
It is a Public API access key.
For explanation of parameters,
  see https://developers.google.com/apis-explorer/#s/calendar/v3/calendar.events.list
###

fs.readFile('./api_key', (err,API_KEY) ->
  return console.log(err) if err

  BASE_URL = 'https://www.googleapis.com/calendar/v3/calendars/'
  DEFAULT_PARAMS = '/events?singleEvents=true&orderBy=startTime' +
                   '&maxResults=10&fields=items(summary%2Cstart%2Cend)%2Csummary'

  # Can get calId from Google Calendar
  calId = 'rpp0nrlp282t9h18hhol5f0dkc@group.calendar.google.com'
  date = new Date()
  date.setDate(date.getDate() - 1)
  timeMin = date.toISOString()
  url = "#{BASE_URL}#{calId}#{DEFAULT_PARAMS}&timeMin=#{timeMin}&key=#{API_KEY}"

  rp(url).then((response) ->
    console.log(response)
  ).catch((err) ->
    error = new Error "Couldn't get calendar info. Error: #{err}"
    error.name = err.name
    throw error
  )
)
