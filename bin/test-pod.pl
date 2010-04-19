#!/usr/bin/perl -w
#
# Run like this:
#	YAZ_LOG=pod perl -I ../lib test-pod.pl "bagel.indexdata.com/gils" "bagel.indexdata.com/marc"

use strict;
use warnings;

use ZOOM::Pod;

if (@ARGV == 0) {
    printf STDERR "Usage: $0 <target1> [<target2> ...]\n";
    exit 1;
}

ZOOM::Log::mask_str("appl");
my $pod = new ZOOM::Pod(@ARGV);
$pod->option(elementSetName => "b");
$pod->callback(ZOOM::Event::RECV_SEARCH, \&completed_search);
$pod->callback(ZOOM::Event::RECV_RECORD, \&got_record);
#$pod->callback(exception => \&exception_thrown);
$pod->search_pqf("the");
my $err = $pod->wait({});
die "$pod->wait() failed with error $err" if $err;

sub completed_search {
    my($conn, $arg, $rs, $event) = @_;

    my $host = $conn->option("host");
    print "$host : found ", $rs->size(), " records\n";
    my %state = (next_to_show => 0, next_to_fetch => 0);
    request_records($conn, $rs, \%state, 2);
    $arg->{$host} = \%state;
    return 0;
}

sub got_record {
    my($conn, $arg, $rs, $event) = @_;

    my $host = $conn->option("host");
    my $state = $arg->{$host};

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
    print "$host: record $i is ", render_record($rec), "\n";
    request_records($conn, $rs, $state, 3)
	if $i == $state->{next_to_fetch}-1;

    return 0;
}

sub exception_thrown {
    my($conn, $arg, $rs, $exception) = @_;
    print "Uh-oh!  $exception\n";
    return 0;
}

sub request_records {
    my($conn, $rs, $state, $count) = @_;

    my $i = $state->{next_to_fetch};
    ZOOM::Log::log("appl", "requesting $count records from $i for ",
		   $conn->option("host"));
    $rs->records($i, $count, 0);
    $state->{next_to_fetch} += $count;
}

sub render_record {
    my($rec) = @_;

    return "undefined" if !defined $rec;
    return "'" . $rec->render() . "'";
}
