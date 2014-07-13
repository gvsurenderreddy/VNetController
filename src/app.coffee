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

    @delete '/Topology/:id': ->       
        console.log "POST Topology destroy received" 
        topology.del @params.id, (res) =>
            console.log res
            @send res    
    @get '/Topology/:id/status': ->       
        topology.status @params.id, (res) =>
            console.log res
            @send res    


###
    @post '/Project': ->       
        console.log "POST Project received" + JSON.stringify @body        
        project.create @body, (res) =>
            console.log res
            @send res    
    @get '/Project' : ->
        console.log "GET Project received" + JSON.stringify @body        
        project.list (res) =>
            console.log res
            @send res    
    @put '/node': ->
        switchctrl.listSwitches (res) =>
            console.log res
            @send res  

    @delete '/node': ->   
        console.log "createVM received" + JSON.stringify @body        
        vmctrl.createVM @body, (res) =>
            console.log res
            @send res

    @post '/startVM': ->   
        console.log "startVM received" + JSON.stringify @body        
        vmctrl.startVM @body, (res) =>
            console.log res
            @send res    

    @post '/stopVM': ->   
        console.log "stopVM received" + JSON.stringify @body        
        vmctrl.stopVM @body, (res) =>
            console.log res
            @send res    

    @get '/listVMs': ->   
        console.log "listVMs received" + JSON.stringify @body        
        vmctrl.listVMs @body, (res) =>
            console.log res
            @send res    

    @post '/deleteVMs': ->   
        console.log "deleteVMs received" + JSON.stringify @body        
        vmctrl.deleteVMs @body, (res) =>
            console.log res
            @send res    

    @post '/deleteVM': ->   
        console.log "deleteVM received" + JSON.stringify @body        
        vmctrl.deleteVM @body, (res) =>
            console.log res
            @send res    
###