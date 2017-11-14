#!perl -w
use strict;
use warnings;
use XML::Simple;
use LWP::Simple;
use MIME::Base64;
use Data::Dumper;  $|=1;

my $Gateway = "192.168.0.74";

my @testdata = (
  "WS=62_2BQCaxjQAALBeIQEAAAGGFDADiAAAEAAOA2sxAOkWAXIEVAAADC",
  "WS=62_2BQCaxjQAALDWIQEAAAGHFDADiAAADwAMAyAxAOkWAXIEVAAA5D",
  "WS=7G_2BQCaxjQAAK_YIQEAAAGFFDADiAAAEQAPA3IxAOsVA9EEXwAA4A",
  "WS=7G_2BQCaxjQAALBQIQEAAAGGFDADiAAAEgAQA3gxAOoVA9EEXwAAEE",
  "WS=ck32BQCaxjQAALAaIQEAAAGAFDADiAEAAQAAAAAAAAARAOABXAAFC3",
  "WS=ck32BQCaxjQAALEKIQEAAAGCFDADiAEAAQAAAAAAAAARAOABXAAFE9",
  "WS=FRT3BQCaxjQAALAOIQEAAAB6FDADiAAAEAAOA2sxAOwVA2EEQgAAC2",
  "WS=FRT3BQCaxjQAALCHIQEAAAB7FDADiAAADwAMAyAxAOwVA2EEQgAAA2",
  "WS=FxP3BQCaxjQAAK_2IQEAAAGFFDADiAAADwAMAyAxAOoVAAsEPgAA4E",
  "WS=g6f2BQCaxjQAALDIIQEAAAGHFDADiAAADgAMA1kxAP0WAUwEUQAA36",
  "WS=gXD2BQCaxjQAALBcIQEAAAGGFDADiAAACAAGAu4xAOkTAZgERwAA89",
  "WS=kWr2BQCaxjQAALB4IQEAAAGGFDADiAMAAQAAAAAxAPsVAXsEkkAFBF",
  "WS=MnL2BQCaxjQAAK_3IQEAAAGFFDADiAAACAAGAu4xAOkUAPkEQwAABE",
  "WS=MnL2BQCaxjQAALBvIQEAAAGGFDADiAAACAAGAu4xAOkUAPkEQwAA3E",
  "WS=MnL2BQCaxjQAALC2IQIAAAAwFDADiAMAAQAAAAAAAOkUAPkEQ0AB63",
  "WS=MnL2BQCaxjQAALC2IQIAAAAxFDADiAMAAQAAAAAxAOkUAPkEQ0QB2F",
  "WS=MnL2BQCaxjQAALDmIQEAAAGHFDADiAMAAQAAAAAxAOkUAPkEQ0QB27",
  "WS=NVL2BQCaxjQAALDAIQIAAAAtFDADiAMAAQAAAAAxAOsSArIEYAAF79",
  "WS=NVL2BQCaxjQAALDBIQIAAAAuFDADiAMACAAGAu4xAOsSArIEYAAB83",
  "WS=NVL2BQCaxjQAALDPIQEAAAGHFDADiAAADQALA04xAOsSArIEYAAA33",
  "WS=qBP3BQCaxjQAALABIQEAAAF7FDADiAEAAQAAAAAAAAATA-ABZwAF08",
  "WS=qBP3BQCaxjQAALDxIQEAAAF9FDADiAEAAQAAAAAAAAASA-ABZwAFE5",
  "WS=R3D2BQCaxjQAALBgIQEAAAGGFDADiAAAEAAOA2sxAOgVAy0EQAAAD0",
  "WS=rhP3BQCaxjQAAK_vIQEAAAGFFDADiAAADwAMAyAxAOoWAFgESgAAA9",
  "WS=rhP3BQCaxjQAALBoIQEAAAGGFDADiAAAEQAPA3IxAOoWAFgESgAA08",
  "WS=SFH2BQCaxjQAALDBIQEAAAGHFDADiAAAEgAQA3gxAOsSA68ERgAA3D",
  "WS=SFH2BQCaxjQAALE5IQEAAAGIFDADiAAAEQAPA3IxAOoSA68ERgAAB0",
  "WS=UFP2BQCaxjQAAK-5IQEAAAGFFDADiAAAEQAPA3IxAOYVAcQEQwAAD1",
  "WZ=i6g1dwCaxjQAAK_kIQEAADe0ClODp_YFAJrGNEg=A3,S=2000005259",
  "WZ=i6g1dwCaxjQAAK_xIQEAADe3ClM1UvYFAJrGNEg=61,S=2000005259",
  "WZ=i6g1dwCaxjQAAK_yIQEAADe4ClPrb_YFAJrGNEg=06,S=2000005259",
  "WZ=i6g1dwCaxjQAALA1IQEAADfBClOuE_cFAJrGNEg=9C,S=2000005259",
  "WZ=i6g1dwCaxjQAALACIQEAADe7ClMycvYFAJrGNEg=EB,S=2000005259",
  "WZ=i6g1dwCaxjQAALACIQEAADe8ClMXE_cFAJrGNEg=A5,S=2000005259",
  "WZ=i6g1dwCaxjQAALAjIQEAADfAClOlp_YFAJrGNEg=28,S=2000005259",
  "WZ=i6g1dwCaxjQAALANIQEAADe-ClORavYFAJrGNEg=5F,S=2000005259",
  "WZ=i6g1dwCaxjQAALAOIQEAADe_ClOoE_cFAJrGNEg=2C,S=2000005259",
  "WZ=i6g1dwCaxjQAALCGIQEAADfCClNQU_YFAJrGNEg=92,S=2000005259",
  "WZ=i6g1dwCaxjQAALCUIQEAADfDClMVFPcFAJrGNEg=3A,S=2000005259",
  "WZ=i6g1dwCaxjQAALD6IQEAADfOClOLqDV3AJrGNEg=4B,S=2000005259",
  "WZ=i6g1dwCaxjQAALD9IQEAADfPClORavYFAJrGNEg=A3,S=2000005259",
  "WZ=i6g1dwCaxjQAALDkIQEAADfKClNIUfYFAJrGNEg=B8,S=2000005259",
  "WZ=i6g1dwCaxjQAALDXIQEAADfGClPsb_YFAJrGNEg=C4,S=2000005259",
  "WZ=i6g1dwCaxjQAALDzIQEAADfMClMycvYFAJrGNEg=AE,S=2000005259",
  "WZ=i6g1dwCaxjQAALDzIQEAADfNClMXE_cFAJrGNEg=A8,S=2000005259"
);


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

