#!/usr/bin/env bash

set +x
green='\e[1;32m%s\e[0m\n'
red='\e[1;31m%s\e[0m\n'

# Source openrc
source /root/openrc
# Changing the quota
openstack quota set --secgroups 10000 default 2>/dev/null
if [[ "${?}" -eq "0" ]]; then
  printf "$green"   "SecGroup Quota changed"
else
  printf "$red"   "Failed to change the quota"
fi

openstack quota set --volumes 10000 default 2>/dev/null
if [[ "${?}" -eq "0" ]]; then
  printf "$green"   "Volumes Quota changed"
else
  printf "$red"   "Failed to change the quota"
fi

# Changing kernel params

sysctl -w net.ipv4.tcp_wmem=25165824
sysctl -w net.ipv4.tcp_max_syn_backlog=10000000
sysctl -w net.ipv4.route.flush=1
