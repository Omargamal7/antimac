#!/bin/sh

PATH=/usr/bin:/bin
MSG="System is going down in 14 seconds..."

# echo 'disabled.' ; exit
touch /run/runit.stopit
chmod 100 /run/runit.stopit && echo "$MSG" | wall
/bin/sleep 14
