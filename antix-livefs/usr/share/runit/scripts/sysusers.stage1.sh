#!/bin/sh
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin

. /usr/share/runit/scripts/runit-functions.sh
. /etc/runit/config/system.conf

SERVICE1=sysusers

load_service() {
if [ -x /usr/bin/opensysusers-sysusers ]; then
     opensysusers-sysusers || return 1
else
	printf "opensysusers-sysusers not installed" && stat_warn $SERVICE1
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
