#!/usr/bin/perl -w

# $Id: test-pod.pl,v 1.2 2006-05-09 12:09:44 mike Exp $
#
# Run like this:
#	ZOOM_RECORD_NO_FORCE_SYNC=1 perl -I lib test-pod.pl
# (at least until the default sync. behaviour of ZOOM-C changes.)

use strict;
use warnings;

use ZOOM::Pod;

my $pod = new ZOOM::Pod("bagel.indexdata.com/gils",
			"z3950.loc.gov:7090/Voyager",
			"localhost:9999",
			);
$pod->callback(ZOOM::Event::RECV_SEARCH, \&completed_search);
$pod->callback(ZOOM::Event::RECV_RECORD, \&got_record);
$pod->search_pqf("mineral");
my $err = $pod->wait();
print "failed with error $err" if $err;

sub completed_search {
    my($conn, $rs, $event) = @_;
    print $conn->option("host"), ": found ", $rs->size(), " records\n";
    my $rec = $rs->record(0);
    print($conn->option("host"), ": rec(0) is ",
	  defined $rec ? ("$rec = '", $rec->render(), "'") : "undefined",
	  "\n");
    return 0;
}

sub got_record {
    my($conn, $rs, $event) = @_;
    my $rec = $rs->record(0);
    print $conn->option("host"), ": got 0: $rec = '", $rec->render(), "'\n";
    return 0;
}
