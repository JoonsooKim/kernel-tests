#!/bin/bash

source "lib/system.sh"
source "lib/options.sh"

DIR=result-fragmentation-$BENCH_TYPE

# "name,cmd" for each entry
LOGS=( "vmstat, cat /proc/vmstat" "meminfo, cat /proc/meminfo"	\
	"pagetypeinfo, cat /proc/pagetypeinfo" "dmesg, sudo dmesg -c" )

dump_env()
{
	echo "-----------------------"
	echo "REPEAT: $OPT_REPEAT"
	echo "SEQUENCE: $OPT_SEQUENCE"
	echo "KERNEL: $OPT_KERNEL"
	echo "BENCHMARK: $OPT_BENCHMARK"
	echo "MEM: $OPT_MEM"
	echo "TAG: $OPT_TAG"
	echo "KERNEL_PARAM: $OPT_KERNEL_PARAM"
	echo "ZRAM_SIZE: $OPT_ZRAM_SIZE"
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
}
