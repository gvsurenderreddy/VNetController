StormRegistry = require 'stormregistry'
StormData = require 'stormdata'
util = require('util')
request = require('request-json');
extend = require('util')._extend
ip = require 'ip'
async = require 'async'


vnetbuilderurl = 'http://localhost:5680/'
vnetprovisionerurl = 'http://localhost:5681/'


IPManager = require('./IPManager')
node = require('./Node')
switches = require('./Switches')


#============================================================================================================
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

#============================================================================================================
class TopologyData extends StormData
    TopologySchema =
        name: "Topology"
        type: "object"
        additionalProperties: true
        properties:            
            projectid: {type:"string", required:false}
            name: {type:"string", required:true}            
            virtualization: { type: "string", required: false}
            ipassignment:{ type: "string", required: false}
            wanip_pool:{ type: "string", required: false}
            lanip_pool:{ type: "string", required: false}
            loip_pool:{ type: "string", required: false}            
            switches:
                    type: "array"
                    items:
                        name: "switch"
                        type: "object"
                        required: false
                        additionalProperties: true
                        properties:
                            name: {type:"string", required:false}            
                            type:  {type:"string", required:false}            
                            ports: {type:"integer", required:false}
            nodes:
                    type: "array"
                    items:
                        name: "node"
                        type: "object"
                        required: true
                        additionalProperties: true
                        properties:
                            name: {type:"string", required:true}            
                            type: {type:"string", required:false}
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
                            no_of_wan_interfaces : {type:"integer", required:false}            
                            no_of_lan_interfaces : {type:"integer", required:false}            
                            no_of_lo_interfaces : {type:"integer", required:false} 
            links:
                    type: "array"
                    items:
                        name: "node"
                        type: "object"
                        required: true
                        additionalProperties: true
                        properties:                
                            type: {type:"string", required:true}
                            switch: {type:"string", required:false}
                            connected_nodes:
                                type: "array"
                                required: true
                                additionalProperties: true
                                items:
                                    type: "object"
                                    required: true                                    
                                    properties:
                                        name:{"type":"string", "required":true}                            
    constructor: (id, data) ->
        super id, data, TopologySchema



#============================================================================================================

class Topology   

    createSwitches :(cb)->
        #async parallel to be used to create nodes and sw.create responses to be handled.
        for sw in @switchobj
            sw.create()            

        async.each @switchobj, (sw,callback) =>
            util.log "create switch "
            sw.create (result) =>   
                util.log "create switch result " + JSON.stringify result
                callback()
        ,(err) =>
            if err
                console.log "error occured " + err
                cb(false)
            else
                console.log "createswitches all are processed "
                cb (true)



    createNodes :(cb)->
        #async parallel to be used to create nodes and node create responses to be handled.
        async.each @nodeobj, (n,callback) =>
            util.log "create node "
            n.create (result) =>   
                util.log "create node result " + result
                n.start (result)=>                    
                    util.log "start node result" + result
                    callback()
        ,(err) =>
            if err
                console.log "error occured " + err
                cb(false)
            else
                console.log "createNodes all are processed "
                cb (true)

    provisionNodes :(cb)->
        #async parallel to be used to create nodes and node create responses to be handled.
        async.each @nodeobj, (n,callback) =>
            util.log "provision node "
            n.provision (result) =>   
                util.log "provision node result " + result
                callback()
        ,(err) =>
            if err
                console.log "error occured " + err
                cb(false)
            else
                console.log "provisionNodes all are processed "
                cb (true)

    
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
        @createSwitches (res)=>
            util.log "createswitches result" + res            
        @createNodes (res)=>
            util.log "topologycreation status" + res
                #Check the sttatus and do provision
            util.log "readu for provision"
            @provisionNodes (res)=>
                util.log "provision" + res


        
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


    get :()->
        nodestatus = []
        switchstatus = []

        for n in @nodeobj
            nodestatus.push n.get()
        for n in @switchobj
            switchstatus.push n.get()
        #"config" : @config        
        "nodes" : nodestatus
        "switches":  switchstatus

    provision: ()->
        



    vmstatus :(callback)->
        arr = []
        util.log "inside topoloy status function"
        for n in @nodeobj
            n.nodestatus (val) =>
                arr.push val
                callback arr

#============================================================================================================

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

#============================================================================================================

instance = new TopologyMaster '/tmp/topology.db'
module.exports =  instance