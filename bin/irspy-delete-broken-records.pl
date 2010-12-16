#!/opt/local/bin/perl
#
# ./irspy-delete-broken-records.pl user=admin,password=fruitbat,localhost:8018/IR-Explain---1 'concat(count(irspy:status/irspy:probe[@ok=1]), "/", count(irspy:status/irspy:probe))'

use lib '../lib';
use XML::LibXML;
use ZOOM;
use strict;
use warnings;

die "Usage: $0 <database> <xpath>\n" if @ARGV != 2;
my($dbname, $xpath) = @ARGV;

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
    my $val = $xc->findvalue($xpath);
    print "Record $i/$n: $val\n";
}
