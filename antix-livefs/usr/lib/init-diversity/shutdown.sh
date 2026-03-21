#!/bin/bash

[ "$UID" -eq 0 ] || exec sudo bash "$0" "$@"

if mountpoint -q /live/aufs; then
		if [ $(cat /proc/cmdline | grep -ic "init=/") -eq 0 ]; then
				if [ $(ps -p1 | grep -ic "runit") -eq 1 ]; then
					/usr/lib/runit/shutdown $@;
					exit 0
				elif [ $(ps -p1 | grep -ic "s6-svscan") -eq 1 ] && [ -e /run/s6-rc ]; then
					openvt -c12 -f -- /usr/bin/s6-linux-init-shutdown $@;
					exit 0
				elif [ $(ps -p1 | grep -ic "s6-svscan") -eq 1 ] && [ -e /run/66 ]; then
					/usr/bin/66-shutdown $@;
					exit 0
				elif [ $(ps -p1 | grep -ic "dinit") -eq 1 ] || [ $(/sbin/init --version | grep -ic "Dinit") -eq 1 ]; then
					/usr/lib/dinit/shutdown $@
					exit 0
				elif [ $(ps -p1 | grep -ic "init") -eq 1 ] && [ $(/sbin/init --version | grep -ic "SysV") -eq 1 ]; then
					/usr/lib/sysvinit/shutdown $@
					exit 0
				else 
					sync && sleep 5 && /usr/bin/busybox shutdown -f;
					exit 1
				fi
		else
				if [ $(ps -p1 | grep -ic "runit") -eq 1 ]; then
					/usr/lib/runit/shutdown $@;
					exit 0
				elif [ $(ps -p1 | grep -ic "s6-svscan") -eq 1 ] && [ -e /run/s6-rc ]; then
					openvt -c12 -f -- /usr/bin/s6-linux-init-shutdown $@;
					exit 0
				elif [ $(ps -p1 | grep -ic "s6-svscan") -eq 1 ] && [ -e /run/66 ]; then
					/usr/bin/66-shutdown $@;
					exit 0
				elif [ $(cat /proc/cmdline | grep -ic "dinit") -eq 1 ]; then
					/usr/lib/dinit/shutdown $@
					exit 0
				elif [ $(cat /proc/cmdline | grep -ic "sysvinit") -eq 1 ]; then
					/usr/lib/sysvinit/shutdown $@
					exit 0
				else 
					sync && sleep 5 && /usr/bin/busybox shutdown -f;
					exit 1
				fi	
		fi
else
		if [ $(cat /proc/cmdline | grep -ic "init=/") -eq 0 ]; then
				if [ $(ps -p1 | grep -ic "runit") -eq 1 ]; then
					/usr/lib/runit/shutdown $@;
					exit 0
				elif [ $(ps -p1 | grep -ic "s6-svscan") -eq 1 ] && [ -e /run/s6-rc ]; then
					/usr/bin/s6-linux-init-shutdown $@;
					exit 0
				elif [ $(ps -p1 | grep -ic "s6-svscan") -eq 1 ] && [ -e /run/66 ]; then
					/usr/bin/66-shutdown $@;
					exit 0
				elif [ $(ps -p1 | grep -ic "dinit") -eq 1 ] || [ $(/sbin/init --version | grep -ic "Dinit") -eq 1 ]; then
					/usr/lib/dinit/shutdown $@
					exit 0
				elif [ $(ps -p1 | grep -ic "init") -eq 1 ] && [ $(/sbin/init --version | grep -ic "SysV") -eq 1 ]; then
					/usr/lib/sysvinit/shutdown $@
					exit 0
				else 
					sync && sleep 5 && /usr/bin/busybox shutdown -f;
					exit 1
				fi
		else
				if [ $(ps -p1 | grep -ic "runit") -eq 1 ]; then
					/usr/lib/runit/shutdown $@;
					exit 0
				elif [ $(ps -p1 | grep -ic "s6-svscan") -eq 1 ] && [ -e /run/s6-rc ]; then
					/usr/bin/s6-linux-init-shutdown $@;
					exit 0
				elif [ $(ps -p1 | grep -ic "s6-svscan") -eq 1 ] && [ -e /run/66 ]; then
					/usr/bin/66-shutdown $@;
					exit 0
				elif [ $(ps -p1 | grep -ic "dinit") -eq 1 ] || [ $(cat /proc/cmdline | grep -ic "dinit") -eq 1 ]; then
					/usr/lib/dinit/shutdown $@
					exit 0
				elif [ $(ps -p1 | grep -ic "init") -eq 1 ] && [ $(cat /proc/cmdline | grep -ic "sysvinit") -eq 1 ]; then
					/usr/lib/sysvinit/shutdown $@
					exit 0
				else 
					sync && sleep 5 && /usr/bin/busybox shutdown -f;
					exit 1
				fi	
		fi
	
fi
