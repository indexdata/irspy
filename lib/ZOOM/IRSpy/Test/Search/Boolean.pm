# $Id: Boolean.pm,v 1.1 2006-10-25 10:08:50 sondberg Exp $

# See the "Main" test package for documentation

package ZOOM::IRSpy::Test::Search::Boolean;

use 5.008;
use strict;
use warnings;

use ZOOM::IRSpy::Test;
our @ISA = qw(ZOOM::IRSpy::Test);


sub start {
    my $class = shift();
    my($conn) = @_;
    my %pqfs = ('and'   => '@and @attr 1=4 mineral @attr 1=4 water',
                'or'    => '@or @attr 1=4 mineral @attr 1=4 water',
                'not'   => '@not @attr 1=4 mineral @attr 1=4 water',
                'and-or'=> '@and @or @attr 1=4 mineral @attr 1=4 water ' .
                           '@attr 1=4 of' 
                );

    foreach my $operator (keys %pqfs) {
	$conn->irspy_search_pqf($pqfs{$operator},
                                {'operator' => $operator},
				ZOOM::Event::RECV_SEARCH, \&found,
				exception => \&error);
    }
}


sub found {
    my($conn, $task, $test_args, $event) = @_;
    my $operator = $test_args->{'operator'};
    my $n = $task->{rs}->size();

    $conn->log("irspy_test", "search using boolean operator ", $operator,
                             " found $n record", $n==1 ? "" : "s");
    $conn->record()->store_result('boolean', 'operator' => $operator,
                                             'ok'       => 1);

    return ZOOM::IRSpy::Status::TASK_DONE;
}


sub error {
    my($conn, $task, $test_args, $exception) = @_;
    my $operator = $test_args->{'operator'};

    $conn->log("irspy_test", "search using boolean operator ", $operator,
                             " had error: ", $exception);
    $conn->record()->store_result('boolean', 'operator' => $operator,
                                             'ok'       => 0);
    return ZOOM::IRSpy::Status::TASK_DONE;
}


1;