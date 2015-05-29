
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

util = require 'util'
authenticatorurl = "127.0.0.1:2222"

## Global IP Manager for  -- To be relooked the design
#MGMT_SUBNET = "10.0.3.0"
#WAN_SUBNET = "172.16.1.0"
#LAN_SUBNET = "10.10.10.0"

#Todo : 
#Global MGMT_SUBNET  and WAN, LAN SUBNET per topology-  currently all 3 subnets are global.
#ipmgr = new IPManager(WAN_SUBNET,LAN_SUBNET, MGMT_SUBNET)
#============================================================================================================
class TopologyRegistry extends StormRegistry
    constructor: (filename) ->
        @on 'load', (key,val) ->
            util.log "restoring #{key} with:",val
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
        #additionalProperties: true
        properties:                        
            name: {type:"string", required:true}
            projectid: {type:"string", required:true}
            passcode: {type:"string", required:true}
            switches:
                    type: "array"
                    items:
                        name: "switch"
                        type: "object"
                        required: false
                        #additionalProperties: true
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
                        #additionalProperties: true
                        properties:
                            name: {type:"string", required:true}            
                            type: {type:"string", required:false}
                            Services:
                                type: "array"
                                required: true
                                #additionalProperties: true
                                items:
                                    type: "object"
                                    required: true                                    
                                    properties:
                                        name:           {"type":"string", "required":false}                                                                                
                                        config:        
                                            type: "object"
                                            required : false                                         

            links:
                    type: "array"
                    items:
                        name: "node"
                        type: "object"
                        required: true
                        #additionalProperties: true
                        properties:                
                            type: {type:"string", required:true}
                            switch: {type:"string", required:false}
                            make: {type:"string", required:false}
                            config:        
                                type: "object"
                                required : false
                            connected_nodes:
                                type: "array"
                                required: true
                                #additionalProperties: true
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

    # Object Iterator functions... Async each is used in many place.. hence cannot be removed currently.
    # To be converted in to Hash model.
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
                #Todo:  Result value - Error Check to be done.
                util.log "create switch result " + JSON.stringify result
                callback()
        ,(err) =>
            if err
                util.log "Error occured on createswitches function " + err
                cb(false)
            else
                util.log "createswitches completed "
                cb (true)

    startSwitches :(cb)->
        async.each @switchobj, (sw,callback) =>
            util.log "start switch "
            sw.start (result) =>   
                #Todo : Result vaue to be checked.
                util.log "start switch result " + JSON.stringify result
                callback()
        ,(err) =>
            if err
                util.log "error occured " + err
                cb(false)
            else
                util.log "startswitches all are processed "
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
            util.log "createing a node "
            
            n.create (result) =>   
                util.log "create node result " + result
                #check continuosly till we get the creation status value 
                create = false
                async.until(
                    ()->
                        return create
                    (repeat)->
                        n.getstatus (result)=>
                            util.log "node creation #{n.uuid} status " + result.data.status
                            unless result.data.status is "creation-in-progress"
                                create = true
                                n.start (result)=>                    
                                    util.log "node start #{n.uuid} result " + result
                                    return
                            setTimeout(repeat, 30000);
                    (err)->                        
                        util.log "createNodes completed execution"
                        callback(err)                        
                )
        ,(err) =>
            if err
                util.log "createNodes error occured " + err
                cb(false)
            else
                util.log "createNodes all are processed "
                cb (true)


    provisionNodes :(cb)->
        async.each @nodeobj, (n,callback) =>
            util.log "provisioning a node #{n.uuid}"
            n.provision (result) =>   
                #Todo : Result to be checked.
                util.log "provision node #{n.uuid} result  " + result
                callback()
        ,(err) =>
            if err
                util.log "ProvisionNodes error occured " + err
                cb(false)
            else
                util.log "provisionNodes all are processed "
                cb (true)

    destroyNodes :()->
        #@tmparray = []
        #@destroySwithes()
        util.log "destroying the Nodes"

        async.each @nodeobj, (n,callback) =>
            util.log "delete node #{n.uuid}"
            n.del (result) =>                
                #@tmparray.push result
                #Todo: result to be checked
                callback()
        ,(err) =>
            if err
                util.log  "destroy nodes error occured " + err
                return false
            else
                util.log "destroyNodes all are processed " + @tmparray
                return true
    
    destroySwitches :()->
        #@tmparray = []
        #@destroySwithes()
        util.log "destroying the Switches"

        async.each @switchobj, (n,callback) =>
            util.log "delete switch #{n.uuid}"
            n.del (result) =>                
                #Todo result to be checked
                #@tmparray.push result
                callback()
        ,(err) =>
            if err
                util.log "Destroy switches error occured " + err
                return false
            else
                util.log "Destroy Switches all are processed " + @tmparray
                return true

    #Create Links  
    createLinks :(cb)->
        #travel each node and travel each interface 
        #get bridgename and vethname
        # call the api to add virtual interface to the switch
        async.each @nodeobj, (n,callback) =>
            util.log "create a Link"
            #travelling each interface

            for ifmap in n.config.ifmap
                if ifmap.veth?
                    obj = @getSwitchObjbyName(ifmap.brname)
                    if obj?
                        obj.connect ifmap.veth , (res) =>
                            util.log "Link connect result" + res
            #once all the ifmaps are processed, callback it.
            # TOdo : check whether async each to be used  for ifmap processing.
            callback()    

        ,(err) =>
            if err
                util.log "createLinks error occured " + err
                cb(false)
            else
                util.log "createLinks  all are processed "
                cb (true)



    #Topology REST API functions
    create :(@tdata , @projectdata)->
        util.log "Topology create - topodata: " + JSON.stringify @tdata                       
        util.log "Topology create - projectdata: " + JSON.stringify @projectdata                       

        @config = extend {}, @tdata
        @config = extend @config, @projectdata
        @uuid = @tdata.id

        util.log "topology config data " + JSON.stringify @config

        util.log "vnetbuilderip  config " + @config.vnetbuilderip
        util.log "vnetprovisoiner ip  config " + @config.vnetprovisionerip
        #util.log "vnetbuilderip  project " + @projectdata.vnetbuilderip


        ipmgr = new IPManager(@config.wansubnet,@config.lansubnet, @config.mgmtsubnet)

        if @tdata.data.switches?
            for sw in @tdata.data.switches   
                obj = new switches(sw, @config.vnetbuilderip , @config.vnetprovisionerip)
                @switchobj.push obj

        for val in @tdata.data.nodes
            obj = new node(@tdata.data.projectid, val , @config.vnetbuilderip, @config.vnetprovisionerip )
            mgmtip = ipmgr.getFreeMgmtIP() 
            obj.addMgmtInterface mgmtip , '255.255.255.0'
            @nodeobj.push obj
        sindex = 1
        for val in @tdata.data.links                        
            x = 0
            if val.type is "lan"
                temp = ipmgr.getFreeLanSubnet()                 
                for n in  val.connected_nodes
                    obj = @getNodeObjbyName(n.name)
                    if obj?
                        startaddress = temp.iparray[x++]
                        obj.addLanInterface(val.switch, startaddress, temp.subnetMask, null, val.config) if obj.config.type is "router"
                        obj.addLanInterface(val.switch, startaddress, temp.subnetMask, temp.iparray[0], val.config) if obj.config.type is "host"


            if val.type is "wan"
                temp = ipmgr.getFreeWanSubnet()
                #swname = "#{val.type}_#{val.connected_nodes[0].name}_#{val.connected_nodes[1].name}"
                swname = "#{val.type}_sw#{sindex}"
                sindex++
                util.log "  wan swname is "+ swname
                obj = new switches
                    name : swname
                    ports: 2
                    type : val.type
                    make : val.make , @config.vnetbuilderip ,@config.vnetprovisionerip
                @switchobj.push obj
                for n in  val.connected_nodes
                    obj = @getNodeObjbyName(n.name)
                    if obj?
                        startaddress = temp.iparray[x++]
                        obj.addWanInterface(swname, startaddress, temp.subnetMask, null, val.config)

        #Todo : Below functions (create) to be placed in asyn framework
        @createSwitches (res)=>
            util.log "createswitches result" + res            

        @createNodes (res)=>
            util.log "topologycreation status" + res
            #Check the sttatus and do provision
            @createLinks (res)=>
                util.log "create links result " + res

                @startSwitches (res)=>
                    util.log "start switches result "  + res
                    util.log "Ready for provision"

                    #provision
                    @provisionNodes (res)=>
                        util.log "provision" + res



    del :()->
        res = @destroyNodes() 
        res1 = @destroySwitches()
        return {
            "id" : @uuid
            "status" : "deleted"
        }


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
    #vmstatus :(callback)->
    #    arr = []
    #    util.log "inside topoloy status function"
    #    for n in @nodeobj
    #        n.nodestatus (val) =>
    #            arr.push val
    #            callback arr
    #Device specific rest api functions


