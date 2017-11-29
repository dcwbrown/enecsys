#!/usr/bin/perl
use strict;
use warnings;
#use POSIX;
use List::Util qw(min max);
$| = 1;


my $ForDate = '';

sub note (@) {
  my $msg = strftime("%Y-%m-%d %H:%M:%S ", localtime(time)) . join('',@_);
  print $msg;
  open LOG, ">>enecsys.log" or die "Couldn't create log.";
  print LOG $msg;
  close LOG;
}

# Accumulate graph data

my %readings = ();

sub addreading {
  my ($serial,$timeslot,$Watts) = @_;
  if (!exists($readings{$serial})) {
    my %panel = ();
    $readings{$serial} = \%panel;
  }
  if (!exists($readings{$serial}->{$timeslot})) {
    $readings{$serial}->{$timeslot} = 0;
    $readings{$serial}->{"count".$timeslot} = 0;
  }
  $readings{$serial}->{$timeslot} += $Watts;
  $readings{$serial}->{"count".$timeslot} += 1;
}

my %minkwh = ();
my %maxkwh = ();

sub nocounts {
  my @result = ();
  for my $key (@_) {
    if (substr($key,0,5) ne "count") {push @result, $key}
  }
  return @result;
}

sub hourlabel {
  my ($timeslot) = @_;
  $timeslot = int($timeslot/12);
  return ($timeslot < 13) ? $timeslot : $timeslot-12;
}

sub processday {
  # Average cases when there are multiple readings per timeslot
  # extract min and max axis values

  my $mintimeslot = 12*24;
  my $maxtimeslot = 0;
  my $minwatts    = 1000;
  my $maxwatts    = 0;
  for my $serial (sort keys %readings) {
    for my $timeslot (sort keys %{$readings{$serial}}) {
      if (substr($timeslot,0,5) ne "count") {
        if ($readings{$serial}->{"count".$timeslot} > 1) {
          $readings{$serial}->{$timeslot} /= $readings{$serial}->{"count".$timeslot};
          #print "$serial $timeslot " . $readings{$serial}->{"count".$timeslot} . " readings.\n";
        }
        $mintimeslot = min $mintimeslot, $timeslot;
        $maxtimeslot = max ($maxtimeslot, $timeslot);
        $minwatts = min($minwatts, $readings{$serial}->{$timeslot});
        $maxwatts = max($maxwatts, $readings{$serial}->{$timeslot});
      }
    }
  }


  printf "Timeslot range on $ForDate from %02d:%02d to %02d:%02d, max watts %1.2f.\n",
         int($mintimeslot/12), int($mintimeslot%12)*5,
         int($maxtimeslot/12), int($maxtimeslot%12)*5,
         $maxwatts;

  # Round maxwatts up to whole multiple of 25
  $maxwatts = 25 * int(($maxwatts+24)/25);

  # Round min and max time outwards to whole hours
  $mintimeslot = 12 * int($mintimeslot/12);
  $maxtimeslot = 12 * int(($maxtimeslot + 11)/12);

  print HTML "  <body>\n";


  my $leftmargin   = 20;
  my $rightmargin  = 10;
  my $topmargin    = 5;
  my $bottommargin = 30;
  my $chartwidth   = $maxtimeslot-$mintimeslot + $leftmargin + $rightmargin;
  my $chartheight  = $topmargin + $maxwatts + $bottommargin;
  my $totalkwh     = 0;

  #     <svg width=\"12%\" viewbox=\"0 0 @{[$maxtimeslot-$mintimeslot]} @{[$maxwatts+1]}\" class=\"graph\">

  for my $serial (qw/100036587 100036679 100078510 100050853 100036588 100029264 100027762 100028744
                     100028981 100036737 100078359 100037170 100078504 100035217 100078613 100050819/) {

    print HTML <<"    END-CHART-HEADER";
      <svg width="12%" viewbox="0 0 $chartwidth $chartheight" class="graph">
        <polyline fill="none" stroke="#0074d9" stroke-width="1" points="
    END-CHART-HEADER

    for my $timeslot (sort {$a <=> $b} nocounts keys %{$readings{$serial}}) {
      my $x = $timeslot-$mintimeslot + $leftmargin;
      my $y = $topmargin + int($maxwatts) - int($readings{$serial}->{$timeslot});
      print HTML "          $x, $y\n";
    }
    print HTML "         \"/>\n";

    my $firsttimeline = 12 * int(($mintimeslot+11)/12);
    my $lasttimeline  = 12 * int($maxtimeslot/12);

    # Vertical grid lines on the hour
    for (my $timeline = $firsttimeline; $timeline<=$lasttimeline; $timeline += 12) {
      my $x = $leftmargin + $timeline-$mintimeslot;
      print HTML <<"      END-CHART-HOUR-GRID";
        <line x1="$x" y1="$topmargin" x2="$x" y2="@{[$topmargin+$maxwatts]}" style="stroke:#808080; stroke-width: 0.25"/>
        <text style='text-anchor: middle; font-size: 7; font-family: Arial'
              x='$x' y='@{[$topmargin+$maxwatts+8]}'>
          @{[hourlabel($timeline)]}
        </text>
      END-CHART-HOUR-GRID
    }

    # Horizontal grid lines at every multiple of 25 watts
    for (my $watts = 0; $watts<=$maxwatts; $watts += 25) {
      my $x = $leftmargin-2;
      my $y = $topmargin + $maxwatts-$watts;
      print HTML <<"      END-CHART-WATT-GRID";
        <line x1="$leftmargin" y1="$y" x2="@{[$chartwidth-$rightmargin]}" y2="$y" style="stroke:#808080; stroke-width: 0.25"/>\n";
        <text style='text-anchor: end; font-size: 7; font-family: Arial'
              x='$x' y='@{[$y+3]}'>
          $watts
        </text>
      END-CHART-WATT-GRID
    }

    my $kWh = sprintf("%1.3f", $maxkwh{$serial} - $minkwh{$serial});
    $totalkwh += $kWh;
    print HTML <<"    END-CHART-TRAILER";
        <text style='text-anchor: middle; font-size: 9; font-family: Arial'
              x='@{[$leftmargin+($chartwidth-$leftmargin-$rightmargin)/2]}' y='@{[$topmargin + $maxwatts + 20]}'>
          Serial $serial, $kWh kWh
        </text>
      </svg>
    END-CHART-TRAILER
  }

  $ForDate =~ /([0-9]{4})([0-9]{2})([0-9]{2})/;
  my ($yy,$mm,$dd) = ($1,$2,$3);
  print HTML <<"  END-CHART-TITLE";
    <svg width="100%" height="100">
      <text style='text-anchor: middle; font-size: 24; font-family: Arial' x='50%' y='30'>
        Date $yy-$mm-$dd, Generation $totalkwh kWh
      </text>
    </svg>
    <svg width="100%" height="20">
      <line x1="0" y1="0" x2="100%" y2="0" style="stroke:#808080; stroke-width: 1"/>\n";
    </svg>
  END-CHART-TITLE
}


