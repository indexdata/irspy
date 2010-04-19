#!/usr/bin/perl -w

#
# Run like this:
#	find-different-access-point.pl fish bagel:210/gils bagel:210/marc
# This is not an IRSpy program: it's a ZOOM-Perl program, which is
# used to find a BIB-1 attribute that is supported differently by two
# or more targets.  Using the output of this, it's possible to create
# an IRSpy test plugin that passes one server and fails another.

use strict;
use warnings;
use ZOOM;

if (@ARGV < 3) {
    print STDERR "Usage $0 <PQF> <target1> <target2> [<target3> ...]";
    exit 1;
}

my $query = shift(@ARGV);
my @conns = map { new ZOOM::Connection($_) } @ARGV;

print "$query\n";
print "@ARGV\n";
for (my $i = 1; $i < 9999; $i++) {
    print "$i";
    my $different = 0;
    my $sofar = undef;
    foreach my $conn (@conns) {
	my $rs;
	eval { $rs = $conn->search_pqf("\@attr 1=$i $query") };
	my $ok = !$@;
	print "\t", $ok ? "ok(" . $rs->size(). ")" : "FAIL($@)";
	if (!defined $sofar) {
	    $sofar = $ok;
	} elsif ($ok != $sofar) {
	    $different = 1;
	}
    }
    print "\n";
    last if $different;
}