#============================================================================================================


class TopologyMaster
    constructor :(filename) ->
        @registry = new TopologyRegistry filename        
        @topologyObj = {}
        


    authenticate : (data,callback) ->
        util.log "authenticate  input data is " + JSON.stringify data
        client = request.newClient("http://localhost:2222")
        client.get "/project/#{data.projectid}/passcode/#{data.passcode}", (err, res, body) =>
            util.log "err" + JSON.stringify err if err?            
            util.log "result body " + JSON.stringify body
            util.log " result " + res.statusCode if res?.statusCode?
            if res.statusCode == 200                
                return callback false , null unless body?.data?.projectid?
                if body.data.projectid is data.projectid
                    return callback true , body.data
            return callback false , null

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

            #authenicate the project id and passcode 
            @authenticate topodata.data , (result, projectdata) =>
                return callback new Error "Auth Failed" if result is false

                #one Topology per Project
                #Check whether Topology already exists for this project.  If yes, return the error.
                li = @registry.list()
                util.log "li  " + JSON.stringify li
                for i in li
                    util.log "iterating  i " + JSON.stringify i
                    if i.data.projectid is topodata.data.projectid
                        util.log "Topology exists for the projectid " + topodata.data.projectid
                        util.log "Existing Topology details " + i.data
                        return callback new Error "Topology already exists" 

                #finally create a project                    
                util.log "in topology creation"
                obj = new Topology
                obj.create topodata, projectdata                
                @topologyObj[obj.uuid] = obj
                return callback @registry.add topodata                
   
    del : (id, callback) ->
        obj = @topologyObj[id]
        if obj? 
            #remove the registry entry
            @registry.remove obj.uuid
            #remove the topology object entry from hash
            delete @topologyObj[id]
            #call the del method to remove the nodes, switches etc.
            result = obj.del()
            #Todo : delete the object (to avoid memory leak)- dont know how.
            #delete obj
            return callback result
        else
            return callback new Error "Unknown Topology ID"

    get : (id, callback) ->
        obj = @topologyObj[id]
        if obj? 
            return callback obj.get()
        else
            return callback new Error "Unknown Topology ID"

    getproject : (id, callback) ->
        tmp = [] 
        result = []
        tmp = @registry.list()        
        for i in tmp
            if i.data.projectid is id
                result.push i
        return callback result
        
    #Device specific rest API f#unctions

    deviceStats: (topolid, deviceid, callback) ->
        obj = @topologyObj[topolid]
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
        obj = @topologyObj[topolid]
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
        obj = @topologyObj[topolid]
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
        obj = @topologyObj[topolid]
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
        obj = @topologyObj[topolid]        
        if obj? 
            deviceobj = obj.getNodeObjbyUUID(deviceid)
            if deviceobj?
                deviceobj.stop (result)=>
                    callback result
            else                
                return callback new Error "Unknown Device ID"
        else
            return callback new Error "Unknown Topology ID"

    deviceTrace: (topolid, deviceid, callback) ->
        obj = @topologyObj[topolid]        
        if obj? 
            deviceobj = obj.getNodeObjbyUUID(deviceid)
            if deviceobj?
                deviceobj.trace (result)=>
                    callback result
            else                
                return callback new Error "Unknown Device ID"
        else
            return callback new Error "Unknown Topology ID"

    deviceDelete: (topolid, deviceid, callback) ->
        obj = @topologyObj[topolid]
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
    #status : (data , callback) ->
    #    obj = @get@topologyObj(data)
    #    if obj?                    
    #        return callback obj.vmstatus() 
    #    else
    #        return callback new Error "Unknown Topology ID"

#============================================================================================================
module.exports =  new TopologyMaster '/tmp/topology.db'



#Limitations ---  To be addressed later
#1. vm name is used as given in the REST API.  Hence there is a  possibility that node (VM may exists in the same name)
#  No check in the code,  User should take care of the vmname name .
#There is a limitation in the lxcname and vm name ---  Name should not exceed 5 chars
#2. Application LOST the topology details upon restarts, it lost the existing topology object .
#  Application doesnt  and poll the status of the existing topology and get the object.
#4.   some code cleanup - wherever mentioned in the code.
#5.   config file to read the port number for ventbuilder, ventprovisioner, venetcontroller and default port.. ?
#6. secure communication to vnetbuilder and provisioner


