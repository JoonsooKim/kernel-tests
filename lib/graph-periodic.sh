#!/bin/bash

# Sample Command
# bash lib/graph-periodic.sh
#	--base_dir "log/fragmentation-build/768/default/bzImage-kcompactd"
#	--input_file "fraginfo-periodic.log"
#	--compare_dir "log/fragmentation-build/768/default/bzImage-base"
#	--input_number 5
#	--output_file test.png
#	--key_index 4

source lib/options.sh

OPTGRAPH_OUTPUT_FILE=`mktemp -u`.png
OPTGRAPH_COL_BEGIN=0
OPTGRAPH_COL_END=0

setup_periodic_graph_option()
{
	while true; do
		case "$1" in
		--key_index)
			OPTGRAPH_KEY_INDEX=$2
			shift 2;;
		--base_dir)
			OPTGRAPH_BASE_DIR=$2
			shift 2;;
		--compare_dir)
			OPTGRAPH_COMPARE_DIR=$2
			shift 2;;
		--input_file)
			OPTGRAPH_INPUT_FILE=$2
			shift 2;;
		--input_number)
			OPTGRAPH_INPUT_NUMBER=$2
			shift 2;;
		--base_files)
			OPTGRAPH_BASE_FILES="$2"
			shift 2;;
		--compare_files)
			OPTGRAPH_COMPARE_FILES="$2"
			shift 2;;
		--output_file)
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

setup_periodic_graph_files()
{
	local DIR=$1
	local FILE
	local FILES
	local I

	for I in `seq 1 $OPTGRAPH_INPUT_NUMBER`; do
		FILE=$DIR/$I/$OPTGRAPH_INPUT_FILE
		if [ -f $FILE ]; then
			FILES="$FILES $FILE"
		fi
	done

	echo "$FILES"
}

setup_periodic_graph_option_post()
{
	if [ "$OPTGRAPH_INPUT_FILE" == "" ]; then
		return
	fi

	if [ "$OPTGRAPH_INPUT_NUMBER" == "" ]; then
		return
	fi

	if [ "$OPTGRAPH_BASE_DIR" != "" ]; then
		OPTGRAPH_BASE_FILES=`setup_periodic_graph_files $OPTGRAPH_BASE_DIR`
	fi

	if [ "$OPTGRAPH_COMPARE_DIR" != "" ]; then
		OPTGRAPH_COMPARE_FILES=`setup_periodic_graph_files $OPTGRAPH_COMPARE_DIR`
	fi

	if [ "$OPTGRAPH_BASE_FILES" == "" ] || [ "$OPTGRAPH_COMPARE_FILES" == "" ]; then
		echo "Invalid input"
		exit 1
	fi
}

normalize_data()
{
	local FILE=$1
	local KEY_IDX=$2
	local NORMALIZED_FILE

	NORMALIZED_FILE=`mktemp`
	awk -v KEY_IDX=$KEY_IDX '
	{
		if (match($1, /DATE:/)) {
			print $0
			next
		}

		for (i = KEY_IDX + 1; i <= NF; i++) {
			if (match($i, /^[0-9]+$/) ||
				match($i, /^[0-9]+[.][0-9]+$/)) {
				printf ("%s-V%d %s\n", $KEY_IDX, i, $i)
			}
		}
	}
	' $FILE > $NORMALIZED_FILE

	echo $NORMALIZED_FILE
}

normalize_files()
{
	local FILES="$1"
	local KEY_IDX=$2
	local FILE
	local NORMALIZED_FILE
	local NORMALIZED_FILES

	if [ "$KEY_IDX" == "" ]; then
		echo "$FILES"
		return
	fi

	for FILE in $FILES; do
		NORMALIZED_FILE=`normalize_data $FILE $KEY_IDX`
		NORMALIZED_FILES="$NORMALIZED_FILES $NORMALIZED_FILE"
	done

	echo $NORMALIZED_FILES
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
			if (match($i, /^[0-9]+$/) ||
				match($i, /^[0-9]+[.][0-9]+$/)) {
				sum += strtonum($i)
				count++
			}
		}
		printf (" %f\n", sum/count)
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
		grep -e "DATE:" $GREP_OP $FILE > $FILTERED_FILE
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
	setup_periodic_graph_option_post

	echo "OPTGRAPH_BASE_FILES: $OPTGRAPH_BASE_FILES"
	echo "OPTGRAPH_COMPARE_FILES: $OPTGRAPH_COMPARE_FILES"
}

setup_graph_options "$@"

GRAPH_BASE_NORMALIZED_FILES=`normalize_files "$OPTGRAPH_BASE_FILES" $OPTGRAPH_KEY_INDEX`
GRAPH_BASE_FILE=`paste_data "$GRAPH_BASE_NORMALIZED_FILES"`
GRAPH_BASE_FILE=`average_data $GRAPH_BASE_FILE`
GRAPH_BASE_FILE=`filtered_data $GRAPH_BASE_FILE "$OPTGRAPH_GREP_OPTION"`
GRAPH_BASE_FILE=`transform_data $GRAPH_BASE_FILE`

GRAPH_COMPARE_NORMALIZED_FILES=`normalize_files "$OPTGRAPH_COMPARE_FILES" $OPTGRAPH_KEY_INDEX`
GRAPH_COMPARE_FILE=`paste_data "$GRAPH_COMPARE_NORMALIZED_FILES"`
GRAPH_COMPARE_FILE=`average_data $GRAPH_COMPARE_FILE`
GRAPH_COMPARE_FILE=`filtered_data $GRAPH_COMPARE_FILE "$OPTGRAPH_GREP_OPTION"`
GRAPH_COMPARE_FILE=`transform_data $GRAPH_COMPARE_FILE`


echo "Graph will be generated at $OPTGRAPH_OUTPUT_FILE"
Rscript lib/graph-line.R csv $GRAPH_BASE_FILE $GRAPH_COMPARE_FILE $OPTGRAPH_OUTPUT_FILE $OPTGRAPH_COL_BEGIN $OPTGRAPH_COL_END
