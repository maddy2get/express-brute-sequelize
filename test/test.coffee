expect = require('expect.js')
Sequelize = require('sequelize')

sequelize = new Sequelize('sequelizeBrute-test', 'root', 'new-password', {
  host: "127.0.0.1"
  dialect: "mysql"
  logging: false
})

SequelizeStore = require('../')

describe 'MongoStore', ->
  sequelizeStore = null
  beforeEach (done) ->
    this.timeout(5000)
    new SequelizeStore(sequelize, 'brute-force', {}, (store) ->
      sequelizeStore = store
      done()
    )

  it 'should be able to set a value', (done) ->
    sequelizeStore.set('foo', {count:123}, 1000, (err) ->
      return done(err) if err
      sequelizeStore._table.find
        where:
          _id: 'foo'
      .success (doc) ->
        expect(doc.count).to.be(123)
        expect(doc.expires).to.be.a(Date)
        done()
      .error (err) ->
        done(err)
    )

  it 'should be able to get a value', (done) ->
    sequelizeStore.set('foo', {count:123}, 1000, (err) ->
      return done(err) if err
      sequelizeStore.get 'foo', (err, doc) ->
        return done(err) if err
        expect(doc).have.property('count')
        expect(doc.count).to.be(123)
        done()
    )

  it 'should return undefined if expired', (done) ->
    sequelizeStore.set('foo', {count:123}, 0, (err) ->
      return done(err) if err
      setTimeout ->
          sequelizeStore.get 'foo', (err, doc) ->
            expect(doc).to.be(undefined)
            done()
      , 200
    )



  it 'should delete the doc if expired', (done) ->
    sequelizeStore.set('foo', {count:123}, 0, (err) ->
      return done(err) if err
      setTimeout ->
          sequelizeStore.get 'foo', (err, doc) ->
            setTimeout ->
                sequelizeStore._table.find
                  where:
                    _id: 'foo'
                .success (doc) ->
                  expect(doc).to.be(null)
                  done()
                .error (err) ->
                  done(err)
            , 100
            done()
      , 100
    )

  it 'should be able to reset', (done) ->
    sequelizeStore.set('foo', {count:123}, 1000, (err) ->
      return done(err) if err
      sequelizeStore.reset 'foo', (err, doc) ->
        return done(err) if err
        sequelizeStore._table.find
          where:
            _id: 'foo'
        .success (doc) ->
          expect(doc).to.be(null)
          done()
        .error (err) ->
          done(err)
    )