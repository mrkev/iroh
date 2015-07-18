chai    = require 'chai'
chai.use(require("chai-as-promised"));
chai.should()
expect = chai.expect

iroh = require '../index.js'

describe 'Iroh', ->
  
  describe 'call_db', ->
    it 'should exist', ->
      expect(iroh.caldb).to.exist
      # should_match calldb, iroh.calldb

  # describe 'get_menus', null

  describe 'getJSON', ->
    iroh = require '../index.js'
  
    it 'should return ids when no id', ->
      iroh.getJSON().then((data) -> data.dining).should.eventually.be.an("array").with.length.above(0); 
  
    it 'should return a valid object when a valid id', ->
      expected_keys = ["name", "description", \
                       "coordinates", "timezone", \
                       "events", "updated", "location_id"]
      
      iroh.getJSON("north_star").then((data) ->
        # console.log Object.keys(data).sort().join(','), expected_keys.sort().join(',')
  
        Object.keys(data).sort().join('') is expected_keys.sort().join('')
      ).should.eventually.equal(true) 
    
    it 'should return null when an invalid id', ->
      iroh.getJSON("nope").should.become(null)

  describe 'Iroh.get_events', ->
    iroh = require '../index.js'
  
    it 'should not include end date on range: [s..t)', ->
      iroh.get_events(['okenshields'], iroh.DATE_RANGE('April 6, 2015', 'April 8, 2015')).then((res) ->
        return res.okenshields.length == 4
      ).should.eventually.equal(true) 

  