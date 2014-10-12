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
        topodata = JSON.parse(JSON.stringify(@body))
        topology.create topodata, (res) =>
            util.log "POST Topology result " + res
            @response.setHeader "Access-Control-Allow-Origin", "*"
            @send res    

    @get '/Project/:id': ->
        util.log "GET Project  received" + JSON.stringify @params.id        
        topology.getproject @params.id,  (res) =>
            util.log "GET Project result " + res
            @response.setHeader "Access-Control-Allow-Origin", "*"
            @send res    



    @get '/Topology': ->
        util.log "GET Topology  received" + JSON.stringify @body        
        topology.list (res) =>
            util.log "GET Topology result " + res
            @response.setHeader "Access-Control-Allow-Origin", "*"
            @send res    

    @get '/Topology/:id/status': -> 
        util.log "GET Topology/id #{@params.id}received - topology id "
        topology.get @params.id, (res) =>
            util.log "GET Topology/id result " + res
            @response.setHeader "Access-Control-Allow-Origin", "*"
            @send res    
            
    @delete '/Topology/:id': ->       
        util.log "DELETE Topology  #{@params.id} received" 
        topology.del @params.id, (res) =>
            util.log "DELETE Topology  #{@params.id} result  " + res
            @response.setHeader "Access-Control-Allow-Origin", "*"
            @send res    

    # Device specific control operations
    @get '/Topology/:id/device/:did': -> 
        util.log "GET Topology #{@params.id}  device id#{@params.did}  received"
        topology.deviceGet @params.id, @params.did, (res) =>
            util.log "GET Topology #{@params.id}  device id#{@params.did} - result " + res
            @response.setHeader "Access-Control-Allow-Origin", "*"
            @send res  

    @get '/Topology/:id/device/:did/status': -> 
        util.log "GET Topology #{@params.id}  device id#{@params.did}  status received"
        topology.deviceStatus @params.id, @params.did, (res) =>
            util.log "GET Topology #{@params.id}  device id#{@params.did} status result - " + res
            @response.setHeader "Access-Control-Allow-Origin", "*"
            @send res  

    @get '/Topology/:id/device/:did/stats': -> 
        util.log "GET Topology #{@params.id}  device id#{@params.did}  stats received"
        topology.deviceStats @params.id, @params.did, (res) =>
            util.log "GET Topology #{@params.id}  device id#{@params.did} stats result" + res
            @response.setHeader "Access-Control-Allow-Origin", "*"
            @send res  

    @put '/Topology/:id/device/:did/start': -> 
        util.log "PUT Topology #{@params.id}  device id#{@params.did} start received"
        topology.deviceStart @params.id, @params.did, (res) =>
            util.log "PUT Topology #{@params.id}  device id#{@params.did} start - result" + res
            @response.setHeader "Access-Control-Allow-Origin", "*"
            @send res    

    @put '/Topology/:id/device/:did/stop': -> 
        util.log "PUT Topology #{@params.id}  device id#{@params.did}  stop received"
        topology.deviceStop @params.id, @params.did, (res) =>
            util.log "PUT Topology #{@params.id}  device id#{@params.did} stop result - " + res
            @response.setHeader "Access-Control-Allow-Origin", "*"
            @send res    

    @put '/Topology/:id/device/:did/trace': -> 
        util.log "PUT Topology #{@params.id}  device id#{@params.did}  trace received"
        topology.deviceTrace @params.id, @params.did, (res) =>
            util.log "PUT Topology #{@params.id}  device id#{@params.did} Trace result - " + res
            @response.setHeader "Access-Control-Allow-Origin", "*"
            @send res    

    @delete '/Topology/:id/device/:did': -> 
        util.log "DELETE Topology #{@params.id}  device id#{@params.did}  delete received"
        topology.deviceDelete @params.id, @params.did, (res) =>
            util.log " DELETE Topology #{@params.id}  device id#{@params.did}  - result " + res
            @response.setHeader "Access-Control-Allow-Origin", "*"
            @send res    

    #Service specific functions 
    #To be implemented
    

    @post '/Topology/:id/device/:did/service' 
    @get '/Topology/:id/device/:did/service' 
    @get '/Topology/:id/device/:did/service/:id' 
    @put '/Topology/:id/device/:did/service/:id' 
    @put '/Topology/:id/device/:did/service/:id/start'
    @put '/Topology/:id/device/:did/service/:id/stop'


    ###   
    @post '/Topology/:id/device/:did/quagga' 
    @get '/Topology/:id/device/:did/quagga' 
    @get '/Topology/:id/device/:did/quagga/:id' 
    @put '/Topology/:id/device/:did/quagga/:id' 
    @put '/Topology/:id/device/:did/quagga/:id/start'
    @put '/Topology/:id/device/:did/quagga/:id/stop'

    @post '/Topology/:id/device/:did/snort'
    @get '/Topology/:id/device/:did/snort/:id'
    @put '/Topology/:id/device/:did/snort/:id'
    @put '/Topology/:id/device/:did/snort/:id/start'
    @put '/Topology/:id/device/:did/snort/:id/stop'

    @post '/Topology/:id/device/:did/iptables/'
    @get '/Topology/:id/device/:did/iptables/:id'    
    @put '/Topology/:id/device/:did/iptables/:id'
    @put '/Topology/:id/device/:did/iptables/:id/start'
    @put '/Topology/:id/device/:did/iptables/:id/stop'


    @post '/Topology/:id/device/:did/openvpn/'
    @get '/Topology/:id/device/:did/openvpn/:id'    
    @put '/Topology/:id/device/:did/openvpn/:id'
    @put '/Topology/:id/device/:did/openvpn/:id/start'
    @put '/Topology/:id/device/:did/openvpn/:id/stop'

    @post '/Topology/:id/device/:did/strongswan/'
    @get '/Topology/:id/device/:did/strongswan/:id'    
    @put '/Topology/:id/device/:did/strongswan/:id'
    @put '/Topology/:id/device/:did/strongswan/:id/start'
    @put '/Topology/:id/device/:did/strongswan/:id/stop'
    
    ###