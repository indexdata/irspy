# $Id: Quick.pm,v 1.2 2006-10-17 16:21:31 mike Exp $

package ZOOM::IRSpy::Test::Quick;

use 5.008;
use strict;
use warnings;

use ZOOM::IRSpy::Test;
our @ISA = qw(ZOOM::IRSpy::Test);

sub subtests { qw(Ping Search::DBDate Search::Title) }

sub start {
    my $class = shift();
    my($conn) = @_;

    $conn->log("irspy_test", "Quick test no-opping");
}

1;
