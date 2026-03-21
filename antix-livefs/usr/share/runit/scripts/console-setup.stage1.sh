#!/bin/sh
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin

. /usr/share/runit/scripts/runit-functions.sh
. /etc/runit/config/system.conf

SERVICE1=console-setup

load_service() {
	TTYS=${TTYS:-6}
    _index=0
    while [ ${_index} -le $TTYS ]; do
        if [ -n "$FONT" ]; then
            setfont ${FONT_MAP:+-m $FONT_MAP} ${FONT_UNIMAP:+-u $FONT_UNIMAP} \
                    $FONT -C "/dev/tty${_index}"
        fi
        printf "\033%s" "%G" >/dev/tty${_index}
        _index=$((_index + 1))
    done
    if [ -n "$KEYMAP" ]; then
        loadkeys -q -u ${KEYMAP}
    fi
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
