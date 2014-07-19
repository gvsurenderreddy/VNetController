VNetController
==============

Virtual Network Controller 


WebAPI:

1. post '/Topology'

Description:
creates a new Topology
This API immediately returs with resource id. The resource creation will be in progress.
Resource status can be checked with /Topology/:id/status API.


Request Data:

{
  "projectid":"1",
  "name":"testtopology",
  "virtualization":"lxc",
  "ipassignment":"manual",
  "wanip_pool":"172.27.0.0/24",
  "lanip_pool":"10.0.0.0/24",
  "loip_pool":"1.1.1.0/2",  
  "switches":[
    {
      "name":"lansw1",
      "ports":8,
      "type":"bridge"     
    }
  ],  
  "nodes":[
    {
      "name":"vm1",
      "type":"router",
      "Services":[
        {
          "name":"quagga",
          "enabled":true
        }
      ],
      "no_of_wan_interfaces":2,
      "no_of_lan_interfaces":1,
      "no_of_lo_interfaces":1      
    },
    {
      "name":"vm2",
      "type":"router",
      "Services":[
        {
          "name":"quagga",
          "enabled":true
        }
      ],
      "no_of_wan_interfaces":2,
      "no_of_lan_interfaces":1,
      "no_of_lo_interfaces":1      
    },
    {
      "name":"vm3",
      "type":"router",
      "Services":[
        {
          "name":"quagga",
          "enabled":true
        }
      ],
      "no_of_wan_interfaces":2,
      "no_of_lan_interfaces":1,
      "no_of_lo_interfaces":1      
    },
    {
      "name":"server1",
      "type":"host",
      "Services":[
        {
          "name":"webserver",
          "enabled":true
        }
      ],
      "no_of_wan_interfaces":2,
      "no_of_lan_interfaces":1,
      "no_of_lo_interfaces":1      
    }
    
  ],
  "links":[
    {
      "type":"wan",
      "connected_nodes":[{"name":"vm1"},{"name":"vm2"}],
      "switch":""
    },
    {
      "type":"wan",
      "connected_nodes":[{"name":"vm2"},{"name":"vm3"}],
      "switch":""
    },
    {
      "type":"lan",
      "connected_nodes":[{"name":"vm1"},{"name":"server1"}],
      "switch":"lansw1"
    }    
    ]
  
}


Response Data:
{
    "id": "722363cd-1984-4506-b9f0-f0aafe4157a3",
    "data": {
        "projectid": "1",
        "name": "testtopology",
        "virtualization": "lxc",
        "ipassignment": "manual",
        "wanip_pool": "172.27.0.0/24",
        "lanip_pool": "10.0.0.0/24",
        "loip_pool": "1.1.1.0/2",
        "switches": [
            {
                "name": "lansw1",
                "ports": 8,
                "type": "bridge"
            }
        ],
        "nodes": [
            {
                "name": "vm1",
                "type": "router",
                "Services": [
                    {
                        "name": "quagga",
                        "enabled": true
                    }
                ],
                "no_of_wan_interfaces": 2,
                "no_of_lan_interfaces": 1,
                "no_of_lo_interfaces": 1
            },
            {
                "name": "vm2",
                "type": "router",
                "Services": [
                    {
                        "name": "quagga",
                        "enabled": true
                    }
                ],
                "no_of_wan_interfaces": 2,
                "no_of_lan_interfaces": 1,
                "no_of_lo_interfaces": 1
            },
            {
                "name": "vm3",
                "type": "router",
                "Services": [
                    {
                        "name": "quagga",
                        "enabled": true
                    }
                ],
                "no_of_wan_interfaces": 2,
                "no_of_lan_interfaces": 1,
                "no_of_lo_interfaces": 1
            },
            {
                "name": "server1",
                "type": "host",
                "Services": [
                    {
                        "name": "webserver",
                        "enabled": true
                    }
                ],
                "no_of_wan_interfaces": 2,
                "no_of_lan_interfaces": 1,
                "no_of_lo_interfaces": 1
            }
        ],
        "links": [
            {
                "type": "wan",
                "connected_nodes": [
                    {
                        "name": "vm1"
                    },
                    {
                        "name": "vm2"
                    }
                ],
                "switch": ""
            },
            {
                "type": "wan",
                "connected_nodes": [
                    {
                        "name": "vm2"
                    },
                    {
                        "name": "vm3"
                    }
                ],
                "switch": ""
            },
            {
                "type": "lan",
                "connected_nodes": [
                    {
                        "name": "vm1"
                    },
                    {
                        "name": "server1"
                    }
                ],
                "switch": "lansw1"
            }
        ]
    },
    "saved": true
}



2. get '/Topology'

http://localhost:8888/topology/

Description:
List of Topologies.


Response Data:

