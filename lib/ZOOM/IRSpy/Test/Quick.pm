# $Id: Quick.pm,v 1.3 2006-10-25 10:48:34 mike Exp $

package ZOOM::IRSpy::Test::Quick;

use 5.008;
use strict;
use warnings;

use ZOOM::IRSpy::Test;
our @ISA = qw(ZOOM::IRSpy::Test);

sub subtests { qw(Ping Record::Fetch) }

sub start {
    my $class = shift();
    my($conn) = @_;

    $conn->log("irspy_test", "Quick test no-opping");
}

1;
