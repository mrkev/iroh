iroh = (require "./index")

# iroh
#   .get_events ['okenshields'], iroh.DATE_RANGE('April 6, 2015', 'April 8, 2015')
#   .then (res) ->
#     console.log res

# {
#   okenshields:
#     [ { summary: 'Open until 2:30pm',
#         start: Mon Apr 06 2015 11:00:00 GMT-0400 (EDT),
#         end: Mon Apr 06 2015 14:30:00 GMT-0400 (EDT) },
#       { summary: 'Open until 2:30pm',
#         start: Tue Apr 07 2015 11:00:00 GMT-0400 (EDT),
#         end: Tue Apr 07 2015 14:30:00 GMT-0400 (EDT) },
#       { summary: 'Dinner served until 7:30pm',
#         start: Mon Apr 06 2015 16:30:00 GMT-0400 (EDT),
#         end: Mon Apr 06 2015 19:30:00 GMT-0400 (EDT) },
#       { summary: 'Dinner served until 7:30pm',
#         start: Tue Apr 07 2015 16:30:00 GMT-0400 (EDT),
# }

iroh
  .get_menus ['okenshields', 'north_star'], ['Breakfast']
  .then JSON.stringify
  .then console.log 
  .catch (e) -> console.trace e

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
