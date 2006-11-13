# $Id: Named.pm,v 1.1 2006-11-02 11:46:40 sondberg Exp $

# See the "Main" test package for documentation

package ZOOM::IRSpy::Test::ResultSet::Named;

use 5.008;
use strict;
use warnings;

use ZOOM::IRSpy::Test;
our @ISA = qw(ZOOM::IRSpy::Test);


sub start {
    my $class = shift();
    my($conn) = @_;

    $conn->log('irspy_test', 'Testing for named resultset support');

    $conn->irspy_search_pqf("\@attr 1=4 mineral", {},
                            {'setname' => 'a', 'start' => 0, 'count' => 0},	
			    ZOOM::Event::RECV_SEARCH, \&completed_search_a,
			    exception => \&error);
}


sub completed_search_a {
    my ($conn, $task, $test_args, $event) = @_;
    my $rs = $task->{rs};
    my $record = '';
    my $hits = $rs->size();

    ## How should be handle the situation when there is 0 hits?
    if ($hits > 0) {
        $record = $rs->record(0)->raw(); 
    } 

    $conn->irspy_search_pqf("\@attr 1=4 4ds9da94",
                            {'record_a' => $record, 'hits_a' => $hits,
                             'rs_a' => $rs},
                            {'setname' => 'b'},	
			    ZOOM::Event::RECV_SEARCH, \&completed_search_b,
			    exception => \&error);

    return ZOOM::IRSpy::Status::TASK_DONE;
}


sub completed_search_b {
    my($conn, $task, $test_args, $event) = @_;
    my $rs = $test_args->{rs_a};
    my $record = '';
    my $error = '';

    $rs->cache_reset();

    if ($test_args->{'hits_a'} > 0) {
        my $hits = $rs->size();
        my $record = $rs->record(0)->raw();

        if ($hits != $test_args->{'hits_a'}) {
            $conn->log('irspy_test', 'Named result set not supported: ',
                                     'Mis-matching hit counts');
            $error = 'hitcount';
        }

        if ($record ne $test_args->{'record_a'}) {
            $conn->log('irspy_test', 'Named result set not supported: ',
                                     'Mis-matching records');
            $error = 'record';
        }
    }

    update($conn, $error eq '' ? 1 : 0, $error);

    return ZOOM::IRSpy::Status::TASK_DONE;
}


sub error {
    my($conn, $task, $test_args, $exception) = @_;

    $conn->log("irspy_test", "Named resultset check failed:", $exception);
    return ZOOM::IRSpy::Status::TASK_DONE;
}


sub update {
    my ($conn, $ok, $error) = @_;
    my %args = ('ok' => $ok);

    if (!$ok) {
        $args{'error'} = $error;
    }

    $conn->record()->store_result('named_resultset', %args); 
}

1;