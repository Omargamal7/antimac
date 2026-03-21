#!/bin/sh
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin

. /usr/share/runit/scripts/runit-functions.sh
. /etc/runit/config/system.conf

SERVICE1=bootmisc

unload_service(){
[ "$DELAYLOGIN" ] || DELAYLOGIN=yes
. /usr/share/runit/scripts/init-functions.sh
. /usr/share/runit/scripts/vars.sh

#
# If login delaying is enabled then create the flag file
# which prevents logins before startup is complete
#
case "$DELAYLOGIN" in
	 Y*|y*)
	echo "System bootup in progress - please wait" > /run/nologin
	;;
esac

# Remove bootclean's flag files.
# Don't run bootclean again after this!
rm -f /tmp/.clean /run/.clean /run/lock/.clean
rm -f /tmp/.tmpfs /run/.tmpfs /run/lock/.tmpfs

readonly utmp='/var/run/utmp'
if > "${utmp}" ; then
	chgrp utmp "${utmp}" || log_warning_msg "failed to chgrp ${utmp}"
	chmod 664  "${utmp}" || log_warning_msg "failed to chmod ${utmp}"
	return 0
else
	log_failure_msg "failed to truncate ${utmp}"
	return 1
fi
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
