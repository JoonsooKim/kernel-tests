args = commandArgs(trailingOnly=1)

if (length(args) < 4) {
	stop("Invalid argument: We need at least 4 arguments")
}

file.type <- args[1]
file.base <- args[2]
file.compare <- args[3]
file.graph <- args[4]

col.begin <- 0
col.end <- 0
if (length(args) >= 5)
	col.begin <- as.numeric(args[5])

if (length(args) >= 6)
	col.end <- as.numeric(args[6])

if (grepl("csv", file.type)) {
	file.sep <- ","
	file.header <- 1
} else {
	file.sep <- " "
	file.header <- 0
}

color.base <- 1
color.compare <- 2

file.base
file.compare
file.graph
col.begin
col.end
file.sep
file.header

# Read Data
data.base <- read.delim2(file=file.base, header=file.header, sep=file.sep, stringsAsFactors=0)
if (is.na(data.base[1,ncol(data.base)]))
	data.base[ncol(data.base)] <- NULL
data.compare <- read.delim2(file=file.compare, header=file.header, sep=file.sep, stringsAsFactors=0)
if (is.na(data.compare[1,ncol(data.compare)]))
	data.compare[ncol(data.compare)] <- NULL

if (col.begin == 0)
	col.begin <- 1
if (col.end == 0)
	col.end <- ncol(data.base)

data.base <- data.base[,col.begin:col.end]
data.compare <- data.compare[,col.begin:col.end]

# Draw graph
if (file.header == 1) {
	col.seq <- colnames(data.base)
} else {
	col.seq <- seq.int(col.begin, col.end) - col.begin
}
col.names.base <- paste0("base-", col.seq)
col.names.compare <- paste0("compare-", col.seq)

ncol.base <- ncol(data.base)
ncol.compare <- ncol(data.compare)
nrow.base <- nrow(data.base)
nrow.compare <- nrow(data.compare)

ngraph <- col.end - col.begin + 1

options(device="png")
png(filename=file.graph, 2048, 512 * ngraph)
par(mfrow=c(ngraph,1))

for (i in 1:ncol.base) {
	matplot(data.base[,i], type="l", col=color.base)
	matlines(data.compare[,i], type="l", col=color.compare)
	mtext(col.names.base[i], line = 1, col=color.base)
	mtext(col.names.compare[i], col=color.compare)
}

dev.off()
