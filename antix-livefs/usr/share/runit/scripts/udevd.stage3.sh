#!/bin/sh
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin

. /usr/share/runit/scripts/runit-functions.sh
. /etc/runit/config/system.conf

SERVICE1=udevd

# Note: This service is only needed for initialization, 
#       udev will be controlled by runit on stage 2.

load_service(){
    udevd --daemon
}

unload_service(){
   ! pgrep -f "udevd" >/dev/null 2>&1 || udevadm control --exit
}

#~ # MAIN START
#~ stat_busy "Starting $SERVICE1"
#~ load_service || stat_die $SERVICE1
#~ add_daemon $SERVICE1
#~ stat_done $SERVICE1


# MAIN STOP
stat_busy "Stopping $SERVICE1"
unload_service || stat_die $SERVICE1
rm_daemon $SERVICE1
stat_done $SERVICE1
