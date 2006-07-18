# $Id: Ping.pm,v 1.6 2006-07-18 10:40:13 mike Exp $

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
    $pod->callback("exception", \&not_connected);
    my $err = $pod->wait($irspy);

    return 0;
}


sub connected { maybe_connected(@_, 1) }
sub not_connected { maybe_connected(@_, 0) }

sub maybe_connected {
    my($conn, $irspy, $rs, $event, $ok) = @_;

    my $rec = $irspy->record($conn);
    $irspy->log("irspy_test", $conn->option("host"),
		($ok ? "" : " not"), " connected");
    $rec->failed(1) if !$ok;
    ### At this point we should note the successful connection in $rec
    return 0;
}


1;
