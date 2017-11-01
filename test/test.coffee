expect = require('expect')
Sequelize = require('sequelize')
sequelize = new Sequelize('database', 'username', 'password',{dialect:'sqlite',storage:':memory:',logging:false})

SequelizeStore = require('../')

describe 'Sequelize Store', ->
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
      sequelizeStore._table.find(where:{_id: 'foo'})
      .then (doc) ->
        expect(doc.count).toBe(123)
        done()
      .catch (err) ->
        done(err)
    )
    return

  it 'should be able to get a value', (done) ->
    sequelizeStore.set('foo', {count:123}, 1000, (err) ->
      return done(err) if err
      sequelizeStore.get 'foo', (err, doc) ->
        return done(err) if err
        expect(doc.count).toBe(123)
        done()
    )
    return

  it 'should return undefined if expired', (done) ->
    sequelizeStore.set('foo', {count:123}, 0, (err) ->
      return done(err) if err
      setTimeout ->
          sequelizeStore.get 'foo', (err, doc) ->
            expect(doc).toBe(undefined)
            done()
      , 200
    )
    return

  it 'should delete the doc if expired', (done) ->
    sequelizeStore.set('foo', {count:123}, 0, (err) ->
      return done(err) if err
      sequelizeStore.get 'foo', (err, doc) ->
        sequelizeStore._table.find(where:{ _id: 'foo'})
        .then (doc) ->
          expect(doc).toBe(null)
          done()
        .catch (err) ->
          done(err)
    )
    return
    

  it 'should be able to reset', (done) ->
    sequelizeStore.set('foo', {count:123}, 1000, (err) ->
      return done(err) if err
      sequelizeStore.reset 'foo', (err, doc) ->
        return done(err) if err
        sequelizeStore._table.find
          where:
            _id: 'foo'
        .then (doc) ->
          expect(doc).toBe(null)
          done()
        .catch (err) ->
          done(err)
    )
    return