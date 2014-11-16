iroh = require("./index.coffee")

iroh.getJSON("north_star").then (data) ->
  console.dir data
