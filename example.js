'use strict';
/* global require, console */
var iroh = require('./index');

iroh.getJSON('north_star').then(function (data) {
  data.events.forEach(function (evt) {
    console.log(evt)
  });
}).catch(console.trace);
