# $Id: Title.pm,v 1.5 2006-10-06 11:33:08 mike Exp $

# See the "Main" test package for documentation

package ZOOM::IRSpy::Test::Search::Title;

use 5.008;
use strict;
use warnings;

use ZOOM::IRSpy::Test;
our @ISA = qw(ZOOM::IRSpy::Test);


sub start {
    my $class = shift();
    my($conn) = @_;

    $conn->irspy_search_pqf('@attr 1=4 mineral',
			    ZOOM::Event::RECV_SEARCH, \&found,
			    "exception", \&error);
}


sub found {
    my($conn, $task, $event) = @_;

    my $n = $task->{rs}->size();
    $conn->log("irspy_test",
	       "title search found $n record", $n==1 ? "" : "s");
    my $rec = $conn->record();
    $rec->append_entry("irspy:status", "<irspy:search_title ok='1'>" .
		       isodate(time()) . "</irspy:search_title>");

    return ZOOM::IRSpy::Status::TASK_DONE;
}


sub error {
    my($conn, $task, $exception) = @_;

    $conn->log("irspy_test", "error: $exception");
    my $rec = $conn->record();
    $rec->append_entry("irspy:status", "<irspy:search_title ok='0'>" .
		       isodate(time()) . "</irspy:search_title>");
    return ZOOM::IRSpy::Status::TEST_BAD;
}


1;
