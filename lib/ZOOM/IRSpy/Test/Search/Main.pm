# $Id: Main.pm,v 1.2 2006-10-06 11:33:08 mike Exp $

package ZOOM::IRSpy::Test::Search::Main;

use 5.008;
use strict;
use warnings;

use ZOOM::IRSpy::Test;
our @ISA = qw(ZOOM::IRSpy::Test);

sub subtests { qw(Search::Title Search::Bib1) }

sub start {
    # Do nothing -- this test is just a subtest container
}

1;
