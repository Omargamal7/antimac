#!/usr/bin/sh

## Start 66 user services if s6-66 is detected
while [ $(ps -p1 | grep -ic "s6-svscan") -eq 1 ] && [ -e /run/66 ]; do
	export PATH=$PATH:/usr/sbin:/usr/lib/execline/bin:/usr/libexec
	
	exec sh -c '
		trap "66 tree stop && 66 scandir remove && rm -rf /run/66/scandir/$(id -u)" EXIT TERM
		66 scandir check || bash -c "coproc 66 scandir start &"
		66 tree start &
		'
done &

## Start s6-rc user services if s6-rc is detected
while [ $(ps -p1 | grep -ic "s6-svscan") -eq 1 ] && [ -e /run/s6-rc ]; do
	export PATH=$PATH:/usr/sbin:/usr/lib/execline/bin:/usr/libexec
	
	exec sh -c '
		trap "s6-rc -l /tmp/$(id -u)/s6-rc -D change default && rm -rf /tmp/$(id -u)" EXIT TERM
		mkdir -p "/tmp/$(id -u)/service"
		[ ! -e "/tmp/$(id -u)/service/.s6-svscan" ] && bash -c "coproc s6-svscan /tmp/$(id -u)/service"
		[ ! -e "/tmp/$(id -u)/s6-rc" ] && s6-rc-init -c "$(/usr/lib/execline/bin/homeof $(whoami))/.s6-rc/compiled" -l "/tmp/$(id -u)/s6-rc" "/tmp/$(id -u)/service"
		s6-rc -l "/tmp/$(id -u)/s6-rc" -up change default
		'
done & 

## Start dinit user services if dinit is detected
while [ $(ps -p1 | grep -ic "dinit") -eq 1 ] || [ $(cat /proc/cmdline | grep -ic "dinit") -eq 1 ] || ( [ $(cat /proc/cmdline | grep -ic "init=/") -eq 0 ] && [ $(/sbin/init --version | grep -ic "Dinit") -eq 1 ] ); do
	export PATH=$PATH:/usr/sbin:/usr/lib/execline/bin:/usr/libexec
	exec sh -c '
		dinit "$@" -q -l /var/tmp/log/dinit.log &
		'
done & 

## Start runit user services if runit is detected
while  [ $(ps -p1 | grep -ic "runit") -eq 1 ]; do
	export PATH=$PATH:/usr/sbin:/usr/lib/execline/bin:/usr/libexec

	 exec sh -c '
		trap "sv stop ${HOME}/.runit/service/* || sv stop ${HOME}/.config/service/*" EXIT TERM
		if [ -d ${HOME}/.runit/service ]; then
			sv restart ${HOME}/.runit/service/* || runsvdir -P ${HOME}/.runit/service >/dev/null 2>&1 && sv start ${HOME}/.runit/service/*
		else 
			[ -d ${HOME}/.config/service ] && sv restart ${HOME}/.config/service/* || [ -d ${HOME}/.config/service ] && runsvdir -P ${HOME}/.config/service >/dev/null 2>&1 && sv start ${HOME}/.runit/service/*
		fi
		'
done & 
