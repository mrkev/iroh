iroh = require("./index.js")

# chai = require 'chai'
# chai.should()

# iroh.get_events(['okenshields'], iroh.DATE_RANGE('April 6, 2015', 'April 8, 2015')).then (res) ->
#   console.log res

# iroh.get_menus(['Breakfast'], ['okenshields'], iroh.DIM_LOCATIONS, false).then (res) ->
#   console.dir res.okenshields

# iroh.get_menus(iroh.ALL_MEALS, iroh.ALL_LOCATIONS, iroh.DIM_MEALS).then (res) ->
#  console.log res

###

halls = require './data/halls'

# Option A

## matches event_res(), x
# Generates a model. Good if not many possible keys

event_res = () ->
  model = {}
  halls.withCalendars().forEach (hall) ->
    model[hall] = (x) -> x is undefined or (of_type.array(x) and each(x).matches(event))
  return model 

# Option B

## 
# Tests an object directly. Each key can be tested too, which means they can
# be arbitrary

event_res = (obj) ->

  return Object.keys(obj).reduce((acc, hall) ->

    halls.withCalendars().indexOf(hall) > -1 && \
    obj[k] is undefined or (of_type.array(x) and each(x).matches(event)) && \
    acc

  , true)


# Model for event

event =
  summary : (x) -> typeof x is 'string'
  start   : (x) -> x instanceof Date
  end     : (x) -> x instanceof Date

{ okenshields:
   [ { summary: 'Open until 2:30pm',
       start: Mon Apr 06 2015 11:00:00 GMT-0400 (EDT),
       end: Mon Apr 06 2015 14:30:00 GMT-0400 (EDT) },
     { summary: 'Open until 2:30pm',
       start: Tue Apr 07 2015 11:00:00 GMT-0400 (EDT),
       end: Tue Apr 07 2015 14:30:00 GMT-0400 (EDT) },
     { summary: 'Dinner served until 7:30pm',
       start: Mon Apr 06 2015 16:30:00 GMT-0400 (EDT),
       end: Mon Apr 06 2015 19:30:00 GMT-0400 (EDT) },
     { summary: 'Dinner served until 7:30pm',
       start: Tue Apr 07 2015 16:30:00 GMT-0400 (EDT),
       end: Tue Apr 07 2015 19:30:00 GMT-0400 (EDT) } ] }

###