# Write out an SVG chart

open HTML, ">enecsys-svg.html" or die "Couldn't create html file.";
print HTML "<html>\n";

open LOG, "<enecsys.log" or die "Couldn't open log.";
while (<LOG>) {
  chomp;
  if (/^([0-9]+)-([0-9]+)-([0-9]+) ([0-9]+):([0-9]+):([0-9]+) ([0-9]+) ([0-9.]+) ([0-9]+) ([0-9.]+) ([0-9]+) ([0-9]+) ([0-9]+) ([0-9.]+)/) {
    my ($year,$mon,$day,$hr,$min,$sec,$serial,$mA,$W,$eff,$Hz,$ACV,$Deg,$kWh) = ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14);
    #print "$serial $hr.$min.$sec $W\n";
    my $timeslot = $hr*12 + int($min/5); # Each slot is 5 minutes.
    #printf "%02d:%02d $timeslot\n", $hr, $min;

    if ("$year$mon$day" ne $ForDate) {
      if ($ForDate ne '') {processday();}
      $ForDate = "$year$mon$day";
      %readings = ();
      %minkwh   = ();
      %maxkwh   = ();
    }

    addreading($serial, $timeslot, $W);
    # Extract min and max kWh for each serial. Min is the first encounters, and max the last.
    if (!exists $minkwh{$serial}) {$minkwh{$serial} = $kWh;}
    $maxkwh{$serial} = $kWh;
  }
}
close LOG;

if ((keys %minkwh) > 0) {processday()}

print HTML "  </body>\n";
print HTML "</html>\n";
close HTML;