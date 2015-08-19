
################################## CONSTANTS. ##################################

##
# Milliseconds in a day
module.exports.MS_ONE_DAY = 86400000
module.exports.DAYS_OF_WEEK = ["MO", "TU", "WE", "TH", "FR", "SA", "SU"]

################################### CHECKERS ###################################

##
# @return true if value is an array,
# false otherwise
module.exports.is_array = Array.isArray || (value) ->
  return {}.toString.call(value) is '[object Array]'

##
# @return true if value is an array,
# false otherwise
module.exports.is_date = 
  (date) -> date instanceof Date && !(isNaN date.valueOf())

################################# CONSTRUCTORS #################################

##
# Creates date_range objects
# @return a date_range
module.exports.date_range = (start, end) ->

    start = Date.parse start # Start date
    end   = Date.parse end   # End date
    
    return {
      s : start
      e : end
      _type : 'date_range'
    }
