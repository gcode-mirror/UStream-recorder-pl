#!/bin/bash
DATE=`date '+%Y%m%d_%H%M%S'`
export IFS=$'\n'

#DIR=`pwd`
#cd "${DIR}"

DIR='/home/tknr/Videos/ustream'
for CHANNEL in `cat ${DIR}channel.txt | tr -d '\r' | grep -v "^#" | sed -e "s/http:\/\/www\.ustream\.tv\/channel\///g"` ;
do
	COMMAND="python ustreamRTMPDump.py http://www.ustream.tv/channel/${CHANNEL} | tail -1"
	COMMAND="${COMMAND} -o ${DIR}/${CHANNEL}/${CHANNEL}_${DATE}.flv -B 43200"
	LOG="/var/log/crond/ustroku_${CHANNEL}.log"

	if [ `ps -ef | grep "$COMMAND" | grep -v grep| wc -l` -gt 0 ] ; then
		echo "already running : ${COMMAND}" >> "${LOG}"
	else
		${COMMAND} >> "${LOG}"
	fi
done
