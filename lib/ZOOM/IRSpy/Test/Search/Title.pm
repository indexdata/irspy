# $Id: Title.pm,v 1.4 2006-09-13 16:30:27 mike Exp $

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

    my $n = $rs->size();
    $irspy->log("irspy_test", $conn->option("host"),
		" title search found $n record", $n==1 ? "" : "s");
    my $rec = $irspy->record($conn);
    $rec->append_entry("irspy:status", "<irspy:search_title ok='1'>" .
		       $irspy->isodate(time()) . "</irspy:search_title>");
    return 0;
}


1;
