StormRegistry = require 'stormregistry'
StormData = require 'stormdata'

class ProjectRegistry extends StormRegistry
    constructor: (filename) ->
        @on 'load', (key,val) ->
            console.log "restoring #{key} with:",val
            entry = new ProjectData key,val
            if entry?
                entry.saved = true
                @add entry

        @on 'removed', (entry) ->
            entry.destructor() if entry.destructor?

        super filename

    add: (data) ->
        return unless data instanceof ProjectData
        entry = super data.id, data

    update: (data) ->        
        super data.id, data    

    get: (key) ->
        entry = super key
        return unless entry?

        if entry.data? and entry.data instanceof ProjectData
            entry.data.id = entry.id
            entry.data
        else
            entry

class ProjectData extends StormData

    ProjectSchema =
        name: "Project"
        type: "object"
        additionalProperties: true
        properties:            
            name:   { type: "string", required: true}
            email:   { type: "string", required: true}
            virtualization: { type: "string", required: true}
            ipassignment:{ type: "string", required: true}
            wanip_pool:{ type: "string", required: false}
            lanip_pool:{ type: "string", required: false}
            loip_pool:{ type: "string", required: false}            

    constructor: (id, data) ->
        super id, data, ProjectSchema

util = require('util')
class Project
	constructor :(filename) ->
		@registry = new ProjectRegistry filename

	create : (@data, callback)->
		try			
			Accdata = new ProjectData null, @data
		catch err
			util.log "invalid schema" + err
			return callback new Error "Invalid Input "
		finally				
			util.log JSON.stringify Accdata			
			@registry.add Accdata
			return callback Accdata

	list: (callback) ->
		return callback @registry.list()
    get: (id, callback) ->
        return callback @registry.get(id)


instance = new Project '/tmp/projects.db'
module.exports = instance
