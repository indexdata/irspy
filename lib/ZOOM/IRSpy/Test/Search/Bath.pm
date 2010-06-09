# This tests the main searches specified The Bath Profile, Release 2.0, 
# 	http://www.collectionscanada.gc.ca/bath/tp-bath2-e.htm
# Specifically section 5.A.0 ("Functional Area A: Level 0 Basic
# Bibliographic Search and Retrieval") and its subsections:
#	http://www.collectionscanada.gc.ca/bath/tp-bath2.7-e.htm#a

package ZOOM::IRSpy::Test::Search::Bath;

use 5.008;
use strict;
use warnings;

use ZOOM::IRSpy::Test;
our @ISA = qw(ZOOM::IRSpy::Test);

use ZOOM::IRSpy::Utils qw(isodate);


my @bath_queries = (
    [ author => 1003 ],	# 5.A.0.1
    [ title => 4 ],	# 5.A.0.2
    [ subject => 21 ],	# 5.A.0.3
    [ any => 1016 ],	# 5.A.0.4
    );


sub start {
    my $class = shift();
    my($conn) = @_;

    start_search($conn, 0);
}


sub start_search {
    my($conn, $qindex) = @_;

    return ZOOM::IRSpy::Status::TEST_GOOD
	if $qindex >= @bath_queries;

    my $ref = $bath_queries[$qindex];
    my($name, $use_attr) = @$ref;

    my $query = "\@attr 1=$use_attr \@attr 2=3 \@attr 3=3 \@attr 4=2 \@attr 5=100 \@attr 6=1 the";
    $conn->irspy_search_pqf($query, { qindex => $qindex }, {},
			    ZOOM::Event::ZEND, \&search_complete,
			    "exception", \&search_complete);
    return ZOOM::IRSpy::Status::TASK_DONE;
}


sub search_complete {
    my($conn, $task, $udata, $event) = @_;
    my $ok = ref $event && $event->isa("ZOOM::Exception") ? 0 : 1;

    my $qindex = $udata->{qindex};
    my $ref = $bath_queries[$qindex];
    my($name, $use_attr) = @$ref;

    my $n = $task->{rs}->size();

    $conn->log("irspy_test", "bath search #$qindex ('$name') ",
	       $ok ? ("found $n record", $n==1 ? "" : "s") :
	              "had error: $event");

    my $rec = $conn->record();
    $rec->append_entry("irspy:status",
		       "<irspy:search_bath name='$name' ok='$ok'>" .
		       isodate(time()) . "</irspy:search_bath>");

    return start_search($conn, $qindex+1);
}


1;
