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
  get_hall_menu: (location, meal, date) ->

    console.log(today(), meal, location)

    date = today() if not date

    # Alow for straight-up ids
    loc = menu_locations[location] if typeof location is 'string'

    # No menu available.
    console.log('No menu available for that location') if loc is null

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

