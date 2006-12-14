#!/usr/bin/perl -w

# $Id: irspy-stats.pl,v 1.1 2006-12-14 17:35:13 mike Exp $
#
#	perl -I ../lib irspy-stats.pl localhost:3313/IR-Explain---1

use strict;
use warnings;
use ZOOM::IRSpy;

if (@ARGV > 2) {
    print STDERR "Usage: $0 [CQL-query]\n";
    exit 1;
}

my($dbname, $query) = @ARGV;
my $stats = new ZOOM::IRSpy::Stats($dbname, $query);
use Data::Dumper;
print Dumper($stats);
