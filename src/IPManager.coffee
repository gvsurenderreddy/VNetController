StormRegistry = require 'stormregistry'
StormData = require 'stormdata'
util = require('util')
request = require('request-json');
extend = require('util')._extend
ip = require 'ip'
async = require 'async'

##########################################################################################################
#It works perfectly, even its not clean.
# revisit later.

# utility functions
subnetting = (net, curprefix, newprefix ) ->
    
    netmask = ip.fromPrefixLen(curprefix)
    newmask = ip.fromPrefixLen(newprefix)
    xx = new Buffer 4
    iter =  ( newprefix - curprefix ) 
    iterations = Math.pow(2, iter)
    answer = []
    do () ->
        for i in [0..iterations-1]
            result = ip.subnet(net,newmask)            
            result.status = "free"
            result.iparray = []

            xx = ip.toBuffer(result.firstAddress)
            for i in [0..result.numHosts-1]                               
                result.iparray[i] = ip.toString(xx)
                xx[3]++ 

            answer.push result
            xx = ip.toBuffer(result.broadcastAddress)
            xx[3]++     
            if xx[3] == 0x00
                xx[2]++
            str = ip.toString(xx)
            net = str
    return answer


iplist = (address) ->
    iparray = []
    result = ip.subnet(address, '255.255.255.0')
    xx = ip.toBuffer(result.firstAddress)
    for i in [0..result.numHosts-1]
        iparray[i] = ip.toString(xx)
        xx[3]++ 
    return iparray

##########################################################################################################
class IPManager
    constructor :(wan,lan,mgmt) ->
        util.log "wan pool #{wan} "
        util.log "lan pool #{lan} "
        util.log "mgmt pool #{mgmt}"
        @wansubnets = subnetting wan, 24, 30
        @lansubnets = subnetting lan, 24, 27
        @wanindex = 0
        @lanindex = 0
        @mgmtindex = 1
        @mgmtips = iplist(mgmt)

    listwansubnets:()->
        util.log "wansubnets " + JSON.stringify @wansubnets
    listlanubnets:()->
        util.log "lansubnets " + JSON.stringify @lansubnets
    getFreeWanSubnet:()->
        @wansubnets[@wanindex++]
    getFreeLanSubnet:()->
        @lansubnets[@lanindex++]
    getFreeMgmtIP :()->
        @mgmtips[@mgmtindex++]

###################################################################################################
module.exports = IPManager