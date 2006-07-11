# $Id: Title.pm,v 1.2 2006-07-11 14:16:35 mike Exp $

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

    return 0;
}


sub found {
    my($conn, $irspy, $rs, $event) = @_;

    my $rec = $irspy->record($conn);
    my $n = $rs->size();
    $irspy->log("irspy_test", $conn->option("host"),
		" title search found $n record", $n==1 ? "" : "s");
    ### We should note the success or failure of the search in $rec
    return 0;
}


1;
