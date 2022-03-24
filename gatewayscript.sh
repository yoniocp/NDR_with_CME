#!/bin/bash

fw ctl set int fw_daf_module_mac_mode 1
echo "fw_daf_module_mac_mode=1" >> $FWDIR/modules/fwkern.conf

exit 0
