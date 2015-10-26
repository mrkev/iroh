chai = require 'chai'
type = require '../lib/type'
iroh = require '../index.js'

chai.use (require "chai-as-promised")
chai.should()
expect = chai.expect


describe 'call_db', ->

  it 'exists', -> expect(iroh.caldb).to.exist

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
