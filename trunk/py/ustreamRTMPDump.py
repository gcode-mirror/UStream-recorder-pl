#!/usr/bin/env python
# This script finds the rtmpdump command syntax for opening a UStream stream.
# http://www.tech-juice.org/2012/05/20/how-to-play-ustream-channels-in-vlc/
 
import sys
import urllib2
import re
 
 
def getVideoData(url):
    # Get the HTML contents
    req = urllib2.Request(url)
    response = urllib2.urlopen(req)
    html = response.read()
 
    # Extract the channel ID from the HTML
    channelId = None
    m = re.search("Channel\sID\:\s+(\d+)", html)
    if (m):
        channelId = m.group(1)
	print "channelId:" + channelId
 
    # Extract the channel title from the HTML
    channelTitle = None
    m = re.search("property\=\"og\:url\"\s+content\=\"http\:\/\/www." +
            "ustream\.tv\/(?:channel\/)?([^\"]+)\"", html)
    if (m):
        channelTitle = m.group(1)
	print "channelTitle:" + channelTitle
 
    amfContent = None
    if (channelId):
        amfUrl = ("http://cdngw.ustream.tv/Viewer/getStream/1/"
        + channelId + ".amf")

	print "amfUrl:" + amfUrl

        response = urllib2.urlopen(amfUrl)
        amfContent = response.read()
 
	print "amfContent:" + amfContent + "\n"

        rtmpUrl = re.search("(rtmp\:\/\/[^\x00]+)", amfContent).group(1)
        f = open('tmp.txt', 'w')
        f.write(amfContent)
        streamName = re.search("streamName(?:\W+)([^\x00]+)",
                amfContent).group(1)
 
    return (channelId, channelTitle, rtmpUrl, streamName)
 
 
def getRtmpCommand(rtmpUrl, streamName):
    result = ("rtmpdump -v -r \"" + rtmpUrl + "/" + streamName + "\""
              " -W \"http://www.ustream.tv/flash/viewer.swf\" --live")
    return result
 
 
def main(argv=None):
    # Process arguments
    if argv is None:
        argv = sys.argv[1:]
 
    usage = ("Usage: ustreamRTMPDump.py <ustream channel url> [filename]\n"
            "e.g. \"ustreamRTMPDump.py 'http://www.ustream.tv/ffrc'\"")
 
    if (len(argv) < 1):
        print usage
        return
 
    # Get RTMP information and print it
    url = argv[0]
    print "Opening url: " + url + "\n"
 
    (channelId, channelTitle, rtmpUrl, streamName) = getVideoData(url)
    print "Channel ID: " + channelId
    print "Channel Title: " + channelTitle
    print "RTMP URL: " + rtmpUrl
    print "RTMP Streamname: " + streamName + "\n"
 
    rtmpCmd = getRtmpCommand(rtmpUrl, streamName)
    print "RTMP Command:\n" + rtmpCmd
 
if __name__ == "__main__":
    main()
