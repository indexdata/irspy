%# $Id: edit.mc,v 1.12 2006-11-16 11:50:03 mike Exp $
<%args>
$id => undef
</%args>
<%perl>
my $conn = new ZOOM::Connection("localhost:3313/IR-Explain---1", 0,
				user => "admin", password => "fruitbat");
my $rec = '<explain xmlns="http://explain.z3950.org/dtd/2.0/"/>';
if (defined $id && $id ne "") {
    $conn->option(elementSetName => "zeerex");
    my $qid = $id;
    $qid =~ s/"/\\"/g;
    my $query = qq[rec.id="$qid"];
    my $rs = $conn->search(new ZOOM::Query::CQL($query));
    my $n = $rs->size();
    if ($n == 0) {
	$id = undef;
    } else {
	$rec = $rs->record(0);
    }
}
</%perl>
<& /details/form.mc, id => $id, conn => $conn, rec => $rec &>
