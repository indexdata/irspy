%# $Id: delete.mc,v 1.4 2007-01-24 09:28:02 mike Exp $
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
      <a href="full.html?id=<% xml_encode(uri_escape($id)) %>">No</a><br/>
     </p>
% } else {
<%perl>
    my $conn = new ZOOM::Connection("localhost:8018/IR-Explain---1", 0,
				    user => "admin", password => "fruitbat",
				    elementSetName => "zeerex");
    # I am thinking that ZOOM should provide delete(), update(), etc.
    my $p = $conn->package();
    $p->option(action => "recordDelete");
    $p->option(recordIdOpaque => $id);
    $p->option(record => "<dummy/>"); # Work around Zebra bug
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
