#!/usr/bin/perl -w

# $Id: irspy-stats.pl,v 1.5 2007-10-31 16:07:40 mike Exp $
#
#	perl -I ../lib irspy-stats.pl localhost:8018/IR-Explain---1 "net.host=*indexdata*"

use strict;
use warnings;
use ZOOM::IRSpy;

if (@ARGV < 2) {
    print STDERR "Usage: $0 [CQL-query]\n";
    exit 1;
}

my($dbname, $query) = @ARGV;
my $stats = new ZOOM::IRSpy::Stats($dbname, $query);
$stats->print();
