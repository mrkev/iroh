##
# Supplementary Menu Mcjiggs
#
# Hither thee wilt findeth the source of all menus, if 't be true hath said menu
# is not a hall menu, for all menus that art not hall menus has't to beest
# fetched in a way that is not the usual, and tis peradventure a bit more
# involved, but as of now worketh, and lest I glad it doest.
#

rp            = (require 'request-promise')
parser        = (require 'xml2json')
calendars     = (require '../data/calendars.json')
halls         = (require '../data/halls')
Promise       = (require 'es6-promise').Promise
merge_objects = (require '../lib/utils').merge_objects
union         = (require '../lib/utils').union
isArr         = (require '../lib/type').is_array

today = -> new Date

#################################### Module ####################################

halls_general = halls.property('general_menu_id') # @todo: property exists?
halls_breakfast = halls.property('general_menu_id_breakfast')

class MenuManager

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
      acc[c.cclass] =
        name : c.cond
        options : []

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


  ## THE ACUTAL CLASS ## 

  constructor: ->
    @uri = 'http://living.sas.cornell.edu/dine/whattoeat/menus.cfm'
    @all_meals     = -> ['Breakfast', 'General']
    @all_locations = -> union Object.keys(halls_general), Object.keys(halls_breakfast)

  ##
  # Gets a single menu for a location.
  get_brb_menu: (meal, location_id) ->

    console.log(today(), meal, location_id)

    res = {
        meal, 
        location: location_id
        menu: null
      }

    return (Promise.resolve res) if !(meal is 'General') and !(meal is 'Breakfast')

    # Which menu id are we talking about?
    smid = if meal is 'General' \
      then halls_general[location_id] \
      else halls_breakfast[location_id]

    # Nothing or...
    return (Promise.resolve res) if smid is undefined

    # ... something! Yeah! Alright first get the xml menu
    rp('https://cornell.webfood.com/xmlstoremenu.dca?s=' + smid)
    
    .catch (e) -> console.log "HTTP request failed.", e

    # XML has more than one root (aka. invalid). 
    # Fix by adding a root, sanitize a bit & parse.
    .then (xml)-> new Promise (res, rej) ->
      xml  = '<root name="whatup">\n' + xml.replace(/&/g, "+") + '</root>\n'
      json = (parser.toJson xml)
      res (JSON.parse json)

    .catch (e) -> console.log "XML parsing failed.", e

    # get and format the condiments and stations
    .then (json) ->
      cond = json.root.menu[1].cc.reduce(condiments_reduce, {})
      stat = json.root.menu[0].station.map((x) -> station_map(x, cond))
      (stat)

    .catch (e) -> console.log "Error getting condiments and/or stations", e

    ## As of now, data looks like this:
    # [ { name: 'Liberty Pizza', items: [Object] },
    #   { name: 'Liberty Calzones', items: [Object] },
    #   { name: '5 Star Subs', items: [Object] },
    #   { name: 'Grill', items: [Object] } ]

    # Flatten the stations
    .then (stations) ->
      stations.reduce (acc, station) ->
        acc.concat station.items.map (item) ->
          item.category = station.name
          item
      , []

    .catch (e) -> console.log "Couldn't flatten the stations", e

    ## Now the data looks like (YAML):
    #  - name:
    #    description:
    #    price:
    #    extras:
    #      - name:
    #        options:
    #          - name:
    #    category:
    #  - ...
    
    # Build the final object
    .then (menu) -> 
      res.menu = menu
      return res

module.exports = new MenuManager

##
# Gets a list and information for special (non-dining hall) locations.
get_central = ->
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


if require.main == module
  iroh = module.exports
  iroh.get_brb_menu('General', 'bear_necessities').then (res) ->
    console.log res



