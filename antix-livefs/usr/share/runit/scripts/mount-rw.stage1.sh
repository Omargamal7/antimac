#!/bin/sh
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin

. /usr/share/runit/scripts/runit-functions.sh
. /etc/runit/config/system.conf

SERVICE1=mount-rw

load_service(){
if [ -d /live/aufs ]; then
    printf "Live/Frugal system detected" && stat_warn $SERVICE1
else
	mount -o remount,rw /
fi
}

unload_service() {
if [ -d /live/aufs ]; then
    printf "Live/Frugal system detected" && stat_warn $SERVICE1
else
	sync && sleep 3 && mount -o remount,ro /
fi
}

# MAIN START
stat_busy "Starting $SERVICE1"
load_service || stat_die $SERVICE1
add_daemon $SERVICE1
stat_done $SERVICE1


#~ # MAIN STOP
#~ stat_busy "Stopping $SERVICE1"
#~ unload_service || stat_die $SERVICE1
#~ rm_daemon $SERVICE1
#~ stat_done $SERVICE1
