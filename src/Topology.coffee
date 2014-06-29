StormRegistry = require 'stormregistry'
StormData = require 'stormdata'

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
            switches:
                    type: "array"
                    items:
                        name: "switch"
                        type: "object"
                        required: true
                        additionalProperties: true
                        properties:
                            name: {type:"string", required:true}            
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
                            wan:
                                type: "array"
                                required: true
                                additionalProperties: true
                                items:
                                    name : "wan"
                                    type: "object"
                                    required: true                                    
                                    properties:                                       
                                        index : {type:"integer", required:true}
                                        linktype : {type: "string", required: true}
                                        protocol : {type: "string", required: true}
                                        connect_to: {type: "string", required: true}
                            lan:
                                type: "array"
                                required: true
                                additionalProperties: true
                                items:
                                    name : "lan"
                                    type: "object"
                                    required: true                                    
                                    properties:                                       
                                        index : {type:"integer", required:true}
                                        linktype : {type: "string", required: true}
                                        protocol : {type: "string", required: true}
                                        connect_to: {type: "string", required: true}
    constructor: (id, data) ->
        super id, data, TopologySchema

util = require('util')
request = require('request-json');

#-----------------------------------------------------------------------------------------------#
#    Switch Classes
#-----------------------------------------------------------------------------------------------#

class SwitchData extends StormData

class SwitchIf extends StormRegistry




#-----------------------------------------------------------------------------------------------#
#    Switch Classes
#-----------------------------------------------------------------------------------------------#

class NodeIf extends StormData

class NodeIf extends StormRegistry



##################################################################################################
class IPManager















class Topology
    constructor :(filename) ->
        @registry = new TopologyRegistry filename

    createSwitches: (topo)->
        client = request.newClient('http://localhost:5680/')
        util.log "createSwitches "+ JSON.stringify topo.switches
        for sw in topo.switches   
            util.log "sw :"+ JSON.stringify sw
            ip = {}
            ip.type = "bridge"
            ip.projectid = "test122"            
            client.post '/createswitch', ip, (err, res, body) =>
                util.log "err" + JSON.stringify err if err?
                util.log "res " + JSON.stringify res
                util.log "body" + JSON.stringify body  

    createVMs : (topo) ->
        client = request.newClient('http://localhost:5680/')
        util.log "createSwitches "+ JSON.stringify topo.nodes
        for node in topo.nodes
            util.log "node :"+ JSON.stringify node
            ip = {}
            ip.type = "bridge"
            ip.projectid = "test122"            
            client.post '/createswitch', ip, (err, res, body) =>
                util.log "err" + JSON.stringify err if err?
                util.log "res " + JSON.stringify res
                util.log "body" + JSON.stringify body  


    create : (@data, callback)->
        try			
            topodata = new TopologyData null, @data
        catch err
            util.log "invalid schema" + err
            return callback new Error "Invalid Input "
        finally				
            util.log JSON.stringify topodata
            #data inter validity check
            @registry.add topodata

                        
#            @createSwitches topodata.data
            callback topodata.data

	list: (callback) ->
		return callback @registry.list()

              


module.exports = Topology