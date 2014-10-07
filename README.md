VNetController
==============

Virtual Network Controller 


WebAPI:
--

###1. post '/Topology' 

Description:
creates a new Topology
This API immediately returs with resource id. The resource creation will be in progress.
Resource status can be checked with /Topology/:id/status API.


Request Data:
```
{ 
  "name":"testtopology", 
  "projectid":"A1",
  "passcode":"aaaa",
  "switches":[
    {
      "name":"lansw1",
      "ports":8,
      "type":"lan",
      "make":"bridge"
    }
  ],  
  "nodes":[
    {
      "name":"v1",
      "type":"router",
      "Services":[
        {
          "name":"quagga",        
          "config":{}
        },
        {
          "name":"openvpn",          
          "config":{}
        },
        {
          "name":"snort",          
          "config":{}
        },
        {
          "name":"strongswan",          
          "config":{}
        },
        {
          "name":"iptables",          
          "config":{}
        },
        {
          "name":"iproute2",          
          "config":{}
        }
      ]      
    },
    {
      "name":"v2",
      "type":"router",
      "Services":[
        {
          "name":"quagga",
          "config":{}
          
        }
      ]      
    },
    {
      "name":"v3",
      "type":"router",
      "Services":[
        {
          "name":"quagga",
          "config":{}
        }
      ]      
    },
    {
      "name":"server1",
      "type":"host",
      "Services":[
        {
          "name":"apache",
          "config":{}
        }
      ]      
    }    
  ],
  "links":[
    {
      "type":"wan",
      "connected_nodes":[{"name":"v1"},{"name":"v2"}],
      "switch":"",
      "make":"bridge",
      "config":{
        "bandwidth":"1mbps",        
        "delay":10,
        "jitter":1,
        "pktloss":"0%"
      }
    },
    {
      "type":"wan",
      "connected_nodes":[{"name":"v2"},{"name":"v3"}],
      "switch":"",
      "make":"bridge",
      "config":{
        "bandwidth":"512kbps",        
        "delay":10,
        "jitter":1,
        "pktloss":"10%"
      }

    },
    {
      "type":"lan",
      "connected_nodes":[{"name":"v1"},{"name":"server1"}],
      "switch":"lansw1",
      "make":"bridge",
      "config":{        
      }
    }    
    ]  
}
```

Response Data:
```
To be updated

```

### 2. get '/Topology/:id/status'

http://localhost:8888/topology/722363cd-1984-4506-b9f0-f0aafe4157a3/status

Description:  Get the status of the topology (status of node, ip details, vm status)

