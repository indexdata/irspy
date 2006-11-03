# $Id: Fetch.pm,v 1.14 2006-11-03 13:37:33 mike Exp $

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

    my $n = $task->{rs}->size();
    $conn->log("irspy_test", "Fetch test search found $n records");
    return ZOOM::IRSpy::Status::TEST_SKIPPED if $n == 0;

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
    #@syntax = qw(grs-1 sutrs usmarc xml); # simplify for debugging
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

    # Due to a bug in ZOOM-C (as of YAZ 2.1.38 of 31st October 2006),
    # diagnostics in Present responses are not reported, so that we
    # always end up in this callback rather than in error() where we
    # should be.  Luckily, we can test whether the retrieval really
    # did work by rendering the record, which will yield an undefined
    # result if the fetch failed.
    my $record = _fetch_record($rs, 0, $syn);
    my $text = $record->render();
    if (defined $text) {
	$conn->log("irspy_test", "Successfully retrieved a $syn record");
	if (0) {
	    print STDERR "Hits: ", $rs->size(), "\n";
	    print STDERR "Syntax: ", $syn, "\n";
	    print STDERR $text;
	}
    } else {
	$conn->log("irspy_test", "Retrieval of $syn record failed: ",
		   "exception unavailable");
    }

    $conn->record()->store_result('record_fetch',
                                  'syntax'   => $syn,
                                  'ok'       => defined $text ? 1 : 0);

    return ZOOM::IRSpy::Status::TASK_DONE;
}


sub _fetch_record {
    my($rs, $index0, $syntax) = @_;

    my $oldSyntax = $rs->option(preferredRecordSyntax => $syntax);
    my $record = $rs->record(0);
    $oldSyntax = "" if !defined $oldSyntax;
    $rs->option(preferredRecordSyntax => $oldSyntax);

    return $record;
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
