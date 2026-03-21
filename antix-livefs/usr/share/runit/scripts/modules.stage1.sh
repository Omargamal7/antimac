#!/bin/sh
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin

. /usr/share/runit/scripts/runit-functions.sh
. /etc/runit/config/system.conf

SERVICE1=modules

# Silently exit if the kernel does not support modules.
[ -f /proc/modules ] || exit 0
[ -x /sbin/modprobe  ] || exit 0

load_module() {
  local module args
  module="$1"
  args="$2"
  
  modprobe $module $args > /dev/null 2>&1 || true
}

modules_files() {
  local modules_load_dirs='/etc/modules-load.d /run/modules-load.d /usr/local/lib/modules-load.d /usr/lib/modules-load.d /lib/modules-load.d'
  local processed=' '
  local add_etc_modules=true

  for dir in $modules_load_dirs; do
    [ -d $dir ] || continue
    for file in $(run-parts --list --regex='\.conf$' $dir 2> /dev/null || true); do
      local base=${file##*/}
      if echo -n "$processed" | grep -qF " $base "; then
        continue
      fi
      if [ "$add_etc_modules" -a -L $file \
	  -a "$(readlink -f $file)" = /etc/modules ]; then
        add_etc_modules=
      fi
      processed="$processed$base "
      echo $file
    done
  done

  if [ "$add_etc_modules" ]; then
    echo /etc/modules
  fi
}

load_service() {
files=$(modules_files)
if [ "$files" ] ; then
  grep -h '^[^#]' $files |
  while read module args; do
    [ "$module" ] || continue
    load_module "$module" "$args"
  done
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
