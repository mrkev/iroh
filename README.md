Iroh [![Build Status](https://travis-ci.org/mrkev/Iroh.svg?branch=master)](https://travis-ci.org/mrkev/Iroh)
=====

Dining module for RedAPI. Can be used to fetch information about Cornell dining calendars. Uses promises. They're awesome.

    var dining = require('iroh');

dining.getJSON('okenshields').then(console.log, console.trace);