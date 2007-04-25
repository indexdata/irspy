%# $Id: delete.mc,v 1.6 2007-04-25 13:28:42 mike Exp $
<%args>
$id
$really => 0
</%args>
% if (!$really) {
     <h2>Warning</h2>
     <p class="error">
      Are you sure you want to delete the target
      <% xml_encode($id) %>?
     </p>
     <p>
      <a href="?really=1&amp;id=<% xml_encode(uri_escape($id)) %>">Yes</a><br/>
      <a href="/full.html?id=<% xml_encode(uri_escape($id)) %>">No</a><br/>
     </p>
% } else {
<%perl>
    # We can't delete records using recordIdOpaque, since character
    # sets are handled differently here in extended services from how
    # they are used in the Alvis filter's record-parsing, and so
    # non-ASCII characters come out differently in the two contexts.
    # Instead, we must send a record whose contents indicate the ID of
    # that which we wish to delete.  There are two ways, both
    # unsatisfactory: we could either fetch the actual record them
    # resubmit it in the deletion request (which wastes a search and a
    # fetch) or we could build a record by hand from the parsed-out
    # components (which is error-prone and which I am not 100% certain
    # will work since the other contents of the record will be
    # different).  The former evil seems to be the lesser.
    my $conn = new ZOOM::Connection("localhost:8018/IR-Explain---1", 0,
				    user => "admin", password => "fruitbat",
				    elementSetName => "zeerex");
    my $rs = $conn->search(new ZOOM::Query::CQL(cql_target($id)));
    if ($rs->size() == 0) {
	$m->comp("/details/error.mc",
		 title => "Error", message => "No such ID '$id'");
	return 0;
    }
    my $rec = $rs->record(0);
    my $xml = $rec->render();

    my $p = $conn->package();
    $p->option(action => "recordDelete");
    $p->option(record => $xml);
    $p->send("update");
    $p->destroy();

    $p = $conn->package();
    $p->send("commit");
    $p->destroy();
</%perl>
     <p>
      Deleted record
      <% xml_encode($id) %>
     </p>
% }
