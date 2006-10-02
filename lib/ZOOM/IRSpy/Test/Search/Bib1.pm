# $Id: Bib1.pm,v 1.4 2006-10-02 13:02:10 sondberg Exp $

# See the "Main" test package for documentation

package ZOOM::IRSpy::Test::Search::Bib1;

use 5.008;
use strict;
use warnings;
use Data::Dumper;

use ZOOM::IRSpy::Test;
our @ISA = qw(ZOOM::IRSpy::Test);
our @Bib1_Attr = qw(1 2 3 4 5 6 7 8 9); 


sub run {
    my $this = shift();
    my $irspy = $this->irspy();
    my $pod = $irspy->pod();

    $pod->callback(ZOOM::Event::RECV_SEARCH, \&found);
    $pod->callback("exception", \&error_handler);
    $pod->callback(ZOOM::Event::ZEND, \&continue);

    foreach my $attr (@Bib1_Attr) {
        $pod->search_pqf('@attr 1=' . $attr . ' water' );
        $irspy->{'handle'}->{'attr'} = $attr;
        my $err = $pod->wait($irspy);
    }

    return 0;
}


sub found {
    my($conn, $irspy, $rs, $event) = @_;
    my $href = $irspy->{'handle'};
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


sub continue { 
    my ($conn, $irspy, $rs, $event) = @_;

    print "ZEND\n";
}



sub error_handler { maybe_connected(@_, 0) }

sub maybe_connected {
    my($conn, $irspy, $rs, $event, $ok) = @_;

    $irspy->log("irspy_test", $conn->option("host"),
		($ok ? "" : " not"), " connected");
    my $rec = $irspy->record($conn);
    $rec->append_entry("irspy:status", "<irspy:probe ok='$ok'>" .
		       $irspy->isodate(time()) . "</irspy:probe>");
    $conn->option(pod_omit => 1) if !$ok;
    return 0;
}

1;
