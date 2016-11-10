#!/bin/bash

source lib/benchmark.sh

main()
{
	local SEQ
	local KERNEL

	setup_options "$@"

	for SEQ in $OPT_SEQUENCE; do
		for KERNEL in ${OPT_KERNEL[@]}; do

			benchmark_begin "$KERNEL" "$SEQ"
			benchmark_do
			benchmark_end

		done;

	done
}

main "$@"
