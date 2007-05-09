#!/usr/bin/perl -w

# $Id: irspy.pl,v 1.28 2007-05-09 11:07:03 mike Exp $
#
# Run like this:
#	YAZ_LOG=irspy,irspy_test IRSPY_SAVE_XML=1 perl -I../lib irspy.pl -t Quick localhost:8018/IR-Explain---1 Z39.50:amicus.oszk.hu:1616/ANY
#	YAZ_LOG=irspy,irspy_test sudo ./setrlimit -n 3000 -u mike -- perl -I../lib irspy.pl -t Main -a localhost:8018/IR-Explain---1
#	YAZ_LOG=irspy,irspy_test perl -I../lib irspy.pl -t Main -a -n 100 localhost:8018/IR-Explain---1
#
# Available log-levels are as follows:
#	irspy -- high-level application logging
#	irspy_debug -- low-level debugging (not very interesting)
#	irspy_event -- invocations of ZOOM_event() and individual events
#	irspy_unhandled -- unhandled events (not very interesting)
#	irspy_test -- adding, queueing and running tests
#	irspy_task -- adding, queueing and running tasks

# I have no idea why this directory is not in Ubuntu's default Perl
# path, but we need it because just occasionally overload.pm:88
# requires Scalar::Util, which is in this directory.

use lib '/usr/share/perl/5.8.7';
use Scalar::Util;

use strict;
use warnings;
use Getopt::Std;
use ZOOM::IRSpy::Web;
use Carp;

$SIG{__DIE__} = sub {
    my($msg) = @_;
    confess($msg);
};

my %opts;
if (!getopts('wt:af:n:', \%opts) || @ARGV < 1) {
    print STDERR "\
Usage $0: [options] <IRSpy-database> [<target> ...]
	-w		Use ZOOM::IRSpy::Web subclass
	-t <test>	Run the specified <test> [default: all tests]
	-a		Test all targets (slow!)
	-f <query>	Test targets found by the specified query
	-n <number>	Number of connection to keep in active set
";
    exit 1;
}

my($dbname, @targets) = @ARGV;
my $class = "ZOOM::IRSpy";
$class .= "::Web" if $opts{w};

my $spy = $class->new($dbname, "admin", "fruitbat", $opts{n});
if (@targets) {
    $spy->targets(@targets);
} elsif ($opts{f}) {
    $spy->find_targets($opts{f});
} elsif (!$opts{a}) {
    print STDERR "$0: specify -a, -f <query> or list of targets\n";
    exit 1;
}

$spy->initialise($opts{t});
my $res = $spy->check();
if ($res == 0) {
    print "All tests were attempted\n";
} else {
    print "$res tests were skipped\n";
}


# Fake the HTML::Mason class that ZOOM::IRSpy::Web uses
package HTML::Mason::Commands;
BEGIN { our $m = bless {}, "HTML::Mason::Commands" }
sub flush_buffer { print shift(), " flushing\n" if 0 }
