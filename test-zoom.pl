#!/usr/bin/perl -w

# $Id: test-zoom.pl,v 1.1 2006-07-18 16:15:25 mike Exp $
#
# Run the same way as "test-pod.pl".  This is supposed to be an
# exactly equivalent program but written using the ZOOM-Perl
# asynchronous-event API directly rather than through the intermediary
# of ZOOM::Pod.

use strict;
use warnings;

use ZOOM;

if (@ARGV == 0) {
    printf STDERR "Usage: $0 <target1> [<target2> ...]\n";
    exit 1;
}

ZOOM::Log::mask_str("appl");
my @conn;
my %rs;				# maps connection to result-set
my %state;			# maps connection to app. state structure
foreach my $target (@ARGV) {
    my $conn = new ZOOM::Connection($target, 0, async => 1,
				    elementSetName => "b");
    push @conn, $conn;
    $rs{$conn} = $conn->search_pqf("the");
}

my $res = 0;
while ((my $i = ZOOM::event(\@conn)) != 0) {
    my $conn = $conn[$i-1];
    my $ev = $conn->last_event();
    my $evstr = ZOOM::event_str($ev);
    ZOOM::Log::log("pod", "connection ", $i-1, ": event $ev ($evstr)");
    $conn->_check();		# die if any errors occur

    if ($ev == ZOOM::Event::RECV_SEARCH) {
	$res = completed_search($conn, \%state, $rs{$conn}, $ev);
	die "recieve search failed with error $res" if $res;
    } elsif ($ev == ZOOM::Event::RECV_RECORD) {
	$res = got_record($conn, \%state, $rs{$conn}, $ev);
	die "recieve record failed with error $res" if $res;
    }
}




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
