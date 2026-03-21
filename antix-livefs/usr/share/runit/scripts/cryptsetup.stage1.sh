#!/bin/sh
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin

. /usr/share/runit/scripts/runit-functions.sh
. /etc/runit/config/system.conf

SERVICE1=cryptsetup

load_service(){
	if [ -r /lib/cryptsetup/cryptdisks-functions ]; then
	. /lib/cryptsetup/cryptdisks-functions
else
	printf "cryptdisks-functions isn't accesible" && stat_warn $SERVICE1
fi
INITSTATE="remaining"
DEFAULT_LOUD="yes"
do_start
}

unload_service(){
	if [ -r /lib/cryptsetup/cryptdisks-functions ]; then
	. /lib/cryptsetup/cryptdisks-functions
else
	printf "cryptdisks-functions isn't accesible" && stat_warn $SERVICE1
fi
INITSTATE="remaining"
DEFAULT_LOUD="yes"
do_stop
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
