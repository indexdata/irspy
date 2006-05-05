#!/usr/bin/perl -w

# $Id: test-pod.pl,v 1.1 2006-05-05 22:14:46 mike Exp $

use strict;
use warnings;

use ZOOM::Pod;

my $pod = new ZOOM::Pod("bagel.indexdata.com/gils",
			"z3950.loc.gov:7090/Voyager");
$pod->callback(ZOOM::Event::RECV_SEARCH, \&show_result);
$pod->search_pqf("mineral");
my $err = $pod->wait();
print "failed with error $err" if $err;

sub show_result {
    my($conn, $rs, $event) = @_;
    print $conn->option("host"), ": found ", $rs->size(), " records\n";
    return 0;
}
