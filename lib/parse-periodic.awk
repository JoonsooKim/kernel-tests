# transform periodic key:value data to matrix
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
