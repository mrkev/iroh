require '../lib/date_format'
cheerio = require 'cheerio'
rp      = require 'request-promise'
halls   = require '../data/halls'
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
    @all_meals     = -> ['Breakfast', 'Lunch', 'Dinner', 'Brunch']
    @all_locations = -> Object.keys(menu_locations)

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
  #
  # (String, String, Date) -> Promise of {
  #   menu: Option menu[] # Null if not available/invalid
  #   meal: String
  #   locaiton: String
  # }
  get_hall_menu: (location, meal, date) ->

    date = today() if not date

    # Alow for straight-up ids
    loc = menu_locations[location] if typeof location is 'string'

    # No menu available.
    return Promise.resolve({
      menu : null,
      meal,
      location
    }) if not loc

    # Goddamnit cornell.
    # Apparently they are using AWS Sticky load balancing.
    # Idk how long this is gonna work before we need to
    # use like a headless browser or something.
    #
    # Or acutally, I think request supports cookie jars.
    # Maybe we would just have to request the landing page
    # first, get the cookie, and move forward.
    cookie = "AWSELB=957D09DF1C0424879E70A279FE7B5867F429E80A31A901AA4709C33F1FFBAA451F1515F44944B200AC0BE8E2F498E9FA5448EABEAF77C24236BD3F64A4CA4636BD695C3C7B;"
    
    # Do the request
    rp.post
      uri: @uri
      headers:
        'Cookie' : cookie
      form:
        menudates: date.format 'yyyy-mm-dd'
        menuperiod: meal
        menulocations: loc

    # Throw any errors
    .catch (err) =>
      throw new Error("Request error on menu for #{meal} #{date}" + err)

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

      # done.
      return {
        menu,
        meal,
        location
      }

module.exports = new MenuManager

## Test
if require.main == module
  iroh = module.exports
  iroh.get_hall_menu('okenshields', 'Lunch').then (res) ->
    console.log res

    ##
    # { menu:
    #    [ { name: 'Homestyle Chicken Noodle Soup',
    #        category: 'Soup Station',
    #        healthy: false }, ...],
    #    meal: 'Lunch',
    #    location: 'okenshields' }

