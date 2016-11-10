#!/bin/bash

source lib/system.sh
source lib/options.sh
source lib/log.sh
source lib/watchdog.sh

setup_swap_zram()
{
	if [ "$OPT_ZRAM_SIZE" == "" ]; then
		return;
	fi

	exec_cmd "sudo swapoff -a"
	exec_sudo_echo "32" "/sys/block/zram0/max_comp_streams"
	exec_sudo_echo "$OPT_ZRAM_SIZE" "/sys/block/zram0/disksize"
	exec_cmd "sudo mkswap /dev/zram0"
	exec_cmd "sudo swapon /dev/zram0"
}

setup_system()
{
	setup_swap_zram
}

benchmark_begin()
{
	local KERNEL="$1"
	local LOG_PREFIX="$2"

	if [ "$1" == "" ]; then
		echo "$FUNCNAME: fail: no kernel"
		exit 1;
	fi

	if [ "$LOG_PREFIX" == "" ]; then
		LOG_PREFIX="unknown"
	fi

	watchdog_run
	setup_log_system "$KERNEL" "$LOG_PREFIX"
	run_system $KERNEL
	setup_system
	dump_log begin
}

benchmark_do()
{
	echo "$FUNCNAME: $JOB_FILE"

	push_file "$OPT_JOB_FILE" "$OPT_JOB_FILE"
	exec_cmd "bash $OPT_JOB_FILE"
}

benchmark_end()
{
	dump_log end
	shutdown_system
	watchdog_stop
}
