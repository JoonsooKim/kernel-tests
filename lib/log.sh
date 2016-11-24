#!/bin/bash

source "lib/system.sh"
source "lib/options.sh"

DIR=result-fragmentation-$BENCH_TYPE

# "name,cmd" for each entry
LOGS=( "vmstat, cat /proc/vmstat" "meminfo, cat /proc/meminfo"	\
	"pagetypeinfo, cat /proc/pagetypeinfo" "dmesg, sudo dmesg -c" )

dump_env()
{
	local I
	local NR
	local ENTRY

	echo "-----------------------"
	echo "REPEAT: $OPT_REPEAT"
	echo "SEQUENCE: $OPT_SEQUENCE"

	NR=${#OPT_KERNEL[@]}
	for I in `seq 0 $(($NR-1))`; do
		ENTRY=${OPT_KERNEL[$I]}
		echo "KERNEL: $ENTRY"
	done

	echo "BENCHMARK: $OPT_BENCHMARK"
	echo "MEM: $OPT_MEM"
	echo "TAG: $OPT_TAG"
	echo "KERNEL_PARAM: $OPT_KERNEL_PARAM"
	echo "ZRAM_SIZE: $OPT_ZRAM_SIZE"
	echo "WATCHDOG_SEC: $OPT_WATCHDOG_SEC"

	NR=${#OPT_LOGS_PERIODIC[@]}
	for I in `seq 0 $(($NR-1))`; do
		ENTRY=${OPT_LOGS_PERIODIC[$I]}
		echo "PERIODIC_LOG: $ENTRY"
	done

	echo -e "-----------------------\n"
}

record_env()
{
	dump_env > $LOG_ENV
	cat "$OPT_JOB_FILE" >> $LOG_ENV
}

setup_log_system()
{
	local KERNEL="$1"
	local PREFIX="$2"

	LOG_DIR="$PWD/log/$OPT_BENCHMARK/$OPT_MEM/$OPT_TAG/$KERNEL/$PREFIX"
	mkdir -p $LOG_DIR &> /dev/null
	LOG_ENV="$LOG_DIR/env.log"
	LOG_BENCHMARK="$LOG_DIR/benchmark.log"
	LOG_PERIODIC="$LOG_DIR/*-periodic.log"

	clear_log
	dump_env
	record_env
}

setup_log_file()
{
	local ENTRY=$1
	local POSTFIX=$2

	LOG_NAME=`echo $ENTRY | tr "," "\n" | sed 's/^[ \t]*//' | head -n1`
	LOG_CMD=`echo $ENTRY | tr "," "\n" | sed 's/^[ \t]*//' | tail -n1`
	LOG_FILE=$LOG_DIR/$LOG_NAME-$POSTFIX.log
}

add_log()
{
	local NR_LOGS=${#LOGS[@]}

	LOGS[$NR_LOGS]=$1
}

dump_log()
{
	local I
	local ENTRY
	local POSTFIX=$1
	local NR_LOGS=${#LOGS[@]}

	for I in `seq 0 $(($NR_LOGS-1))`; do
		ENTRY=${LOGS[$I]}
		setup_log_file "$ENTRY" $POSTFIX
		exec_cmd_silent "$LOG_CMD" > $LOG_FILE
	done
}

clear_log()
{
	local I
	local ENTRY
	local NR_LOGS=${#LOGS[@]}

	for I in `seq 0 $(($NR_LOGS-1))`; do
		ENTRY=${LOGS[$I]}
		setup_log_file "$ENTRY" "*"
		rm -f $LOG_FILE
	done
	rm -f $LOG_ENV
	rm -f $LOG_BENCHMARK
	rm -f $LOG_PERIODIC
}

periodic_log()
{
	local INTERVAL="$1"
	local ENTRY="$2"
	local PID
	local NR_LOGS

	setup_log_file "$ENTRY" "periodic"
	exec_cmd_silent "while sleep $INTERVAL; do echo -n 'DATE: '; date +%s; $LOG_CMD; done" > $LOG_FILE &

	PID=$!
	NR_LOGS=${#LOGS_PERIODIC_PID[@]}
	LOGS_PERIODIC_PID[$NR_LOGS]=$PID
}

periodic_log_run()
{
	local I
	local NR_LOGS=${#OPT_LOGS_PERIODIC[@]}
	local ENTRY

	for I in `seq 0 $(($NR_LOGS-1))`; do
		ENTRY=${OPT_LOGS_PERIODIC[$I]}
		periodic_log 1 "$ENTRY"
	done
}

periodic_log_stop()
{
	local I
	local PID
	local NR_LOGS=${#LOGS_PERIODIC_PID[@]}

	for I in `seq 0 $(($NR_LOGS-1))`; do
		PID=${LOGS_PERIODIC_PID[$I]}
		kill $PID
	done

	sleep 1
}
