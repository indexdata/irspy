# $Id: Bib1.pm,v 1.1 2006-09-26 13:12:28 sondberg Exp $

# See the "Main" test package for documentation

package ZOOM::IRSpy::Test::Search::Bib1;

use 5.008;
use strict;
use warnings;
use Data::Dumper;

use ZOOM::IRSpy::Test;
our @ISA = @ISA = qw(ZOOM::IRSpy::Test);
our @Bib1_Attr = qw(1 2 3 4 5 6 7 8 9); 


sub run {
    my $this = shift();
    my $irspy = $this->irspy();
    my $pod = $irspy->pod();

    $pod->callback(ZOOM::Event::RECV_SEARCH, \&found);

    foreach my $attr (@Bib1_Attr) {
        $pod->search_pqf('@attr 1=' . $attr . ' water' );
        my $err = $pod->wait({'irspy' => $irspy, 'attr' => $attr});
    }

    return 0;
}


sub found {
    my($conn, $href, $rs, $event) = @_;
    my $irspy = $href->{'irspy'};
    my $attr = $href->{'attr'};
    my $n = $rs->size();
    my $rec = $irspy->record($conn);

    $irspy->log("irspy_test", $conn->option("host"),
		" Bib-1 attribute=$attr search found $n record",
                $n==1 ? "" : "s");

    $rec->append_entry("irspy:status", "<irspy:search set='bib1' attr='$attr'" .
                       " ok='1'>" . $irspy->isodate(time()) .
                       "</irspy:search>");
    return 0;
}


1;
