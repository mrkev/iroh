



### /src

All scripts that mine/generate the information Iroh servers are here. Here's a map of who feeds who as of now:

### This is how it will look in the future, just wanted to write the readme now lol.

```
 /               | /data    +---------------+               
                 |          | calendar_hall |               
 +----------+ <--|--------- +---------------+               
 | index.js |    |                                          
 +----------+ <--|---                      +--------------+ 
                 |    \                    |   menu_brb   | 
                 |      ----+--------+ <-- +--------------+ 
                 |          |  menu  |                      
                 |          +--------+ <-- +--------------+ 
                 |                         |  menu_hall   | 
                 |                         +--------------+ 
```

Note that there's no `calendar.coffee` script, since there's only one source for calendar data, and we don't want extra complexity here, but if there's ever some other `calendar_*` added one should be made.