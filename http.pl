#!/usr/bin/perl
use strict;
use warnings;
use HTTP::Daemon;
use HTTP::Status;

my %pages = (
  "/enecsys"  => \&serveReport,
  "/dir"      => \&serveDirectory
);

my $d = HTTP::Daemon->new(LocalPort => 8080) || die;
while (my $c = $d->accept) {
  while (my $r = $c->get_request) {
    if ($r->method eq 'GET' &&  exists $pages{$r->uri->path}) {
      $pages{$r->uri->path}->($c, $r->uri->query);
    } else {$c->send_error(RC_NOT_FOUND)}
  }
  $c->close;
  undef($c);
}

sub serveReport {my ($c, $q) = @_;
  my $fn = GetReport($q);
  if (defined($fn)) {
    $c->send_file_response($fn);
  } else {
    $c->send_error(RC_BAD_REQUEST)
  }
}

sub serveDirectory {my ($c, $q) = @_;
  $c->send_file_response("/d");
}



use POSIX;
use List::Util qw(min max);
$| = 1;





# Accumulate graph data

my $day;         # yyyy-mm-dd
my %readings;
my %minkwh;
my %maxkwh;
my $mintimeslot;
my $maxtimeslot;
my $minwatts;
my $maxwatts;

sub ParseLogFile {
  my ($lfn) = @_;

  %readings = ();
  %minkwh   = ();
  %maxkwh   = ();

  open LOG, "<$lfn" or die "Couldn't open $lfn.";
  while (<LOG>) {
    chomp;
    if (/^([0-9]+)-([0-9]+)-([0-9]+) ([0-9]+):([0-9]+):([0-9]+) ([0-9]+) ([0-9.]+) ([0-9]+) ([0-9.]+) ([0-9]+) ([0-9]+) ([0-9]+) ([0-9.]+)/) {
      my ($year,$mon,$day,$hr,$min,$sec,$serial,$mA,$W,$eff,$Hz,$ACV,$Deg,$kWh) = ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14);
      my $timeslot = $hr*12 + int($min/5); # Each slot is 5 minutes.

      # Record every wattage read indexed by timeslot
      if (!exists($readings{$serial})) {
        my %panel = ();
        $readings{$serial} = \%panel;
      }
      if (!exists($readings{$serial}->{$timeslot})) {
        $readings{$serial}->{$timeslot} = 0;
        $readings{$serial}->{"count".$timeslot} = 0;
      }
      $readings{$serial}->{$timeslot} += $W;
      $readings{$serial}->{"count".$timeslot} += 1;

      # Extract min and max kWh for each serial. Min is the first encounters, and max the last.
      if (!exists $minkwh{$serial}) {$minkwh{$serial} = $kWh;}
      $maxkwh{$serial} = $kWh;
    }
  }
  close LOG;

  # Average wattages where there is more than one in the same timeslot.
  # Extract min and max for timeslot and wattage.
  $mintimeslot = 12*24;
  $maxtimeslot = 0;
  $minwatts    = 1000;
  $maxwatts    = 0;
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
}



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

sub FormatSVG {
  printf "Timeslot range from %02d:%02d to %02d:%02d, max watts %1.2f.\n",
         int($mintimeslot/12), int($mintimeslot%12)*5,
         int($maxtimeslot/12), int($maxtimeslot%12)*5,
         $maxwatts;

  # Round maxwatts up to whole multiple of 25
  $maxwatts = 25 * int(($maxwatts+24)/25);

  # Round min and max time outwards to whole hours
  $mintimeslot = 12 * int($mintimeslot/12);
  $maxtimeslot = 12 * int(($maxtimeslot + 11)/12);

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

  print HTML <<"  END-CHART-TITLE";
    <svg width="100%" height="100">
      <text style='text-anchor: middle; font-size: 24; font-family: Arial' x='50%' y='30'>
        Date $day, Generation $totalkwh kWh
      </text>
    </svg>
    <svg width="100%" height="20">
      <line x1="0" y1="0" x2="100%" y2="0" style="stroke:#808080; stroke-width: 1"/>\n";
    </svg>
  END-CHART-TITLE
}



sub FormatReportFile {
  my ($rfn) = @_;

  open HTML, ">$rfn" or die "Couldn't create $rfn.";
  print HTML "<html>\n  <body>\n";

  FormatSVG();

  print HTML "  </body>\n</html>\n";
  close HTML;

}


sub MakeReport {
  my ($lfn, $rfn) = @_;
  print "MakeReport($lfn, $rfn)\n";

  ParseLogFile($lfn);
  FormatReportFile($rfn);
}


sub GetReport {
  ($day) = @_;
  my $today = strftime("%Y-%m-%d", localtime(time));
  print "GetReport($day), today = $today.\n";
  my $lfn = "enecsys-$day.log"; # Log file name
  my $rfn = "report-$day.html"; # Report file name
  if (($day eq $today) || !(-f $rfn)) {  # Always regenerate todays report as more sun may have shone
    if (-f $lfn) {MakeReport($lfn, $rfn);}
    if (! -f $rfn) {$rfn = undef;}
  }
  return $rfn;
}