Response data:
```
{
    "nodes": [
        {
            "id": "9cb1bc7a-8a8f-4976-906d-e7a296a30ff3",
            "config": {
                "Services": [
                    {
                        "name": "quagga",
                        "enabled": true
                    }
                ],
                "type": "router",
                "name": "vm1",
                "memory": "128m",
                "vcpus": "2",
                "ifmap": [
                    {
                        "ifname": "eth0",
                        "hwAddress": "00:16:3e:5a:55:11",
                        "ipaddress": "10.0.3.2",
                        "netmask": "255.255.255.0",
                        "type": "mgmt"
                    },
                    {
                        "ifname": "eth1",
                        "hwAddress": "00:16:3e:5a:55:15",
                        "brname": "wan_vm1_vm2",
                        "ipaddress": "172.16.1.1",
                        "netmask": "255.255.255.252",
                        "type": "wan"
                    },
                    {
                        "ifname": "eth2",
                        "hwAddress": "00:16:3e:5a:55:19",
                        "brname": "lansw1",
                        "ipaddress": "10.10.10.1",
                        "netmask": "255.255.255.224",
                        "type": "lan"
                    }
                ],
                "id": "9cb1bc7a-8a8f-4976-906d-e7a296a30ff3"
            },
            "status": {
                "result": "started"
            },
            "statistics": {}
        },
        {
            "id": "0b957ac0-5c0f-48cb-8331-520782673725",
            "config": {
                "Services": [
                    {
                        "name": "quagga",
                        "enabled": true
                    }
                ],
                "type": "router",
                "name": "vm2",
                "memory": "128m",
                "vcpus": "2",
                "ifmap": [
                    {
                        "ifname": "eth0",
                        "hwAddress": "00:16:3e:5a:55:12",
                        "ipaddress": "10.0.3.3",
                        "netmask": "255.255.255.0",
                        "type": "mgmt"
                    },
                    {
                        "ifname": "eth1",
                        "hwAddress": "00:16:3e:5a:55:16",
                        "brname": "wan_vm1_vm2",
                        "ipaddress": "172.16.1.2",
                        "netmask": "255.255.255.252",
                        "type": "wan"
                    },
                    {
                        "ifname": "eth2",
                        "hwAddress": "00:16:3e:5a:55:17",
                        "brname": "wan_vm2_vm3",
                        "ipaddress": "172.16.1.5",
                        "netmask": "255.255.255.252",
                        "type": "wan"
                    }
                ],
                "id": "0b957ac0-5c0f-48cb-8331-520782673725"
            },
            "status": {
                "result": "started"
            },
            "statistics": {}
        },
        {
            "id": "b2afaaa9-0e74-475f-8cb9-0a2fdb1e185a",
            "config": {
                "Services": [
                    {
                        "name": "quagga",
                        "enabled": true
                    }
                ],
                "type": "router",
                "name": "vm3",
                "memory": "128m",
                "vcpus": "2",
                "ifmap": [
                    {
                        "ifname": "eth0",
                        "hwAddress": "00:16:3e:5a:55:13",
                        "ipaddress": "10.0.3.4",
                        "netmask": "255.255.255.0",
                        "type": "mgmt"
                    },
                    {
                        "ifname": "eth1",
                        "hwAddress": "00:16:3e:5a:55:18",
                        "brname": "wan_vm2_vm3",
                        "ipaddress": "172.16.1.6",
                        "netmask": "255.255.255.252",
                        "type": "wan"
                    }
                ],
                "id": "b2afaaa9-0e74-475f-8cb9-0a2fdb1e185a"
            },
            "status": {
                "result": "started"
            },
            "statistics": {}
        },
        {
            "id": "4ef72ed9-ba32-486f-b23f-f8ec6c22cf3f",
            "config": {
                "Services": [
                    {
                        "name": "webserver",
                        "enabled": true
                    }
                ],
                "type": "host",
                "name": "server1",
                "memory": "128m",
                "vcpus": "2",
                "ifmap": [
                    {
                        "ifname": "eth0",
                        "hwAddress": "00:16:3e:5a:55:14",
                        "ipaddress": "10.0.3.5",
                        "netmask": "255.255.255.0",
                        "type": "mgmt"
                    },
                    {
                        "ifname": "eth1",
                        "hwAddress": "00:16:3e:5a:55:20",
                        "brname": "lansw1",
                        "ipaddress": "10.10.10.2",
                        "netmask": "255.255.255.224",
                        "type": "lan"
                    }
                ],
                "id": "4ef72ed9-ba32-486f-b23f-f8ec6c22cf3f"
            },
            "status": {
                "result": "started"
            },
            "statistics": {}
        }
    ],
    "switches": [
        {
            "uuid": "af9f52a5-5a97-45df-b935-a1a8106137c5",
            "config": {
                "type": "bridge",
                "ports": 8,
                "name": "lansw1"
            },
            "status": {
                "result": "running",
                "reason": "failed to create"
            },
            "statistics": {}
        },
        {
            "uuid": "0cf39199-db4b-4c1e-9bff-e2408166b596",
            "config": {
                "type": "bridge",
                "ports": 2,
                "name": "wan_vm1_vm2"
            },
            "status": {
                "result": "failed",
                "reason": "failed to create"
            },
            "statistics": {}
        },
        {
            "uuid": "5f2cb07c-c295-44f1-94b1-1d8165b3fb77",
            "config": {
                "type": "bridge",
                "ports": 2,
                "name": "wan_vm2_vm3"
            },
            "status": {
                "result": "failed",
                "reason": "failed to create"
            },
            "statistics": {}
        }
    ]
}
```

### 3. delete '/Topology/:id'

http://localhost:8888/topology/722363cd-1984-4506-b9f0-f0aafe4157a3/

Description:

Delete the Topology. removes the VMs,switches associated with  topology

Response:
```
true

```
### 4. get '/Topology'

http://localhost:8888/topology/

Description:
List of Topologies. (Just a DB output)


Response Data:
```
To be updated 
```

## Device control APIs

###5. get '/Topology/:id/device/:id/'

http://localhost:8888/topology/657b7a07-6c55-4d40-894d-b878db5c7ee6/device/9cb1bc7a-8a8f-4976-906d-e7a296a30ff3/

Description:
Get the  of the device config, status, statistics 
Note:  The statistics is the last collected. use statistics api to collect statistics

```
{
    "id": "9cb1bc7a-8a8f-4976-906d-e7a296a30ff3",
    "config": {
        "Services": [
            {
                "name": "quagga",
                "enabled": true
            }
        ],
        "type": "router",
        "name": "vm1",
        "memory": "128m",
        "vcpus": "2",
        "ifmap": [
            {
                "ifname": "eth0",
                "hwAddress": "00:16:3e:5a:55:11",
                "ipaddress": "10.0.3.2",
                "netmask": "255.255.255.0",
                "type": "mgmt"
            },
            {
                "ifname": "eth1",
                "hwAddress": "00:16:3e:5a:55:15",
                "brname": "wan_vm1_vm2",
                "ipaddress": "172.16.1.1",
                "netmask": "255.255.255.252",
                "type": "wan"
            },
            {
                "ifname": "eth2",
                "hwAddress": "00:16:3e:5a:55:19",
                "brname": "lansw1",
                "ipaddress": "10.10.10.1",
                "netmask": "255.255.255.224",
                "type": "lan"
            }
        ],
        "id": "9cb1bc7a-8a8f-4976-906d-e7a296a30ff3"
    },
    "status": {
        "result": "started"
    },
    "statistics": {}
}
```



