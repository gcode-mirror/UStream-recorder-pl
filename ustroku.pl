#!/usr/bin/perl
use strict;
use warnings;
use File::Path;
use LWP::Simple;

my ( $ustream_url, $dir, $stop ) = @ARGV;

my $usage = <<USAGE;
usage: sudo ./ustream_download.pl USTREAM_URL TARGET_DIRECTORY [rtmpdump stop option]
e.g. sudo ./ustream_download.pl http://www.ustream.tv/channel/naf-libe-events 600
USAGE

die $usage unless $ustream_url;
die $usage unless $dir;

my ($channel_id,$channel_title,$rtmp_url,$stream_name) = get_video_data($ustream_url);

# debug
print "channel_id:".$channel_id."¥n";
print "channel_title:".$channel_title."¥n";
print "rtmp_url:".$rtmp_url."¥n";
print "stream_name:".$stream_name."¥n";

# get filename
my @tm   = localtime;
my $time = sprintf(
	'%04d%02d%02d_%02d%02d%02d',
	1900 + $tm[5],
	1 + $tm[4],
	@tm[ 3, 2, 1, 0 ]
);
my $filename = $dir . '/' . $channel_title . '_' . $time . '.flv';

# get rtmp command
my $rtmp_command = get_rtmp_command($rtmp_url,$stream_name);
if ($stop) {
	$rtmp_command .= ' --stop ' . $stop . ' -o "' . $filename . '"';
} else {
	$rtmp_command .= ' -o "' . $filename . '"';
}
print $rtmp_command. "\n";

# make directory
eval { mkpath($dir) };
if ($@) {
	die "Couldn't create $dir: $@";
}

# execute rtmp command
system($rtmp_command);

sub get_video_data {
	my $url = shift;

	# Get the HTML contents
	my $html = get($url);

	# Extract the channel ID from the HTML
	my $channel_id;
	if ( $html =~ /Channel\sID\:\s+(\d+)/m ) {
		$channel_id = $1;
	}else{
		die 'channel_id not found. url:'.$url;
	}

	# Extract the channel title from the HTML
	my $channel_title;
	if ( $html =~ /property\=\"og\:url\"\s+content\=\"http\:\/\/www\.ustream\.tv\/(?:channel\/)?([^\"]+)\"/m )
	{
		$channel_title = $1;
	}else{
		die 'channel_title not found. url:'.$url;
	}
	
	# Extract amf
	my $amf_url = 'http://cdngw.ustream.tv/Viewer/getStream/1/'. $channel_id .'.amf';
	my $amf_content = get($amf_url);
	
	my $rtmp_url;
	if( $amf_content =~ /(rtmp\:\/\/[^\x00]+)/m ){
		$rtmp_url = $1;
	}else{
		die 'rtmp_url not found. amf_url:'.$amf_url;
	}
	
	my $stream_name;
	if( $amf_content =~ /streamName(?:\W+)([^\x00]+)/m ){
		$stream_name = $1;
	}else{
		die 'stream_name not found. amf_url:'.$amf_url;
	}
	
	return ($channel_id,$channel_title,$rtmp_url,$stream_name);
}

sub get_rtmp_command{
	my $rtmp_url = shift;
	my $stream_name = shift;
	return "rtmpdump -v -r \"" . $rtmp_url . "/" . $stream_name . "\" -W \"http://www.ustream.tv/flash/viewer.swf\" --live";
}
