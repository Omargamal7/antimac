#!/bin/sh
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin

. /usr/share/runit/scripts/runit-functions.sh
. /etc/runit/config/system.conf

SERVICE1=dmesg

load_service(){

if [ -f /var/log/dmesg.log ]; then
		savelog -q -p -c 5 /var/log/dmesg.log
	else
		touch /var/log/dmesg.log
		chown root:adm /var/log/dmesg.log
		chmod 640 /var/log/dmesg.log
	fi

	if which dmesg >/dev/null 2>&1
	then
		dmesg -Ts 524288 > /var/log/dmesg.log
	elif [ -c /dev/klog ]
	then
		dd if=/dev/klog of=/var/log/dmesg.log &
		sleep 1
		kill $!
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

