#!/bin/bash

clish -c 'set static-route 10.110.0.4/32 nexthop gateway address 10.254.0.1 on' -s
#fw ctl set int fw_daf_module_mac_mode 1
#echo "fw_daf_module_mac_mode=1" >> $FWDIR/modules/fwkern.conf

exit 0
