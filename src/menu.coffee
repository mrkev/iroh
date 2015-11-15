

##################################### Maps #####################################

union     = (require '../lib/utils').union
is_array  = (require '../lib/type').is_array
is_date   = (require '../lib/type').is_date
not_halls = (require '../src/menu_brb').all_locations()
all_halls = (require '../data/halls').all('halls');
all_brbs  = (require '../data/halls').all('brbs');

is_hall   = (id) -> (all_halls.indexOf id) > 0
is_brb    = (id) -> (all_brbs.indexOf id) > 0

today     = -> new Date

empty_menu = (location, meal) -> { location, meal, menu: [] }

class MenuManager

  constructor: ->
    @hall_manager = (require '../src/menu_hall')
    @brb_manager  = (require '../src/menu_brb')
    @all_meals = -> ['Breakfast', 'Lunch', 'Dinner', 'General']
    @all_locations = -> union not_halls, @hall_manager.all_locations()
  
  ##
  # Gets all points in the specified (meal, location, time) coordinates
  # on menu-space.
  #
  # @param meals        array of meals to query for
  # @param locations    array of locations to query for
  # @param time         menu for when?
  #    # Note: if 'time' is not a date, it will be set to today.
  # 
  # @return Promise to menus. lol.
  get_menus: (locations, meals, time) ->

    # Setup the time
    time = today() if not (is_date time) 

    # Accept singles
    meals     = if not is_array meals then [meals] else meals
    locations = if not is_array locations then [locations] else locations

    # We need something to work with
    (Promise.resolve {}) if !meals or !locations

    # Cross product; a promise for each point
    promises = []
    locations.forEach (location) =>
      meals.forEach (meal) =>
        if (is_hall location)
          promises.push (@hall_manager.get_hall_menu location, meal, time) 
        else if (is_brb location)
          promises.push (@brb_manager.get_brb_menu location, meal) 
        else
          promises.push Promise.resolve (empty_menu location, meal)
    (Promise.all promises)

  
module.exports = new MenuManager

if require.main == module
  iroh = module.exports
  iroh.get_menus(['okenshields', 'bear_necessities', 'oy'], ['Breakfast', 'Dinner']).then (res) ->
    console.log res

