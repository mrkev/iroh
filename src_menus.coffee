require './vendor/date_format'
cheerio = require 'cheerio'
request = require 'request'
Promise = require('es6-promise').Promise;
halls   = require './the_halls'

##
# Should be a { hall_id : int } map, where int is the id to use in the request
# to fetch the menu for that hall.
menu_locations = halls.property('hall_menu_id')

today = ->
  return new Date()

class MenuManager
  constructor: (@uri) ->
    @cache = {}
    @all_meals     = () -> ['Breakfast', 'Lunch', 'Dinner', 'Brunch']
    @all_locations = () -> Object.keys(menu_locations)
    
    @dim_meals     = () -> 'MEALS'
    @dim_locations = () -> 'LOCATIONS'
  

  ### GET MENUS ###

  ## Kudos to Feifran Zhou. He did this.
  # @param date       A date object.
  # 
  # @param period     The meal to fetch. One of;
  #                    - Breakfast
  #                    - Lunch
  #                    - Dinner
  #                    - Brunch
  # 
  # @param loc        A location id string. One of;
  #                    - cook_house_dining_room
  #                    - becker_house_dining_room
  #                    - keeton_house_dining_room
  #                    - rose_house_dining_room
  #                    - jansens_dining_room_bethe_house
  #                    - robert_purcell_marketplace_eatery
  #                    - north_star
  #                    - risley_dining
  #                    - 104west
  #                    - okenshields
  fetch : (date, period, location, should_refresh, callback) ->
    
    # Alow for straight-up ids
    if typeof location is 'string'
      loc = menu_locations[location]

    # No menu available.
    if loc is null
      console.log('No menu available for that location');
      callback(null, period, location)

    # period + midnight of date + location + remove whitespace
    key = (period + date.setHours(0,0,0,0) + location).replace(/\s/g, '')
    
    if @cache[key] != undefined && !should_refresh
      callback(@cache[key], period, location)
      return

    request.post({
      uri: @uri,
      form: {
        menudates: date.format('yyyy-mm-dd')
        menuperiod: period
        menulocations: loc
      }
    }, ((err, httpResp, body) ->
         
      # Nothing here.   
      if err 
        error = new Error()
        error.name = '503'
        throw error
      
      # Parse it through
      $ = cheerio.load(body)
      menuItems = []
      currentCategory = ''
      for sib in $('#menuform').siblings()
        continue unless $(sib).hasClass('menuCatHeader') || $(sib).hasClass('menuItem')
        if $(sib).hasClass('menuCatHeader')
          currentCategory = $(sib).text().trim()
          continue
        isHealthy = $(sib).children().length >= 1
        menuItems.push({
          name: $(sib).text().trim()
          category: currentCategory
          healthy: isHealthy
        })
      menuItems = null if menuItems.length is 0
      @cache[key] = menuItems
      
      # done.
      callback(menuItems, period, location)
    ).bind(this))

    return null


  ## 
  # fetch(), but promised.
  get : (date, period, loc, should_refresh) ->
    self = this
    console.log(today(), period, loc)
    return new Promise (resolve, reject) -> 
      self.fetch date, period, loc, should_refresh, (menu_items, period, loc) ->
        resolve 
          location : loc
          meal : period
          menu : menu_items
  
  ## 
  # Gets all menus in the specified (meal, location) coordinate ranges.
  #
  # @param meals        array of meals to query for
  # @param locations    array of locations to query for
  # @param key_dim      dimension to reduce on. values from this dimension
  #                     will be used as top-level key
  # @param do_refresh   Overwrite cache
  # @return Promise to massive object. lol.
  get_menus : (meals, locations, key_dim, do_refresh) ->
    self = this
    
    # Make it a boolean, cuz why not. Lets be tidy.
    do_refresh = !!do_refresh

    # We need something to work with
    return Promise.resolve({}) if !meals or !locations 

    promises  = []
    
    # Cross product the dimensions. A promise for each point
    locations.forEach (location) -> 
      meals.forEach (meal) ->
        promises.push(self.get(today(), meal, location, do_refresh))

    console.log 'ordering by', key_dim
    # Reduce...
    return Promise.all(promises).then (results) ->
      console.log 'ra DUCE'      
      
      # ...with locations as keys
      if key_dim is self.dim_locations()
        return results.reduce((prev, curr) ->
          prev[curr.location]            = {} if !prev[curr.location]
          prev[curr.location][curr.meal] = curr.menu
          return prev
        , {})
      
      # ...with meals as keys
      if key_dim is self.dim_meals()
        return results.reduce((prev, curr) ->
          prev[curr.meal]                = {} if !prev[curr.meal]
          prev[curr.meal][curr.location] = curr.menu
          return prev
        , {})



module.exports = new MenuManager('http://living.sas.cornell.edu/dine/whattoeat/menus.cfm')

