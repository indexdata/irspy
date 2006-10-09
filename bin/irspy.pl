#!/usr/bin/perl -w

# $Id: irspy.pl,v 1.11 2006-10-09 07:29:43 mike Exp $
#
# Run like this:
#	YAZ_LOG=irspy,irspy_test,irspy_debug,irspy_event perl -I ../lib irspy.pl -t Main localhost:3313/IR-Explain---1 bagel.indexdata.dk/gils z3950.loc.gov:7090/Voyager bagel.indexdata.dk:210/marc

use strict;
use warnings;
use Getopt::Std;
use ZOOM::IRSpy;

my %opts;
if (!getopts('t:', \%opts) || @ARGV < 1) {
    print STDERR "\
Usage $0: [options] <IRSpy-database> [<target> ...]
If no targets are specified, all targets in DB are tested.
	-t <test>	Run the specified <test> [default: all tests]
";
    exit 1;
}

my($dbname, @targets) = @ARGV;
my $spy = new ZOOM::IRSpy($dbname, "admin", "fruitbat");
$spy->targets(@targets) if @targets;
$spy->initialise();
my $res = $spy->check($opts{t});
if ($res == 0) {
    print "All tests were run\n";
} else {
    print "Some tests were skipped\n";
}
