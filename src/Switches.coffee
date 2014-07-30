StormRegistry = require 'stormregistry'
StormData = require 'stormdata'
util = require('util')
request = require('request-json');
extend = require('util')._extend
ip = require 'ip'
async = require 'async'


vnetbuilderurl = 'http://localhost:5680/'
vnetprovisionerurl = 'http://localhost:5681/'

class switches    
    constructor:(sw)->
        @config = extend {}, sw
        @config.make ?= "bridge"
        @status = {}
        @statistics = {}
        util.log " switch config " + JSON.stringify @config


    create: (callback)->
        client = request.newClient('http://localhost:5680/')
        client.post '/switch', @config, (err, res, body) =>
            util.log "err" + JSON.stringify err if err?
            util.log "create switches result " + JSON.stringify body
            @uuid = body.id     
            #unless body instanceof Error
            #Error cases to be handled
            @status.result = body.status
            @status.reason = body.reason if body?.reason?
            callback

    del: (callback)->
        client = request.newClient('http://localhost:5680/')
        client.del "/switch/#{@uuid}", (err, res, body) =>
            util.log "err" + JSON.stringify err if err?
            util.log "delete switches result " + JSON.stringify body if body?
            unless body instanceof Error    
                @status.result = body.status if body?.status?
                callback @status

    get:()->
        "uuid":@uuid
        "config":@config
        "status":@status
        "statistics":@statistics



    stop:()->
        #To be done
        client = request.newClient('http://localhost:5680/')
        client.put "/switch/#{@uuid}/stop", @config, (err, res, body) =>
            util.log "err" + JSON.stringify err if err?
            util.log "start switche result " + JSON.stringify body if body?
            unless body instanceof Error
                @status.result = body.status if body?.status?
                callback @status

    start:(callback)->
        client = request.newClient('http://localhost:5680/')
        client.put "/switch/#{@uuid}/start", @config, (err, res, body) =>
            util.log "err" + JSON.stringify err if err?
            util.log "start switche result " + JSON.stringify body if body?
            unless body instanceof Error
                @status.result = body.status if body?.status?
                callback @status

    
    connect:(ifname, callback)->
        client = request.newClient('http://localhost:5680/')
        val =
            "ifname": ifname
        client.put "/switch/#{@uuid}/connect", val, (err, res, body) =>
            util.log "err" + JSON.stringify err if err?
            util.log "start switche result " + JSON.stringify body if body?
            unless body instanceof Error
                @status.result = body.status if body?.status?
                callback @status


    switchStatus:()->
        #To be done    
    statistics:()->

#####################################################################################################

module.exports = switches