

##
# [{a : b}, {c : d}] -> {a : b, c : d}
module.exports.merge_objects = (objs) ->
  c = {}
  objs.forEach (obj) ->
    (Object.keys obj).forEach (key) ->
      c[key] = obj[key]
  return c

################################ Set Operations ################################

##
# Computes A U B
# array, array -> array
module.exports.union = (a, b) ->
  (a.filter (x) -> (b.indexOf x) is -1)
    .concat b

##
# Computes A / B
# array, array -> array
module.exports.difference = (a, b) ->
  a.reduce (acc, x) ->
    acc.push x if (b.indexOf x) is -1
    acc
  , []

module.exports.assert_print = (a, b) -> console.log "#{a} == #{b}"

if require.main is module
  assert_print = module.exports.assert_print
  assert_print (module.exports.union      [1, 2], [3]), ([1, 2, 3])
  assert_print (module.exports.union      [1, 2], [1]), ([1, 2])
  assert_print (module.exports.difference [1, 2], [2]), ([1])
