#!/usr/bin/perl
use strict;
use warnings;
use POSIX;
use IO::Socket::INET;
$| = 1;

my %hto6 = (
  'A' =>  0,  'B' =>  1,  'C' =>  2,  'D' =>  3,  'E' =>  4,  'F' =>  5,  'G' =>  6,  'H' =>  7,
  'I' =>  8,  'J' =>  9,  'K' => 10,  'L' => 11,  'M' => 12,  'N' => 13,  'O' => 14,  'P' => 15,
  'Q' => 16,  'R' => 17,  'S' => 18,  'T' => 19,  'U' => 20,  'V' => 21,  'W' => 22,  'X' => 23,
  'Y' => 24,  'Z' => 25,  'a' => 26,  'b' => 27,  'c' => 28,  'd' => 29,  'e' => 30,  'f' => 31,
  'g' => 32,  'h' => 33,  'i' => 34,  'j' => 35,  'k' => 36,  'l' => 37,  'm' => 38,  'n' => 39,
  'o' => 40,  'p' => 41,  'q' => 42,  'r' => 43,  's' => 44,  't' => 45,  'u' => 46,  'v' => 47,
  'w' => 48,  'x' => 49,  'y' => 50,  'z' => 51,  '0' => 52,  '1' => 53,  '2' => 54,  '3' => 55,
  '4' => 56,  '5' => 57,  '6' => 58,  '7' => 59,  '8' => 60,  '9' => 61,  '-' => 62,  '_' => 63
  # ,  "\r" => 0, "\n" => 0
);

sub u8 {my ($bits) = @_;
  return ord(pack("B8", substr($bits, 0, 8)));
}

sub u16 {my ($bits) = @_;
  return (ord(pack("B8", substr($bits, 0, 8))) << 8)
       +  ord(pack("B8", substr($bits, 8, 8)));
}

sub u24 {my ($bits) = @_;
  return (ord(pack("B8", substr($bits, 0,  8))) << 16)
       + (ord(pack("B8", substr($bits, 8,  8))) << 8)
       +  ord(pack("B8", substr($bits, 16, 8)));
}

my %DcMilliamps   = ();
my %DcWatts       = ();
my %Efficiency    = ();
my %Frequency     = ();
my %AcVolts       = ();
my %Temperature   = ();
my %WattHours     = ();
my %KilowattHours = ();

sub note (@) {
  my $timestamp = strftime("%Y-%m-%d %H:%M:%S ", localtime(time));
  my $today = substr($timestamp,0,10);
  my $msg = $timestamp . join('',@_);
  print $msg;
  open LOG, ">>enecsys-$today.log" or die "Couldn't append to log.";
  print LOG $msg;
  close LOG;
}

sub showstring {
  my ($str) = @_;
  $str =~ s/[\r\n]/./g;
  print "'", $str, "'.\n";
}

sub decode {
  my ($status) = @_;
  $status =~ s/[\r\n]*$//;
  print "Decoding: "; showstring($status);

  my $bits = '';
  for my $ch (unpack("C*", $status)) {
    $bits .= substr(unpack("B8", chr($hto6{chr($ch)})), 2);
  }
  # Extract serial number (little endian)
  my $Serial = 0;
  for (my $i=0; $i<4; $i++) {
    $Serial += ord(pack("B8", substr($bits, 0, 8))) << $i*8;
    $bits = substr($bits, 8);
  }
  $bits = substr($bits, 19*8); # Skip 19 bytes
  $DcMilliamps{$Serial}    = u16($bits) * 0.025;  $bits = substr($bits, 16);
  $DcWatts{$Serial}        = u16($bits);          $bits = substr($bits, 16);
  $Efficiency{$Serial}     = u16($bits) * 0.1;    $bits = substr($bits, 16);
  $Frequency{$Serial}      =  u8($bits);          $bits = substr($bits,  8);
  $AcVolts{$Serial}        = u16($bits);          $bits = substr($bits, 16);
  $Temperature{$Serial}    =  u8($bits);          $bits = substr($bits,  8);
  $WattHours{$Serial}      = u16($bits);          $bits = substr($bits, 16);
  $KilowattHours{$Serial}  = u16($bits);          $bits = substr($bits, 16);

  note sprintf "%d %3.3f %d %1.1f %d %d %d %3.3f '%s'\n",
    $Serial,
    $DcMilliamps{$Serial},
    $DcWatts{$Serial},
    $Efficiency{$Serial},
    $Frequency{$Serial},
    $AcVolts{$Serial},
    $Temperature{$Serial},
    $KilowattHours{$Serial} + 0.001 * $WattHours{$Serial},
    $status;
}

sub report {
  print "\n";
  print "Serial No.   DC mA  DC W  Eff %  Hz  AC V  Deg         kWh\n";
  print "----------  ------  ----  -----  --  ----  ---  ----------\n";
  for my $Serial (sort keys %DcMilliamps) {
    printf "%10d  %6.3f  %4d  %4.1f%%  %2d  %4d  %3d  %10.3f\n",
           $Serial,
           $DcMilliamps{$Serial},
           $DcWatts{$Serial},
           $Efficiency{$Serial},
           $Frequency{$Serial},
           $AcVolts{$Serial},
           $Temperature{$Serial},
           $KilowattHours{$Serial} + 0.001 * $WattHours{$Serial};
  }
}


note "Creating socket ", "port 5040", "\n";

# creating a listening socket
my $socket = new IO::Socket::INET (
    LocalHost => '0.0.0.0',
    LocalPort => '5040',
    Proto => 'tcp',
    Listen => 5,
    Reuse => 1
);
die "cannot create socket $!\n" unless $socket;


my $client_socket = $socket->accept();
my $client_address = $client_socket->peerhost();
my $client_port = $client_socket->peerport();
note "Enecsys gateway connected from $client_address:$client_port.\n";

my $emptycount = 0;

my $buffer = '';

while (1) {
  my $data = "";
  my $result = $client_socket->recv($data, 200);

  if (defined($result)) {
    #note "recv result: '$result'\n";
  } else {
    note "recv result undefined, exiting.\n";
    exit;
  }

  if (length($data) > 0) {
    #note "Data received:      "; showstring($data);
    $buffer .= $data;
    #note "Accumulated buffer: "; showstring($buffer);
    while ($buffer =~ /^(.*?)\r(.*)$/) {
      $data = $1;  $buffer = $2;
      #note "Selected data:      "; showstring($data);
      #note "Remaining buffer:   "; showstring($buffer);
      $data =~ s/[\r\n]*$//;
      print "Received: '$data'\n";
      if (substr($data,0,2) eq "16") {
        if (substr($data,12,2) ne 'cg') {
          $client_socket->send("0E0000000000cgAD83\r");
        }
      } elsif (substr($data,0,2) eq "49") {
        decode(substr($data,21));
        report();
      }
    }
  } else {
    note "recv returned empty data.\n";
    if ($emptycount++ >= 10) {
      print "10 empty receives. Exiting.\n";
      exit;
    }
  }
}


$socket->close();
