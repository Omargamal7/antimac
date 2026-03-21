#!/bin/sh
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin

. /usr/share/runit/scripts/runit-functions.sh
. /etc/runit/config/system.conf

SERVICE1=binfmt

load_service(){
    mountpoint -q /proc/sys/fs/binfmt_misc || \
    mount -t binfmt_misc binfmt /proc/sys/fs/binfmt_misc || return 1

    for files in /proc/sys/fs/binfmt_misc/*; do
        [ "$files" = /proc/sys/fs/binfmt_misc/register ] && continue
        [ "$files" = /proc/sys/fs/binfmt_misc/status ]   && continue
        echo -1 > "$files"
    done

    for path in /usr/lib/binfmt.d /etc/binfmt.d /run/binfmt.d; do
        [ ! -d $path ] && continue
        [ -z "$(ls $path)" ] && continue
        grep -h "^:" $path/* | \
            while read -r line; do
                printf "%s" "$line" > /proc/sys/fs/binfmt_misc/register || return 1
            done
    done
    return 0
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

