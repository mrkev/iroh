iroh = require("./index.js")


# iroh.get_events(['okenshields'], iroh.DATE_RANGE('April 6, 2015', 'April 8, 2015')).then (res) ->
#   console.log res

iroh.get_menus(['bear_necessities'], iroh.ALL_MEALS).then (res) ->
  console.dir res

# iroh.get_menus(iroh.ALL_MEALS, iroh.ALL_LOCATIONS, iroh.DIM_MEALS).then (res) ->
#  console.log res


console.log 
  locations : iroh.ALL_LOCATIONS
  halls : iroh.ALL_HALLS
  brbs : iroh.ALL_BRBS

###