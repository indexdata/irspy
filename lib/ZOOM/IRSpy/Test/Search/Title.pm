# $Id: Title.pm,v 1.3 2006-07-24 17:02:51 mike Exp $

# See the "Main" test package for documentation

package ZOOM::IRSpy::Test::Search::Title;

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

    $pod->callback(ZOOM::Event::RECV_SEARCH, \&found);
    $pod->search_pqf('@attr 1=4 computer');
    my $err = $pod->wait($irspy);
    ### Should notice failure and log it.

    return 0;
}


sub found {
    my($conn, $irspy, $rs, $event) = @_;

    my $rec = $irspy->record($conn);
    my $n = $rs->size();
    $irspy->log("irspy_test", $conn->option("host"),
		" title search found $n record", $n==1 ? "" : "s");
    $rec->append_entry("irspy:status", "<irspy:search_title ok='1'>" .
		       $irspy->isodate(time()) . "</irspy:search_title>");
    return 0;
}


1;
