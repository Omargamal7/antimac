#!/bin/sh
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin

. /usr/share/runit/scripts/runit-functions.sh
. /etc/runit/config/system.conf

SERVICE1=bootlogd

load_service(){
if [ -x /sbin/bootlogd ]; then
     bootlogd -e -c -l /run/bootlog || return 1
else
	printf "bootlogd not installed" && echo "Please install bootlogd to enable this log" >/run/bootlog && stat_warn $SERVICE1
fi
}

unload_service(){
    [ -f /run/bootlogd.pid ] || return 0
    touch /var/log/boot.log
    kill $(< /run/bootlogd.pid)
    rm -f /run/bootlogd.pid
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
