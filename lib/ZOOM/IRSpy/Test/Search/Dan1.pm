# $Id: Dan1.pm,v 1.1 2006-10-13 13:40:29 sondberg Exp $

# See the "Main" test package for documentation

package ZOOM::IRSpy::Test::Search::Dan1;

use 5.008;
use strict;
use warnings;

use ZOOM::IRSpy::Test;
our @ISA = qw(ZOOM::IRSpy::Test);


sub start {
    my $class = shift();
    my($conn) = @_;
    my @attrs = ( 1..27            # Dan-1
                );

    foreach my $attr (@attrs) {
	$conn->irspy_search_pqf("\@attr dan1 1=$attr mineral",
                                {'attr' => $attr},
				ZOOM::Event::RECV_SEARCH, \&found,
				exception => \&error);
    }
}


sub found {
    my($conn, $task, $test_args, $event) = @_;
    my $attr = $test_args->{'attr'};
    my $n = $task->{rs}->size();

    $conn->log("irspy_test", "search on access-point $attr found $n record",
	       $n==1 ? "" : "s");
    $conn->record()->append_entry("irspy:status",
				  "<irspy:search set='dan1' ap='$attr' ok='1'>".
				  isodate(time()) .
				  "</irspy:search>");

    return ZOOM::IRSpy::Status::TASK_DONE;
}


sub error {
    my($conn, $task, $test_args, $exception) = @_;
    my $attr = $test_args->{'attr'};

    $conn->log("irspy_test", "search on access-point $attr had error: ",
	       $exception);
    $conn->record()->append_entry("irspy:status",
				  "<irspy:search set='dan1' ap='$attr' ok='0'>".
				  isodate(time()) .
				  "</irspy:search>");
    return ZOOM::IRSpy::Status::TASK_DONE;
}


1;
