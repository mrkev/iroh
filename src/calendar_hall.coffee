rp         = require 'request-promise'
Cache      = require '../lib/cacherator'
cal_tools  = require '../lib/calendar_tools'
type       = require '../lib/type'
calendars  = require '../data/calendars.json'
Promise    = require('es6-promise').Promise

MS_ONE_DAY = 86400000

##
# Iroh
#
# Calendar event module for RedAPI
class Iroh

  ##
  # @param  [caldb]  Map of location_id -> ical_url for calendars to use.
  # @return          The mighty Iroh, constructed and ready to tea.
  constructor : (@caldb) ->

    # Clear all cache every day
    self = @
    clear_cache = ->
      Cache.clear('/calendar_hall')
      self._timer = setTimeout clear_cache, MS_ONE_DAY
    clear_cache()

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
          data = cal_tools.icalchurner(response)
          data['location_id'] = location_id
          data["coordinates"] = curr_loc.coordinates if curr_loc.coordinates

          Cache.set MS_ONE_DAY, "/calendar_hall/#{location_id}", data

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
  getJSON : (location_id) ->
    cached = Cache.get "/calendar_hall/#{location_id}"
    if cached
      Promise.resolve cached
    else
      @query location_id

  ##
  # Creates date_range objects
  # @return a date_range
  date_range : (start, end) ->

    start = Date.parse start # Start date
    end   = Date.parse end   # End date

    return {
      s : start
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
    if not type.is_array(days) and days._type is undefined
      days = [days]

    # Array of days -> Array of date ranges
    if type.is_array(days)
      days = days.map (d) ->
        date_range =
          s : cal_tools.start_of_day(Date.parse d)
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
            rendered = rendered.concat(cal_tools.render_calendar events, range.s, range.e)
          catch e
            console.trace e


        results[loc_id] = rendered

      return results
    )

    .catch (err) ->
      console.trace err


module.exports = new Iroh(calendars)
