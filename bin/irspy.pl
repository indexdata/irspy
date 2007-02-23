#!/usr/bin/perl -w

# $Id: irspy.pl,v 1.22 2007-02-23 16:44:50 mike Exp $
#
# Run like this:
#	YAZ_LOG=irspy,irspy_test IRSPY_SAVE_XML=1 perl -I../lib irspy.pl -t Quick localhost:8018/IR-Explain---1 z3950.loc.gov:7090/Voyager bagel.indexdata.dk/gils bagel.indexdata.dk:210/marc
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
use ZOOM::IRSpy::Web;

my %opts;
if (!getopts('wt:af:', \%opts) || @ARGV < 1) {
    print STDERR "\
Usage $0: [options] <IRSpy-database> [<target> ...]
	-w		Use ZOOM::IRSpy::Web subclass
	-t <test>	Run the specified <test> [default: all tests]
	-a		Test all targets (slow!)
	-f <query>	Test targets found by the specified query
";
    exit 1;
}

my($dbname, @targets) = @ARGV;
my $class = "ZOOM::IRSpy";
$class .= "::Web" if $opts{w};

my $spy = $class->new($dbname, "admin", "fruitbat");
if (@targets) {
    $spy->targets(@targets);
} elsif ($opts{f}) {
    $spy->find_targets($opts{f});
} elsif (!$opts{a}) {
    print STDERR "$0: specify -a, -f <query> or list of targets\n";
    exit 1;
}

$spy->initialise();
my $res = $spy->check($opts{t});
if ($res == 0) {
    print "All tests were attempted\n";
} else {
    print "$res tests were skipped\n";
}


# Fake the HTML::Mason class that ZOOM::IRSpy::Web uses
package HTML::Mason::Commands;
BEGIN { our $m = bless {}, "HTML::Mason::Commands" }
sub flush_buffer { print shift(), " flushing\n" if 0 }
