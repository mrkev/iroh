##
# Interface to interact with the halls object (currently in calendars.json) in
# a more abstract way. 
# 

calendars = require '../data/calendars.json'
util      = require '../lib/utils.coffee'

################################### Helpers. ################################### 

##
# map_of_property 
#   { a : {b : c}
#     d : {b : e}
#     f : {b : g} }, b 
#   -> {a : c, d : e, f : g}
map_of_property = (map, property) ->
  return Object.keys(map)
  .map((x) ->

    return undefined if map[x][property] is null
    return undefined if map[x][property] is undefined 

    obj = {}
    obj[x] = map[x][property]
    return obj
  )
  .filter((x) ->
    return (not (x is null)) and (not (x is undefined))
  )
  .reduce((acc, x) ->
    Object.keys(x).forEach (key) ->
      acc[key] = x[key]
    return acc
  )

##
# invert_map
# {a : b} -> {b : a}
invert_map = (map) ->
  res = {}
  Object.keys(map).forEach (key) ->
    res[map[key]] = key
  return res


################################### Exports. ###################################

module.exports = 
  
  ##
  # Returns a map with { hall_id : property }. Only halls where property isn't
  # null or undefined are returned.
  property : (property) ->
    map_of_property calendars, property

  ##
  # Returns a map with { property : hall_id }. Only halls where property isn't
  # null or undefined are returned.
  of_property : (property) ->
    invert_map(map_of_property calendars, property)


  ##
  # Returns an array of all halls with a menu
  with : (p) -> Object.keys(@property p)

  # objects : calendars

  ##
  #
  all : (type) -> switch type
    when 'halls'
      @with 'hall_menu_id'

    when 'brbs'
      util.union (@with 'general_menu_id'), (@with 'general_menu_id_breakfast')

    when 'brbs_breakfast'
      @with 'general_menu_id_breakfast'

    when 'brbs_general'
      @with 'general_menu_id'

    when 'eateries'
      util.union (@with 'hall_menu_id'),
        (util.union (@with 'general_menu_id'), 
          (@with 'general_menu_id_breakfast'))
        


