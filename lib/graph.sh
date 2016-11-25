TYPE=$1
SRC_FILE1=$2
SRC_FILE2=$3
GRAPH_FILE=$4
COL_BEGIN=$5
COL_END=$6
GREP_OP="$7"

# sample command
# bash lib/graph.sh "csv" periodic-FILE1 periodic-FILE2 OUTPUT.png

if [ "$SRC_FILE1" == "" ] || [ "$SRC_FILE2" == "" ]; then
	echo "Invalid argument"
	exit 1;
fi

if [ "$TYPE" == "" ]; then
	TYPE=txt
fi

if [ "$GRAPH_FILE" == "" ]; then
	GRAPH_FILE=`mktemp -u`
	GRAPH_FILE=$GRAPH_FILE".png"
fi

if [ "$COL_BEGIN" == "" ]; then
	COL_BEGIN=0
fi

if [ "$COL_END" == "" ]; then
	COL_END=0
fi

if [ "$GREP_OP" == "" ]; then
	FILTERED_FILE1=$SRC_FILE1
	FILTERED_FILE2=$SRC_FILE2
else
	FILTERED_FILE1=`mktemp`
	FILTERED_FILE2=`mktemp`
	grep -e "DATE:" $GREP_OP $SRC_FILE1 > $FILTERED_FILE1
	grep -e "DATE:" $GREP_OP $SRC_FILE2 > $FILTERED_FILE2
fi


PARSED_FILE1=`mktemp`
PARSED_FILE2=`mktemp`
awk -f lib/parse-periodic.awk $FILTERED_FILE1 > $PARSED_FILE1
awk -f lib/parse-periodic.awk $FILTERED_FILE2 > $PARSED_FILE2

echo "Graph will be generated at $GRAPH_FILE"
Rscript lib/graph-line.R $TYPE $PARSED_FILE1 $PARSED_FILE2 $GRAPH_FILE $COL_BEGIN $COL_END
