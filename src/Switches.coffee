util = require('util')
request = require('request-json');
extend = require('util')._extend

#@vnetbuilderurl = 'http://localhost:5680/'

class switches    
    constructor: (sw , vnetbuilderurl, vnetprovisioner )->                
        @config = extend {}, sw
        @config.vnetbuilderurl = vnetbuilderurl
        @config.vnetprovisionerurl = vnetprovisioner
        @config.make ?= "bridge"
        @status = {}
        @statistics = {}
        util.log " switch config " + JSON.stringify @config
        util.log " switch config vnetbuilderurl " + JSON.stringify @config.vnetbuilderurl
        util.log " switch config vnetprovisionerurl " + JSON.stringify @config.vnetprovisionerurl
        #util.log " vnetbuilderurl  " + @vnetbuilderurl


    create: (callback)->
        client = request.newClient(@config.vnetbuilderurl)
        client.post '/switch', @config, (err, res, body) =>
            #Todo:  response to be checked before process.. (200 OK?)
            util.log "err" + JSON.stringify err if err?
            util.log "create switches result " + JSON.stringify body
            @uuid = body.id     
            #unless body instanceof Error
            #Error cases to be handled
            @status.result = body.status
            @status.reason = body.reason if body?.reason?
            callback

    del: (callback)->
        client = request.newClient(@config.vnetbuilderurl)
        client.del "/switch/#{@uuid}", (err, res, body) =>
            #Todo:  response to be checked before process.. (200 OK?)
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
        client = request.newClient(@config.vnetbuilderurl)
        client.put "/switch/#{@uuid}/stop", @config, (err, res, body) =>
            #Todo:  response to be checked before process.. (200 OK?)
            util.log "err" + JSON.stringify err if err?
            util.log "start switche result " + JSON.stringify body if body?
            unless body instanceof Error
                @status.result = body.status if body?.status?
                callback @status

    start:(callback)->
        client = request.newClient(@config.vnetbuilderurl)
        client.put "/switch/#{@uuid}/start", @config, (err, res, body) =>
            #Todo:  response to be checked before process.. (200 OK?)
            util.log "err" + JSON.stringify err if err?
            util.log "start switche result " + JSON.stringify body if body?
            unless body instanceof Error
                @status.result = body.status if body?.status?
                callback @status

    
    connect:(ifname, callback)->
        client = request.newClient(@config.vnetbuilderurl)
        val =
            "ifname": ifname        
        client.put "/switch/#{@uuid}/connect", val, (err, res, body) =>
            #Todo:  response to be checked before process.. (200 OK?)
            util.log "err" + JSON.stringify err if err?
            util.log "start switche result " + JSON.stringify body if body?
            unless body instanceof Error
                @status.result = body.status if body?.status?
                callback @status
    switchStatus:()->
        #Todo be done    
    statistics:()->
        #Todo

#####################################################################################################

module.exports = switches

#Todo items:  HTTP Request json timeout, response code to be checked 
