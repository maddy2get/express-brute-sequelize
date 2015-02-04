AbstractClientStore = require('express-brute/lib/AbstractClientStore')
moment = require('moment')
_ = require('underscore')
Sequelize = require('sequelize')

bruteStore = module.exports = (sequelize, table, options, callback) ->
  AbstractClientStore.apply(this, arguments)
  this.options = _.extend({}, bruteStore.defaults, options)
  self = this
  self._table = sequelize.define(table, {
    _id:
      type: Sequelize.STRING
      unique: true
    expires:
      type: Sequelize.DATE
    firstRequest:
      type: Sequelize.DATE
    lastRequest:
      type: Sequelize.DATE
    count:
      type: Sequelize.INTEGER
  })

  self._table.sync().on('success', ->
    if self.options.logging
      console.log "bruteStore initialized - table #{table} created"
    callback(self)
  ).on('error', ->
    if self.options.logging
      console.log "Failed to initialize bruteStore - table #{table}"
    callback(self)
  )

bruteStore.prototype = Object.create(AbstractClientStore.prototype)

bruteStore.prototype.set = (key, value, lifetime, callback) ->
  self = this
  _id = this.options.prefix+key
  expiration = if lifetime then moment().add(lifetime, 'seconds').toDate() else null

  self._table.find
    where:
      _id: _id
  .success (doc) ->
    if doc
      doc._id = _id
      doc.count = value.count
      doc.lastRequest = value.lastRequest
      doc.firstRequest = value.firstRequest
      doc.expires = expiration
      doc.save().on 'success',  ->
        callback() if callback
      .on 'error', (err) ->
        callback(err) if callback

    else
      self._table.create
        _id: _id
        count: value.count
        lastRequest: value.lastRequest
        firstRequest: value.firstRequest
        expires: expiration
      .success (doc) ->
        callback() if callback
      .error (err) ->
        callback(err) if callback

  .error (err) ->
    callback(err) if callback

bruteStore.prototype.get = (key, callback) ->
  self = this
  _id = this.options.prefix+key
  self._table.find
    where:
      _id: _id
  .success (doc) ->
    data = {}
    if doc && new Date(doc.expires).getTime() < new Date().getTime()
      self._table.destroy
        _id: _id
      return callback()
    if doc
      data.count = doc.count
      data.lastRequest = new Date(doc.lastRequest)
      data.firstRequest = new Date(doc.firstRequest)
      typeof callback == 'function' && callback(null, data)
    else
      typeof callback == 'function' && callback(null, null)
  .error (err) ->
    typeof callback == 'function' &&  callback(err, null)

bruteStore.prototype.reset = (key, callback) ->
  self = this
  _id = this.options.prefix+key
  self._table.destroy
    _id: _id
  .success (doc) ->
    typeof callback == 'function' && callback(null, doc)
  .error (err) ->
    typeof callback == 'function' && callback(err, null)

bruteStore.defaults = {
  prefix: ''
  logging: false
}