# $Id: Main.pm,v 1.7 2007-01-29 17:12:54 mike Exp $

package ZOOM::IRSpy::Test::Search::Main;

use 5.008;
use strict;
use warnings;

use ZOOM::IRSpy::Test;
our @ISA = qw(ZOOM::IRSpy::Test);

sub subtests { qw(Search::Bib1 Search::Dan1 Search::Boolean
                  Search::Explain) }

sub start {
    my $class = shift();
    my($conn) = @_;

    $conn->log("irspy_test", "Main::Search test no-opping");
    # Do nothing -- this test is just a subtest container
}

1;
