#!/bin/bash

[ "$UID" -eq 0 ] || exec sudo bash "$0" "$@"

if mountpoint -q /live/aufs; then
		if [ $(cat /proc/cmdline | grep -ic "init=/") -eq 0 ]; then
				if [ $(ps -p1 | grep -ic "runit") -eq 1 ]; then
					sync && touch /run/initctl && ( /usr/lib/runit/runit-init 0);
					exit 0
				elif [ $(ps -p1 | grep -ic "s6-svscan") -eq 1 ] && [ -e /run/s6-rc ]; then
					sync && ( openvt -c12 -f -- /usr/lib/s6-rc/poweroff $@ ) && sleep 3 && ( openvt -c12 -f -- /usr/bin/s6-linux-init-hpr -p -f $@ );
					exit 0
				elif [ $(ps -p1 | grep -ic "s6-svscan") -eq 1 ] && [ -e /run/66 ]; then
					sync && ( /usr/lib/s6-66/poweroff $@ );
					exit 0
				elif [ $(ps -p1 | grep -ic "dinit") -eq 1 ] || [ $(/sbin/init --version | grep -ic "Dinit") -eq 1 ]; then
					sync && ( /usr/lib/dinit/shutdown $@ );
					exit 0
				elif [ $(ps -p1 | grep -ic "init") -eq 1 ] && [ $(/sbin/init --version | grep -ic "SysV") -eq 1 ]; then
					sync  && ( /usr/lib/sysvinit/init 0 ) && sleep 3 && ( /usr/lib/sysvinit/poweroff $@ | /usr/sbin/poweroff $@ );
					exit 0
				else 
					sync && sleep 5 && /usr/bin/busybox poweroff -f;
					exit 1
				fi
		else
				if [ $(ps -p1 | grep -ic "runit") -eq 1 ]; then
					sync && touch /run/initctl && /usr/lib/runit/runit-init 0 ;
					exit 0
				elif [ $(ps -p1 | grep -ic "s6-svscan") -eq 1 ] && [ -e /run/s6-rc ]; then
					sync && ( openvt -c12 -f -- /usr/lib/s6-rc/poweroff $@ )  && sleep 3 && ( openvt -c12 -f -- /usr/bin/s6-linux-init-hpr -p -f $@ );
					exit 0
				elif [ $(ps -p1 | grep -ic "s6-svscan") -eq 1 ] && [ -e /run/66 ]; then
					sync && ( /usr/lib/s6-66/poweroff $@ );
					exit 0
				elif [ $(cat /proc/cmdline | grep -ic "dinit") -eq 1 ]; then
					sync && /usr/lib/dinit/shutdown $@ ;
					exit 0
				elif [ $(cat /proc/cmdline | grep -ic "sysvinit") -eq 1 ]; then
					sync  && /usr/lib/sysvinit/init 0 && sleep 3 && /usr/lib/sysvinit/poweroff $@;
					exit 0
				else 
					sync && sleep 5 && /usr/bin/busybox poweroff -f;
					exit 1
				fi	
		fi
else
		if [ $(cat /proc/cmdline | grep -ic "init=/") -eq 0 ]; then
				if [ $(ps -p1 | grep -ic "runit") -eq 1 ]; then
					sync && touch /run/initctl && ( /usr/lib/runit/runit-init 0 ) ;
					exit 0
				elif [ $(ps -p1 | grep -ic "s6-svscan") -eq 1 ] && [ -e /run/s6-rc ]; then
					sync && ( /usr/lib/s6-rc/poweroff );
					exit 0
				elif [ $(ps -p1 | grep -ic "s6-svscan") -eq 1 ] && [ -e /run/66 ]; then
					sync && ( /usr/lib/s6-66/poweroff $@ );
					exit 0
				elif [ $(ps -p1 | grep -ic "dinit") -eq 1 ] || [ $(/sbin/init --version | grep -ic "Dinit") -eq 1 ]; then
					sync && ( /usr/lib/dinit/shutdown $@ );
					exit 0
				elif [ $(ps -p1 | grep -ic "init") -eq 1 ] && [ $(/sbin/init --version | grep -ic "SysV") -eq 1 ]; then
					sync  && ( /usr/lib/sysvinit/init 0 ) && sleep 3 && ( /usr/lib/sysvinit/poweroff $@ );
					exit 0
				else 
					sync && sleep 5 && /usr/bin/busybox poweroff -f;
					exit 1
				fi
		else
				if [ $(ps -p1 | grep -ic "runit") -eq 1 ]; then
					sync && touch /run/initctl && /usr/lib/runit/runit-init 0;
					exit 0
				elif [ $(ps -p1 | grep -ic "s6-svscan") -eq 1 ] && [ -e /run/s6-rc ]; then
					sync && /usr/lib/s6-rc/poweroff;
					exit 0
				elif [ $(ps -p1 | grep -ic "s6-svscan") -eq 1 ] && [ -e /run/66 ]; then
					sync && /usr/lib/s6-66/poweroff;
					exit 0
				elif [ $(ps -p1 | grep -ic "dinit") -eq 1 ] || [ $(cat /proc/cmdline | grep -ic "dinit") -eq 1 ]; then
					sync && /usr/lib/dinit/shutdown;
					exit 0
				elif [ $(ps -p1 | grep -ic "init") -eq 1 ] && [ $(cat /proc/cmdline | grep -ic "sysvinit") -eq 1 ]; then
					sync  && /usr/lib/sysvinit/init 0 && sleep 3 && /usr/lib/sysvinit/poweroff $@ ;
					exit 0
				else 
					sync && sleep 5 && /usr/bin/busybox poweroff -f;
					exit 1
				fi	
		fi
	
fi
