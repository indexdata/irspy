# $Id: Fetch.pm,v 1.4 2006-10-25 10:19:33 mike Exp $

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

    foreach my $syn (@syntax) {
        $conn->option('preferredRecordSyntax' => $syn);
        $conn->option('start'   => 0);
        $conn->option('count'   => 1);

        ## Here I want to get a use attribute from the session, which we've
        ## managed to search for in the Search/Bib1 or Search/Dan1 tests. But
        ## how? So far we search for title: 1=4
	$conn->irspy_search_pqf("\@attr 1=4 mineral",
                                {'syntax' => $syn},
                                ZOOM::Event::RECV_RECORD, \&record,
				exception => \&error);
    }
}


sub record {
    my($conn, $task, $test_args, $event) = @_;
    my $syn = $test_args->{'syntax'};
    my $rs = $task->{rs};

    if (1) {
        print STDERR $rs->record(0)->render();
    }

    $conn->log("irspy_test", "Successfully retrieved a $syn record");
    $conn->record()->store_result('record_fetch',
                                  'syntax'   => $syn,
                                  'ok'       => 1);

    return ZOOM::IRSpy::Status::TASK_DONE;
}


sub error {
    my($conn, $task, $test_args, $exception) = @_;
    my $syn = $test_args->{'syntax'};

    $conn->log("irspy_test", "Retrieval of $syn record failed:", $exception);
    $conn->record()->store_result('record_fetch',
                                  'syntax'       => $syn,
                                  'ok'        => 0);
    return ZOOM::IRSpy::Status::TASK_DONE;
}


1;
