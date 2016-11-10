#!/bin/bash

QEMU_DIR=qemu-img
SYSTEM_DIR=$HOME/$QEMU_DIR
SYSTEM_REDIR_PORT=5555

exec_cmd()
{
	local CMD="$1"

	ssh localhost -p $SYSTEM_REDIR_PORT "$CMD" | tee -a "$LOG_BENCHMARK"
}

exec_cmd_silent()
{
	local CMD="$1"

	ssh localhost -p $SYSTEM_REDIR_PORT "$CMD"
}

exec_sudo_echo()
{
	local CONTENT="$1"
	local FILE="$2"
	local OPTION="$3"

	ssh localhost -p $SYSTEM_REDIR_PORT \
		"echo $CONTENT | sudo tee $OPTION $FILE > /dev/null" | \
		tee -a "$LOG_BENCHMARK"
}

push_file()
{
	local SRC_PATH="$1"
	local DST_PATH_TMP="$2"
	local DST_PATH

	if [ "$DST_PATH_TMP" == "" ]; then
		DST_PATH="localhost:."
	else
		DST_PATH="localhost:$DST_PATH_TMP"
	fi

	scp -r -P $SYSTEM_REDIR_PORT "$SRC_PATH" "$DST_PATH"
}

check_system()
{
	local NR_RUNNING
	# Testing QEMU system will open 5555 port for ssh
	local PORT=5555

	NR_RUNNING=`ps aux | grep qemu-system | grep ubuntu | grep $PORT | wc -l`

	if [ "$NR_RUNNING" != "0" ]; then
		return 1
	fi

	return 0
}

check_ssh()
{
	local I

	check_system
	if [ "$?" == "0" ]; then
		return 0
	fi

	for I in {1..20}; do
		ssh localhost -p $SYSTEM_REDIR_PORT -o ConnectionAttempts=1 -o ConnectTimeout=1	exit &> /dev/null

		if [ "$?" == "0" ]; then
			return 1
		fi

		sleep 1
	done

	return 0
}

kill_system()
{
	local PID=$1
	if [ "$PID" != "" ]; then
		kill "$PID"
		return
	fi

	# Testing QEMU system will open 5555 port for ssh
	PID=5555

	PID=`ps aux | grep qemu-system | grep ubuntu | grep $PID | awk '{print $2}'`
	echo "$FUNCNAME: $PID"
	kill "$PID"
}

run_system()
{
	local I
	local KERNEL="$1"
	local IS_RUNNING

	# wait 5 sec
	for I in {1..5}; do
		check_system
		IS_RUNNING=$?
		if [ "$IS_RUNNING" == "0" ]; then
			break;
		fi

		sleep 1
	done

	check_system
	IS_RUNNING=$?
	if [ "$IS_RUNNING" == "1" ]; then
		kill_system
		sleep 3

		check_system
		IS_RUNNING=$?
		if [ "$IS_RUNNING" == "1" ]; then
			echo "$FUNCNAME: fail: exist previuos system"
			exit 1
		fi
	fi

	pushd $PWD &> /dev/null
	cd $SYSTEM_DIR;
	bash boot-common.sh "x86" "$KERNEL" "$OPT_MEM" "$OPT_KERNEL_PARAM" &> /dev/null &
	SYSTEM_PID=$!
	popd &> /dev/null

	for I in {1..5}; do
		check_system
		IS_RUNNING=$?
		if [ "$IS_RUNNING" == "1" ]; then
			break;
		fi

		sleep 1
	done

	check_ssh
	if [ "$?" == "0" ]; then
		echo "$FUNCNAME: fail: ssh connection"
		exit 1
	fi
}

shutdown_system()
{
	local I
	local IS_RUNNING

	exec_cmd "sudo shutdown -h now"
	for I in {1..10}; do
		check_system
		if [ "$?" == "0" ]; then
			echo "$FUNCNAME: shutdown system"
			return
		fi

		sleep 1
	done

	echo "$FUNCNAME: fail: shutdown system"
	echo "$FUNCNAME: try kill"

	kill_system
}

