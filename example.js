'use strict';
/* global require, console */
var iroh = require('./index');

iroh.getJSON('north_star').then(function (data) {
  console.dir(data);
}).catch(console.trace);
