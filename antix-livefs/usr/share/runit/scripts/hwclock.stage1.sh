#!/bin/sh
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin

. /usr/share/runit/scripts/runit-functions.sh
. /etc/runit/config/system.conf

SERVICE1=hwclock

case $HARDWARECLOCK in
    UTC) HWCLOCK_PARAMS+=" --systz --utc --noadjfile" ;;
    localtime) HWCLOCK_PARAMS+=" --systz --localtime --noadjfile" ;;
    *) HWCLOCK_PARAMS="--hctosys";;
 esac

load_service(){
    if [ -x /sbin/hwclock ]; then
		hwclock --systz $HWCLOCK_PARAMS
    else
		printf "$SERVICE1 not installed" && stat_warn $SERVICE1
    fi
}

unload_service(){
	if [ -x /sbin/hwclock ]; then
		hwclock --systohc $HWCLOCK_PARAMS
	else
		printf "$SERVICE1 not installed" && stat_warn $SERVICE1
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
