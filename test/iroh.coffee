chai = require 'chai'
type = require '../lib/type'
iroh = require '../index.js'

chai.use (require "chai-as-promised")
chai.should()
expect = chai.expect

describe 'DATE_RANGE', ->
  it 'works, I guess', ->
    dr = 
      s: new Date('Mon Apr 06 2015 00:00:00 GMT-0400 (EDT)')
      e: new Date('Wed Apr 08 2015 00:00:00 GMT-0400 (EDT)')
      _type: 'date_range'

    iroh.DATE_RANGE('April 6, 2015', 'April 8, 2015').should.deep.equal dr

describe 'get_menus', ->

  it 'exists', -> expect(iroh.get_menus).to.exist

  it 'returns an array', null

  describe 'response array', ->

    it 'all elements have a hall', null

    it 'all elements have a meal type', null

    it 'menu is null on no data for point', null
      # { meal: 'Dinner', location: 'bear_necessities', menu: null } ]

  # describe 'get_events', ->
  
    it 'should not include end date on range: [s..t)', ->
      iroh.get_events ['okenshields'], iroh.DATE_RANGE('April 6, 2015', 'April 8, 2015')
      .then (res) -> res.length == 4
      .should.eventually.equal true 


describe 'get_events', ->

  it 'does the thing', ->
    iroh.get_events(['okenshields'], [])
    .should.eventually.deep.equal []
