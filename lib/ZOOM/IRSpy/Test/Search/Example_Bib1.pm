# $Id: Example_Bib1.pm,v 1.1 2006-10-02 13:02:58 sondberg Exp $

# This is an example test probe. The assumptions are:
# 
# 1. We should reuse as much as possible of the existing framework
# 2. Each method is called with a method that inherits from the ZOOM class
# 3. The notion of a Pod is dropped, because each connection is completely
#    independent.
# 4  The wait method should block program execution and control is passed to
#    the ZOOM/C layer.
# 5. The "handle" property can be more or less institutionalized. But I think
#    we need a way to share information between methods and callbacks...
# 6. We'll need to discuss how we setup the order in which the tests are
#    carried out. I don't like the idea that all connections must be in the
#    same test state all the time. I *think* that this can be done multi
#    threaded - conceptually (not the perl way of doing threads). Thus the
#    method continue(1/0)

package ZOOM::IRSpy::Test::Search::Example_Bib1;

use 5.008;
use strict;
use warnings;
use Data::Dumper;

use ZOOM::IRSpy::Test;
our @ISA = qw(ZOOM::IRSpy::Test);
our @Bib1_Attr = qw(1 2 3 4 5 6 7 8 9); 


sub run {
    my $this = shift();         ## Connection object
    my $irspy = $this->irspy(); ## Each connection shares the irspy object

    ## On your own risk "handle reference" - we simply gonna need that!
    my $handle = $this->{'handle'};

    ## Callbacks can be overwritten - but they exist in the Test base class
    ## such that you don't *need* to overwrite them everytime you write a
    ## new testing module...
    
    $this->callback(ZOOM::Event::RECV_SEARCH, \&found);

    foreach my $attr (@Bib1_Attr) {
        $this->search_pqf('@attr 1=' . $attr . ' water' );
        $handle->{'bib1_attr'} = $attr;
        $this->wait();          ## I assume this wait blocks execution!
    }

    $this->continue(1);         ## Perform the next test in the sequence
    #$this->continue(0);         ## Perform the next test in the sequence

    return 0;
}


sub found {
    my ($this) = @_;
    my $irspy = $this->irspy();
    my $handle = $this->{'handle'};
    my $bib1_attr = $handle->{'bib1_attr'};
    my $rs = $this->getResultSet();
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
