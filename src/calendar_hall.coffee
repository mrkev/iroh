rp         = require 'request-promise'
Cache      = require '../lib/cacherator'
cal_tools  = require '../lib/calendar_tools'
type       = require '../lib/type'
calendars  = require '../data/calendars.json'
Promise    = require('es6-promise').Promise

MS_ONE_DAY = 86400000

Date::addDays = (days) ->
  dat = new Date @valueOf()
  dat.setDate(dat.getDate() + days)
  dat

##
# Iroh
#
# Calendar event module for RedAPI
class Iroh

  constructor : (@caldb) ->

  ##
  # Queries and transforms data for specified [location_id]. Saves it in cache.
  # @param  [location_id] Valid location identifier to query.
  # @return Promise -> JSON object for parsed iCalendar data for location,
  query : (location_id) ->
    curr_loc = @caldb[location_id]

    # return list of dining ids if no location_id is specified
    return Promise.resolve(dining: Object.keys(@caldb)) if not location_id

    # return null if location_id not recognized
    return Promise.resolve(null) if not curr_loc

    url = curr_loc.icalendar
    new Promise((resolve, reject) ->

      rp(url).then((response) ->
        try
          data = cal_tools.icalchurner(response)
          data['location_id'] = location_id
          data["coordinates"] = curr_loc.coordinates if curr_loc.coordinates

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
  # Gets all events in the specified (locations, days) ranges.
  #
  # @param locations    array of locations to query for
  # @return             Promise to massive object. lol.
  get_events : (locations, days) ->

    # Make it an array.
    days = [days] if not (type.is_array days)

    # Parse each element in the array.
    days = days
      .map cal_tools.date_range
      .reduce (acc, x) ->
        acc.concat x
        acc
      , []

    Promise.resolve([]) if days.length is 0

    ## Get our calendars

    locations = locations.map (loc) => (@query loc)
    results = {}

    Promise.all(locations).then (res) ->

      res.forEach (loc) ->

        events = loc.events
        loc_id = loc.location_id

        rendered = []

        days.peek()
        days.forEach (range) ->
          console.log range
          try
            rendered = rendered.concat(cal_tools.render_calendar events, range.start, range.end)
          catch e
            console.trace e

        results[loc_id] = rendered

      results

    .catch (err) ->
      console.trace err


module.exports = new Iroh(calendars)
