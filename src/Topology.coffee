
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
            name: {type:"string", required:true}
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
                            make: {type:"string", required:true}
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
                            make: {type:"string", required:false}
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

    constructor :() ->        
        @config = {}
        @status = {}
        @statistics = {}        
        @switchobj = []
        @nodeobj =  []
        @linksobj = []
        @ipmgr = new IPManager("172.16.1.0","10.10.10.0", "10.0.3.0")


    getNodeObjbyName:(name) ->
        for obj in @nodeobj
            util.log "getNodeObjbyName" + obj.config.name
            if obj.config.name is name
                util.log "getNodeObjbyName found " + obj.config.name
                return obj
        return null

    getSwitchObjbyName:(name) ->
        util.log "inpjut for check " + name
        for obj in @switchobj
            util.log "getSwitchObjbyName iteratkon " + obj.config.name
            if obj.config.name is name
                util.log "getSwitchObjbyName found " + obj.config.name
                return obj
        return null

    getSwitchObjbyUUID:(uuid) ->
        for obj in @switchobj
            util.log "getSwitchObjbyUUID " + obj.uuid
            if obj.uuid is uuid
                util.log "getSwitchObjbyUUID found " + obj.uuid
                return obj
        return null



    getNodeObjbyUUID:(uuid) ->
        for obj in @nodeobj
            util.log "getNodeObjbyUUID" + obj.uuid
            if obj.uuid is uuid
                util.log "getNodeObjbyUUID found " + obj.config.uuid
                return obj
        return null


    createSwitches :(cb)->
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

    startSwitches :(cb)->
        async.each @switchobj, (sw,callback) =>
            util.log "start switch "
            sw.start (result) =>   
                util.log "start switch result " + JSON.stringify result
                callback()
        ,(err) =>
            if err
                console.log "error occured " + err
                cb(false)
            else
                console.log "startswitches all are processed "
                cb (true)

    #create and start the nodes
    # The node creation process is async.  node create (create) call immediately respond with "creation-in-progress"
    # creation process may take few minutes dependes on the VM SIZE.
    # poll the node status(getStatus) function, to get the creation status.  Once its created, the node will be 
    # started with (start ) function.
    # 
    # Implementation:
    #  async.each is used to process all the nodes.
    #  async.until is used for poll the status  until the node creation is success. once creation is success it start the node.

    createNodes :(cb)->    
        async.each @nodeobj, (n,callback) =>
            util.log "create node "
            
            n.create (result) =>   
                util.log "create node result " + result
                #check continuosly till we get the creation status value 
                create = false
                async.until(
                    ()->
                        return create
                    (repeat)->
                        n.getstatus (result)=>
                            console.log "node creation status " + result.data.status
                            unless result.data.status is "creation-in-progress"
                                create = true
                                n.start (result)=>                    
                                    util.log "start node result" + result
                                    return
                            setTimeout(repeat, 30000);
                    (err)->                        
                        console.log "completed execution"
                        callback(err)                        
                )
        ,(err) =>
            if err
                console.log "error occured " + err
                cb(false)
            else
                console.log "createNodes all are processed "
                cb (true)


    provisionNodes :(cb)->
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

    destroyNodes :()->
        @tmparray = []
        #@destroySwithes()
        util.log "destroying the Nodes"

        async.each @nodeobj, (n,callback) =>
            util.log "delete node #{n.uuid}"
            n.del (result) =>                
                @tmparray.push result
                callback()
        ,(err) =>
            if err
                console.localhostg "error occured " + err
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
            n.del (result) =>                
                @tmparray.push result
                callback()
        ,(err) =>
            if err
                console.log "error occured " + err
                return false
            else
                console.log "all are processed " + @tmparray
                return true

    #Create Links  - Todo
    createLinks :(cb)->
        #travel each node and travel each interface 
        #get bridgename and vethname
        # call the api to add virtual interface to the switch
        async.each @nodeobj, (n,callback) =>
            util.log "create Links"
            #travelling each interface
            for ifmap in n.config.ifmap
                if ifmap.veth?
                    obj = @getSwitchObjbyName(ifmap.brname)
                    if obj?
                        obj.connect ifmap.veth , (res) =>
                            console.log "connect result" + res
                            callback()                                
        ,(err) =>
            if err
                console.log "error occured " + err
                cb(false)
            else
                console.log "connected links  all are processed "
                cb (true)



    #Topology REST API functions
    create :(@tdata)->
        util.log "Topology create: " + JSON.stringify @tdata                       

        @config = extend {}, tdata
        @uuid = @tdata.id

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
                    type : val.type
                    make : val.make
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
            @createLinks (res)=>
                console.log "create links result " + res

                @startSwitches (res)=>
                    console.log "start switches result "  + res
                    util.log "ready for provision"

                    #provision
                    @provisionNodes (res)=>
                        util.log "provision" + res


    del :()->
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

    #below function is not used- to be removed
    vmstatus :(callback)->
        arr = []
        util.log "inside topoloy status function"
        for n in @nodeobj
            n.nodestatus (val) =>
                arr.push val
                callback arr
    #Device specific rest api functions


