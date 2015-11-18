iroh = (require "./index")

### Uncomment examples below and run to see whats up kthx ###

# iroh
#   .get_events(['okenshields'], iroh.DATE_RANGE('April 6, 2015', 'April 8, 2015'))
#   .then (res) ->
#     console.log res

# iroh
#   .get_menus ['okenshields', 'north_star'], ['Breakfast']
#   .then JSON.stringify
#   .then console.log
#   .catch (e) -> console.trace e

# iroh
#   .get_menus(iroh.ALL_LOCATIONS, iroh.ALL_MEALS)
#   .then(JSON.stringify)
#   .then(console.log)
#   .catch(console.trace)

# console.log
#   locations : iroh.ALL_LOCATIONS
#   halls : iroh.ALL_HALLS
#   brbs : iroh.ALL_BRBS
