%# $Id: edit.mc,v 1.10 2006-11-14 14:54:41 mike Exp $
<%args>
$id => undef
</%args>
<%once>
use ZOOM;
</%once>
<%perl>
my $conn = new ZOOM::Connection("localhost:3313/IR-Explain---1", 0,
				user => "admin", password => "fruitbat");
if (!defined $id || $id eq "") {
    $m->comp("/details/form.mc", id => undef, conn => $conn,
	     rec => '<explain xmlns="http://explain.z3950.org/dtd/2.0/"/>');
} else {
    $conn->option(elementSetName => "zeerex");
    my $qid = $id;
    $qid =~ s/"/\\"/g;
    my $query = qq[rec.id="$qid"];
    my $rs = $conn->search(new ZOOM::Query::CQL($query));
    my $n = $rs->size();
    if ($n == 0) {
	$m->comp("/details/error.mc",
		 title => "Error", message => "No such ID '$id'");
    } else {
	my $rec = $rs->record(0);
	$m->comp("/details/form.mc", id => $id, conn => $conn, rec => $rec);
    }
}
</%perl>
