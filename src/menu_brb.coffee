##
# Supplementary Menu Mcjiggs
# 
# Hither thee wilt findeth the source of all menus, if 't be true hath said menu
# is not a hall menu, for all menus that art not hall menus has't to beest
# fetched in a way that is not the usual, and tis peradventure a bit more
# involved, but as of now worketh, and lest I glad it doest.
# 

rp          = require('request-promise')
parser      = require('xml2json')
calendars   = require('../data/calendars.json')
halls       = require '../data/halls'
Promise     = require('es6-promise').Promise

isArr = Array.isArray || (value) -> 
  return {}.toString.call(value) is '[object Array]'


################################### Helpers. ################################### 

## 
# [{a : b}, {c : d}] -> {a : b, c : d}
merge_objects = (objs) ->
  c = {}
  objs.forEach (obj) ->
    Object.keys(obj).forEach (key) ->
      c[key] = obj[key]
  return c

##################################### Maps ##################################### 

## 
# { general_menu_id : location name } 
location_for_id_g = halls.of_property 'general_menu_id'

##
# { general_menu_id : location name } 
id_for_location_g = halls.property 'general_menu_id'

location_for_id_b = halls.of_property 'general_menu_id_breakfast'
id_for_location_b = halls.property 'general_menu_id_breakfast'


location_for_id = merge_objects [location_for_id_g, location_for_id_b]

# console.log 'lyo', id_for_location_g
# console.log 'lyo', id_for_location_b

#################################### Module ####################################

##
# Get's the menu for location with special menu id {smid}. 
module.exports.get_menu = (smid) ->

  console.log 'getting', smid

  return Promise.resolve({}) if smid is undefined
  # return Promise.resolve({}) if Object.keys(location_for_id).indexOf(smid.toString()) < 0

  ## HELPERS ##
  
  ##
  # String of condiment descriptions + condiment map => array of 
  # condiments/extras
  condimentify = (str, cond) ->
    return null if not str
    res = []
    for i in [1..str.length] by 2
      id = str[i-1..i].toLowerCase()
      res.push(cond[id])
    return res
 
  ##
  # Formats station array to something decent. Uses condiments to fill
  # available condiments for each menu item.
  station_map = (station, condiments) ->
    delete station.type                       # Remove useless info

    station.item = [station.item] if not isArr station.item
    station.items = station.item.map((i) ->   # Fix items
      res = {
        name : i.idesc
        description : i.ifdesc
        price : i.icost
        extras : condimentify(i.icond, condiments)
        # igroup : i.igroup
        # iid : i.iid 
        # extra : i.iextra 
      }
      delete res.extras if res.extras is null
      return res
    )
    delete station.item
    delete station.id
    return station

  ##
  # Formats condiments array to something decent. aka something like,
  # { aa:
  #   { name: 'Choice of Bread',
  #     options: [ [Object], [Object] ] },
  #   ae: { name: 'Heated' },
  #   af: { name: 'Cold' },
  #   ag: { name: '16 ounce beverage', options: [ [Object] ] },
  #   ah: { name: '22 ounce beverage', options: [ [Object] ] }
  # }
  condiments_reduce = (acc, c) ->
    if (typeof c.cond) is 'string'
      acc[c.cclass] = {
        name : c.cond
        options : []
      }
    
    else 
      acc[c.cclass] = {
        name : c.cond[0]
        options : c.cond.reduce((acu, x, i) ->
          return acu if i is 0
          res = {name : x.cname}
          res.price = x.ccost if x.ccost
          acu.push(res)
          return acu
        , [])
      }
    delete acc[c.cclass].options if acc[c.cclass].options.length is 0
    return acc


  ## ALRIGHT LETS ROLL ##

  rp('https://cornell.webfood.com/xmlstoremenu.dca?s=' + smid)
      .then((xml)->
        return new Promise((res, rej) ->
          # XML has more than one root (aka. invalid). Fix by adding a root & 
          # parse.
          xml  = '<root name="whatup">\n' + xml.replace(/&/g, "+") + '</root>\n'
          json = parser.toJson(xml)
          res JSON.parse(json)
          
          # console.log xml
          
          # parseString(xml, (err, json) ->
          #   rej err if err
          #   res json
          # )
        )
      )
      .catch((err) ->
        console.log 'Error with request'
        console.trace err
      )


      .then((json) ->

        console.log 'SUP'

        cond = json.root.menu[1].cc.reduce(condiments_reduce, {})
        console.log 'SUP'
        stat = json.root.menu[0].station.map((x) -> station_map(x, cond))
        console.log 'SUP'
        return {
          stations : stat
        }
      )

      .catch(console.trace)


      ## As of now, data looks like this:
      # { stations:
      # [ { name: 'Liberty Pizza', items: [Object] },
      #   { name: 'Liberty Calzones', items: [Object] },
      #   { name: '5 Star Subs', items: [Object] },
      #   { name: 'Grill', items: [Object] } ] }

      # Flatten stations
      .then((json) ->
        return json.stations.reduce((acc, station) ->
          return acc.concat(station.items.map (item) ->
            item.category = station.name
            return item
          )
        , [])
      )


      ## As of now:
      # [ { name: '18 inch Buffalo Chicken Pizza',
      #   description: 'Thin crust Pizza topped with blue cheese.',
      #   price: 15.99,
      #   extras: [ [Object] ],
      #   category: 'Liberty Pizza' },
      # { name: '1/2 Pound Boneless Wings',
      #   description: 'Served with a side of blue cheese and celery sticks.',
      #   price: 6.49,
      #   extras: [ [Object], [Object] ],
      #   category: 'Liberty Pizza' }
      # ... ]
      

      # Add location name and we're done
      .then((foodz_array) ->
        final = {}
        final[location_for_id[smid]] = foodz_array
        return final
      )


