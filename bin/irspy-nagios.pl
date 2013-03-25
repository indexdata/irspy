#!/usr/bin/perl
# Copyright (c) 2013 IndexData ApS, http://indexdata.com
#
# irspy-nagios.pl - check if IRSpy updates run

use strict;
use warnings;

use LWP::Simple;
use HTTP::Date;
use Getopt::Long;

my $help;
my $debug = 0;
my $update_cycle_days = 7;
my $url = 'http://irspy.indexdata.com/raw.html?id=Z39.50%3Aopencontent.indexdata.com%3A210%2Foaister';

sub usage () {
    <<EOF;
usage: $0 [ options ]

--debug=0..2            debug option, default: $debug
--days=1..7          	alert if older than days, default $update_cycle_days
--url=URL        	url to check, default $url

EOF
}


##################################################################
# main
#
GetOptions(
    "debug=i"                  => \$debug,
    "days=i"              => \$update_cycle_days,
    "url=s"       => \$url,
) or die usage;
die usage if $help;

my $data = get $url;

die "No data for $url\n" if !defined $data;
warn $data if $debug >= 2;

if ($data =~ m,<dateModified>(.*?)</dateModified>,) {
  my $date = $1;
  my $time = str2time($date);

  my $last_update =  time() - $time;
  warn "last update: $last_update seconds ago\n" if $debug;

  if ($last_update > 24*3600* $update_cycle_days) {
	die "Last update is older than $last_update seconds: $date\n";
  }

} else {
   die "cannot parse date field <dateModified> from $url\n";
}

exit 0;

