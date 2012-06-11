#!/usr/bin/perl
## origin: http://yamamoto56.blogtribe.org/entry-7e7433e69297f71915d737146675fcf0.html
use strict;
use Encode;
use LWP::UserAgent;
use Data::AMF::IO;
use Data::AMF::Parser;
use utf8;
#binmode(STDOUT, ':raw :encoding(cp932)'); # 標準出力の文字コードを指定
#binmode(STDERR, ':raw :encoding(cp932)'); # 標準エラー出力の文字コードを指定
binmode(STDOUT, ':raw :encoding(utf8)'); # 標準出力の文字コードを指定
binmode(STDERR, ':raw :encoding(utf8)'); # 標準エラー出力の文字コードを指定

# チャンネルID未指定時はNHK World
&testUST();


sub testUST {
  my $cid = shift || 8990235; # NHK World
  my $amfurl = 'http://cdngw.ustream.tv/Viewer/getStream/1/'. $cid .'.amf';
  
  my $browser = LWP::UserAgent->new;
  $browser->agent( 'Mozilla/4.0 (compatible; MSIE 8.0; Windows NT 6.1; Trident/4.0)' );
  #$browser->proxy( 'http', 'http://localhost:8888/' );
  
  my $response = $browser->get( $amfurl );
  if ( !$response->is_success ) {
    print STDERR $response->status_line ."\n";
    return;
  }
  
  # ここでUTF8デコードするとパースできないので出力時にデコードする
  #my $amfcontent = decode( 'utf8', $response->content );
  my $amfcontent = $response->content;
  
  my $amfobj = &testDeserialize( $amfcontent );
  print "\nheaders:\n";
  for my $header ( @{ $amfobj->{'headers'} } ) {
    &printRef( $header, '', '' );
  }
  print "\nmessages:\n";
  for my $message ( @{ $amfobj->{'messages'} } ) {
    &printRef( $message, '', '' );
  }
}


##################################################################
# AMFデシリアライズ
# 引数：AMFバイナリストリング
# 戻り値：{ 'headers', 'messages' }
##################################################################
sub testDeserialize {
  my ($data) = @_;
  
  my $io = Data::AMF::IO->new( data => $data );
  
  my $ver           = $io->read_u16;
  my $header_count  = $io->read_u16;
  
  my $parser = Data::AMF::Parser->new( version => 0 );
  
  my @headers;
  for my $i (1 .. $header_count) {
      my $name  = $io->read_utf8;
      my $must  = $io->read_u8;
      my $len   = $io->read_u32;
      
      my $data    = $io->read($len);
      my ($value) = $parser->parse($data); # parseはリストを返す
      push( @headers, {$name => $value, 'required'=>$must} );
  }
  
  my $message_count = $io->read_u16;
  
  my @messages;
  for my $i (1 .. $message_count) {
      my $target_uri   = $io->read_utf8;
      my $response_uri = $io->read_utf8;
      my $len          = $io->read_u32;
      
      my $data    = $io->read($len);
      my ($value) = $parser->parse($data);
      push( @messages, {'target'=>$target_uri, 'response'=>$response_uri, 'data'=>$value} );
  }
  
  return { 'headers' => \@headers, 'messages' => \@messages };
}


##################################################################
# データ表示
# 引数：変数（参照以外でも可）
# 戻り値：無し
##################################################################
sub printRef {
  my ( $ref, $name, $idt ) = @_;
  if ( $name ne '' ) {
    $name .= ' '; 
  }
  
  if ( ref($ref) eq '' ) {
    print $idt . decode_utf8($ref) ."\n";
  } elsif ( ref($ref) eq 'HASH' ) {
    print $idt . $name .'['. ref($ref) ."]\n";
    &printHashRef( $ref, $idt.'| ' );
  } elsif ( ref($ref) eq 'ARRAY' ) {
    print $idt . $name .'['. ref($ref) ."]\n";
    &printArrayRef( $ref, $idt.'| ' );
  } else {
    print $idt . $name .'['. ref($ref) ."]\n";
  }
}
sub printHashRef {
  my ( $ref, $idt ) = @_;
  
  foreach my $key ( keys %{$ref} ) {
    if ( ref($ref->{$key}) eq '' ) {
      print $idt . $key .' '. decode_utf8($ref->{$key}) ."\n";
    } else {
      &printRef( $ref->{$key}, $key, $idt );
    }
  }
}
sub printArrayRef {
  my ( $ref, $idt ) = @_;
  
  foreach my $item ( @{$ref} ) {
    if ( ref($item) eq '' ) {
      print $idt . decode_utf8( $item ) ."\n";
    } else {
      &printRef( $item, '', $idt );
    }
  }
}