##
# Gets a list and information for special (non-dining hall) locations.
module.exports.get_central = () ->
  rp('https://cornell.webfood.com/xmlstart.dca')
    .then((xml)->
      return new Promise((res, rej) ->

        # XML has more than one root (aka. invalid). Fix & parse.
        xml  = '<root name="whatup">\n' + xml.replace("&", "+") + '</root>\n'
        json = parser.toJson(xml)
        res JSON.parse(json)
      
      )
    )
    .catch(console.trace)
    
    .then((json) ->
      
      # 0 : config
      # 1 : locations
      # 2 : schedule
      return json.root.menu[1].store.map((item) ->
        return {
          name : item.sname
          smenu_id : item.snum
          credit_card : item.scard
          addr : item.saddr2
          latitude : item.slat
          longitude : item.slon
          phone : item.sphone
          message : item.smsg
          misc : item.saddr
        }
      
      )
    )

# module.exports.get_menu('bear_necessities').then (json) -> console.log(json)

##
# Gets the general menus for location with id [location_id].
# @param  location_id {String}
# @return {Promise} will resolve to an object with format
# {
#   general : {Menu} | null
#   breakfast : {Menu} | null
# }
# 
module.exports.getJSON = (location_id) ->
  general_id = id_for_location_g[location_id]
  bkfeast_id = id_for_location_b[location_id]

  # This location has no general menus. 
  return Promise.resolve({}) \
    if (general_id is undefined) and (bkfeast_id is undefined)

  # Get the menus! 
  menus = [module.exports.get_menu(general_id), module.exports.get_menu(bkfeast_id)]

  # console.log menus

  # Return an object:
  # hall:
  #   general: 
  #   breakfast: 
  return Promise.all(menus).then (data) ->
    res = {}
    res[location_id] = {}

    res[location_id].general = data[0] if not (data[0] is {})
    res[location_id].breakfast = data[1] if not (data[1] is {})

    return res

module.exports.getJSON('goldies').then (data) -> console.dir(data)





