##
# Iroh
# Calendar event module for RedAPI
# 

rp         = require 'request-promise'
cal_tools  = require '../lib/calendar_tools'
type       = require '../lib/type'
all_halls  = (require '../data/halls').all('halls')
Promise    = require('es6-promise').Promise

MS_ONE_DAY = 86400000


icalendar = (require '../data/halls').property('icalendar')
coordinates = (require '../data/halls').property('coordinates')

##
# Queries and transforms data for specified [location_id]. 
# @param  [location_id] Valid location identifier to query.
# @return Promise -> JSON object for parsed iCalendar data for location,
query = (location_id) ->

  # return Promise to null if location_id not recognized
  return Promise.resolve(null) if not icalendar[location_id]

  return rp (icalendar[location_id])
    .catch (err) ->
      error = new Error "Couldn't fetch icalendar for #{location_id}: #{err}"
      error.name = err.name
      throw error

    .then (response) ->
      try
        data = cal_tools.icalchurner(response)
        data['location_id'] = location_id
        data["coordinates"] = coordinates[location_id] if coordinates[location_id]
        return data
      catch error
        throw error
      return

    .catch (err) ->
      error = new Error "Couldn't load calendar #{location_id}. Error: #{err}"
      error.name = err.name
      throw error

##
# Creates date_range objects
# @return a date_range
date_range = (start, end) ->

  s = (Date.parse start) # Start date
  e = (Date.parse end)   # End date

  return {s, e, _type : 'date_range'}


##
# Gets all events in the specified (locations, days) ranges.
#
# @param locations    array of locations to query for
# @return             Promise to massive object. lol.
get_events = (locations, days) ->

  ## Setup our date ranges

  # Single day -> Array of days
  if not type.is_array(days) and days._type is undefined
    days = [days]

  # Array of days -> Array of date ranges
  if type.is_array(days)
    days = days.map (d) ->
      date_range =
        s : cal_tools.start_of_day(Date.parse d)
        e : (Date.parse d).add(1).days()
      return date_range

    return Promise.resolve([])

  # Date range -> Array of date ranges
  if days._type is 'date_range'
    days = [days]


  ## Get our calendars

  locations = locations.map (loc) => query loc
  results = []

  return Promise.all(locations).then (res) ->
    res
    .filter (x) -> !!x
    .forEach (loc) ->

      events = loc.events
      loc_id = loc.location_id

      rendered = []

      # Render our calendars
      days.forEach (range) ->
        try
          rendered = rendered.concat(cal_tools.render_calendar events, range.s, range.e)
        catch e
          throw new Error('Error rendering calendars!' + e)

      rendered.forEach (x) ->
        x.location = loc_id
        results.push(x)

    return results

module.exports = {get_events, date_range}



if require.main is module

  (get_events ['okenshields'], date_range('April 6, 2015', 'April 8, 2015'))
    .then (res) -> console.log res
    .catch (err) -> console.trace err
