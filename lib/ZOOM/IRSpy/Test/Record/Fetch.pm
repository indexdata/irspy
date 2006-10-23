# $Id: Fetch.pm,v 1.1 2006-10-23 13:54:52 sondberg Exp $

# See the "Main" test package for documentation

package ZOOM::IRSpy::Test::Record::Fetch;

use 5.008;
use strict;
use warnings;

use ZOOM::IRSpy::Test;
our @ISA = qw(ZOOM::IRSpy::Test);


sub start {
    print STDERR "Got here\n";
    exit 1;
    my $class = shift();
    my($conn) = @_;
    my @syntax = ( 'canmarc',
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
                   'swemarc'
                   'ukmarc',
                   'unimarc',
                   'usmarc',
                   'xml',
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
    my $syn = $test_args->{'syn'};

    $conn->log("irspy_test", "search on access-point $attr found $n record",
	       $n==1 ? "" : "s");
    $conn->record()->store_result('record_fetch',
                                  'syntax'   => $syn,
                                  'ok'       => 1);

    return ZOOM::IRSpy::Status::TASK_DONE;
}


sub error {
    my($conn, $task, $test_args, $exception) = @_;
    my $syn = $test_args->{'syn'};

    $conn->log("irspy_test", "search on access-point $attr had error: ",
	       $exception);
    $conn->record()->store_result('record_fetch',
                                  'syntax'       => $syn,
                                  'ok'        => 0);
    return ZOOM::IRSpy::Status::TASK_DONE;
}


1;
