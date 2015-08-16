iroh = require("./index.js")


# iroh.get_events(['okenshields'], ['April 6, 2015 - April 8, 2015 | April 9, 2015']).then (res) ->
#   console.log res

iroh.get_events(['okenshields'], ['April 6, 2015 - April 8, 2015 | May 9, 2015']).then (res) ->
  console.log res

# iroh.get_menus(['Breakfast'], ['okenshields'], iroh.DIM_LOCATIONS, false).then (res) ->
#   console.dir res.okenshields

# iroh.get_menus(iroh.ALL_MEALS, iroh.ALL_LOCATIONS, iroh.DIM_MEALS).then (res) ->
#  console.log res

###