#my %Time1         = ();
#my %Time2         = ();
my %DcMilliamps   = ();
my %DcWatts       = ();
my %Efficiency    = ();
my %Frequency     = ();
my %AcVolts       = ();
my %Temperature   = ();
my %WattHours     = ();
my %KilowattHours = ();

sub decode {
  my ($status) = @_;
  $status =~ s/[\r\n]*$//;
  my ($kind, $equal, $rest) = unpack("a2a1a*", $status);
  if ($kind eq 'WS') {
    my $bits = '';
    for my $ch (unpack("C*", $rest)) {
      $bits .= substr(unpack("B8", chr($hto6{chr($ch)})), 2);
    }

    # Extract serial number (little endian)
    my $Serial = 0;
    for (my $i=0; $i<4; $i++) {
      $Serial += ord(pack("B8", substr($bits, 0, 8))) << $i*8;
      $bits = substr($bits, 8);
    }

    # $bits = substr($bits, 5*8); # Skip 5 bytes
    # $Time1{$Serial} = u16($bits);    $bits = substr($bits, 16);
    # $bits = substr($bits, 4*8); # Skip 4 bytes
    # $Time2{$Serial} = u24($bits);    $bits = substr($bits, 24);
    # $bits = substr($bits, 5*8); # Skip 5 bytes

    $bits = substr($bits, 19*8); # Skip 19 bytes

    $DcMilliamps{$Serial}    = u16($bits) * 0.025;   $bits = substr($bits, 16);
    $DcWatts{$Serial}        = u16($bits);           $bits = substr($bits, 16);
    $Efficiency{$Serial}     = u16($bits) * 0.1;     $bits = substr($bits, 16);
    $Frequency{$Serial}      =  u8($bits);           $bits = substr($bits,  8);
    $AcVolts{$Serial}        = u16($bits);           $bits = substr($bits, 16);
    $Temperature{$Serial}    =  u8($bits);           $bits = substr($bits,  8);
    $WattHours{$Serial}      = u16($bits);           $bits = substr($bits, 16);
    $KilowattHours{$Serial}  = u16($bits);           $bits = substr($bits, 16);
  }
}

sub report {
  print "\n";
  #print "Serial No.  Time1  Time2   DC mA  DC W  Eff %  Hz  AC V  Deg         kWh\n";
  #print "----------  -----  -----  ------  ----  -----  --  ----  ---  ----------\n";
  print "Serial No.   DC mA  DC W  Eff %  Hz  AC V  Deg         kWh\n";
  print "----------  ------  ----  -----  --  ----  ---  ----------\n";
  for my $Serial (sort keys %DcMilliamps) {
    #printf "%10d  %5d  %5d  %6.3f  %4d  %4.1f%%  %2d  %4d  %3d  %10.3f\n",
    printf "%10d  %6.3f  %4d  %4.1f%%  %2d  %4d  %3d  %10.3f\n",
           $Serial,
          #$Time1{$Serial},
          #$Time2{$Serial},
           $DcMilliamps{$Serial},
           $DcWatts{$Serial},
           $Efficiency{$Serial},
           $Frequency{$Serial},
           $AcVolts{$Serial},
           $Temperature{$Serial},
           $KilowattHours{$Serial} + 0.001 * $WattHours{$Serial};
  }
}


# for my $status (@testdata) {
#   #print "$status:\n";
#   decode $status;
# }
# report();
#
# exit;




sub main {
  my $parser = new XML::Simple;

  while (1) {

    my $page = get("http://$Gateway/ajax.xml");
    #print Dumper($page);

    if (defined $page) {
      my $dom = $parser->XMLin($page);
      #print Dumper($dom);

      if (exists($dom->{"zigbeeData"})) {
        my $data = $dom->{"zigbeeData"};
        if (ref($data) eq '') {
          #print "zigbeeData: ", $data, "\n";
          decode $data;
          report();
        }
      }

      sleep 0.5;
    }
  }
}

main();

# monitor.pl - Enecsys gateway monitor - monitor solar panel status messages
