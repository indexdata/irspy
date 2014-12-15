#!/usr/bin/perl

# Run as:
#	./reindex.pl user=admin,password=SWORDFISH,localhost:8018/IR-Explain---1
#	./reindex.pl -d -q zeerex.reliability=0 localhost:8018/IR-Explain---1

use strict;
use warnings;
use ZOOM;
use Getopt::Long;

my $setUdb = 0;
my $delete = 0;
my $noAction = 0;
my $query = 'cql.allRecords=1';
if (!GetOptions(
	 'setUdb' => \$setUdb,
	 'delete' => \$delete,
	 'noAction' => \$noAction,
	 'query=s' => \$query,
    ) || @ARGV != 1) {
    print STDERR "Usage: $0 [-s|--setUdb] [-d|--delete] [-n|--noaction] [-q <query>] <target>\n";
    exit 1;
}

my $conn = new ZOOM::Connection($ARGV[0]);
$conn->option(preferredRecordSyntax => "xml");
$conn->option(elementSetName => "zebra::data");
my $rs = $conn->search(new ZOOM::Query::CQL($query));

my $n = $rs->size();
$| = 1;
print "$0: reindexing $n records\n";
foreach my $i (1..$n) {
    print ".";
    print " $i/$n (", int($i*100/$n), "%)\n" if $i % 50 == 0;
    my $rec = $rs->record($i-1);
    my $xml = $rec->render();
    if ($xml !~ /<\/(e:)?host>/) {
	# There is an undeletable phantom record: ignore it
	next;
    }

    if ($setUdb) {
	my $udb = qq[<i:udb xmlns:i="http://indexdata.com/irspy/1.0">irspy-$i</i:udb>];
	$xml =~ s/<\/(e:)?host>/$1$udb/;
    }

    update($conn, $xml);
}
print " $n/$n (100%)\n" if $n % 50 != 0;
commit($conn);
print "committed\n";


# These might be better as ZOOM::Connection methods
sub update {
    my($conn, $xml) = @_;

    return if $noAction;
    my $p = $conn->package();
    $p->option(action => $delete ? "recordDelete" : "specialUpdate");
    $p->option(record => $xml);
    $p->send("update");
    $p->destroy();
}

sub commit {
    my($conn) = @_;

    my $p = $conn->package();
    $p->send("commit");
    $p->destroy();
}
