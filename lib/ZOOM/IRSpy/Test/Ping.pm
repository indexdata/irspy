# $Id: Ping.pm,v 1.22 2007-03-02 12:17:33 mike Exp $

# See the "Main" test package for documentation

package ZOOM::IRSpy::Test::Ping;

use 5.008;
use strict;
use warnings;

use ZOOM::IRSpy::Test;
our @ISA = qw(ZOOM::IRSpy::Test);

use ZOOM::IRSpy::Utils qw(isodate);

use Text::Iconv;
my $conv = new Text::Iconv("LATIN1", "UTF8");


sub start {
    my $class = shift();
    my($conn) = @_;

    $conn->irspy_connect(undef, {},
			 ZOOM::Event::ZEND, \&connected,
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
	    #print STDERR "\$conn->option('init_opt_$opt') = '", $conn->option("init_opt_$opt"), "'\n";
	    $conn->record()->store_result('init_opt', option => $opt)
		if $conn->option("init_opt_$opt");
	}

	foreach my $opt (qw(serverImplementationId
			    serverImplementationName
			    serverImplementationVersion)) {
	    # There doesn't seem to be a reliable way to tell what
	    # character set the server uses for these.  At least one
	    # server (z3950.bcl.jcyl.es:210/AbsysCCFL) returns an ISO
	    # 8859-1 string containing an o-acute, which breaks the
	    # XML parser if we just insert it naively.  It seems
	    # reasonable, though, to guess that the great majority of
	    # servers will use ASCII, Latin-1 or Unicode.  The first
	    # of these is a subset of the second, so that brings it to
	    # down to two.  The strategy is simply this: assume it's
	    # ASCII-Latin-1, and try to convert to UTF-8.  If that
	    # conversion works, fine; if not, assume it's because the
	    # string was already UTF-8, so use it as is.
	    my $val = $conn->option($opt);
	    Text::Iconv->raise_error(1);
	    my $maybe;
	    eval {
		$maybe = $conv->convert($val);
	    }; if (!$@ && $maybe ne $val) {
		$conn->log("irspy", "converted '$val' from Latin-1 to UTF-8");
		$val = $maybe;
	    }
	    $conn->record()->store_result($opt, value => $val);
	}
    }


    return $ok ? ZOOM::IRSpy::Status::TEST_GOOD :
		 ZOOM::IRSpy::Status::TEST_BAD;
}


1;
