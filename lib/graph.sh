#!/bin/bash

gnuplot_exec()
{
# Order of argument
# 1. Input file 1
# 2. Input file 2
# 3. Output file
# 4. Title Prefix
# 5. Title Postfix for input file 1
# 6. Title Postfix for input file 2
# 7. Data column, Begin
# 8. Data column, End

	local ARG1="$1"
	local ARG2="$2"
	local ARG3="$3"
	local ARG4="$4"
	local ARG5="$5"
	local ARG6="$6"
	local ARG7="$7"
	local ARG8="$8"

	gnuplot -e "arg1='${ARG1}'; arg2='${ARG2}'; arg3='${ARG3}'; \
		arg4='${ARG4}'; arg5='${ARG5}'; arg6='${ARG6}'; \
		arg7='${ARG7}'; arg8='${ARG8}'" graph.gpi
}
