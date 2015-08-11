require '../lib/date_format'
cheerio = require 'cheerio'
rp      = require 'request-promise'
halls   = require '../data/halls'
Cache   = require '../lib/cacherator'
Promise = require('es6-promise').Promise

isArr = Array.isArray || (value) ->
  return {}.toString.call(value) is '[object Array]'

##
# -> { hall_id : int } map, where int is the id to use in the request
# to fetch the menu for that hall.
menu_locations = halls.property('hall_menu_id')

today = -> new Date

class MenuManager
  constructor: ->
    @uri = 'http://living.sas.cornell.edu/dine/whattoeat/menus.cfm'
    @cache = {}
    @all_meals     = -> ['Breakfast', 'Lunch', 'Dinner', 'Brunch']
    @all_locations = -> Object.keys(menu_locations)

    @dim_meals     = -> 'MEALS'
    @dim_locations = -> 'LOCATIONS'

  ### GET MENUS ###

  ##
  # @param date    Menu for what day?
  # @param period  The meal to fetch. One of
  #                > [Breakfast, Lunch, Dinner, Brunch]
  # @param loc     A location id string. One of
  #                > [cook_house_dining_room, becker_house_dining_room, 
  #                   keeton_house_dining_room, rose_house_dining_room, 
  #                   jansens_dining_room_bethe_house, 
  #                   robert_purcell_marketplace_eatery, north_star, 
  #                   risley_dining, 104west, okenshields]
  get_hall_menu: (date, meal, location, should_refresh) ->
    
    console.log(today(), meal, location)

    # Alow for straight-up ids
    loc = menu_locations[location] if typeof location is 'string'

    # No menu available.
    console.log('No menu available for that location') if loc is null

    # cache key is meal + midnight of date + location + remove whitespace
    # This ensures we get a new menu every day. Note, it will also mean our
    # cache will grow quite a bit.
    key = (meal + date.setHours(0,0,0,0) + location).replace(/\s/g, '')

    # We can do cache! Yay!
    return Promise.resolve(@cache[key]) if !should_refresh && @cache[key]

    # Do the request
    rp.post
      uri: @uri
      form:
        menudates: date.format 'yyyy-mm-dd'
        menuperiod: meal
        menulocations: loc

    # Throw any errors
    .catch (err) => throw err
    
    # Process results
    .then (body) =>
      
      # Parse it
      $ = (cheerio.load body)
      menu = []
      currentCategory = ''
      
      for sib in $('#menuform').siblings()
        continue unless $(sib).hasClass('menuCatHeader') || $(sib).hasClass('menuItem')
        if $(sib).hasClass('menuCatHeader')
          currentCategory = $(sib).text().trim()
          continue
        isHealthy = $(sib).children().length >= 1
        menu.push
          name: $(sib).text().trim()
          category: currentCategory
          healthy: isHealthy

      # Menu items should be the menu by now.
      menu = null if menu.length is 0
      
      # Save it in cache
      @cache[key] = menu

      # done.
      return {
        menu, 
        meal, 
        location
      }

  ##
  # Gets all menus in the specified (meal, location) coordinate ranges.
  #
  # @param meals        array of meals to query for
  # @param locations    array of locations to query for
  # @param key_dim      dimension to reduce on. values from this dimension
  #                     will be used as top-level key
  # @param do_refresh   Overwrite cache
  # @return Promise to massive object. lol.
  get_menus : (meals, locations, do_refresh) ->

    # Accept singles
    meals     = if not isArr meals then [meals] else meals
    locations = if not isArr locations then [locations] else locations

    # Make it a boolean, cuz why not. Lets be tidy.
    do_refresh = !!do_refresh

    # We need something to work with
    return Promise.resolve({}) if !meals or !locations

    # Cross product; a promise for each point
    promises = []
    locations.forEach (location) =>
      meals.forEach (meal) =>
        promises.push(@get_hall_menu(today(), meal, location, do_refresh))

    (Promise.all promises)

module.exports = new MenuManager

## Test
if require.main == module
  iroh = module.exports
  iroh.get_menus('Lunch', 'okenshields', false).then (res) ->
    console.log res[0]

    ## 
    # [{ menu:
    #    [ { name: 'Homestyle Chicken Noodle Soup',
    #        category: 'Soup Station',
    #        healthy: false }, ...],
    #    meal: 'Lunch',
    #    location: 'okenshields' }