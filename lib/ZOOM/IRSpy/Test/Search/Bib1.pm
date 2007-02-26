# $Id: Bib1.pm,v 1.16 2007-02-26 17:32:13 mike Exp $

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
    my @attrs = ( 1..63, 1000..1036,            # Bib-1
                  1037..1096, 1185..1209,       # Extended Bib-1
                  1097..1111,                   # Dublin-Core
                  1112..1184                    # GILS
                );

    foreach my $attr (@attrs) {
	$conn->irspy_search_pqf("\@attr 1=$attr mineral",
                                {'attr' => $attr}, {},
				ZOOM::Event::ZEND, \&found,
				exception => \&error);
    }
}


sub found {
    my($conn, $task, $test_args, $event) = @_;
    my $attr = $test_args->{'attr'};
    my $n = $task->{rs}->size();

    $conn->log("irspy_test", "search on access-point $attr found $n record",
	       $n==1 ? "" : "s");
    update($conn, $attr, 1);

    return ZOOM::IRSpy::Status::TASK_DONE;
}


sub error {
    my($conn, $task, $test_args, $exception) = @_;
    my $attr = $test_args->{'attr'};

    $conn->log("irspy_test", "search on access-point $attr had error: ",
	       $exception);
    update($conn, $attr, 0);

    return ZOOM::IRSpy::Status::TEST_BAD
	if $exception->code() == 1; # permanent system error

    return ZOOM::IRSpy::Status::TASK_DONE;
}


sub update {
    my ($conn, $attr, $ok) = @_;
    $conn->record()->store_result('search', 'set'       => 'bib-1',
                                            'ap'        => $attr,
                                            'ok'        => $ok);
}


1;
