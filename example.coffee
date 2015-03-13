iroh = require("./index.js")

iroh.getJSON('north_star').then (data) ->
  console.dir data

# mm.get_menus(mm.all_meals(), mm.all_locations(), mm.dim_meals()).then (res) ->
#  console.log res
