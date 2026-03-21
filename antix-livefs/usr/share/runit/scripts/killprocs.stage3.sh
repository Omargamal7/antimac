#!/bin/sh
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin

. /usr/share/runit/scripts/runit-functions.sh
. /etc/runit/config/system.conf

SERVICE1=killprocs

unload_service(){

. /usr/share/runit/scripts/init-functions.sh

# Kill all processes.
log_action_begin_msg "Asking all remaining processes to terminate"
killall5 -15 # SIGTERM
log_action_end_msg 0
alldead=""
for seq in 1 2 3 4 5 6 7 8 9 10; do
	# use SIGCONT/signal 18 to check if there are
	# processes left.  No need to check the exit code
	# value, because either killall5 work and it make
	# sense to wait for processes to die, or it fail and
	# there is nothing to wait for.
		
	if killall5 -18 ; then
		    :
	else
		   alldead=1
		   break
	fi

	sleep 1
done
if [ -z "$alldead" ] ; then
	   log_action_begin_msg "Killing all remaining processes"
	   killall5 -9 # SIGKILL
	   log_action_end_msg 1
else
	   log_action_begin_msg "All processes ended within $seq seconds."
	   log_action_end_msg 0
fi
}

# MAIN STOP
stat_busy "Stopping $SERVICE1"
unload_service || stat_die $SERVICE1
rm_daemon $SERVICE1
stat_done $SERVICE1
