# $Id: Bib1.pm,v 1.8 2006-10-12 14:40:33 mike Exp $

# See the "Main" test package for documentation

package ZOOM::IRSpy::Test::Search::Bib1;

use 5.008;
use strict;
use warnings;

use ZOOM::IRSpy::Test;
our @ISA = qw(ZOOM::IRSpy::Test);


sub start {
    my $class = shift();
    my($conn) = @_;

    my @attrs = (1,		# personal name
		 4,		# title
		 52,		# subject
		 1003,		# author
		 1016,		# any
		 );
    foreach my $attr (@attrs) {
	$conn->irspy_search_pqf("\@attr 1=$attr mineral", $attr,
				ZOOM::Event::RECV_SEARCH, \&found,
				exception => \&error);
    }
}


sub found {
    my($conn, $task, $attr, $event) = @_;

    my $n = $task->{rs}->size();
    $conn->log("irspy_test", "search on access-point $attr found $n record",
	       $n==1 ? "" : "s");
    $conn->record()->append_entry("irspy:status",
				  "<irspy:search_bib1 ap='$attr' ok='1'>" .
				  isodate(time()) .
				  "</irspy:search_bib1>");

    return ZOOM::IRSpy::Status::TASK_DONE;
}


sub error {
    my($conn, $task, $attr, $exception) = @_;

    $conn->log("irspy_test", "search on access-point $attr had error: ",
	       $exception);
    $conn->record()->append_entry("irspy:status",
				  "<irspy:search_bib1 ap='$attr' ok='0'>" .
				  isodate(time()) .
				  "</irspy:search_bib1>");
    return ZOOM::IRSpy::Status::TASK_DONE;
}


1;
