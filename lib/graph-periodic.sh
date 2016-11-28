#!/bin/bash

source lib/options.sh

OPTGRAPH_TYPE=csv
OPTGRAPH_OUTPUT_FILE=`mktemp -u`.png
OPTGRAPH_COL_BEGIN=0
OPTGRAPH_COL_END=0

setup_periodic_graph_option()
{
	while true; do
		case "$1" in
		--type)
			OPTGRAPH_TYPE=$2
			shift 2;;
		--base_files)
			OPTGRAPH_BASE_FILES="$2"
			shift 2;;
		--compare_files)
			OPTGRAPH_COMPARE_FILES="$2"
			shift 2;;
		--ouput_file)
			OPTGRAPH_OUTPUT_FILE=$2
			shift 2;;
		--column_begin)
			OPTGRAPH_COL_BEGIN=$2
			shift 2;;
		--column_end)
			OPTGRAPH_COL_END=$2
			shift 2;;
		--grep_option)
			OPTGRAPH_GREP_OPTION="$2"
			shift 2;;
		*)
			if [ "$1" == "" ]; then
				break;
			fi

			shift 1;;
		esac
	done
}

paste_data()
{
	local FILES="$1"
	local PASTED_FILE

	PASTED_FILE=`mktemp`
	paste $FILES > $PASTED_FILE

	echo $PASTED_FILE
}

average_data()
{
	local FILE="$1"
	local AVERAGE_FILE

	AVERAGE_FILE=`mktemp`
	awk '
		{
			if (match($1, /DATE:/)) {
				print $1 " " $2
				next
			}

			printf ("%s", $1)

			count = 0
			sum = 0
			for (i = 2; i <= NF; i++) {
				if (match($i, /^[0-9]+$/)) {
					sum += strtonum($i)
					count++
				}
			}
			printf (" %d\n", sum/count)
		}
	' $FILE > $AVERAGE_FILE

	echo $AVERAGE_FILE
}

filtered_data()
{
	local FILE=$1
	local GREP_OP="$2"
	local FILTERED_FILE

	if [ "$GREP_OP" == "" ]; then
		echo $FILE
		return
	else
		FILTERED_FILE=`mktemp`
		grep -e "DATE:" $GREP_OP $PASTED_FILE > $FILTERED_FILE
	fi

	echo $FILTERED_FILE
}

# transform_data: transform periodic key:value data to matrix
#
# From
# Period-1
# key1: value1-1
# key2: value2-1
# Period-2
# key1: value1-2
# key2: value2-2
#
# To
# Period1: value1-1 value2-1
# Period2: value1-2 value2-2
transform_data()
{
	local FILE=$1
	local DST_FILE

	DST_FILE=`mktemp`
	awk '
	{
		if ($1 == "DATE:") {
			period = strtonum($2)
			if (period_min == "" || period_min > period)
				period_min = period
			if (period_max == "" || period_max < period)
				period_max = period
			row = 0
			next
		}

		data[period][$1] = strtonum($2)
		col_name[row++] = $1
	}

	END {
		for (i = 0; i < row; i++) {
			if (i != 0)
				printf(",")
			printf("%s", col_name[i])
		}
		printf("\n")

		for (i = period_min; i <= period_max; i++) {
			head = 1

			for (j = 0; j < row; j++) {
				col = col_name[j]
				if (head != 1)
					printf(",")
				printf("%s", data[i][col])
				head = 0
			}

			printf("\n")
		}
	}
	' $FILE > $DST_FILE

	echo $DST_FILE
}

setup_graph_options()
{
	setup_option_file "$@"
	setup_periodic_graph_option "$@"
}

setup_graph_options "$@"

echo "OPTGRAPH_BASE_FILES: $OPTGRAPH_BASE_FILES"
GRAPH_BASE_FILE=`paste_data "$OPTGRAPH_BASE_FILES"`
GRAPH_BASE_FILE=`average_data $GRAPH_BASE_FILE`
GRAPH_BASE_FILE=`filtered_data $GRAPH_BASE_FILE "$OPTGRAPH_GREP_OPTION"`
GRAPH_BASE_FILE=`transform_data $GRAPH_BASE_FILE`

echo "OPTGRAPH_COMPARE_FILES: $OPTGRAPH_COMPARE_FILES"
GRAPH_COMPARE_FILE=`paste_data "$OPTGRAPH_COMPARE_FILES"`
GRAPH_COMPARE_FILE=`average_data $GRAPH_COMPARE_FILE`
GRAPH_COMPARE_FILE=`filtered_data $GRAPH_COMPARE_FILE "$OPTGRAPH_GREP_OPTION"`
GRAPH_COMPARE_FILE=`transform_data $GRAPH_COMPARE_FILE`


echo "Graph will be generated at $OPTGRAPH_OUTPUT_FILE"
Rscript lib/graph-line.R $OPTGRAPH_TYPE $GRAPH_BASE_FILE $GRAPH_COMPARE_FILE $OPTGRAPH_OUTPUT_FILE $OPTGRAPH_COL_BEGIN $OPTGRAPH_COL_END
