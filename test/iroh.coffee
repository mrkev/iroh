chai = require 'chai'
chai.use(require("chai-as-promised"));
chai.should()
expect = chai.expect

describe 'Iroh instance', ->
  iroh = require '../index.coffee'
  
  it 'should have a calendar database', ->
    expect(iroh.caldb).to.exist
  
  it 'should always fufill its promises', ->
    iroh.getJSON("north_star").should.be.fulfilled

  it 'should return ids when no id', ->
    iroh.getJSON().then((data) -> data.dining).should.eventually.be.an("array").with.length.above(0); 

  it 'should return a valid object when a valid id', ->
    expected_keys = ["name", "description", \
                     "coordinates", "timezone", \
                     "events", "updated"]
    iroh.getJSON("north_star").then((data) ->
      console.log Object.keys(data).sort().join(','), expected_keys.sort().join(',')

      Object.keys(data).sort().join('') is expected_keys.sort().join('')
    ).should.eventually.equal(true) 
  
  it 'should return null when an invalid id', ->
    iroh.getJSON("nope").should.become(null)

