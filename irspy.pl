#!/usr/bin/perl -w

# $Id: irspy.pl,v 1.3 2006-05-22 16:43:36 mike Exp $
#
# Run like this:
#	YAZ_LOG=irspy perl -I lib irspy.pl -t "bagel.indexdata.dk/gils z3950.loc.gov:7090/Voyager" localhost:1313/IR-Explain---1

use strict;
use warnings;
use Getopt::Std;
use Net::Z3950::IRSpy;

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

my $spy = new Net::Z3950::IRSpy($dbname);
$spy->targets($targetList) if defined $targetList;
$spy->initialise();
my $query = $spy->query();
my $n = $spy->hitcount();
print "found $n records from query: $query\n";
$spy->check();
