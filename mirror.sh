#!/bin/bash
: '
------- No supported in production -------
Enable MSS Clamping in a CME managed GW
Needs to be run in Autoprovision template with "MIRROR" as a custom parameter and also Rulebase name to install and VPN community as last parameter
------- No supported in production -------
'
. /opt/CPshared/5.0/tmp/.CPprofile.sh
AUTOPROV_ACTION=$1
GW_NAME=$2
CUSTOM_PARAMETERS=$3
RULEBASE=$4
COMM_VPN=$5
if [[ $AUTOPROV_ACTION == delete ]]
then
	echo "Connection to API server"
		SID=$(mgmt_cli -r true login -f json | jq -r '.sid')
	echo "Removing objects created by mirror"	
		mgmt_cli --session-id $SID set simple-gateway name $GW_NAME vpn-settings.vpn-domain-type addresses_behind_gw
		mgmt_cli --session-id $SID delete group name grp_$GW_NAME
		mgmt_cli --session-id $SID delete host name ip_$GW_NAME
		mgmt_cli publish --session-id $SID
	echo "Logging out of session"
		mgmt_cli logout --session-id $SID
        exit 0
fi
if [[ $CUSTOM_PARAMETERS != MIRROR ]];
then
    exit 0
fi
if [[ $CUSTOM_PARAMETERS == MIRROR ]]
then
INSTALL_STATUS=1
POLICY_PACKAGE_NAME=$RULEBASE
    echo "Connection to API server"
    SID=$(mgmt_cli -r true login -f json | jq -r '.sid')
    GW_JSON=$(mgmt_cli --session-id $SID show simple-gateway name $GW_NAME -f json)
    GW_UID=$(echo $GW_JSON | jq '.uid')
    GW_ETH1=$(echo $GW_JSON | jq '."interfaces"[1] ."ipv4-address"')
	
    echo "Configure GW topology"
		mgmt_cli --session-id $SID add host name ip_$GW_NAME ip-address $GW_ETH1 ignore-warnings true
		mgmt_cli --session-id $SID add group name grp_$GW_NAME members ip_$GW_NAME
		mgmt_cli --session-id $SID set simple-gateway name $GW_NAME vpn-settings.vpn-domain-type manual vpn-settings.vpn-domain grp_$GW_NAME
		mgmt_cli --session-id $SID set vpn-community-star name $COMM_VPN satellite-gateways.add $GW_NAME
    
	echo "Add VXLAN interface"
		GW_ETH0_NAME=$(echo $GW_JSON | jq '.interfaces[0] .name')
		GW_ETH0_ADDRESS=$(echo $GW_JSON | jq '."interfaces"[0] ."ipv4-address"')
		GW_ETH0_MASK=$(echo $GW_JSON | jq '."interfaces"[0] ."ipv4-network-mask"')
		GW_ETH1_NAME=$(echo $GW_JSON | jq '.interfaces[1] .name')
		GW_ETH1_ADDRESS=$(echo $GW_JSON | jq '."interfaces"[1] ."ipv4-address"')
		GW_ETH1_MASK=$(echo $GW_JSON | jq '."interfaces"[1] ."ipv4-network-mask"')
		mgmt_cli --session-id $SID set simple-gateway uid $GW_UID interfaces.0.name $GW_ETH0_NAME interfaces.0.ipv4-address $GW_ETH0_ADDRESS interfaces.0.ipv4-network-mask $GW_ETH0_MASK interfaces.0.anti-spoofing false interfaces.0.topology external interfaces.1.name $GW_ETH1_NAME interfaces.1.ipv4-address $GW_ETH1_ADDRESS interfaces.1.ipv4-network-mask $GW_ETH1_MASK interfaces.1.anti-spoofing false interfaces.1.topology internal interfaces.1.topology-settings.ip-address-behind-this-interface "network defined by the interface ip and net mask" interfaces.2.name vxlan400 interfaces.2.ipv4-address 1.1.1.1 interfaces.2.ipv4-network-mask 255.255.255.255 interfaces.2.anti-spoofing false
		mgmt_cli --session-id $SID set generic-object uid $GW_UID firewallSetting.trafficMirroringEnabled true firewallSetting.trafficMirroringInterface vxlan400
    
	echo "Publishing changes"
        mgmt_cli publish --session-id $SID
    
	echo "Install policy"
        until [[ $INSTALL_STATUS != 1 ]]; do
            mgmt_cli --session-id $SID -f json install-policy policy-package $POLICY_PACKAGE_NAME targets $GW_UID
            INSTALL_STATUS=$?
        done
    
	echo "Policy Installed"
    echo "Logging out of session"
    mgmt_cli logout --session-id $SID
    exit 0
fi
exit 0
