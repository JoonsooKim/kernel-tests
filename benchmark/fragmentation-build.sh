#!/bin/bash
# repeat kernel build to check fragmentation effect

DIR=Projects/remote_git/linux
THREADS=12
RETRY=3

cd $DIR
make x86_64_defconfig

for i in `seq $RETRY`; do
	make clean
	make -j$THREADS
done
