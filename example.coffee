iroh = require("./index.coffee")
iroh.getJSON("north_star").then (data) ->
  
  # console.dir (JSON.stringify(data.events))
  console.dir data
  return