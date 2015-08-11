

##################################### Maps #####################################

# ##
# # { general_menu_id : location name }
# location_for_id_g = halls.of_property 'general_menu_id'

# ##
# # { general_menu_id : location name }
# id_for_location_g = halls.property 'general_menu_id'

# location_for_id_b = halls.of_property 'general_menu_id_breakfast'
# id_for_location_b = halls.property 'general_menu_id_breakfast'


# location_for_id = merge_objects [location_for_id_g, location_for_id_b]

# # console.log 'lyo', id_for_location_g
# # console.log 'lyo', id_for_location_b
# # 

today = -> new Date
union = (require '../lib/utils').union
isArr = (require '../lib/type').is_array
not_halls = (require '../src/menu_brb').all_locations()

is_hall = (id) -> (not_halls.indexOf id) is -1

class MenuManager

  constructor: ->
    @hall_manager = (require '../src/menu_hall')
    @brb_manager  = (require '../src/menu_brb')
  
  get_menus: (time, meals, locations, do_refresh) ->

    # Accept singles
    meals     = if not isArr meals then [meals] else meals
    locations = if not isArr locations then [locations] else locations

    # We need something to work with
    (Promise.resolve {}) if !meals or !locations

    # Cross product; a promise for each point
    promises = []
    locations.forEach (location) =>
      meals.forEach (meal) =>
        if (is_hall location)
          promises.push (@hall_manager.get_hall_menu time, meal, location, do_refresh) 
        else
          promises.push (@brb_manager.get_brb_menu meal, location, do_refresh) 

    (Promise.all promises)

  
module.exports = new MenuManager

if require.main == module
  iroh = module.exports
  iroh.get_menus(today(), ['Lunch', 'Dinner'], ['okenshields', 'bear_necessities']).then (res) ->
    console.log res

