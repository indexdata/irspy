# $Id: Ping.pm,v 1.16 2006-11-29 18:18:37 mike Exp $

# See the "Main" test package for documentation

package ZOOM::IRSpy::Test::Ping;

use 5.008;
use strict;
use warnings;

use ZOOM::IRSpy::Test;
our @ISA = qw(ZOOM::IRSpy::Test);

use ZOOM::IRSpy::Utils qw(isodate);


sub start {
    my $class = shift();
    my($conn) = @_;

    $conn->irspy_connect(undef, {},
			 ZOOM::Event::CONNECT, \&connected,
			 exception => \&not_connected);
}


sub connected { maybe_connected(@_, 1) }
sub not_connected { maybe_connected(@_, 0) }

sub maybe_connected {
    my($conn, $task, $__UNUSED_udata, $event, $ok) = @_;

    $conn->log("irspy_test", ($ok ? "" : "not "), "connected");
    my $rec = $conn->record();
    $rec->append_entry("irspy:status", "<irspy:probe ok='$ok'>" .
		       isodate(time()) . "</irspy:probe>");
    return $ok ? ZOOM::IRSpy::Status::TEST_GOOD :
		 ZOOM::IRSpy::Status::TEST_BAD;
}


1;
