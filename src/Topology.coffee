StormRegistry = require 'stormregistry'
StormData = require 'stormdata'
util = require('util')
request = require('request-json');
extend = require('util')._extend



# utility functions
subnetting = (net, curprefix, newprefix ) ->
    ip = require 'ip'
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



HWADDR_PREFIX = "00:16:3e:5a:55:"
HWADDR_START = 10
getHwAddress = () ->
    HWADDR_START++      
    hwaddr= "#{HWADDR_PREFIX}#{HWADDR_START}"
    hwaddr
#utility functions end



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



class IPManager
    constructor :(wan,lan) ->
        util.log "wan pool #{wan} "
        util.log "lan pool #{lan} "
        @wansubnets = subnetting wan, 24, 30
        @lansubnets = subnetting lan, 24, 27
        @wanindex = 0
        @lanindex = 0
    listwansubnets:()->
        util.log "wansubnets " + JSON.stringify @wansubnets
    listlanubnets:()->
        util.log "lansubnets " + JSON.stringify @lansubnets
    getFreeWanSubnet:()->
        @wansubnets[@wanindex++]
    getFreeLanSubnet:()->
        @lansubnets[@lanindex++]


class node
    constructor:(topoid, data) ->
        @ifmap = []        
        @ifindex = 1
        #util.log "topoid : " + topoid
        @config = extend {}, data        
        @config.memory = "128m"
        @config.vcpus = "2"
        @config.projectid = topoid
        #util.log " node config " + JSON.stringify @config        
        @config.ifmap = @ifmap

    addLanInterface :(brname, startaddress, subnetmask) ->         
            interf =
                "ifname" : "eth#{@ifindex++}"
                "hwAddress" : getHwAddress()
                "brname" : brname
                "ipaddress": startaddress
                "netmask" : subnetmask
                "gateway" : startaddress
                "type":"lan"
            @ifmap.push  interf

    create : ()->
        client = request.newClient('http://localhost:5680/')
        client.post '/createVM', @config, (err, res, body) =>
            util.log "err" + JSON.stringify err if err?            
            util.log "node result " + JSON.stringify body
            @status = body.result

    destroy :()->

    status : ()->

    statistics :()->


class switches    
    constructor:(sw)->
        @config = extend {}, sw
        util.log " switch config " + JSON.stringify @config

    create:()->
        client = request.newClient('http://localhost:5680/')
        client.post '/createswitch', @config, (err, res, body) =>
                util.log "err" + JSON.stringify err if err?
                util.log "switches result " + JSON.stringify body
                @status = body.result

    destroy:()->

    status:()->

    statistics:()->


class links
    constructor :(topoid, tdata) ->       
        @config = extend {}, tdata
        util.log "links "+ JSON.stringify @config

        name = "#{tdata.type}_#{tdata.connected_nodes[0].name}_#{tdata.connected_nodes[1].name}"
        util.log "link name is " + name
        @config.switch =
                "name": name                
                "ports": 2
                "type": "bridge"
        @config.switchobj = new switches @config.switch




class Topology

    #@switchobj = []
    #@nodeobj =  []
    #@subnets = []

    createSwitches :()->
        for sw in @switchobj
            sw.create()

    createNodes :()->
        for n in @nodeobj
            n.create()

    connectNode: () ->

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

        @switchobj = []
        @nodeobj =  []
        @linksobj = []

        @ipmgr = new IPManager("172.16.1.0","10.10.10.0")


        for sw in @tdata.data.switches   
            obj = new switches sw
            @switchobj.push obj

        for val in @tdata.data.nodes
            obj = new node @tdata.data.projectid, val
            @nodeobj.push obj
            
        for val in @tdata.data.links                        
            x = 0
            #temp = @ipmgr.getFreeWanSubnet() if val.type is "wan"
            if val.type is "lan"
                temp = @ipmgr.getFreeLanSubnet() 

                
                for n in  val.connected_nodes
                    obj = @getNodeObjbyName(n.name)
                    if obj?
                        startaddress = temp.iparray[x++]
                        obj.addLanInterface(val.switch, startaddress, temp.subnetMask)
        
        @createSwitches()
        @createNodes()        


class TopologyMaster
    constructor :(filename) ->
        @registry = new TopologyRegistry filename
    
    list : (callback) ->
        return callback @registry.list()

    create : (@data, callback)->
        project = require './project'
        try	            
            topodata = new TopologyData null, @data

        catch err
            util.log "invalid schema" + err
            return callback new Error "Invalid Input "
        finally				
            util.log JSON.stringify topodata            
            callback @registry.add topodata
            @obj = new Topology topodata
            #@createSwitches topodata.data
    status : (callback) ->
        @obj.status()

  

instance = new TopologyMaster '/tmp/topology.db'
module.exports =  instance