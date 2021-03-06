#!/bin/bash

LONGOPTS="option_file:,help,repeat:,sequence:,kernel:,benchmark:,mem:,tag:,param:,zram_size:,watchdog_sec:,periodic_log:"

OPT_BENCHMARK=""
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

do_option_file()
{
	local FILE="$1"
	local COMMENT

	while read -r LINE || [[ -n "$LINE" ]]; do
		COMMENT=`echo "$LINE" | grep "^#" | wc -l`
		if [ "$COMMENT" == "1" ]; then
			continue
		fi
		eval set -- "$LINE"
		setup_option "$1" "$2"
	done < "$FILE"
}

setup_option_file()
{
	while true; do
		case "$1" in
		--option_file)
			do_option_file "$2"
			shift 2;;
		*)
			if [ "$1" == "" ]; then
				break;
			fi

			shift 1;;
		esac
	done
}

setup_option()
{
	while true; do
		case "$1" in
		--help)
			usage; break;;
		--repeat)
			OPT_REPEAT=$2; shift 2;;
		--sequence)
			OPT_SEQUENCE="$2"; shift 2;;
		--kernel)
			local NR_KERNELS=${#OPT_KERNEL[@]}
			OPT_KERNEL[$NR_KERNELS]="$2"; shift 2;;
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
		--log)
			add_log "$2"; shift 2;;
		--periodic_log)
			local NR_LOGS=${#OPT_LOGS_PERIODIC[@]}
			OPT_LOGS_PERIODIC[$NR_LOGS]="$2"; shift 2;;
		--)
			break;;
		*)
			if [ "$1" == "" ]; then
				break;
			fi

			shift 1;;
		esac
	done
}

check_option()
{
	local NR_KERNELS=${#OPT_KERNEL[@]}

	if [ "$NR_KERNELS" == "0" ] || [ "$OPT_BENCHMARK" == "" ]; then
		echo "Invalid argument"
		exit 1
	fi
}

setup_option_post()
{
	if [ "$OPT_SEQUENCE" == "" ]; then
		OPT_SEQUENCE=`seq -s " " 1 $OPT_REPEAT`
	fi

	OPT_JOB_FILE="$BENCHMARK_DIR/$OPT_BENCHMARK.sh"
}

setup_options()
{
	setup_option_file "$@"
	setup_option "$@"
	setup_option_post
	check_option
}
