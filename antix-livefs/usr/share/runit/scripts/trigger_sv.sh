#!/bin/sh
# Copyright: 2022-2024 Lorenzo Puliti <plorenzo@disroot.org>
# License: BSD-3-clause

set -e
# purge bits disabled for now
runitsvdir=$CPSV_DEST
test -n "$runitsvdir" || runitsvdir=/usr/share/runit/sv.current
defaultdir=/etc/service
# policy-rc.d layer
if [ -x /usr/sbin/policy-rc.d ]; then
	set +e ; /usr/sbin/policy-rc.d ; rc=$? ; set -e
	 if [ "$rc" = "101" ]; then
		echo "trigger action denied by policy-rc.d" && exit 0
	 fi
fi
case  ${1} in
	setup)
	    [ -e /etc/runit/verbose ] && echo "Runit triggered upgrade: ${1}"
	    mkdir -p /usr/share/runit/sv.now
	    if [ -x /etc/runit/atomic.upgrade ]; then
		/etc/runit/atomic.upgrade
	    else
		#force sv.current to point to sv.now?
		CPSV_DEST=/usr/share/runit/sv.now cpsv -f s || true
	    fi
	    separator=
	    for svpath in /etc/sv/* separator "$runitsvdir"/* ; do
		if  [ "$svpath" = 'separator' ]; then
			separator=1
			continue
		fi
		[ -r "$svpath/.meta/bin" ] || continue # rule out no binfile case
		currentsvd=${svpath%/*}
		service=${svpath##*/}
		binpath="$(cat $svpath/.meta/bin)"
		test -n $binpath || continue # rule out empty bin file
		if [ -n "$separator" ]; then
			#skip pkg sv in favor of local service in /etc/sv/
			[ -d "/etc/sv/$service" ] && continue
		fi
		if [ -x /usr/sbin/policy-rc.d ]; then
			set +e ; /usr/sbin/policy-rc.d "$service" start ; rc=$? ; set -e
			if [ "$rc" = "101" ]; then
				echo "$service: action denied by policy-rc.d" && continue
			fi
		fi
		if [ ! -e "$binpath" ] ; then #disable unless noreplace
	            [ -e "/etc/runit/runsvdir/default/$service" ] || continue # skip already disabled
		    if [ ! -e  "$svpath/.meta/noreplace" ]; then
			if [ -r "$svpath/.meta/enable" ]; then
				enable=$(cat "$svpath/.meta/enable")
				if [ "$enable" = yes ]; then
					rm -f /etc/runit/runsvdir/default/"$service"
					[ -e /etc/runit/verbose ] && echo "$service disabled"
				fi
			else
				rm -f /etc/runit/runsvdir/default/"$service"
				[ -e /etc/runit/verbose ] && echo "$service disabled"
			fi
#		         if [ -r "$runitsvdir/$service/.meta/pkg" ]; then
#		             pkgname=$(cat "$runitsvdir/$service/.meta/pkg")
#		             if ! dpkg -l "$pkgname" > /dev/null ; then
				#NAME="$service"  /lib/runit-helper/runit-helper postrm purge
#				[ -e /etc/runit/verbose ] && echo "$service purged"
#		             fi
#		         fi
		    else #noreplace
		        [ -h "/etc/runit/runsvdir/default/$service" ] && \
		        echo "please disable $service manually from a getty"
		    fi
		else # enable unless 'enble=no'
		    if [ -e "$svpath/.meta/enable" ]; then
	                enable=$(cat "$svpath/.meta/enable")
	                if [ "$enable" = yes ] && \
	                   [ ! -h "/etc/runit/runsvdir/default/.$service" ] ; then
	                      # avoid infinte loop of symlinks
	                      if [ ! -h "/etc/runit/runsvdir/default/$service" ]; then
	                         ln -sf "$svpath" "/etc/runit/runsvdir/default/$service"
	                         [ -e /etc/runit/verbose ] && echo "$service enabled"
	                         echo $(stat -c %W "$binpath") > "$svpath/.meta/wtime"
	                      fi
	                fi
		    else
		        if [ ! -h "/etc/runit/runsvdir/default/.$service" ] && \
		              [ ! -h "/etc/runit/runsvdir/default/$service" ]; then
		              ln -sf "$svpath" "/etc/runit/runsvdir/default/$service"
			      [ -e /etc/runit/verbose ] && echo "$service enabled"
			      echo $(stat -c %W "$binpath") > "$svpath/.meta/wtime"
		        fi
		    fi
		fi
		unset binpath
	    done
	    unset separator
	    # purge fallback for case: [ ! -e runitsvdir/service ] && [ -d /var/log/runit/service ] 
	    # pkg removed + not purged + system rebooted; then pkg purge happens
	    # when purge of pkg happens in a later time we have to cleanup the log directory
