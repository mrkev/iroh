
class Cacherator
  constructor: () ->
    @cache = {}

  clear : (path) ->
    @cache[path] = undefined

  set : (time, path, data) ->
    self = @
    @cache[path] = {}
    @cache[path].data = data
    @cache[path].created = new Date();
    @cache[path].timeout = setTimeout(() -> 
      delete self.cache[path]
    , time)

  get : (path) ->
    if @cache[path] and @cache[path].data
      return @cache[path].data
    else
      return undefined

module.exports = new Cacherator()

if not module.parent
  cache = module.exports

  cache.set 1000, '/sample/data', {a : 1}
  console.log cache.get('/sample/data')