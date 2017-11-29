#!/usr/bin/perl
use IO::Socket::INET;
$| = 1;

# creating a listening socket
my $socket = new IO::Socket::INET (#
  PeerAddr => "gw.enecsys.net",
  PeerPort => "5040",
  Proto    => 'tcp',
  Type     => SOCK_STREAM
);
die "cannot create socket $!\n" unless $socket;



$socket->send("167735A88A00IQAAAABfAlIB0E\r")                                                     or  die "send  1 failed.\n";
$socket->send("4A7735A88A01180743WZ=i6g1dwCaxjQAACsoIQEAAAAuClOLqDV3AJrGNEg=52,S=2000005259C2\r") or  die "send  2 failed.\n";
$socket->send("167735A88A00IQAAAABgAlIB6C\r")                                                     or  die "send  3 failed.\n";
$socket->send("167735A88A00IQAAAABhAlIB5C\r")                                                     or  die "send  4 failed.\n";
$socket->send("4A7735A88A01180940WZ=i6g1dwCaxjQAACwYIQEAAAAvClOLqDV3AJrGNEg=3C,S=2000005259C1\r") or  die "send  5 failed.\n";
$socket->send("167735A88A00IQAAAABiAlIB3E\r")                                                     or  die "send  6 failed.\n";
$socket->send("167735A88A00IQAAAABjAlIB98\r")                                                     or  die "send  7 failed.\n";
$socket->send("4A7735A88A01181141WZ=i6g1dwCaxjQAAC0IIQEAAAAwClOLqDV3AJrGNEg=8D,S=200000525936\r") or  die "send  8 failed.\n";
$socket->send("167735A88A00IQAAAABkAlIBFA\r")                                                     or  die "send  9 failed.\n";
$socket->send("167735A88A00IQAAAABlAlIBD3\r")                                                     or  die "send 10 failed.\n";
$socket->send("4A7735A88A01181341WZ=i6g1dwCaxjQAAC34IQEAAAAxClOLqDV3AJrGNEg=35,S=2000005259B7\r") or  die "send 11 failed.\n";
$socket->send("167735A88A00IQAAAABmAlIBB1\r")                                                     or  die "send 12 failed.\n";
$socket->send("167735A88A00IQAAAABnAlIB17\r")                                                     or  die "send 13 failed.\n";
$socket->send("4A7735A88A01181541WZ=i6g1dwCaxjQAAC7oIQEAAAAyClOLqDV3AJrGNEg=DF,S=2000005259C3\r") or  die "send 14 failed.\n";
$socket->send("167735A88A00IQAAAABoAlIB75\r")                                                     or  die "send 15 failed.\n";
$socket->send("167735A88A00IQAAAABpAlIB77\r")                                                     or  die "send 16 failed.\n";
$socket->send("4A7735A88A01181742WZ=i6g1dwCaxjQAAC_ZIQEAAAAzClOLqDV3AJrGNEg=B1,S=200000525995\r") or  die "send 17 failed.\n";
$socket->send("167735A88A00IQAAAABqAlIB15\r")                                                     or  die "send 18 failed.\n";
$socket->send("167735A88A00IQAAAABrAlIBB3\r")                                                     or  die "send 19 failed.\n";
$socket->send("4A7735A88A01181942WZ=i6g1dwCaxjQAADDJIQEAAAA0ClOLqDV3AJrGNEg=25,S=2000005259E8\r") or  die "send 20 failed.\n";
$socket->send("167735A88A00IQAAAABsAlIBD1\r")                                                     or  die "send 21 failed.\n";
$socket->send("167735A88A00IQAAAABtAlIBF8\r")                                                     or  die "send 22 failed.\n";

print "Received: '";
while (1) {
  $socket->recv($data,1);
  if (length($data) > 0) {
    $data =~ s/\r/\n/g;
    print $data;
  } else {
    break;
  }
}
print "'.\n";

$socket->close();