StormRegistry = require 'stormregistry'
StormData = require 'stormdata'
util = require('util')
request = require('request-json');
extend = require('util')._extend
ip = require 'ip'
async = require 'async'
vnetbuilderurl = 'http://localhost:5680/'
vnetprovisionerurl = 'http://localhost:5681/'

##########################################################################################################
# utility functions
subnetting = (net, curprefix, newprefix ) ->
    
    netmask = ip.fromPrefixLen(curprefix)
    newmask = ip.fromPrefixLen(newprefix)
    xx = new Buffer 4
    iter =  ( newprefix - curprefix ) 
    iterations = Math.pow(2, iter)
    answer = []
    do () ->
        for i in [0..iterations-1]
            result = ip.subnet(net,newmask)            
            result.status = "free"
            result.iparray = []

            xx = ip.toBuffer(result.firstAddress)
            for i in [0..result.numHosts-1]                               
                result.iparray[i] = ip.toString(xx)
                xx[3]++ 

            answer.push result
            xx = ip.toBuffer(result.broadcastAddress)
            xx[3]++     
            if xx[3] == 0x00
                xx[2]++
            str = ip.toString(xx)
            net = str
    return answer


iplist = (address) ->
    iparray = []
    result = ip.subnet(address, '255.255.255.0')
    xx = ip.toBuffer(result.firstAddress)
    for i in [0..result.numHosts-1]
        iparray[i] = ip.toString(xx)
        xx[3]++ 
    return iparray


HWADDR_PREFIX = "00:16:3e:5a:55:"
HWADDR_START = 10
getHwAddress = () ->
    HWADDR_START++      
    hwaddr= "#{HWADDR_PREFIX}#{HWADDR_START}"
    hwaddr
#utility functions end

#####################################################################################################

class TopologyRegistry extends StormRegistry
    constructor: (filename) ->
        @on 'load', (key,val) ->
            console.log "restoring #{key} with:",val
            entry = new TopologyData key,val
            if entry?
                entry.saved = true
                @add entry

        @on 'removed', (entry) ->
            entry.destructor() if entry.destructor?

        super filename

    add: (data) ->
        return unless data instanceof TopologyData
        entry = super data.id, data

    update: (data) ->        
        super data.id, data    

    get: (key) ->
        entry = super key
        return unless entry?

        if entry.data? and entry.data instanceof TopologyData
            entry.data.id = entry.id
            entry.data
        else
            entry

class TopologyData extends StormData
    TopologySchema =
        name: "Topology"
        type: "object"
        additionalProperties: true
        properties:            
            projectid: {type:"string", required:true}
            name: {type:"string", required:true}            
            virtualization: { type: "string", required: true}
            ipassignment:{ type: "string", required: true}
            wanip_pool:{ type: "string", required: false}
            lanip_pool:{ type: "string", required: false}
            loip_pool:{ type: "string", required: false}            
            switches:
                    type: "array"
                    items:
                        name: "switch"
                        type: "object"
                        required: true
                        additionalProperties: true
                        properties:
                            name: {type:"string", required:true}            
                            type:  {type:"string", required:true}            
                            ports: {type:"integer", required:true}
            nodes:
                    type: "array"
                    items:
                        name: "node"
                        type: "object"
                        required: true
                        additionalProperties: true
                        properties:
                            name: {type:"string", required:true}            
                            type: {type:"string", required:true}
                            Services:
                                type: "array"
                                required: true
                                additionalProperties: true
                                items:
                                    type: "object"
                                    required: true                                    
                                    properties:
                                        name:           {"type":"string", "required":false}                                        
                                        enabled:        {"type":"boolean", "required":false}
                                        autoprovision:  {"type":"boolean", "required":false}
                                        autostart:  {"type":"boolean", "required":false}                                        
                            no_of_wan_interfaces : {type:"integer", required:true}            
                            no_of_lan_interfaces : {type:"integer", required:true}            
                            no_of_lo_interfaces : {type:"integer", required:true} 
            links:
                    type: "array"
                    items:
                        name: "node"
                        type: "object"
                        required: true
                        additionalProperties: true
                        properties:                
                            type: {type:"string", required:true}
                            switch: {type:"string", required:true}
                            connected_nodes:
                                type: "array"
                                required: true
                                additionalProperties: true
                                items:
                                    type: "object"
                                    required: true                                    
                                    properties:
                                        name:{"type":"string", "required":false}                            
    constructor: (id, data) ->
        super id, data, TopologySchema

##########################################################################################################
class IPManager
    constructor :(wan,lan,mgmt) ->
        util.log "wan pool #{wan} "
        util.log "lan pool #{lan} "
        util.log "mgmt pool #{mgmt}"
        @wansubnets = subnetting wan, 24, 30
        @lansubnets = subnetting lan, 24, 27
        @wanindex = 0
        @lanindex = 0
        @mgmtindex = 1
        @mgmtips = iplist(mgmt)

    listwansubnets:()->
        util.log "wansubnets " + JSON.stringify @wansubnets
    listlanubnets:()->
        util.log "lansubnets " + JSON.stringify @lansubnets
    getFreeWanSubnet:()->
        @wansubnets[@wanindex++]
    getFreeLanSubnet:()->
        @lansubnets[@lanindex++]
    getFreeMgmtIP :()->
        @mgmtips[@mgmtindex++]

