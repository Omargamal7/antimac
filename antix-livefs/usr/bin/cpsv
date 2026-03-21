#!/bin/sh
#cpsv - utility to install and manage runscripts

# Copyright: 2022-2024 Lorenzo Puliti <plorenzo@disroot.org>
# License: BSD-3-clause
set -e

err() { >&2 printf '%s\n\n' "$*"; exit 1; }
fatal() { err "${0##*/}: fatal: $*"; }
warn() { >&2 printf '%s\n' "${0##*/}: warning: $*"; }
usage() {
  err "Usage: ${0##*/} [ -f ] a  <service> [<service-2> <service-3> ... ]
       ${0##*/} p  <service>
       ${0##*/} d  <service>
       ${0##*/} [ -f ] s
       ${0##*/} l"
}

if [ $# -eq 0 ]; then
	warn "wrong syntax"  && usage
fi

rcode=0
runitsvdir=$CPSV_DEST
test -n "$runitsvdir" || runitsvdir=/etc/sv
test -d "$runitsvdir" || fatal "${0##*/} $runitsvdir : not a directory"
cpsvsrc=$CPSV_SOURCE
test -n "$cpsvsrc" || cpsvsrc=/usr/share/runit/sv.src
test -d "$cpsvsrc" || fatal "${0##*/} $cpsvsrc : not a directory"
#if [ "$(id -u)" = 0 ] ; then # TODO user instances
sysvdir=/etc/init.d
systemdsvdir=/lib/systemd/system
systemdetcdir=/etc/systemd/system

make_svlinks() {
	service="$1"
	if [ ! -h "$runitsvdir/$service/supervise" ] && [ ! -d "$runitsvdir/$service/supervise" ]; then
		ln -s /run/runit/supervise/"$service" "$runitsvdir/$service/supervise"
	fi
	if [ -e "$runitsvdir/$service/.meta/finish" ] && [ ! -e "$runitsvdir/$service/finish" ]; then
		ln -s /lib/runit/finish-exec "$runitsvdir/$service/finish"
	fi
	if [ -d "$runitsvdir/$service/log" ]; then
		if [ ! -h "$runitsvdir/$service/log/supervise" ] && [ ! -d "$runitsvdir/$service/log/supervise" ]; then
			ln -s /run/runit/supervise/"$service".log "$runitsvdir/$service"/log/supervise
		fi
		if [ ! -e "$runitsvdir/$service/log/run" ]; then
			ln -s /etc/sv/svlogd/run "$runitsvdir/$service/log/run"
		elif [ -h "$runitsvdir/$service/log/run" ]; then
			if [ -n "$force" ] && [ ! -e "$cpsvsrc/$service/log/run" ]; then
				rm "$runitsvdir/$service/log/run"
				ln -s /etc/sv/svlogd/run "$runitsvdir/$service/log/run"
			fi
		fi
	fi
}

sv_diff() {
	service="$1"
	retdiff=0
	exclude='--exclude=supervise --exclude=conf --exclude=wtime --exclude=log'
	if ! diff -Naur --color $exclude "$cpsvsrc/$service" "$runitsvdir/$service"; then
		retdiff=1
	fi
	if [ -e "$cpsvsrc/$service/log/run" ] || [ -d "$runitsvdir/$service/log" ]; then
		if [ ! -d "$cpsvsrc/$service/log" ]; then
			if ! diff -Naur --color --exclude=supervise "$cpsvsrc/$service/log" "$runitsvdir/$service/log"; then
				retdiff=1
			fi
		fi
	else
		if [ -d "$cpsvsrc/$service/log" ]; then
			if ! diff -Naur --color "/etc/sv/svlogd/run" "$runitsvdir/$service/log/run"; then
				retdiff=1
			fi
			if ! diff -Naur --color --exclude=supervise --exclude=run "$cpsvsrc/$service/log" "$runitsvdir/$service/log"; then
				retdiff=1
			fi
		fi
	fi
	return "$retdiff"
}

cp_sv() {
	service="$1"
	if [ -d "$runitsvdir/$service" ]; then
		if ! sv_diff "$service" >/dev/null ; then
			if [ -n "$force" ]; then
				cp -a "$cpsvsrc/$service" "$runitsvdir/"
				make_svlinks "$service"
			else
				warn "skipping $service, local version exists, use -f to overwrite" \
				&& rcode=$((rcode+1))
			fi
		fi
	else
		cp -a "$cpsvsrc/$service" "$runitsvdir/"
		make_svlinks "$service"
	fi
}

loop_cpsv() {
	for dir in "$cpsvsrc"/* ; do
		stocksv=${dir##*/}
		if [ -e "$systemdsvdir/$stocksv.service" ] || [ -x "$sysvdir/$stocksv" ]; then
			cp_sv "$stocksv"
		else
			if [ -r "$cpsvsrc/$stocksv/.meta/bin" ]; then
				binpath="$(cat $cpsvsrc/$stocksv/.meta/bin)"
				test -n "$binpath" || continue
				if [ -e "$binpath" ]; then
					cp_sv "$stocksv"
				fi
			fi
		fi
	done
}

loop_listsv() {
	for dir in "$cpsvsrc"/* ; do
		service=${dir##*/}
		status=
		if [ -e "$systemdsvdir/$service.service" ] || [ -x "$sysvdir/$service" ]; then
			if [ ! -d "$runitsvdir/$service" ]; then
				status='[a]' #available, not installed in /etc/sv/
			elif ! sv_diff "$service" >/dev/null ; then
				status='[l]' #installed but is local version
			else
				status='[i]' # installed, package version
			fi
		elif [ -r "$cpsvsrc/$service/.meta/bin" ]; then
			binpath="$(cat $cpsvsrc/$service/.meta/bin)"
			if [ -n "$binpath" ] && [ -e "$binpath" ]; then
				if [ ! -d "$runitsvdir/$service" ]; then
					status='[a]' #available, not installed in /etc/sv/
				elif ! sv_diff "$service" >/dev/null ; then
					status='[l]' #installed but is local version
				else
					status='[i]' # installed, package version
				fi
			else
				if [ -d "$runitsvdir/$service" ]; then
					status='[p]' #purged
				else
					continue
				fi
			fi
		else
			if [ -d "$runitsvdir/$service" ] && [ ! -e "$systemdetcdir/$service.service" ]; then
				#purged: inaccurate for sysv only services
				status='[p]'
			else
				continue
			fi
		fi
		echo "$status: $service"
	done
}

while [ $# -gt 0 ]; do
	case $1 in
		a)
		test "$(id -u)" = 0 || fatal "${0##*/} -a must be run by root."
		[ -n "$opt" ] && warn "wrong syntax"  && usage
		[ -z "$2" ] && warn "wrong syntax"  && usage
		add=1
		opt=1
		shift
		;;
		-f)
		force=1
		shift
		;;
#		-r)
#		#TODO replace/swap instead of overwrite (like in -f) the service dir
#		replace=1
#		shift
#		;;
		p)
		test "$(id -u)" = 0 || fatal "${0##*/} -a must be run by root."
		[ -n "$opt" ] && warn "wrong syntax"  && usage
		[ -z "$2" ] && warn "wrong syntax"  && usage
		[ -n "$3" ] && warn "wrong syntax"  && usage
		simlink=1
		opt=1
		shift
		;;
		d)
		[ -n "$opt" ] && warn "wrong syntax"  && usage
		[ -z "$2" ] && warn "wrong syntax"  && usage
		[ -n "$3" ] && warn "wrong syntax"  && usage
		diff=1
		opt=1
		shift
		;;
		l|--list)
		[ -n "$opt" ] && warn "wrong syntax"  && usage
		[ -n "$2" ] && warn "wrong syntax"  && usage
		list=1
		opt=1
		shift
		;;
		s|--sync)
		test "$(id -u)" = 0 || fatal "${0##*/} --sync must be run by root."
		[ -n "$opt" ] && warn "wrong syntax"  && usage
		[ -n "$2" ] && warn "wrong syntax"  && usage
		sync=1
		opt=1
		shift
		;;
