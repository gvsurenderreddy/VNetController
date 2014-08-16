{@app} = require('zappajs') 8888, ->
    @configure =>
      @use 'bodyParser', 'methodOverride', @app.router, 'static'
      @set 'basepath': '/v1.0'

    @configure
      development: => @use errorHandler: {dumpExceptions: on, showStack: on}
      production: => @use 'errorHandler'

    @enable 'serve jquery', 'minify'

    topology = require('./Topology')        
    util = require('util')

    @post '/Topology': ->       
        util.log "POST Topology received" + JSON.stringify @body        
        topology.create @body, (res) =>
            util.log "POST Topology result " + res
            @send res    

    @get '/Project/:id': ->
        util.log "GET Project  received" + JSON.stringify @params.id        
        topology.getproject @params.id,  (res) =>
            util.log "GET Project result " + res
            @send res    



    @get '/Topology': ->
        util.log "GET Topology  received" + JSON.stringify @body        
        topology.list (res) =>
            util.log "GET Topology result " + res
            @send res    

    @get '/Topology/:id/status': -> 
        util.log "GET Topology/id #{@params.id}received - topology id "
        topology.get @params.id, (res) =>
            util.log "GET Topology/id result " + res
            @send res    
            
    @delete '/Topology/:id': ->       
        util.log "DELETE Topology  #{@params.id} received" 
        topology.del @params.id, (res) =>
            util.log "DELETE Topology  #{@params.id} result  " + res
            @send res    

    # Device specific control operations
    @get '/Topology/:id/device/:did': -> 
        util.log "GET Topology #{@params.id}  device id#{@params.did}  received"
        topology.deviceGet @params.id, @params.did, (res) =>
            util.log "GET Topology #{@params.id}  device id#{@params.did} - result " + res
            @send res  

    @get '/Topology/:id/device/:did/status': -> 
        util.log "GET Topology #{@params.id}  device id#{@params.did}  status received"
        topology.deviceStatus @params.id, @params.did, (res) =>
            util.log "GET Topology #{@params.id}  device id#{@params.did} status result - " + res
            @send res  

    @get '/Topology/:id/device/:did/stats': -> 
        util.log "GET Topology #{@params.id}  device id#{@params.did}  stats received"
        topology.deviceStats @params.id, @params.did, (res) =>
            util.log "GET Topology #{@params.id}  device id#{@params.did} stats result" + res
            @send res  

    @put '/Topology/:id/device/:did/start': -> 
        util.log "PUT Topology #{@params.id}  device id#{@params.did} start received"
        topology.deviceStart @params.id, @params.did, (res) =>
            util.log "PUT Topology #{@params.id}  device id#{@params.did} start - result" + res
            @send res    

    @put '/Topology/:id/device/:did/stop': -> 
        util.log "PUT Topology #{@params.id}  device id#{@params.did}  stop received"
        topology.deviceStop @params.id, @params.did, (res) =>
            util.log "PUT Topology #{@params.id}  device id#{@params.did} stop result - " + res
            @send res    

    @put '/Topology/:id/device/:did/trace': -> 
        util.log "PUT Topology #{@params.id}  device id#{@params.did}  trace received"
        topology.deviceTrace @params.id, @params.did, (res) =>
            util.log "PUT Topology #{@params.id}  device id#{@params.did} Trace result - " + res
            @send res    

    @delete '/Topology/:id/device/:did': -> 
        util.log "DELETE Topology #{@params.id}  device id#{@params.did}  delete received"
        topology.deviceDelete @params.id, @params.did, (res) =>
            util.log " DELETE Topology #{@params.id}  device id#{@params.did}  - result " + res
            @send res    


