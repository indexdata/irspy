#!/usr/bin/perl -w

# $Id: test-pod.pl,v 1.4 2006-05-10 13:00:33 mike Exp $
#
# Run like this:
#	YAZ_LOG=pod perl -I lib test-pod.pl
# (at least until the default sync. behaviour of ZOOM-C changes.)

use strict;
use warnings;

use ZOOM::Pod;

my $pod = new ZOOM::Pod("bagel.indexdata.com/gils",
			"bagel.indexdata.com/marc",
			#"z3950.loc.gov:7090/Voyager",
			#"localhost:9999",
			);
$pod->option(elementSetName => "b");
$pod->callback(ZOOM::Event::RECV_SEARCH, \&completed_search);
$pod->callback(ZOOM::Event::RECV_RECORD, \&got_record);
$pod->search_pqf("the");
my $err = $pod->wait();
die "$pod->wait() failed with error $err" if $err;

sub completed_search {
    my($conn, $state, $rs, $event) = @_;
    print $conn->option("host"), ": found ", $rs->size(), " records\n";
    $state->{next_to_fetch} = 0;
    $state->{next_to_show} = 0;
    request_record($conn, $rs, $state);
    return 0;
}

sub got_record {
    my($conn, $state, $rs, $event) = @_;

    {
	# Sanity-checking assertions.  These should be impossible
	my $ns = $state->{next_to_show};
	my $nf = $state->{next_to_fetch};
	if ($ns > $nf) {
	    die "next_to_show > next_to_fetch ($ns > $nf)";
	} elsif ($ns == $nf) {
	    die "next_to_show == next_to_fetch ($ns)";
	}
    }

    my $i = $state->{next_to_show}++;
    my $rec = $rs->record($i);
    print $conn->option("host"), ": record $i is ", render_record($rec), "\n";
    request_record($conn, $rs, $state);
    return 0;
}

sub request_record {
    my($conn, $rs, $state) = @_;

    my $i = $state->{next_to_fetch}++;
    my $rec = $rs->records($i, 1, 0);
    print($conn->option("host"), ": pre-fetch: record $i is ",
	  render_record($rec), "\n");
}

sub render_record {
    my($rec) = @_;

    return "undefined" if !defined $rec;
    return "'" . $rec->render() . "'";
}
