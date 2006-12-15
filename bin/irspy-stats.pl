#!/usr/bin/perl -w

# $Id: irspy-stats.pl,v 1.2 2006-12-15 10:37:16 mike Exp $
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
$stats->print();
