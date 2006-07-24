# $Id: Ping.pm,v 1.9 2006-07-24 16:16:29 mike Exp $

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
    $rec->append_entry("irspy:status", "<irspy:probe ok='$ok'>" .
		       isodate(time()) . "</irspy:probe>");
    $conn->option(pod_omit => 1) if !$ok;
    return 0;
}


sub isodate {
    my($time) = @_;

    my($sec, $min, $hour, $mday, $mon, $year) = localtime($time);
    return sprintf("%04d-%02d-%02dT%02d:%02d:%02d",
		   $year+1900, $mon+1, $mday, $hour, $min, $sec);
}


1;
