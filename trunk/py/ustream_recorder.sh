#!/bin/bash
DATE=`date '+%Y%m%d_%H%M%S'`
export IFS=$'\n'

#DIR=`pwd`
DIR='/home/tknr/workspace/zzz_ustream-recorder/py/'
cd "${DIR}"

DSTDIR='/home/tknr/Videos/ustream'

for CHANNEL in `cat channel.txt | tr -d '\r' | grep -v "^#" | sed -e "s/http:\/\/www\.ustream\.tv\/channel\///g"` ;
do
	LOG="/var/log/crond/ustroku_${CHANNEL}.log"
	RTMPDUMP_CMD=`python ustreamRTMPDump.py http://www.ustream.tv/channel/${CHANNEL} | tail -1`
	echo "RTMPDUMP_CMD:${RTMPDUMP_CMD}"
	COMMAND="${RTMPDUMP_CMD} -o \"${DSTDIR}/${CHANNEL}/${CHANNEL}_${DATE}.flv\""
	echo "COMMAND:${COMMAND}"

	if [ `ps -ef | grep "$COMMAND" | grep -v grep | wc -l` -gt 0 ] ; then
		echo "already running : ${COMMAND}" >> "${LOG}"
	else
		echo `${COMMAND}` >> "${LOG}" &
	fi
done