[
    {
        "id": "e32214b2-90d3-49bd-a128-6a2ee81a6fd6",
        "data": {
            "projectid": "1",
            "name": "testtopology",
            "virtualization": "lxc",
            "ipassignment": "manual",
            "wanip_pool": "172.27.0.0/24",
            "lanip_pool": "10.0.0.0/24",
            "loip_pool": "1.1.1.0/2",
            "switches": [
                {
                    "name": "lansw1",
                    "ports": 8,
                    "type": "bridge"
                }
            ],
            "nodes": [
                {
                    "name": "vm1",
                    "type": "router",
                    "Services": [
                        {
                            "name": "quagga",
                            "enabled": true
                        }
                    ],
                    "no_of_wan_interfaces": 2,
                    "no_of_lan_interfaces": 1,
                    "no_of_lo_interfaces": 1
                },
                {
                    "name": "vm2",
                    "type": "router",
                    "Services": [
                        {
                            "name": "quagga",
                            "enabled": true
                        }
                    ],
                    "no_of_wan_interfaces": 2,
                    "no_of_lan_interfaces": 1,
                    "no_of_lo_interfaces": 1
                },
                {
                    "name": "vm3",
                    "type": "router",
                    "Services": [
                        {
                            "name": "quagga",
                            "enabled": true
                        }
                    ],
                    "no_of_wan_interfaces": 2,
                    "no_of_lan_interfaces": 1,
                    "no_of_lo_interfaces": 1
                }
            ],
            "links": [
                {
                    "type": "wan",
                    "connected_nodes": [
                        {
                            "name": "vm1"
                        },
                        {
                            "name": "vm2"
                        }
                    ],
                    "switch": ""
                },
                {
                    "type": "wan",
                    "connected_nodes": [
                        {
                            "name": "vm2"
                        },
                        {
                            "name": "vm3"
                        }
                    ],
                    "switch": ""
                },
                {
                    "type": "lan",
                    "connected_nodes": [
                        {
                            "name": "vm1"
                        },
                        {
                            "name": "server1"
                        }
                    ],
                    "switch": "lansw1"
                }
            ]
        },
        "saved": true
    },
    {
        "id": "dd930b74-bc40-4c52-9238-e746e8195ecf",
        "data": {
            "projectid": "1",
            "name": "testtopology",
            "virtualization": "lxc",
            "ipassignment": "manual",
            "wanip_pool": "172.27.0.0/24",
            "lanip_pool": "10.0.0.0/24",
            "loip_pool": "1.1.1.0/2",
            "switches": [
                {
                    "name": "lansw1",
                    "ports": 8,
                    "type": "bridge"
                }
            ],
            "nodes": [
                {
                    "name": "vm1",
                    "type": "router",
                    "Services": [
                        {
                            "name": "quagga",
                            "enabled": true
                        }
                    ],
                    "no_of_wan_interfaces": 2,
                    "no_of_lan_interfaces": 1,
                    "no_of_lo_interfaces": 1
                },
                {
                    "name": "vm2",
                    "type": "router",
                    "Services": [
                        {
                            "name": "quagga",
                            "enabled": true
                        }
                    ],
                    "no_of_wan_interfaces": 2,
                    "no_of_lan_interfaces": 1,
                    "no_of_lo_interfaces": 1
                },
                {
                    "name": "vm3",
                    "type": "router",
                    "Services": [
                        {
                            "name": "quagga",
                            "enabled": true
                        }
                    ],
                    "no_of_wan_interfaces": 2,
                    "no_of_lan_interfaces": 1,
                    "no_of_lo_interfaces": 1
                }
            ],
            "links": [
                {
                    "type": "wan",
                    "connected_nodes": [
                        {
                            "name": "vm1"
                        },
                        {
                            "name": "vm2"
                        }
                    ],
                    "switch": ""
                },
                {
                    "type": "wan",
                    "connected_nodes": [
                        {
                            "name": "vm2"
                        },
                        {
                            "name": "vm3"
                        }
                    ],
                    "switch": ""
                },
                {
                    "type": "lan",
                    "connected_nodes": [
                        {
                            "name": "vm1"
                        },
                        {
                            "name": "server1"
                        }
                    ],
                    "switch": "lansw1"
                }
            ]
        },
        "saved": true
    }
]



3. get '/Topology/:id/status'

http://localhost:8888/topology/722363cd-1984-4506-b9f0-f0aafe4157a3/status

Description:  Get the status of the topology (status of node, ip details, vm status)

Response data:

