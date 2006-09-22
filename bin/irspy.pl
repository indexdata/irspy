#!/usr/bin/perl -w

# $Id: irspy.pl,v 1.7 2006-09-22 15:27:17 mike Exp $
#
# Run like this:
#	YAZ_LOG=irspy,irspy_test,irspy_debug perl -I ../lib irspy.pl -t "bagel.indexdata.dk/gils z3950.loc.gov:7090/Voyager" localhost:3313/IR-Explain---1

use strict;
use warnings;
use ZOOM::IRSpy;

my($dbname, @targets) = @ARGV;
if (!defined $dbname) {
    print STDERR "Usage $0: <IRSpy-database> [<target> ...]\n";
    print STDERR "If no targets are specified, all targets in DB are tested\n";
    exit 1;
}

my $spy = new ZOOM::IRSpy($dbname, "admin", "fruitbat");
$spy->targets(@targets) if @targets;
$spy->initialise();
my $res = $spy->check();
if ($res == 0) {
    print "All tests were run\n";
} else {
    print "Some tests were skipped\n";
}
