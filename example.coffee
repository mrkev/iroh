iroh = (require "./index")

### Uncomment examples below and run to see whats up kthx ### 

# console.log iroh.DATE_RANGE('April 6, 2015', 'April 8, 2015')

# iroh
#   .get_events ['okenshields'], iroh.DATE_RANGE('April 6, 2015', 'April 8, 2015')
#   .then (res) ->
#     console.log res

# iroh
#   .get_menus ['okenshields', 'north_star'], ['Breakfast']
#   .then JSON.stringify
#   .then console.log 
#   .catch (e) -> console.trace e

# iroh
#   .get_menus ['bear_necessities'], iroh.ALL_MEALS
#   .then JSON.stringify
#   .then console.log 

# iroh
#   .get_menus iroh.ALL_MEALS, iroh.ALL_LOCATIONS, iroh.DIM_MEALS
#   .then JSON.stringify
#   .then console.log

# console.log 
#   locations : iroh.ALL_LOCATIONS
#   halls : iroh.ALL_HALLS
#   brbs : iroh.ALL_BRBS
