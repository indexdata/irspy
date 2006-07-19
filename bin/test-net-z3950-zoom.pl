#!/usr/bin/perl -w

# $Id: test-net-z3950-zoom.pl,v 1.1 2006-07-19 11:41:05 mike Exp $
#
# Run the same way as "test-pod.pl".  This is supposed to be an
# exactly equivalent program but written using the Net::Z3950::ZOOM
# imperative API for asynchronous events directly rather than through
# the intermediary of ZOOM::Pod and ZOOM-Perl.

use strict;
use warnings;

use Net::Z3950::ZOOM;

if (@ARGV == 0) {
    printf STDERR "Usage: $0 <target1> [<target2> ...]\n";
    exit 1;
}

Net::Z3950::ZOOM::yaz_log_mask_str("appl");
my @conn;
my %rs;				# maps connection to result-set
my %conn2state;			# maps connection to app. state structure
foreach my $target (@ARGV) {
    my $options = Net::Z3950::ZOOM::options_create();
    Net::Z3950::ZOOM::options_set($options, async => 1);
    Net::Z3950::ZOOM::options_set($options, elementSetName => "b");
    my $conn = Net::Z3950::ZOOM::connection_create($options);
    Net::Z3950::ZOOM::connection_connect($conn, $target, 0);
    push @conn, $conn;
    $rs{$conn} = Net::Z3950::ZOOM::connection_search_pqf($conn, "the");
}

my $res = 0;
while ((my $i = Net::Z3950::ZOOM::event(\@conn)) != 0) {
    my $conn = $conn[$i-1];
    my $ev = Net::Z3950::ZOOM::connection_last_event($conn);
    my $evstr = Net::Z3950::ZOOM::event_str($ev);
    Net::Z3950::ZOOM::yaz_log(Net::Z3950::ZOOM::yaz_log_module_level("pod"),
			      "connection " . ($i-1) . ": event $ev ($evstr)");

    my($errcode, $errmsg, $addinfo) = (undef, "dummy", "dummy");
    $errcode = Net::Z3950::ZOOM::connection_error($conn, $errmsg, $addinfo);
    die "error $errcode ($errmsg) [$addinfo]"
	if $errcode != 0;

    if ($ev == Net::Z3950::ZOOM::EVENT_RECV_SEARCH) {
	$res = completed_search($conn, \%conn2state, $rs{$conn}, $ev);
	die "recieve search failed with error $res" if $res;
    } elsif ($ev == Net::Z3950::ZOOM::EVENT_RECV_RECORD) {
	$res = got_record($conn, \%conn2state, $rs{$conn}, $ev);
	die "recieve record failed with error $res" if $res;
    }
}

sub completed_search {
    my($conn, $arg, $rs, $event) = @_;

    my $host = Net::Z3950::ZOOM::connection_option_get($conn, "host");
    print "$host : found ", Net::Z3950::ZOOM::resultset_size($rs), " records\n";
    my %state = (next_to_show => 0, next_to_fetch => 0);
    request_records($conn, $rs, \%state, 2);
    $arg->{$host} = \%state;
    return 0;
}

sub got_record {
    my($conn, $arg, $rs, $event) = @_;

    my $host = Net::Z3950::ZOOM::connection_option_get($conn, "host");
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
    my $rec = Net::Z3950::ZOOM::resultset_record($rs, $i);
    print "$host: record $i is ", render_record($rec), "\n";
    request_records($conn, $rs, $state, 3)
	if $i == $state->{next_to_fetch}-1;

    return 0;
}

sub request_records {
    my($conn, $rs, $state, $count) = @_;

    my $host = Net::Z3950::ZOOM::connection_option_get($conn, "host");
    my $i = $state->{next_to_fetch};
    Net::Z3950::ZOOM::yaz_log(Net::Z3950::ZOOM::yaz_log_module_level("appl"),
			      "requesting $count records from $i for $host");

    Net::Z3950::ZOOM::resultset_records($rs, $i, $count, 0);
    $state->{next_to_fetch} += $count;
}

sub render_record {
    my($rec) = @_;

    return "undefined" if !defined $rec;
    my $len;
    return "'" . Net::Z3950::ZOOM::record_get($rec, "render", $len) . "'";
}
