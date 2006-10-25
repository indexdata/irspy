# $Id: Fetch.pm,v 1.7 2006-10-25 15:44:50 mike Exp $

# See the "Main" test package for documentation

package ZOOM::IRSpy::Test::Record::Fetch;

use 5.008;
use strict;
use warnings;

use ZOOM::IRSpy::Test;
our @ISA = qw(ZOOM::IRSpy::Test);


sub start {
    my $class = shift();
    my($conn) = @_;

    # Here I want to get a use attribute from the session, which we've
    # managed to search for in the Search/Bib1 or Search/Dan1 tests.
    # But how?  So far we search for title: 1=4
    $conn->irspy_search_pqf("\@attr 1=4 mineral", {}, {},	
			    ZOOM::Event::RECV_SEARCH, \&completed_search,
			    exception => \&error);
}


sub completed_search {
    my($conn, $task, $udata, $event) = @_;

    $conn->log("irspy_test", "Fetch test search succeeded");
    my @syntax = (
                   'canmarc',
                   'danmarc',
                   'grs-1',
                   'ibermarc',
                   'intermarc',
                   'jpmarc',
                   'librismarc',
                   'mab',
                   'normarc',
                   'opac',
                   'picamarc',
                   'rusmarc',
                   'summary',
                   'sutrs',
                   'swemarc',
                   'ukmarc',
                   'unimarc',
                   'usmarc',
                   'xml'
                );
    @syntax = qw(grs-1 sutrs usmarc xml); # simplify for debugging
    foreach my $syntax (@syntax) {
	$conn->irspy_rs_record($task->{rs}, 0,
			       { syntax => $syntax },
			       { start => 0, count => 1,
				 preferredRecordSyntax => $syntax },
                                ZOOM::Event::RECV_RECORD, \&record,
				exception => \&error);
    }

    return ZOOM::IRSpy::Status::TASK_DONE;
}


sub record {
    my($conn, $task, $test_args, $event) = @_;
    my $syn = $test_args->{'syntax'};
    my $rs = $task->{rs};

    $conn->log("irspy_test", "Successfully retrieved a $syn record");
    if (1) {
        print STDERR "Hits: ", $rs->size(), "\n";
        print STDERR "Syntax: ", $syn, "\n";
        print STDERR $rs->record(0)->render();
    }

    $conn->record()->store_result('record_fetch',
                                  'syntax'   => $syn,
                                  'ok'       => 1);

    return ZOOM::IRSpy::Status::TASK_DONE;
}


sub error {
    my($conn, $task, $test_args, $exception) = @_;
    my $syn = $test_args->{'syntax'};

    $conn->log("irspy_test", "Retrieval of $syn record failed: ", $exception);
    $conn->record()->store_result('record_fetch',
                                  'syntax'       => $syn,
                                  'ok'        => 0);
    return ZOOM::IRSpy::Status::TASK_DONE;
}


1;
