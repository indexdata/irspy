
# See the "Main" test package for documentation

package ZOOM::IRSpy::Test::Record::Fetch;

use 5.008;
use strict;
use warnings;

use ZOOM::IRSpy::Test;
our @ISA = qw(ZOOM::IRSpy::Test);


# These queries 
my @queries = (
	       "\@attr 1=4 mineral",
	       "\@attr 1=4 computer",
	       "\@attr 1=44 mineral", # Smithsonian doesn't support AP 4!
	       "\@attr 1=1016 water", # Connector Framework only does 1016
	       ### We can add more queries here
	       );


sub start {
    my $class = shift();
    my($conn) = @_;

    # Here I want to get a use attribute from the session, which we've
    # managed to search for in the Search/Bib1 or Search/Dan1 tests.
    # But how?  So far we search for title: 1=4
    $conn->irspy_search_pqf($queries[0], { queryindex => 0 }, {},
			    ZOOM::Event::ZEND, \&completed_search,
			    exception => \&completed_search);
}


sub completed_search {
    my($conn, $task, $udata, $event) = @_;

    my $n = $task->{rs}->size();
    $conn->log("irspy_test", "Fetch test search (", $task->render_query(), ") ",
	       ref $event && $event->isa("ZOOM::Exception") ?
	       "failed: $event" : "found $n records (event=$event)");
    if ($n == 0) {
	$task->{rs}->destroy();
	my $qindex = $udata->{queryindex}+1;
	my $q = $queries[$qindex];
	return ZOOM::IRSpy::Status::TEST_SKIPPED
	    if !defined $q;

	$conn->log("irspy_test", "Trying another search ...");
	$conn->irspy_search_pqf($queries[$qindex], { queryindex => $qindex }, {},
				ZOOM::Event::ZEND, \&completed_search,
				exception => \&completed_search);
	return ZOOM::IRSpy::Status::TASK_DONE;
    }

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
#                   'opac',
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
    foreach my $i (0 ..$#syntax) {
	my $syntax = $syntax[$i];
	$conn->irspy_rs_record($task->{rs}, 0,
			       { syntax => $syntax,
			         last => ($i == $#syntax) },
			       { start => 0, count => 1,
				 preferredRecordSyntax => $syntax },
                                ZOOM::Event::ZEND, \&record,
				exception => \&fetch_error);
    }

    return ZOOM::IRSpy::Status::TASK_DONE;
}


sub record {
    my($conn, $task, $udata, $event) = @_;
    my $syn = $udata->{'syntax'};
    my $rs = $task->{rs};

    my $record = _fetch_record($rs, 0, $syn);
    my $ok = 0;
    if (!$record || $record->error()) {
	$conn->log("irspy_test", "retrieval of $syn record failed: ",
		   defined $record ? $record->exception() :
				     $conn->exception());
    } else {
	$ok = 1;
	my $text = $record->render();
	$conn->log("irspy_test", "Successfully retrieved a $syn record");
	if (0) {
	    print STDERR "Hits: ", $rs->size(), "\n";
	    print STDERR "Syntax: ", $syn, "\n";
	    print STDERR $text;
	}
    }

    $conn->record()->store_result('record_fetch',
                                  'syntax'   => $syn,
                                  'ok'       => $ok);

    $rs->destroy() if $udata->{last};
    return ($udata->{last} ?
	    ZOOM::IRSpy::Status::TEST_GOOD :
	    ZOOM::IRSpy::Status::TASK_DONE);
}


sub _fetch_record {
    my($rs, $index0, $syntax) = @_;

    my $oldSyntax = $rs->option(preferredRecordSyntax => $syntax);
    my $record = $rs->record(0);
    $oldSyntax = "" if !defined $oldSyntax;
    $rs->option(preferredRecordSyntax => $oldSyntax);

    return $record;
}


sub __UNUSED_search_error {
    my($conn, $task, $test_args, $exception) = @_;

    $conn->log("irspy_test", "Initial search failed: ", $exception);
    return ZOOM::IRSpy::Status::TEST_SKIPPED;
}


sub fetch_error {
    my($conn, $task, $udata, $exception) = @_;
    my $syn = $udata->{'syntax'};

    $conn->log("irspy_test", "Retrieval of $syn record failed: ", $exception);
    $conn->record()->store_result('record_fetch',
                                  'syntax'       => $syn,
                                  'ok'        => 0);
    $task->{rs}->destroy() if $udata->{last};
    return ZOOM::IRSpy::Status::TASK_DONE;
}


1;
