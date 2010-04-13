#!/usr/bin/perl -w

# perl -I ../lib irspy-rewrite-records.pl localhost:8018/IR-Explain---1

use strict;
use warnings;
use ZOOM::IRSpy;
use ZOOM::IRSpy::Utils qw(render_record);

my($dbname) = @ARGV;
die "$0 no database name specified" if !defined $dbname;
my $spy = new ZOOM::IRSpy($dbname, "admin", "fruitbat");
my $rs = $spy->{conn}->search(new ZOOM::Query::CQL("cql.allRecords=1"));
print STDERR "rewriting ", $rs->size(), " target records";

foreach my $i (1 .. $rs->size()) {
    my $xml = render_record($rs, $i-1, "zeerex");
    my $rec = $spy->{libxml}->parse_string($xml)->documentElement();
    ZOOM::IRSpy::_rewrite_zeerex_record($spy->{conn}, $rec);
    print STDERR ".";
}
print STDERR "\nDone\n";
