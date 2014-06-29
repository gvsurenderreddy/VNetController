StormRegistry = require 'stormregistry'
StormData = require 'stormdata'

class AccountRegistry extends StormRegistry
    constructor: (filename) ->
        @on 'load', (key,val) ->
            console.log "restoring #{key} with:",val
            entry = new AccountData key,val
            if entry?
                entry.saved = true
                @add entry

        @on 'removed', (entry) ->
            entry.destructor() if entry.destructor?

        super filename

    add: (data) ->
        return unless data instanceof AccountData
        entry = super data.id, data

    update: (data) ->        
        super data.id, data    

    get: (key) ->
        entry = super key
        return unless entry?

        if entry.data? and entry.data instanceof AccountData
            entry.data.id = entry.id
            entry.data
        else
            entry

class AccountData extends StormData

    AccountSchema =
        name: "Account"
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
        super id, data, AccountSchema

util = require('util')
class Account
	constructor :(filename) ->
		@registry = new AccountRegistry filename

	create : (@data, callback)->
		try			
			Accdata = new AccountData @data.name, @data
		catch err
			util.log "invalid schema" + err
			return callback new Error "Invalid Input "
		finally				
			util.log JSON.stringify Accdata			
			@registry.add Accdata
			return callback Accdata.data

	list: (callback) ->
		return callback @registry.list()

    get: (id,callback) ->
        return callback @registry.get(id)
		
module.exports = Account