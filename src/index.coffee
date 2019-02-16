AbstractClientStore = require('express-brute/lib/AbstractClientStore')
moment = require('moment')
Sequelize = require('sequelize')

module.exports = class bruteStore

  constructor:(sequelize, table, options, callback) ->
    AbstractClientStore.apply(@,arguments)
    @defaults = {prefix: '',logging: false}
    @options = Object.assign({}, @defaults, options)
    @_table = sequelize.define(table, {
      _id: {type: Sequelize.STRING,unique: true}
      expires: {type: Sequelize.DATE}
      firstRequest: {type: Sequelize.DATE}
      lastRequest: {type: Sequelize.DATE}
      count: {type: Sequelize.INTEGER}
    })

    @_table.sync().then =>
      console.log "bruteStore initialized - table #{table} created" if @options.logging
      return callback(@)
    .catch =>
      console.log "Failed to initialize bruteStore - table #{table}" if @options.logging
      return callback(@)

  set:(key, value, lifetime, callback) ->
    _id = @options.prefix+key
    expiration = if lifetime then (moment().add(lifetime, 'seconds')).toDate() else null
    @_table.findOne(where:{_id:_id})
    .then (doc)=>
      if doc
        doc._id = _id
        doc.count = value.count
        doc.lastRequest = value.lastRequest
        doc.firstRequest = value.firstRequest
        doc.expires = expiration
        doc.save()
      else
        @_table.create({_id:_id,count:value.count,lastRequest:value.lastRequest,firstRequest:value.firstRequest,expires:expiration})
    .then (doc) ->
      typeof callback == 'function' && callback()
      return null
    .catch (err) ->
      typeof callback == 'function' && callback(err)
      return null

  get:(key, callback) ->
    _id = @options.prefix+key
    @_table.findOne(where:{_id:_id})
    .then (doc) =>
      return @_table.destroy({where:{"_id":_id}}).then(() -> null) if doc && new Date(doc.expires).getTime() < new Date().getTime()
      return Promise.resolve(count:doc.count,lastRequest:new Date(doc.lastRequest),firstRequest:new Date(doc.firstRequest)) if doc
      Promise.resolve()
    .then (data)->
      data = undefined if !data
      typeof callback == 'function' && callback(null,data)
      return null
    .catch (err) ->
      typeof callback == 'function' && callback(err)
      return null

  reset:(key, callback) ->
    _id = @options.prefix+key
    @_table.destroy({where:{"_id":_id}})
    .then (doc) ->
      return typeof callback == 'function' && callback(null, doc)
      return null
    .catch (err) ->
      return typeof callback == 'function' && callback(err, null)
      return null