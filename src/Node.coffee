StormRegistry = require 'stormregistry'
StormData = require 'stormdata'
util = require('util')
request = require('request-json');
extend = require('util')._extend
ip = require 'ip'
async = require 'async'

vnetbuilderurl = 'http://localhost:5680/'
vnetprovisionerurl = 'http://localhost:5671/'

#utility functions 
#To be modified
HWADDR_PREFIX = "00:16:3e:5a:55:"
HWADDR_START = 10
getHwAddress = () ->
    HWADDR_START++      
    hwaddr= "#{HWADDR_PREFIX}#{HWADDR_START}"
    hwaddr


class node
    constructor:(topoid, data) ->
        @ifmap = []        
        @ifindex = 1
        
        @config = extend {}, data        
        @config.memory = "128m"
        @config.vcpus = "2"
        @config.projectid = topoid        
        @config.ifmap = @ifmap        
        @statistics = {}
        @status = {}


    addLanInterface :(brname, ipaddress, subnetmask, gateway) ->         
        interf =
            "ifname" : "eth#{@ifindex}"
            "hwAddress" : getHwAddress()
            "brname" : brname 
            "ipaddress": ipaddress 
            "netmask" : subnetmask
            "gateway" : gateway if gateway?
            "type":"lan"
            "veth" : "veth_#{@config.name}_eth#{@ifindex}"
        @ifindex++
        @ifmap.push  interf

    addWanInterface :(brname, ipaddress, subnetmask, gateway) ->         
        interf =
            "ifname" : "eth#{@ifindex}"
            "hwAddress" : getHwAddress()
            "brname" : brname
            "ipaddress": ipaddress
            "netmask" : subnetmask
            "gateway" : gateway if gateway?
            "type":"wan"
            "veth" : "veth_#{@config.name}_eth#{@ifindex}"
        
        @ifindex++
        @ifmap.push  interf

    addMgmtInterface :(ipaddress, subnetmask) ->
        interf =
            "ifname" : "eth0"
            "hwAddress" : getHwAddress()                
            "ipaddress": ipaddress
            "netmask" : subnetmask                
            "type":"mgmt"
        @ifmap.push  interf

    #
    create : (callback)->
        client = request.newClient(vnetbuilderurl)
        client.post '/vm', @config, (err, res, body) =>
            util.log "err" + JSON.stringify err if err?            
            util.log "node create result " + JSON.stringify body            
            #failure response not handled properly
            #unless body instanceof Error        
            @uuid = body.id
            @config.id = @uuid     
            @status.result = body.status           
            @status.reason = body.reason if body.reason?
            callback(@status)
                #@start()            

    start : (callback)->        
        client = request.newClient(vnetbuilderurl)
        client.put "/vm/#{@uuid}/start", @config, (err, res, body) =>
            util.log "err" + JSON.stringify err if err?            
            util.log "node start result " + JSON.stringify body            
            #failure cases not handler properly
            #unless body instanceof Error                
            @status.result = body.status
            @status.reason = body.reason if body.reason?
            callback(@status)   

    stop: (callback)->
        client = request.newClient(vnetbuilderurl)
        client.put "/vm/#{@uuid}/stop", @config, (err, res, body) =>
            util.log "err" + JSON.stringify err if err?            
            util.log "node stop result " + JSON.stringify body            
            #failure cases not handler properly
            #unless body instanceof Error                
            @status.result = body.status
            @status.reason = body.reason if body.reason?
            callback(@status)   
                
    #delete the VM
    del :(callback)->
        client = request.newClient(vnetbuilderurl)
        client.del "/vm/#{@uuid}", (err, res, body) =>
            util.log "node del body " + body if body?
            util.log "node del result - res statuscode" + res.statusCode
            callback(body)
                
    #This function get the data stored in the vmbuilder
    getstatus :(callback)->
        util.log "inside get status funciton"
        client = request.newClient(vnetbuilderurl)
        client.get "/vm/#{@uuid}", (err, res, body) =>
            util.log "err" + JSON.stringify err if err?            
            util.log "node status vm result " + JSON.stringify body
            return callback body         

    #This function get the current status 
    getrunningstatus :(callback)->
        util.log "inside get status funciton"
        client = request.newClient(vnetbuilderurl)
        client.get "/vm/#{@uuid}/status", (err, res, body) =>
            util.log "err" + JSON.stringify err if err?            
            util.log "node running status vm result " + JSON.stringify body
            return callback body   

    stats :(callback)->
        # REST API 
        util.log "inside stats funciton"
        client = request.newClient(vnetprovisionerurl)
        client.get "/collect/#{@uuid}/stats", (err, res, body) =>
            util.log "err" + JSON.stringify err if err?            
            util.log "node stats collectoin result " + JSON.stringify body
            @statistics = body
            return callback body    


    #  provisioning function
    provision : (callback)->
        # check the services and start configuring the services
        # REST API to provisioner
        util.log "inside provisioner funciton"
        client = request.newClient(vnetprovisionerurl)
        client.post '/provision', @config, (err, res, body) =>
            util.log "err" + JSON.stringify err if err?            
            util.log "node provision result " + JSON.stringify body
            @status.result = body.status  if body?.status?
            @status.reason = body.reason if body?.reason?
            return callback body    

    provisionStatus : (callback)->
        # check the services and start configuring the services
        # REST API to provisioner
        util.log "inside provisioner funciton"
        client = request.newClient(vnetprovisionerurl)
        client.get "/provision/#{@uuid}/status", (err, res, body) =>
            util.log "err" + JSON.stringify err if err?            
            util.log "node provision result " + JSON.stringify body
            @status.result = body.status  if body?.status?
            @status.reason = body.reason if body?.reason?
            return callback body    
    



    #retun the current data of this object
    get : () ->
        "id" : @uuid
        "config": @config
        "status": @status
        "statistics":@statistics

module.exports = node