###################################################################################################

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
            "ifname" : "eth#{@ifindex++}"
            "hwAddress" : getHwAddress()
            "brname" : brname 
            "ipaddress": ipaddress 
            "netmask" : subnetmask
            "gateway" : gateway if gateway?
            "type":"lan"
        @ifmap.push  interf

    addWanInterface :(brname, ipaddress, subnetmask, gateway) ->         
        interf =
            "ifname" : "eth#{@ifindex++}"
            "hwAddress" : getHwAddress()
            "brname" : brname
            "ipaddress": ipaddress
            "netmask" : subnetmask
            "gateway" : gateway if gateway?
            "type":"wan"
        @ifmap.push  interf

    addMgmtInterface :(ipaddress, subnetmask) ->
        interf =
            "ifname" : "eth0"
            "hwAddress" : getHwAddress()                
            "ipaddress": ipaddress
            "netmask" : subnetmask                
            "type":"mgmt"
        @ifmap.push  interf

    create : ()->
        client = request.newClient(vnetbuilderurl)
        client.post '/vm', @config, (err, res, body) =>
            util.log "err" + JSON.stringify err if err?            
            util.log "node create result " + JSON.stringify body
            @status = body
            unless body instanceof Error        
                @uuid = body.id     
                @status.result = body.status           
                @status.reason = body.reason if body.reason?
                @start()            

    start : ()->        
        client = request.newClient(vnetbuilderurl)
        client.put "/vm/#{@uuid}/start", @config, (err, res, body) =>
            util.log "err" + JSON.stringify err if err?            
            util.log "node start result " + JSON.stringify body            
            unless body instanceof Error                
                @status.result = body.status
                @status.reason = body.reason if body.reason?

            
                
    destroy :(callback)->
        client = request.newClient(vnetbuilderurl)
        client.del "/vm/#{@uuid}", (err, res, body) =>
            util.log "node destroy body " + body if body?
            util.log "node destroy result - res statuscode" + res.statusCode
            callback(body)
            #unless body instanceof Error
            #    @status.result = body.status
            #    @status.reason = body.reason if body.reason?
            #    callback()
                
    nodestatus :(callback)->
        util.log "inside node status funciton"
        client = request.newClient(vnetbuilderurl)
        client.post '/status', @config, (err, res, body) =>
            util.log "err" + JSON.stringify err if err?            
            util.log "node statusVM result " + JSON.stringify body
            return callback body            

    get : () ->
        "config": @config
        "status": @status
        "statistics":@statistics

    provision : ()->
        # check the services and start configuring the services
        # REST API to provisioner

    statistics :()->
        # REST API to provisioner


########################################################################################################

class switches    
    constructor:(sw)->
        @config = extend {}, sw
        @status = {}
        @statistics = {}
        util.log " switch config " + JSON.stringify @config


    create:()->
        client = request.newClient('http://localhost:5680/')
        client.post '/switch', @config, (err, res, body) =>
            util.log "err" + JSON.stringify err if err?
            util.log "create switches result " + JSON.stringify body
            @uuid = body.id     
            unless body instanceof Error
                @status.result = body.status
                @status.reason = body.reason if body.reason?

    destroy:(callback)->
        client = request.newClient('http://localhost:5680/')
        client.del "/switch/#{@uuid}", (err, res, body) =>
            util.log "err" + JSON.stringify err if err?
            util.log "delete switches result " + JSON.stringify body
            unless body instanceof Error
                @status.result = body.status
                @status.reason = body.reason if body.reason?
                callback()
             
    get:()->
        "config":@config
        "status":@status
        "statistics":@statistics
    status:()->
    statistics:()->

#####################################################################################################

class Topology    
    createSwitches :()->
        for sw in @switchobj
            sw.create()

    createNodes :()->
        for n in @nodeobj
            n.create()

    startNodes: ()->
        util.log "startNodes"
        for n in @nodeobj
            util.log "starting node"
            n.start()
    ###
    destroyNodes: ()->    
        util.log "destroyNodes"
        for n in @nodeobj
            util.log "delete node"
            n.destroy()
        return
    destroySwitches :()->
        for sw in @switchobj
            sw.destroy()
