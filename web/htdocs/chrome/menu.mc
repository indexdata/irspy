%# $Id: menu.mc,v 1.14 2006-11-16 17:02:30 mike Exp $
     <p>
      <a href="/"><b>Home</b></a><br/>
      <a href="/all.html">Test&nbsp;all&nbsp;targets</a><br/>
      <a href="/find.html">Find a target</a><br/>
      <a href="/edit.html">Add a target</a><br/>
     </p>
     <p>
      <b>Show targets</b>
      <br/>
% foreach my $i ('a' .. 'z') {
      <a href="/find.html?dc.title=^<% $i %>*&amp;_sort=dc.title&amp;_count=9999&amp;_search=Search"><tt><% uc($i) %></tt></a>
% }
     </p>
<%perl>
our $rec;
my $id = $r->param("id");
{
    # Make up ID for newly created records.  It would be more
    # rigorously correct, but insanely inefficient, to submit the
    # record to Zebra and then search for it; but since we know the
    # formula for IDs anyway, we just build one by hand.
    my $id = $r->param("id");
    my $host = $r->param("host");
    my $port = $r->param("port");
    my $dbname = $r->param("dbname");
    #warn "id='$id', host='$host', port='$port', dbname='$dbname'";
    #warn "%ARGS = {\n" . join("", map { "\t'$_' => '" . $ARGS{$_} . ",'\n" } sort keys %ARGS) . "}\n";
    if ((!defined $id || $id eq "") &&
	defined $host && defined $port && defined $dbname) {
	$id = "$host:$port/$dbname";
#	$r->param(id => $id);
#	$ARGS{id} = $id;
	#warn "id set to '$id'";
    }
}
</%perl>
% if (!defined $id) {
%    $rec = undef;
% } else {
     <div class="panel2">
      <b>This Target</b>
      <a href="<% xml_encode("/full.html?id=" . uri_escape($id)) %>">Show details</a>
      <br/>
      <a href="<% xml_encode("/edit.html?id=" . uri_escape($id)) %>">Edit details</a>
      <br/>
      <a href="<% xml_encode("/edit.html?id=" . uri_escape($id)) . "&amp;copy=1" %>">Copy target</a>
      <p>
       <a href="<% xml_encode("/check.html?id=" . uri_escape($id)) . "&amp;test=Quick" %>">Quick Test</a>
       <br/>
       <a href="<% xml_encode("/check.html?id=" . uri_escape($id)) . "&amp;test=Main" %>">Full Test</a>
      </p>
      <p>
       <a href="<% xml_encode("/raw.html?id=" . uri_escape($id)) %>">XML</a>
      </p>
<%doc><!-- Maybe this would be too heavyweight -->
      <br/>
% my $host = "bagel.indexdata.dk";
% my $port = 210;
      <a href="/find.html?net.host=<% $host %>&net.port=<% $port %>&_search=Search"
	>All databases on this server</a>
</%doc>
     </div>
% }
     <p>
      <b>Documentation</b>
      <br/>
      <a href="/doc.html">Contents</a>
     </p>
     <p>&nbsp;</p>
     <p>
      <a href="http://validator.w3.org/check?uri=referer"><img
        src="/valid-xhtml10.png"
        alt="Valid XHTML 1.0 Strict" height="31" width="88" /></a>
      <br/>
      <a href="http://jigsaw.w3.org/css-validator/"><img
	src="/vcss.png"
	alt="Valid CSS!" height="31" width="88" /></a>
     </p>
