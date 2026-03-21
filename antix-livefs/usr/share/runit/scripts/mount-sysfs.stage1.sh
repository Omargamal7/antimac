#!/bin/sh
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin

. /usr/share/runit/scripts/runit-functions.sh
. /etc/runit/config/system.conf

SERVICE1=mount-sysfs

load_service(){
    mountpoint -q /sys     || mount -t sysfs sys /sys -o nosuid,noexec,nodev
    mountpoint -q /sys/kernel/security || mount -n -t securityfs securityfs /sys/kernel/security
    [ -d /sys/firmware/efi ] && (mountpoint -q /sys/firmware/efi/efivars || mount -n -t efivarfs -o ro efivarfs /sys/firmware/efi/efivars)
}

# MAIN START
stat_busy "Starting $SERVICE1"
load_service  #|| stat_die $SERVICE1 
add_daemon $SERVICE1
stat_done $SERVICE1

#~ # MAIN STOP
#~ stat_busy "Stopping $SERVICE1"
#~ unload_service || stat_die $SERVICE1
#~ rm_daemon $SERVICE1
#~ stat_done $SERVICE1
