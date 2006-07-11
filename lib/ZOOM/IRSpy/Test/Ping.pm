# $Id: Ping.pm,v 1.5 2006-07-11 14:16:06 mike Exp $

# See the "Main" test package for documentation

package ZOOM::IRSpy::Test::Ping;

use 5.008;
use strict;
use warnings;

use ZOOM::IRSpy::Test;
our @ISA;
@ISA = qw(ZOOM::IRSpy::Test);


sub run {
    my $this = shift();
    my $irspy = $this->irspy();
    my $pod = $irspy->pod();

    $pod->callback(ZOOM::Event::CONNECT, \&connected);
    my $err = $pod->wait($irspy);

    return 0;
}


sub connected {
    my($conn, $irspy, $rs, $event) = @_;

    my $rec = $irspy->record($conn);
    $irspy->log("irspy_test", $conn->option("host"), " connected");
    ### At this point we should note the successful connection in $rec
    return 0;
}


1;