#	    for logdir in /var/log/runit/* ; do
#		service=$(basename "$logdir")
#		[ -d "$runitsvdir/$service" ] || continue # already covered by former loop
#		[ -r "$logdir/.pkg" ] || continue
#		pkgname=$(cat "$logdir/.pkg")
#		if ! dpkg -l "$pkgname" > /dev/null ; then
#			rm -f "/etc/runit/runsvdir/default/$service"
#			rm -f "/etc/runit/runsvdir/default/.$service"
#			[ -d "${logdir}" ] && rm -r "${logdir}"
#			[ -e /etc/runit/verbose ] && echo "$service purged (logdir fallback)"
#		fi
#	    done
	    if [ -f  /etc/runit/stopit ] && pidof runsvdir > /dev/null ; then
		kill -s ALRM 1 # force rescan to pick changes in enabled/disabled service status
	    fi
	;;
	upgrade)
	    if [ ! -f /etc/runit/stopit ] || ! pidof runsvdir > /dev/null ; then
		exit 0 # noop if runit is not init and there's no runsvdir running
	    fi
	    [ -e /etc/runit/verbose ] && echo "Runit triggered upgrade: ${1}"
	    #runitsvdir=$CPSV_DEST
	    #test -n "$runitsvdir" || runitsvdir=/usr/share/runit/sv.current
	    #defaultdir=/etc/service
	    for path in "$defaultdir"/* ; do
		[ -r "$path/.meta/bin" ] || continue #rule out no binfile
		binpath="$(cat $path/.meta/bin)"
		test -n $binpath || continue # rule out empty bin file
		[ -e "$binpath" ] || continue #still enabled due to noreplace, but binary removed
		if [ -r "$path/.meta/wtime" ]; then
			bintime="$(stat -c %W $binpath)"
			svtime="$(cat $path/.meta/wtime)"
			if [ -n "$svtime" ]; then
				# skip services non upgraded
				[ "$bintime" -le "$svtime" ] && continue
			fi
		fi
		service=${path##*/}
		if [ -x /usr/sbin/policy-rc.d ]; then
			set +e ; /usr/sbin/policy-rc.d "$service" restart ; rc=$? ; set -e
			if [ "$rc" = "101" ]; then
				echo "$service: restart action denied by policy-rc.d" && continue
			fi
		fi
		# sv restart $service   # after checking that is up + ok-pipe
		[ -p "$path/supervise/ok" ] || continue
		if [ -r "$path/.meta/onupgrade" ]; then
			onupgrade=$(cat "$path/.meta/onupgrade")
			test -n "$onupgrade" || continue
			if [ "${onupgrade}" = restart ] || [ "${onupgrade}" = reload ] ; then
				[ -e /etc/runit/debug ] && echo "sv ${onupgrade} $service"
				sv "${onupgrade}" "$service" || true
			fi
		else
			sv restart "$service" || true #fallback to restart (debhelper default)
		fi
		echo $(stat -c %W "$binpath") > "$path/.meta/wtime"
		unset binpath
		unset bintime
		unset svtime
	    done
	;;
	*)
	;;
esac
