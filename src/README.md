



### /src

All scripts that mine/generate the information Iroh servers are here. Here's a map of who feeds who as of now:

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

Note that there is no `calendar.coffee` script, since there is only one source for calendar data and we don't want extra complexity here. If there's ever some other `calendar_*` one should be made.