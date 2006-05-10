#!/usr/bin/perl -w

# $Id: test-pod.pl,v 1.6 2006-05-10 13:38:31 mike Exp $
#
# Run like this:
#	YAZ_LOG=pod perl -I lib test-pod.pl "bagel.indexdata.com/gils" "bagel.indexdata.com/marc"

use strict;
use warnings;

use ZOOM::Pod;
ZOOM::Log::mask_str("appl");

my $pod = new ZOOM::Pod(@ARGV);
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
    request_records($conn, $rs, $state, 2);
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
    request_records($conn, $rs, $state, 3)
	if $i == $state->{next_to_fetch}-1;

    return 0;
}

sub request_records {
    my($conn, $rs, $state, $count) = @_;

    my $i = $state->{next_to_fetch};
    ZOOM::Log::log("appl", "requesting $count records from $i");
    $rs->records($i, $count, 0);
    $state->{next_to_fetch} += $count;
}

sub render_record {
    my($rec) = @_;

    return "undefined" if !defined $rec;
    return "'" . $rec->render() . "'";
}
