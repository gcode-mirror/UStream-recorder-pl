#!/bin/bash
DIR=`pwd`
cd "${DIR}"
for CHANNEL in `cat ${DIR}channel.txt | tr -d '\r' | grep -v "^#" | sed -e "s/http:\/\/www\.ustream\.tv\/channel\///g"` ;
do
	COMMAND="perl ustream_recorder.pl http://www.ustream.tv/channel/${CHANNEL} ${DIR}/${CHANNEL} 43200"
	LOG="ustroku_${CHANNEL}.log"

	if [ `ps -ef | grep "$COMMAND" | grep -v grep| wc -l` -gt 0 ] ; then
		echo "already running : ${COMMAND}" >> "${LOG}"
	else
		${COMMAND} >> "${LOG}"
	fi
done
