# $Id: Ping.pm,v 1.12 2006-10-06 11:33:08 mike Exp $

# See the "Main" test package for documentation

package ZOOM::IRSpy::Test::Ping;

use 5.008;
use strict;
use warnings;

use ZOOM::IRSpy::Test;
our @ISA = qw(ZOOM::IRSpy::Test);


sub start {
    my $class = shift();
    my($conn) = @_;

    $conn->irspy_connect(ZOOM::Event::CONNECT, \&connected,
			 "exception", \&not_connected);
}


sub connected { maybe_connected(@_, 1) }
sub not_connected { maybe_connected(@_, 0) }

sub maybe_connected {
    my($conn, $rs, $event, $ok) = @_;

    $conn->log("irspy_test", ($ok ? "" : "not "), "connected");
    my $rec = $conn->record();
    $rec->append_entry("irspy:status", "<irspy:probe ok='$ok'>" .
		       isodate(time()) . "</irspy:probe>");
    $conn->option(pod_omit => 1) if !$ok;
    return ZOOM::IRSpy::Status::TASK_DONE;
}


1;