#============================================================================================================

class TopologyMaster
    constructor :(filename) ->
        @registry = new TopologyRegistry filename
        @topologyobj = []

    getTopologyObj : (data) ->
        for obj in @topologyobj
            util.log "topologyobj" + obj.uuid
            if  obj.uuid is data 
                util.log "getTopologyObj found " + obj.uuid
                return obj
        return null

    #Topology specific REST API functions
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
            @obj = new Topology
            @obj.create topodata
            @topologyobj.push @obj

   
    del : (data, callback) ->
        obj = @getTopologyObj(data)
        if obj? 
            @registry.remove obj.uuid
            return callback obj.del()
        else
            return callback new Error "Unknown Topology ID"

    get : (data, callback) ->
        obj = @getTopologyObj(data)
        if obj? 
            return callback obj.get()
        else
            return callback new Error "Unknown Topology ID"

    #Device specific rest API functions
    deviceStats: (topolid, deviceid, callback) ->
        obj = @getTopologyObj(topolid)
        if obj? 
            deviceobj = obj.getNodeObjbyUUID(deviceid)
            if deviceobj?
                deviceobj.stats (result)=>
                    callback result
            else                
                callback new Error "Unknown Device ID"
        else
            callback new Error "Unknown Topology ID"


     deviceGet: (topolid, deviceid, callback) ->
        obj = @getTopologyObj(topolid)
        if obj? 
            deviceobj = obj.getNodeObjbyUUID(deviceid)
            if deviceobj?
                deviceobj.getstatus (result)=>
                    return callback result
            else                
                return callback new Error "Unknown Device ID"
        else
            return callback new Error "Unknown Topology ID"


    deviceStatus: (topolid, deviceid, callback) ->
        obj = @getTopologyObj(topolid)
        if obj? 
            deviceobj = obj.getNodeObjbyUUID(deviceid)
            if deviceobj?
                deviceobj.getrunningstatus (result)=>
                    return callback result
            else                
                return callback new Error "Unknown Device ID"
        else
            return callback new Error "Unknown Topology ID"

    deviceStart: (topolid, deviceid, callback) ->
        obj = @getTopologyObj(topolid)
        if obj? 
            deviceobj = obj.getNodeObjbyUUID(deviceid)
            if deviceobj?
                deviceobj.start (result)=>
                    callback result
            else                
                return callback new Error "Unknown Device ID"
        else
            return callback new Error "Unknown Topology ID"


    deviceStop: (topolid, deviceid, callback) ->
        obj = @getTopologyObj(topolid)
        if obj? 
            deviceobj = obj.getNodeObjbyUUID(deviceid)
            if deviceobj?
                deviceobj.stop (result)=>
                    callback result
            else                
                return callback new Error "Unknown Device ID"
        else
            return callback new Error "Unknown Topology ID"

    deviceDelete: (topolid, deviceid, callback) ->
        obj = @getTopologyObj(topolid)
        if obj? 
            deviceobj = obj.getNodeObjbyUUID(deviceid)
            if deviceobj?
                deviceobj.del (result)=>    
                    return callback result
            else                
                return callback new Error "Unknown Device ID"
        else
            return callback new Error "Unknown Topology ID"

    #not used currenty - to be removed
    status : (data , callback) ->
        obj = @getTopologyObj(data)
        if obj?                    
            return callback obj.vmstatus() 
        else
            return callback new Error "Unknown Topology ID"

#============================================================================================================
instance = new TopologyMaster '/tmp/topology.db'
module.exports =  instance

