
##
# Cacherator. 
# 
# Deals with cache of information, and by this I mean
# keeping it in a variable on memory, and making sure
# it gets cleared after a certain amount of time.
# 
# lol.
class Cacherator

  # So user can do Cache.set Cache.FOREVER, '/', {}
  FOREVER = undefined
  
  ##
  # Return new instance of Cacherator. Useful
  # because we module.export a singleton
  new_instance : () ->
    return new Cacherator()

  constructor: () ->
    @cache = {}

  ##
  # Clears a directory and all subdirectories.
  clear : (path) ->
    pattern = new RegExp("(^#{path})|(^#{path}/[a-zA-Z0-9/]*)", "")
    for key in Object.keys(@cache)
      delete @cache[key] if pattern.test(key)

  ##
  # Removes a single item at @path from the cache. Note, 
  # trailing "/"s matter. Only exact matches are removed.
  del : (path) ->
    delete @cache[key]

  ##
  # Puts an item in the cache. Expires after @time
  # milliseconds.
  set : (time, path, data) ->
    # User can do Cache.set '/', {} to cache for unlimited
    # time
    if typeof time is 'string' and typeof path != 'string'
      path = time
      data = path
      time = undefined

    self = @
    @cache[path] = {}
    @cache[path].data = data
    @cache[path].created = new Date();
    # console.log @cache
    if typeof time is 'number'
      @cache[path].timeout = setTimeout ->
        delete self.cache[path]
      , time

  ##
  # Fetches a single item from the cache.
  get : (path) ->
    if @cache[path] and @cache[path].data
      return @cache[path].data
    else
      return undefined

  ##
  # Fetches information about a cache entry
  info : (path) ->
    if @cache.path
      return {
        created : @cache[path].created
      }
    else
      return undefined

module.exports = new Cacherator()

if not module.parent
  cache = module.exports
  
  cache.set 1000, '/one/two', {a : 1}
  cache.set 1000, '/one', {a : 2}
  cache.clear '/one'
  console.log cache.get('/one/two')
  console.log cache.get('/one')

  cache.set 1000, '/sample/data', {a : 1}
  console.log cache.get('/sample/data')

  setTimeout ->
    console.log cache.get('/sample/data')
  , 1100

# undefined
# undefined
# {a : 1}
# undefined

