# $Id: Ping.pm,v 1.3 2006-06-21 16:10:18 mike Exp $

# See the "Main" test package for documentation

package ZOOM::IRSpy::Test::Ping;

use 5.008;
use strict;
use warnings;

use ZOOM::IRSpy::Test;
our @ISA;
@ISA = qw(ZOOM::IRSpy::Test);


sub run {
    my $this = shift();
    my $irspy = $this->irspy();
    my $pod = $irspy->pod();

    $pod->callback(ZOOM::Event::CONNECT, \&connected);
    my $err = $pod->wait($irspy);

    return 0;
}


sub connected {
    my($conn, $irspy, $rs, $event) = @_;

    my $rec = $irspy->record($conn);
    $irspy->log("irspy_test", $conn->option("host"), " connected");
    ### Note the successful connection in $rec
    return 0;
}


# Some of this Pod-using code may be useful.
#
#$pod->option(elementSetName => "b");
#$pod->callback(ZOOM::Event::RECV_SEARCH, \&completed_search);
#$pod->callback(ZOOM::Event::RECV_RECORD, \&got_record);
##$pod->callback(exception => \&exception_thrown);
#$pod->search_pqf("the");
#my $err = $pod->wait();
#die "$pod->wait() failed with error $err" if $err;
#
#sub completed_search {
#    my($conn, $state, $rs, $event) = @_;
#    print $conn->option("host"), ": found ", $rs->size(), " records\n";
#    $state->{next_to_fetch} = 0;
#    $state->{next_to_show} = 0;
#    request_records($conn, $rs, $state, 2);
#    return 0;
#}
#
#sub got_record {
#    my($conn, $state, $rs, $event) = @_;
#
#    {
#	# Sanity-checking assertions.  These should be impossible
#	my $ns = $state->{next_to_show};
#	my $nf = $state->{next_to_fetch};
#	if ($ns > $nf) {
#	    die "next_to_show > next_to_fetch ($ns > $nf)";
#	} elsif ($ns == $nf) {
#	    die "next_to_show == next_to_fetch ($ns)";
#	}
#    }
#
#    my $i = $state->{next_to_show}++;
#    my $rec = $rs->record($i);
#    print $conn->option("host"), ": record $i is ", render_record($rec), "\n";
#    request_records($conn, $rs, $state, 3)
#	if $i == $state->{next_to_fetch}-1;
#
#    return 0;
#}
#
#sub exception_thrown {
#    my($conn, $state, $rs, $exception) = @_;
#    print "Uh-oh!  $exception\n";
#    return 0;
#}
#
#sub request_records {
#    my($conn, $rs, $state, $count) = @_;
#
#    my $i = $state->{next_to_fetch};
#    ZOOM::Log::log("irspy", "requesting $count records from $i");
#    $rs->records($i, $count, 0);
#    $state->{next_to_fetch} += $count;
#}
#
#sub render_record {
#    my($rec) = @_;
#
#    return "undefined" if !defined $rec;
#    return "'" . $rec->render() . "'";
#}


1;