{
    "status": {
        "nodes": [
            {
                "config": {
                    "no_of_lo_interfaces": 1,
                    "no_of_lan_interfaces": 1,
                    "no_of_wan_interfaces": 2,
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
                    "projectid": "1",
                    "ifmap": [
                        {
                            "ifname": "eth0",
                            "hwAddress": "00:16:3e:5a:55:19",
                            "ipaddress": "10.0.3.2",
                            "netmask": "255.255.255.0",
                            "type": "mgmt"
                        },
                        {
                            "ifname": "eth1",
                            "hwAddress": "00:16:3e:5a:55:23",
                            "brname": "wan_vm1_vm2",
                            "ipaddress": "172.16.1.1",
                            "netmask": "255.255.255.252",
                            "type": "wan"
                        },
                        {
                            "ifname": "eth2",
                            "hwAddress": "00:16:3e:5a:55:27",
                            "brname": "lansw1",
                            "ipaddress": "10.10.10.1",
                            "netmask": "255.255.255.224",
                            "type": "lan"
                        }
                    ]
                },
                "status": {
                    "id": "851778d7-d05d-4314-a155-b08c1e89318e",
                    "status": "failure",
                    "reason": "VM already exists",
                    "result": "started"
                },
                "statistics": {}
            },
            {
                "config": {
                    "no_of_lo_interfaces": 1,
                    "no_of_lan_interfaces": 1,
                    "no_of_wan_interfaces": 2,
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
                    "projectid": "1",
                    "ifmap": [
                        {
                            "ifname": "eth0",
                            "hwAddress": "00:16:3e:5a:55:20",
                            "ipaddress": "10.0.3.3",
                            "netmask": "255.255.255.0",
                            "type": "mgmt"
                        },
                        {
                            "ifname": "eth1",
                            "hwAddress": "00:16:3e:5a:55:24",
                            "brname": "wan_vm1_vm2",
                            "ipaddress": "172.16.1.2",
                            "netmask": "255.255.255.252",
                            "type": "wan"
                        },
                        {
                            "ifname": "eth2",
                            "hwAddress": "00:16:3e:5a:55:25",
                            "brname": "wan_vm2_vm3",
                            "ipaddress": "172.16.1.5",
                            "netmask": "255.255.255.252",
                            "type": "wan"
                        }
                    ]
                },
                "status": {
                    "id": "b1b6ab62-0e72-4a50-ab7a-c6e017227d0d",
                    "status": "failure",
                    "reason": "VM already exists",
                    "result": "started"
                },
                "statistics": {}
            },
            {
                "config": {
                    "no_of_lo_interfaces": 1,
                    "no_of_lan_interfaces": 1,
                    "no_of_wan_interfaces": 2,
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
                    "projectid": "1",
                    "ifmap": [
                        {
                            "ifname": "eth0",
                            "hwAddress": "00:16:3e:5a:55:21",
                            "ipaddress": "10.0.3.4",
                            "netmask": "255.255.255.0",
                            "type": "mgmt"
                        },
                        {
                            "ifname": "eth1",
                            "hwAddress": "00:16:3e:5a:55:26",
                            "brname": "wan_vm2_vm3",
                            "ipaddress": "172.16.1.6",
                            "netmask": "255.255.255.252",
                            "type": "wan"
                        }
                    ]
                },
                "status": {
                    "id": "f27577a3-5e4b-4127-99b2-251a97316833",
                    "status": "failure",
                    "reason": "VM already exists",
                    "result": "started"
                },
                "statistics": {}
            },
            {
                "config": {
                    "no_of_lo_interfaces": 1,
                    "no_of_lan_interfaces": 1,
                    "no_of_wan_interfaces": 2,
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
                    "projectid": "1",
                    "ifmap": [
                        {
                            "ifname": "eth0",
                            "hwAddress": "00:16:3e:5a:55:22",
                            "ipaddress": "10.0.3.5",
                            "netmask": "255.255.255.0",
                            "type": "mgmt"
                        },
                        {
                            "ifname": "eth1",
                            "hwAddress": "00:16:3e:5a:55:28",
                            "brname": "lansw1",
                            "ipaddress": "10.10.10.2",
                            "netmask": "255.255.255.224",
                            "type": "lan"
                        }
                    ]
                },
                "status": {
                    "id": "b37c6839-e604-466b-989c-86e9042eae2b",
                    "status": "created",
                    "result": "started"
                },
                "statistics": {}
            }
        ],
        "switches": [
            {
                "config": {
                    "type": "bridge",
                    "ports": 8,
                    "name": "lansw1"
                },
                "status": {
                    "result": "failed",
                    "reason": "failed to create"
                },
                "statistics": {}
            },
            {
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
}


4. delete '/Topology/:id'

http://localhost:8888/topology/722363cd-1984-4506-b9f0-f0aafe4157a3/

Description:

Delete the Topology. removes the VMs,switches associated with  topology

Response:

true


======================================
Future implementation
5. get '/Topology/:id/node/:id/'

6. delete '/Topology/:id/node/:id'

6. put '/Topology/:id/node/:id/stop'

7. put '/Topology/:id/node/:id/start'

8. put '/Topology/:id/node/:id/service/:id/'

9. put '/Topology/:id/node/:id/service/:id/stop'

10. put '/Topology/:id/node/:id/service/:id/start'

==============================

Lincense:
MIT
