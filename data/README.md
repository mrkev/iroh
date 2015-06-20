

### /data

Data contains all the hard-coded hall data for Iroh. By hard-coded, I mean not computed at runtime.

It should all be exposed through `halls.coffee`, and the outside world should idealy only ever need to `require` `halls.coffee`. 