#!/usr/bin/perl -w

# $Id: irspy.pl,v 1.7 2006-06-21 15:58:08 mike Exp $
#
# Run like this:
#	YAZ_LOG=irspy,irspy_test,irspy_debug perl -I lib irspy.pl -t "bagel.indexdata.dk/gils z3950.loc.gov:7090/Voyager" localhost:1313/IR-Explain---1

use strict;
use warnings;
use Getopt::Std;
use ZOOM::IRSpy;

my %opts;
if (!getopts('t:au', \%opts) || @ARGV != 1) {
    print STDERR qq[Usage: $0 [options] <IRSpy-database>
	-t <t1 t2 ...>	Space-separated list of targets to check
	-a		Check all targets registered in database
	-u		Update information in database
];
    exit 1;
}

my $dbname = $ARGV[0];
my $targetList = $opts{t};
if (!defined $targetList && !$opts{a}) {
    print STDERR "$0: neither -t nor -a specified\n";
    exit 2;
}

my $spy = new ZOOM::IRSpy($dbname);
$spy->targets($targetList) if defined $targetList;
$spy->initialise();
my $res = $spy->check();
if ($res == 0) {
    print "All tests were run\n";
} else {
    print "Some tests were skipped\n";
}
