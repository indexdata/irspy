# $Id: Quick.pm,v 1.4 2007-04-18 15:25:07 mike Exp $

package ZOOM::IRSpy::Test::Quick;

use 5.008;
use strict;
use warnings;

use ZOOM::IRSpy::Test;
our @ISA = qw(ZOOM::IRSpy::Test);

sub subtests { qw(Ping Record::Fetch) }

sub timeout { 20 }

sub start {
    my $class = shift();
    my($conn) = @_;

    $conn->log("irspy_test", "Quick test no-opping");
}

1;
