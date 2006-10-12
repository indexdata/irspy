#!/usr/bin/perl -w

# $Id: irspy.pl,v 1.13 2006-10-12 16:53:04 mike Exp $
#
# Run like this:
#	YAZ_LOG=irspy,irspy_test,irspy_debug,irspy_event perl -I ../lib irspy.pl -t Main localhost:3313/IR-Explain---1 bagel.indexdata.dk/gils z3950.loc.gov:7090/Voyager bagel.indexdata.dk:210/marc
# Available log-levels are as follows:
#	irspy -- high-level application logging
#	irspy_debug -- low-level debugging (not very interesting)
#	irspy_event -- invocations of ZOOM_event() and individual events
#	irspy_unhandled -- unhandled events (not very interesting)
#	irspy_test -- adding, queueing and running tests
#	irspy_task -- adding, queueing and running tasks

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
    print "$res tests were skipped\n";
}
