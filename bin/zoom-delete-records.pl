#!/usr/bin/perl
#
# ./zoom-delete-records.pl user=admin,password=fruitbat,localhost:8018/IR-Explain---1 'concat(count(irspy:status/irspy:probe[@ok=1]), "/", count(irspy:status/irspy:probe))' 'count(irspy:status/irspy:probe[@ok=1]) = 0 and count(irspy:status/irspy:probe) >= 10'

use lib '../lib';
use XML::LibXML;
use ZOOM;
use strict;
use warnings;

die "Usage: $0 <database> <displayXPath> <deleteXPath>\n" if @ARGV != 3;
my($dbname, $displayXPath, $deleteXPath) = @ARGV;

my $libxml = new XML::LibXML;
my $conn = new ZOOM::Connection($dbname);
my $rs = $conn->search(new ZOOM::Query::CQL("cql.allRecords=1"));
$rs->option(elementSetName => "zeerex");

my $n = $rs->size();
foreach my $i (1 .. $n) {
    my $xml = $rs->record($i-1)->render();
    my $rec = $libxml->parse_string($xml)->documentElement();
    my $xc = XML::LibXML::XPathContext->new($rec);
    $xc->registerNs(zeerex => "http://explain.z3950.org/dtd/2.0/");
    $xc->registerNs(irspy => "http://indexdata.com/irspy/1.0");
    my $val = $xc->findvalue($displayXPath);
    print "Record $i/$n: $val";
    $val = $xc->findvalue($deleteXPath);
    print " DELETE" if $val eq "true";
    print "\n";
}
