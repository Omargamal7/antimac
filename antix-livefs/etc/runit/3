#!/bin/sh
exec 2>&1

PATH=/usr/sbin:/sbin:/usr/bin:/bin
export PATH

LAST=0

# While test -x is more natural, it does not consider file with
# executable bit set on 'noexec' filesystem as executable, and /run
# often is mounted as 'noexec'.
[ $(stat -c %a /run/runit.reboot) = 100 ] && LAST=6
# used by /sbin/runlevel
printf "$LAST" >/run/runit.runlevel

[ -x /etc/runit/rc.shutdown ] && /etc/runit/rc.shutdown

echo 'Waiting for services to stop...'
sv -w 25 force-stop /etc/service/*
sv exit /etc/service/*

echo 'Running shutdown tasks...'
if [ -f /etc/runit/native.boot.run ] && [ -d /etc/runit/shutdown-run ]; then
		for f in /etc/runit/shutdown-run/*.sh; do
			[ -r "$f" ] && . "$f"
		done
else
	/lib/runit/run_sysv_scripts "/etc/rc$LAST.d" stop
fi
