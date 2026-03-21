#! /bin/bash
#

#### Check to see if OpenRC is PID 1 - otherwise just use sysvinit #### 
#

if [ $(ps -p1 | grep -ic openrc) -eq 1 ] || [ $(cat /proc/cmdline | grep -ic "openrc") -eq 1 ] || ( [ $(cat /proc/cmdline | grep -ic "init=/") -eq 0 ] && [ $(readlink -e /sbin/init | grep -ic "openrc") -eq 1 ] ); then

#######################################################################
#-----Contents of OpenRC's original rcS script below-----

#!/bin/sh 
# Wrapper of OpenRC called from inittab 

set -e 

exec /usr/sbin/openrc sysinit

else
#######################################################################
#-----Contents of syvinit's original rcS script below-----

#! /bin/sh
#
# rcS
#
# Call all S??* scripts in /etc/rcS.d/ in numerical/alphabetical order
#

exec /etc/init.d/rc S

fi
