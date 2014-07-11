StormRegistry = require 'stormregistry'
StormData = require 'stormdata'
util = require('util')
request = require('request-json');
extend = require('util')._extend
ip = require 'ip'
vnetbuilderurl = 'http://localhost:5680/'
vnetprovisionerurl = 'http://localhost:15682/'

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
        client.post '/createVM', @config, (err, res, body) =>
            util.log "err" + JSON.stringify err if err?            
            util.log "node create result " + JSON.stringify body
            unless body instanceof Error        
                @config = body if body.result?
                @start()            

    start : ()->        
        client = request.newClient(vnetbuilderurl)
        client.post '/startVM', @config, (err, res, body) =>
            util.log "err" + JSON.stringify err if err?            
            util.log "node start result " + JSON.stringify body
            unless body instanceof Error
                @config = body
                callback @config
            callback new Error "Failed to Start"             
                
    destroy :(callback)->
        client = request.newClient(vnetbuilderurl)
        client.post '/deleteVM', @config, (err, res, body) =>
            util.log "err" + JSON.stringify err if err?            
            util.log "node destroy result " + JSON.stringify body
            unless body instanceof Error
                @config = body 
                callback @config                            
            callback new Error "Failed to destroy"

    nodestatus :(callback)->
        util.log "inside node status funciton"
        client = request.newClient(vnetbuilderurl)
        client.post '/statusVM', @config, (err, res, body) =>
            util.log "err" + JSON.stringify err if err?            
            util.log "node statusVM result " + JSON.stringify body
            return callback body            

    provision : ()->
        # check the services and start configuring the services
        # REST API to provisioner

    statistics :()->
        # REST API to provisioner

########################################################################################################

class switches    
    constructor:(sw)->
        @config = extend {}, sw
        util.log " switch config " + JSON.stringify @config

    create:()->
        client = request.newClient('http://localhost:5680/')
        client.post '/createswitch', @config, (err, res, body) =>
            util.log "err" + JSON.stringify err if err?
            util.log "create switches result " + JSON.stringify body
            @status = body.result

    destroy:()->
        client = request.newClient('http://localhost:5680/')
        client.post '/deleteSwitch', @config, (err, res, body) =>
            util.log "err" + JSON.stringify err if err?
            util.log "delete switches result " + JSON.stringify body
            @status = body.result        

    status:()->
    statistics:()->

#####################################################################################################

class Topology    
    createSwitches :()->
        for sw in @switchobj
            sw.create()

    destroySwitches :()->
        for sw in @switchobj
            sw.destroy()

    createNodes :()->
        for n in @nodeobj
            n.create()

    startNodes: ()->
        util.log "startNodes"
        for n in @nodeobj
            util.log "starting node"
            n.start()

    destroyNodes: ()->    
        util.log "destroyNodes"
        for n in @nodeobj
            util.log "delete node"
            n.destroy()
        return

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
        @uuid = @tdata.id
        @projectid = @tdata.data.projectid
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
                util.log "wan swname is "+ swname
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
        
    destroy :()->
        @destroyNodes()
        #@destroySwithes()

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
        project = require './project'
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
        obj = @getTopologyObj(data.id)
        if obj?                    
            return callback obj.vmstatus() 
        else
            return callback new Error "Unknown Topology ID"

    destroy : (data, callback) ->
        obj = @getTopologyObj(data.id)
        callback @registry.remove obj.uuid
        if obj? 
            return callback obj.destroy()
        else
            return callback new Error "Unknown Topology ID"

    getTopologyObj:(data) ->
        for obj in @topologyobj
            util.log "topologyobj" + obj.projectid
            if  obj.projectid is data 
                util.log "getTopologyObj found " + obj.projectid 
                return obj
        return null

##########################################################################################3

instance = new TopologyMaster '/tmp/topology.db'
module.exports =  instance