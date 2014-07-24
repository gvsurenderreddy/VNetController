{@app} = require('zappajs') 8888, ->
    @configure =>
      @use 'bodyParser', 'methodOverride', @app.router, 'static'
      @set 'basepath': '/v1.0'

    @configure
      development: => @use errorHandler: {dumpExceptions: on, showStack: on}
      production: => @use 'errorHandler'

    @enable 'serve jquery', 'minify'

    topology = require('./Topology')        

    @post '/Topology': ->       
        console.log "POST Topology received" + JSON.stringify @body        
        topology.create @body, (res) =>
            console.log res
            @send res    

    @get '/Topology': ->
        console.log "GET Topology  received" + JSON.stringify @body        
        topology.list (res) =>
            console.log res
            @send res    

    @get '/Topology/:id/status': -> 
        console.log "GET Topology/id  received"
        topology.get @params.id, (res) =>
            console.log res
            @send res    
            
    @delete '/Topology/:id': ->       
        console.log "POST Topology destroy received" 
        topology.del @params.id, (res) =>
            console.log res
            @send res    

    # Device specific control operations
    @get '/Topology/:id/device/:did': -> 
        console.log "GET Topology #{@params.id}  device id#{@params.did}  received"
        topology.deviceStatus @params.id, @params.did, (res) =>
            console.log res
            @send res    

    @put '/Topology/:id/device/:did/start': -> 
        console.log "GET Topology #{@params.id}  device id#{@params.did}  received"
        topology.deviceStart @params.id, @params.did, (res) =>
            console.log res
            @send res    

    @put '/Topology/:id/device/:did/stop': -> 
        console.log "GET Topology #{@params.id}  device id#{@params.did}  received"
        topology.deviceStop @params.id, @params.did, (res) =>
            console.log res
            @send res    

    @delete '/Topology/:id/device/:did': -> 
        console.log "DEL Topology/id  received"
        topology.deviceDelete @params.id, @params.did, (res) =>
            console.log res
            @send res    


