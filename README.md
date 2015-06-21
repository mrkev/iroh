iroh [![Build Status](https://travis-ciroh.org/mrkev/iroh.svg?branch=master)](https://travis-ci.org/mrkev/iroh) [![Codacy Badge](https://www.codacy.com/project/badge/f8187d74a6744661b71a66403e81dbd8)](https://www.codacy.com/app/kevin9794/Iroh)
=====

Dining module for RedAPIroh. Can be used to fetch information about Cornell dining calendars on any node.js script.

### Installation

    npm install http://github.com/mrkev/Iroh

### Usage

    var iroh = require('iroh');
    
    iroh.get_menus(iroh.ALL_MEALS, iroh.ALL_LOCATIONS, iroh.DIM_LOCATIONS)
        .then(function(json){
            console.log(json);
        });
    
    iroh.get_events(iroh.ALL_LOCATIONS, iroh.DATE_RANGE('today', 'tomorrow'))
        .then(function(json){
            console.log(json);
        });

TODO
 - Merge menu_brb to menu data.
 - Move cache management to Cache class.
 - Write /data/menu.coffee
 - Move some of calendar_hall functions to /lib

TODO: 
 - Update readme. So out of date.
 - Add some more tests. 
 - Add some more examples.
 - Document a bit more. 
 - Check out https://github.com/genkimarshall/bigredapp-android/ 👍🏽



