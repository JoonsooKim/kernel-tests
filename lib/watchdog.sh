#!/bin/bash

watchdog_run()
{
	local PID=$$

	if [ "$OPT_WATCHDOG_SEC" == "" ]; then
		return
	fi

	echo "$FUNCNAME: watchdog for $OPT_WATCHDOG_SEC second"
	(sleep $OPT_WATCHDOG_SEC; \
	kill $SYSTEM_PID; kill $PID; \
	echo "$FUNCNAME: watchdog triggered";) &

	WATCHDOG_PID=$!
}

watchdog_stop()
{
	if [ "$WATCHDOG_PID" == "" ]; then
		return
	fi

	kill $WATCHDOG_PID
}
