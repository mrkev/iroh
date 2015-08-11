##
# [{a : b}, {c : d}] -> {a : b, c : d}
module.exports.merge_objects = (objs) ->
  c = {}
  objs.forEach (obj) ->
    (Object.keys obj).forEach (key) ->
      c[key] = obj[key]
  return c

module.exports.union = (a, b) ->
  (a.filter (x) -> (b.indexOf x) is -1)
    .concat b