#!/bin/bash
cd "/home/tknr/workspace/zzz_ustream-recorder/"
DSTDIR="/home/tknr/Videos/ustream"
for CHANNEL in `cat channel.txt | tr -d '\r' | grep -v "^#" | sed -e "s/http:\/\/www\.ustream\.tv\/channel\///g"` ;
do
	COMMAND="perl ustroku.pl http://www.ustream.tv/channel/${CHANNEL} ${DSTDIR}/${CHANNEL} 43200 &"
	LOG="/var/log/crond/ustroku_${CHANNEL}.log"

	if [ `ps -ef | grep "$COMMAND" | grep -v grep| wc -l` -gt 0 ] ; then
		echo "already running : ${COMMAND}" >> "${LOG}"
	else
		${COMMAND} >> "${LOG}"
	fi
done
