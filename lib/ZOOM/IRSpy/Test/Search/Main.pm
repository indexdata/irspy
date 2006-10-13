# $Id: Main.pm,v 1.4 2006-10-13 13:40:29 sondberg Exp $

package ZOOM::IRSpy::Test::Search::Main;

use 5.008;
use strict;
use warnings;

use ZOOM::IRSpy::Test;
our @ISA = qw(ZOOM::IRSpy::Test);

sub subtests { qw(Search::Title Search::Bib1 Search::Dan1) }

sub start {
    my $class = shift();
    my($conn) = @_;

    $conn->log("irspy_test", "Main::Search test no-opping");
    # Do nothing -- this test is just a subtest container
}

1;
