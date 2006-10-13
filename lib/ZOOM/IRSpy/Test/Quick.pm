# $Id: Quick.pm,v 1.1 2006-10-13 15:16:29 mike Exp $

package ZOOM::IRSpy::Test::Quick;

use 5.008;
use strict;
use warnings;

use ZOOM::IRSpy::Test;
our @ISA = qw(ZOOM::IRSpy::Test);

sub subtests { qw(Ping Search::Title) }

sub start {
    my $class = shift();
    my($conn) = @_;

    $conn->log("irspy_test", "Quick test no-opping");
}

1;
