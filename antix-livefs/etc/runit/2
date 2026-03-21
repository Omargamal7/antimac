#!/bin/sh

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/sbin:/usr/bin:/bin
SVDIR=/etc/service
export PATH

mkdir -p /run/runit/supervise
#sync available services
/lib/runit/trigger_sv setup

if [ ! -z $runitdir ] && [ -d /etc/runit/runsvdir/"$runitdir" ]; then
	runsv_dir="$runitdir"
elif [ -r /etc/runit/default.runsvdir ]; then
	runsv_dir="$(cat /etc/runit/default.runsvdir)"
else
	runsv_dir=default
fi

# single/recovery mode
if grep -q -w -i 'single' /proc/cmdline ; then
	chpst -P /sbin/sulogin -p /dev/tty1
fi
runsvchdir "$runsv_dir" || runsvchdir default

#sysv emulation
   #90 sec timeout (async timeout) for each script to start, then it detaches
   #to avoid getting stuck at boot. see #838480-msg#49
if [ "$runsv_dir" != solo ] && [ ! -e /etc/runit/no.emulate.sysv ]; then
	/lib/runit/async-timeout /lib/runit/run_sysv_scripts '/etc/rc2.d'
fi


exec env - PATH=$PATH \
runsvdir -P "${SVDIR}" 'log: ...........................................................................................................................................................................................................................................................................................................................................................................................................'
