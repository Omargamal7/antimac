#!/bin/sh
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin

. /usr/share/runit/scripts/runit-functions.sh
. /etc/runit/config/system.conf

SERVICE1=mount-procfs

load_service(){
  grep -v '^#' /etc/fstab | grep /proc | {
    read -r spec file vfstype mntopts x
      if ! mountpoint -q /proc; then
        if [ "$spec" -a "$file" -a "$vfstype" -a "$mntopts" ]; then
          mount -t "$vfstype" "$spec" "$file" -o "$mntopts"
        else
          mount -t proc proc /proc
        fi
      elif [ "$spec" -a "$file" -a "$vfstype" -a "$mntopts" ] && mountpoint -q /proc; then
        mount -t "$vfstype" "$spec" "$file" -o "remount,$mntopts"
      fi
  }
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
