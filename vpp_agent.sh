#!/bin/bash

# Check if vpp is up. Wait for a minute
wait_time=60
command="vppctl show interface eth0"
until [ $wait_time -eq 0 ] || $command; do
  sleep 1s
  ((wait_time--))
done

# Check why we exited the loop
if $command ; then
  echo "Success"
else
  echo "Fail"
  exit 1
fi

#get the ipaddress associated with host name
hostname=$(hostname)
node_ip=$(grep $hostname /config/node/ip | awk -F'=' '{print $2}')

#bring up the interface. Dataplane interface is named eth0 within vpp
vppctl set interface state eth0 up

#setup the ip address
vppctl set interface ip address eth0 $node_ip

#get the gateway IP from the config map
gateway=$(grep gateway /config/node/ip | awk -F'=' '{print $2}')

#generate the mac address for the gateway
p1=$(echo $gateway |  awk -F'.' '{print $1}')
p2=$(echo $gateway |  awk -F'.' '{print $2}')
p3=$(echo $gateway |  awk -F'.' '{print $3}')
p4=$(echo $gateway |  awk -F'.' '{print $4}')
echo $p2 $p3 $p4
h1=$(printf "%02x" $p1)
h2=$(printf "%02x" $p2)
h3=$(printf "%02x" $p3)
h4=$(printf "%02x" $p4)
gateway_mac="42:01:$h1:$h2:$h3:$h4"

#set up ip neighbor for the gateway
vppctl set ip neighbor eth0 $gateway $gateway_mac

#setup the default route
vppctl ip route add 0.0.0.0/0 via $gateway

#infinite loop
while true
do
  echo "Press [CTRL+C] to stop.."
  sleep 3600
done