#		-u)
		#TODO: user instances, needs support in runit, see mk-runscript
#		shift
#		user="${1}"
#		shift
#		;;
		-*|--*)
		warn "unknown option $1" && usage
		;;
		*)
		break
		;;
	esac
done

#extra syntax check
[ -z "$opt" ] && warn "wrong syntax" && usage

if [ -n "$diff" ]; then
	[ -n "$force" ] && warn "wrong syntax"  && usage
	[ ! -d "$cpsvsrc/$1" ] && fatal "no stock service found for $1"
	sv_diff "$1"
	exit
fi
if [ -n "$simlink" ]; then
	[ -n "$force" ] && warn "wrong syntax"  && usage
	[ ! -d "$runitsvdir/$1" ] && fatal "no service found for $1"
	make_svlinks "$1"
	exit 0
fi
if [ -n "$list" ]; then
	[ -n "$force" ] && warn "wrong syntax"  && usage
	loop_listsv
	exit 0
fi
if [ -n "$sync" ]; then
	loop_cpsv
	exit "$rcode"
fi
#add
for arg in "$@"; do
	if [ ! -d "$cpsvsrc/$arg" ]; then
		warn "no stock service found for $arg"
		rcode=$((rcode+1))
	else
		cp_sv "$arg"
	fi
	shift
done

exit "$rcode"
