#!/usr/bin/perl
use strict;
use warnings;
use POSIX;
$| = 1;


my $ForDate = "20171106";

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
  my ($serial,$minute,$Watts) = @_;
  if (!exists($readings{$serial})) {
    my %panel = ();
    $readings{$serial} = \%panel;
  }
  if (!exists($readings{$serial}->{$minute})) {
    $readings{$serial}->{$minute} = 0;
    $readings{$serial}->{"count".$minute} = 0;
  }
  $readings{$serial}->{$minute} += $Watts;
  $readings{$serial}->{"count".$minute} += 1;
}

open LOG, "<enecsys.log" or die "Couldn't open log.";
while (<LOG>) {
  chomp;
  if (/^([0-9]+)-([0-9]+)-([0-9]+) ([0-9]+):([0-9]+):([0-9]+) ([0-9]+) ([0-9.]+) ([0-9]+) ([0-9.]+) ([0-9]+) ([0-9]+) ([0-9]+) ([0-9.]+)/) {
    my ($year,$mon,$day,$hr,$min,$sec,$serial,$mA,$W,$eff,$Hz,$ACV,$Deg,$kWH) = ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14);
    #print "$serial $hr.$min.$sec $W\n";
    my $timeslot = $hr*12 + int($min/5); # Each slot is 5 minutes.
    if ("$year$mon$day" eq $ForDate) {addreading($serial, $timeslot, $W)}
  }
}
close LOG;

# Average cases when there are multiple readings per timeslot

for my $serial (sort keys %readings) {
  for my $minute (sort keys %{$readings{$serial}}) {
    if (substr($minute,0,5) ne "count") {
      if ($readings{$serial}->{"count".$minute} > 1) {
        $readings{$serial}->{$minute} /= $readings{$serial}->{"count".$minute};
        #print "$serial $minute " . $readings{$serial}->{"count".$minute} . " readings.\n";
      }
    }
  }
}

for my $serial (sort keys %readings) {
  for my $minute (sort keys %{$readings{$serial}}) {
    if (substr($minute,0,5) ne "count") {
      my $watts = sprintf("%1.1f", $readings{$serial}->{$minute});
      my $timeslot = sprintf("%02d:%02d", int($minute/12), int($minute%12)*5);
      print "$serial $timeslot $watts\n";
    }
  }
}


# Write out a google chart

open HTML, ">enecsys.html" or die "Couldn't create html file.";
print HTML "<html>\n";
print HTML "  <head>\n";
print HTML "    <script type=\"text/javascript\" src=\"https://www.gstatic.com/charts/loader.js\"></script>\n";
print HTML "    <script type=\"text/javascript\">\n";
print HTML "      google.charts.load('current', {'packages':['corechart']});\n";

sub nocounts {
  my @result = ();
  for my $key (@_) {
    if (substr($key,0,5) ne "count") {push @result, $key}
  }
  return @result;
}

for my $serial (sort keys %readings) {
  print HTML "\n";
  print HTML "      google.charts.setOnLoadCallback(drawPanel${serial}Chart);\n";
  print HTML "      function drawPanel${serial}Chart() {\n";
  print HTML "        var data = google.visualization.arrayToDataTable([\n";
  print HTML "          ['Time', 'Watts'],\n";
  for my $minute (sort {$a <=> $b} nocounts keys %{$readings{$serial}}) {
    my $watts = int($readings{$serial}->{$minute}); #sprintf("%1.1f", $readings{$serial}->{$minute});
    my $timeslot = "new Date(0, 0, 0, " . int($minute/12) . ", " . int($minute%12)*5 . ", 0)";
    print HTML "          [$timeslot, $watts],\n";
  }
  print HTML "        ]);\n";
  print HTML "        var options = {\n";
  print HTML "          title: '$serial',\n";
#  print HTML "          titlePosition: 'none',\n";
  print HTML "          vAxis: {minValue: 0, maxValue: 150,\n";
  print HTML "                  viewWindowMode: 'maximized',\n";
  print HTML "                  ticks: [25,50,75,100,125,150]},\n";
  print HTML "          width: 200,\n";
  print HTML "          curveType: 'function',\n";
  print HTML "          legend: { position: 'bottom' }\n";
  print HTML "        };\n";
  print HTML "        var chart = new google.visualization.LineChart(document.getElementById('panel_${serial}_chart_div'));\n";
  print HTML "        chart.draw(data, options);\n";
  print HTML "      }\n";
}


print HTML "    </script>\n";
print HTML "  </head>\n";
print HTML "  <body>\n";
print HTML "    <table class=\"columns\">\n";
print HTML "      <tr>\n";
for my $serial (('100028981','100036737','100078359','100037170','100078504','100035217','100078613','100050819')) {
  print HTML "        <td><div id=\"panel_${serial}_chart_div\" style=\"border: 1px solid #ccc\"></div></td>\n";
}
print HTML "      </tr>\n";
print HTML "      <tr>\n";
for my $serial (('100036587','100036679','100078510','100050853','100036588','100029264','100027762','100028744')) {
  print HTML "        <td><div id=\"panel_${serial}_chart_div\" style=\"border: 1px solid #ccc\"></div></td>\n";
}
print HTML "      </tr>\n";
print HTML "    </table>\n";

print HTML "  </body>\n";
print HTML "</html>\n";
close HTML;