### 6. get '/Topology/:id/device/:id/status'

http://localhost:8888/topology/657b7a07-6c55-4d40-894d-b878db5c7ee6/device/6da92a34-e259-4c45-994b-5a5a086c5303/status

Description:
get the running status

```
{
    "id": "6da92a34-e259-4c45-994b-5a5a086c5303",
    "status": "running"
}
```

### 7. get '/Topology/:id/device/:id/stats'

http://localhost:8888/topology/657b7a07-6c55-4d40-894d-b878db5c7ee6/device/9cb1bc7a-8a8f-4976-906d-e7a296a30ff3/stats

Description:
get the interface , route statistics

```
{
    "linkstats": [
        {
            "interface": "lo:",
            "status": "<LOOPBACK,UP,LOWER_UP>",
            "mtu": "65536",
            "qdisc": "noqueue",
            "state": "UNKNOWN",
            "mode": "DEFAULT",
            "group": "default",
            "link": "link/loopback",
            "brd": "brd",
            "rxbytes": "3552",
            "rxpackets": "48",
            "rxerror": "0",
            "rxdropped": "0",
            "rxoverrun": "0",
            "rxmcast": "0",
            "txbytes": "3552",
            "txpackets": "48",
            "txerrors": "0",
            "txdropped": "0",
            "txcarrier": "0",
            "txcollisions": "0"
        },
        {
            "interface": "eth0:",
            "status": "<BROADCAST,MULTICAST,UP,LOWER_UP>",
            "mtu": "1500",
            "qdisc": "pfifo_fast",
            "state": "UP",
            "mode": "DEFAULT",
            "group": "default",
            "link": "link/ether",
            "brd": "brd",
            "rxbytes": "4908",
            "rxpackets": "28",
            "rxerror": "0",
            "rxdropped": "0",
            "rxoverrun": "0",
            "rxmcast": "0",
            "txbytes": "758",
            "txpackets": "9",
            "txerrors": "0",
            "txdropped": "0",
            "txcarrier": "0",
            "txcollisions": "0"
        },
        {
            "interface": "eth1:",
            "status": "<BROADCAST,MULTICAST,UP,LOWER_UP>",
            "mtu": "1500",
            "qdisc": "pfifo_fast",
            "state": "UP",
            "mode": "DEFAULT",
            "group": "default",
            "link": "link/ether",
            "brd": "brd",
            "rxbytes": "5875",
            "rxpackets": "41",
            "rxerror": "0",
            "rxdropped": "0",
            "rxoverrun": "0",
            "rxmcast": "0",
            "txbytes": "498",
            "txpackets": "5",
            "txerrors": "0",
            "txdropped": "0",
            "txcarrier": "0",
            "txcollisions": "0"
        }
    ],
    "routestats": [
        {
            "destination": "10.0.3.0/24",
            "dev": "eth0",
            "proto": "kernel",
            "scope": "link",
            "src": "10.0.3.2"
        },
        {
            "destination": "172.16.1.0/30",
            "dev": "eth1",
            "proto": "kernel",
            "scope": "link",
            "src": "172.16.1.1"
        },
        {
            "destination": ""
        }
    ]
}
```


### 7. put '/Topology/:id/device/:id/start'

http://localhost:8888/topology/657b7a07-6c55-4d40-894d-b878db5c7ee6/device/9cb1bc7a-8a8f-4976-906d-e7a296a30ff3/start

Description :  Start the device
```
{
    "result": "started"
}
```
### 8. put '/Topology/:id/node/:id/stop'

http://localhost:8888/topology/657b7a07-6c55-4d40-894d-b878db5c7ee6/device/9cb1bc7a-8a8f-4976-906d-e7a296a30ff3/stop

Description :  Stop the device
```
{
    "result": "stopped"
}
```

### 9. delete '/Topology/:id/device/:id'

http://localhost:8888/topology/657b7a07-6c55-4d40-894d-b878db5c7ee6/device/9cb1bc7a-8a8f-4976-906d-e7a296a30ff3/

Description :  delete the device
```
{
    "id":"9cb1bc7a-8a8f-4976-906d-e7a296a30ff3",
    "status":"deleted"
}
```


#### Future implementation
8. put '/Topology/:id/node/:id/service/:id/'

9. put '/Topology/:id/node/:id/service/:id/stop'

10. put '/Topology/:id/node/:id/service/:id/start'




==============================

Lincense:
MIT
