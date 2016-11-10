#!/bin/bash

OPT_BENCHMARK=""
OPT_KERNEL=""
OPT_REPEAT=1
OPT_SEQUENCE=""
OPT_MEM=4096
OPT_TAG="default"

BENCHMARK_DIR=benchmark

usage()
{
	echo "$FUNCNAME: Not implemented"
	exit 0;
}

setup_options()
{
	local LONGOPTS="help,repeat:,sequence:,kernel:,benchmark:,mem:,tag:,param:,zram_size:,watchdog_sec:,periodic_log:"
	local ARGS=`getopt --longoptions $LONGOPTS -- "$@"`
	local NR_KERNELS

	while true; do
		case "$1" in
		--help)
			usage; break;;
		--repeat)
			OPT_REPEAT=$2; shift 2;;
		--sequence)
			OPT_SEQUENCE="$2"; shift 2;;
		--kernel)
			OPT_KERNEL=( "$2" ); shift 2;;
		--benchmark)
			OPT_BENCHMARK=$2; shift 2;;
		--mem)
			OPT_MEM=$2; shift 2;;
		--tag)
			OPT_TAG=$2; shift 2;;
		--param)
			OPT_KERNEL_PARAM="$2"; shift 2;;
		--zram_size)
			OPT_ZRAM_SIZE=$2; shift 2;;
		--watchdog_sec)
			OPT_WATCHDOG_SEC=$2; shift 2;;
		--periodic_log)
			local NR_LOGS=${#OPT_LOGS_PERIODIC[@]}
			OPT_LOGS_PERIODIC[$NR_LOGS]="$2"; shift 2;;
		--)
			break;;
		*)
			break;;
		esac
	done

	if [ "$OPT_KERNEL" == "" ] || [ "$OPT_BENCHMARK" == "" ]; then
		echo "Invalid argument"
		exit 1
	fi

	if [ "$OPT_SEQUENCE" == "" ]; then
		OPT_SEQUENCE=`seq -s " " 1 $OPT_REPEAT`
	fi

	OPT_JOB_FILE="$BENCHMARK_DIR/$OPT_BENCHMARK.sh"
}