###
    getNodeObjbyName:(name) ->
        for obj in @nodeobj
            util.log "getNodeObjbyName" + obj.config.name
            if obj.config.name is name
                util.log "getNodeObjbyName found " + obj.config.name
                return obj
        return null
   

    constructor :(@tdata) ->
        util.log "Topology class: " + JSON.stringify @tdata               
        util.log "createSwitches "+ JSON.stringify @tdata.data.switches
        @config = {}
        @status = {}
        @statistics = {}
        @config = extend {}, tdata

        @uuid = @tdata.id
        #@projectid = @tdata.data.projectid
        @switchobj = []
        @nodeobj =  []
        @linksobj = []

        @ipmgr = new IPManager("172.16.1.0","10.10.10.0", "10.0.3.0")


        for sw in @tdata.data.switches   
            obj = new switches sw
            @switchobj.push obj

        for val in @tdata.data.nodes
            obj = new node @tdata.data.projectid, val
            mgmtip = @ipmgr.getFreeMgmtIP() 
            obj.addMgmtInterface mgmtip , '255.255.255.0'
            @nodeobj.push obj
            
        for val in @tdata.data.links                        
            x = 0
            if val.type is "lan"
                temp = @ipmgr.getFreeLanSubnet()                 
                for n in  val.connected_nodes
                    obj = @getNodeObjbyName(n.name)
                    if obj?
                        startaddress = temp.iparray[x++]
                        obj.addLanInterface(val.switch, startaddress, temp.subnetMask)

            if val.type is "wan"
                temp = @ipmgr.getFreeWanSubnet()
                swname = "#{val.type}_#{val.connected_nodes[0].name}_#{val.connected_nodes[1].name}"
                util.log "  wan swname is "+ swname
                obj = new switches
                    name : swname
                    ports: 2
                    type : "bridge"                
                @switchobj.push obj
                for n in  val.connected_nodes
                    obj = @getNodeObjbyName(n.name)
                    if obj?
                        startaddress = temp.iparray[x++]
                        obj.addWanInterface(swname, startaddress, temp.subnetMask)
        @createSwitches()
        @createNodes()    
        
    destroyNodes :()->
        @tmparray = []
        #@destroySwithes()
        util.log "destroying the Nodes"

        async.each @nodeobj, (n,callback) =>
            util.log "delete node #{n.uuid}"
            n.destroy (result) =>                
                @tmparray.push result
                callback()
        ,(err) =>
            if err
                console.log "error occured " + err
                return false
            else
                console.log "all are processed " + @tmparray
                return true
    destroySwitches :()->
        @tmparray = []
        #@destroySwithes()
        util.log "destroying the Switches"

        async.each @switchobj, (n,callback) =>
            util.log "delete switch #{n.uuid}"
            n.destroy (result) =>                
                @tmparray.push result
                callback()
        ,(err) =>
            if err
                console.log "error occured " + err
                return false
            else
                console.log "all are processed " + @tmparray
                return true


    destroy :()->
        res = @destroyNodes() 
        res1 = @destroySwitches()
        return true


        ###        
        for n in @nodeobj
            util.log "delete node #{n.uuid}"
            n.destroy (result) =>
                destroynodes.push result if result?

        for sw in @switchobj
            util.log "delete switches #{sw.uuid}"
            sw.destroy (result) =>
                destroyswitches.push result if result?
        

        "nodes" : destroynodes
        "switches" : destroyswitches
        ###


    get :()->
        nodestatus = []
        switchstatus = []

        for n in @nodeobj
            nodestatus.push n.get()
        for n in @switchobj
            switchstatus.push n.get()
        "config" : @config
        "status" :
            "vmstatus" : nodestatus
            "switchstatus":  switchstatus

    vmstatus :(callback)->
        arr = []
        util.log "inside topoloy status function"
        for n in @nodeobj
            n.nodestatus (val) =>
                arr.push val
                callback arr

##############################################################################################        

class TopologyMaster
    constructor :(filename) ->
        @registry = new TopologyRegistry filename
        @topologyobj = []
    
    list : (callback) ->
        return callback @registry.list()

    create : (data, callback)->
        try	            
            topodata = new TopologyData null, data

        catch err
            util.log "invalid schema" + err
            return callback new Error "Invalid Input "
        finally				
            util.log JSON.stringify topodata            
            callback @registry.add topodata
            @obj = new Topology topodata
            @topologyobj.push @obj

    status : (data , callback) ->
        obj = @getTopologyObj(data)
        if obj?                    
            return callback obj.vmstatus() 
        else
            return callback new Error "Unknown Topology ID"

    del : (data, callback) ->
        obj = @getTopologyObj(data)
        if obj? 
            @registry.remove obj.uuid
            return callback obj.destroy()
        else
            return callback new Error "Unknown Topology ID"

    get : (data, callback) ->
        obj = @getTopologyObj(data)
        if obj? 
            return callback obj.get()
        else
            return callback new Error "Unknown Topology ID"



    getTopologyObj:(data) ->
        for obj in @topologyobj
            util.log "topologyobj" + obj.uuid
            if  obj.uuid is data 
                util.log "getTopologyObj found " + obj.uuid
                return obj
        return null

##########################################################################################3

instance = new TopologyMaster '/tmp/topology.db'
module.exports =  instance