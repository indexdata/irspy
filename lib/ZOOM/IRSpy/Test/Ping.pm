# $Id: Ping.pm,v 1.17 2006-12-06 12:58:06 mike Exp $

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
			 ZOOM::Event::RECV_APDU, \&connected,
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

    if ($ok) {
	foreach my $opt (qw(search present delSet resourceReport
			    triggerResourceCtrl resourceCtrl
			    accessCtrl scan sort extendedServices
			    level_1Segmentation level_2Segmentation
			    concurrentOperations namedResultSets
			    encapsulation resultCount negotiationModel
			    duplicationDetection queryType104
			    pQESCorrection stringSchema)) {
	    $conn->record()->store_result('init_opt', option => $opt)
		if $conn->option("init_opt_$opt");
	}
    }

    return $ok ? ZOOM::IRSpy::Status::TEST_GOOD :
		 ZOOM::IRSpy::Status::TEST_BAD;
}


1;
