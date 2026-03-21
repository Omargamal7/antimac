#!/bin/sh

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin

cgroup=/sys/fs/cgroup/runit

if [ -d ${cgroup}/"$1" ]; then
	rmdir ${cgroup}/"$1"
fi
