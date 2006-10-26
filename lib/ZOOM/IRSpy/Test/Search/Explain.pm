# $Id: Explain.pm,v 1.3 2006-10-26 12:55:35 mike Exp $

# See the "Main" test package for documentation

package ZOOM::IRSpy::Test::Search::Explain;

use 5.008;
use strict;
use warnings;

use ZOOM::IRSpy::Test;
our @ISA = qw(ZOOM::IRSpy::Test);


sub start {
    my $class = shift();
    my($conn) = @_;
    my @explain = qw(CategoryList TargetInfo DatabaseInfo SchemaInfo TagSetInfo
                     RecordSyntaxInfo AttributeSetInfo TermListInfo
                     ExtendedServicesInfo AttributeDetails TermListDetails
                     ElementSetDetails RetrivalRecordDetails SortDetails
                     Processing VariantSetInfo UnitSet);

    foreach my $category (@explain) {
	$conn->irspy_search_pqf('@attr exp-1 1=1 ' . $category,
                                {'category' => $category},
				{ databaseName => 'IR-Explain-1' },
				ZOOM::Event::RECV_SEARCH, \&found,
				exception => \&error);
    }
}


sub found {
    my($conn, $task, $test_args, $event) = @_;
    my $category = $test_args->{'category'};
    my $n = $task->{rs}->size();
    my $ok = 0;

    $conn->log("irspy_test", "Explain category ", $category, " gave ", $n,
               " hit(s).");
    if ($n > 0) {
        $ok = 1;
    }

    update($conn, $category, $ok);

    return ZOOM::IRSpy::Status::TASK_DONE;
}


sub error {
    my($conn, $task, $test_args, $exception) = @_;
    my $category = $test_args->{'category'};

    $conn->log("irspy_test", "Explain category lookup failed: ", $exception);
    update($conn, $category, 0);

    return ZOOM::IRSpy::Status::TASK_DONE;
}


sub update {
    my ($conn, $category, $ok) = @_;
    $conn->record()->store_result('explain', 'category'  => $category,
                                             'ok'        => $ok);
}

1;