#!/usr/bin/perl
# this script is an implementation of
# http://textt.net/mapi/20101018201937
# http://pastebin.com/ZMS7L9ja

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

my ( $amf_url, $title ) = get_amf_data($ustream_url);
print "amf_url:" . $amf_url . "\n";
print "title:" . $title . "\n";

my @tm   = localtime;
my $time = sprintf(
	'%04d%02d%02d_%02d%02d%02d',
	1900 + $tm[5],
	1 + $tm[4],
	@tm[ 3, 2, 1, 0 ]
);

my $file = $dir . '/' . ( $title || 'stream' ) . '_' . $time . '.flv';

#$stop ||= 600;

my ( $video_url, $video_id, $stream_name ) = get_video_url($amf_url);
print "video_url:" . $video_url . "\n";
print "video_id:" . $video_id . "\n";
print "stream_name:" . $stream_name . "\n";

if ($video_url) {

	eval { mkpath($dir) };
	if ($@) {
		die "Couldn't create $dir: $@";
	}

	my $command =
	    'rtmpdump -q -v -r "'
	  . $video_url
	  . '" -a "'
	  . $video_id
	  . '" -f "LNX 10,0,45,2" -y "'
	  . $stream_name . '"';

	if ($stop) {
		$command .= ' --stop ' . $stop . ' -o "' . $file . '"';
	}
	else {
		$command .= ' -o "' . $file . '"';
	}

	print $command. "\n";
	system($command);
}
else {
	die "no video url in " . $ustream_url;
}

sub get_video_url {
	my $url     = shift;
	my $amf_bin = get($url);

	if ( $amf_bin =~ m|(rtmp://[^/]+/ustreamVideo/(\d+))|m ) {
		my $video_url   = $1;
		my $video_id    = 'ustreamVideo/' . $2;
		my $stream_name = 'streams/live';
		return ( $video_url, $video_id, $stream_name );
	}

	# added for dommune,2.5D,etc
	if ( $amf_bin =~ m|(rtmp://(\w+).live.edgefcs.net/(\w+))|m ) {
		my $video_url   = $1;
		my $video_id    = $3;
		my $stream_name = '';

		if ( $amf_bin =~ m|(ustream-(\w+)@(\w+))|m ) {
			$stream_name = $1;
			return ( $video_url, $video_id, $stream_name );
		}
		if ( $amf_bin =~ m|(stream_live_(\w+))|m ) {
			$stream_name = $1;
			return ( $video_url, $video_id, $stream_name );
		}

	}

	return;
}

sub get_amf_data {
	my $url = shift;

	my $text = get($url);
	my $channel_id;
	if ( $text =~ /Channel\s+ID\:\s+(\d+)/m ) {
		$channel_id = $1;
	}
	else {
		return;
	}
	my $title = $channel_id;
	if ( $text =~
/property\=\"og\:url\"\s+content\=\"http\:\/\/www.ustream.tv\/channel\/([^\"]+)\"/m
	  )
	{
		$title = $1;
	}

	return (
		'http://cdngw.ustream.tv/Viewer/getStream/1/' . $channel_id . '.amf',
		$title );
}
