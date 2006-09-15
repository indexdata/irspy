%# $Id: found.mc,v 1.1 2006-09-15 16:51:51 mike Exp $
<%once>
use XML::LibXML;
use XML::LibXML::XPathContext;
</%once>
<%perl>
my $query = "";
foreach my $key ($r->param()) {
    next if $key =~ /^_/;
    my $val = $r->param($key);
    next if $val eq "";
    $query .= " and " if $query ne "";
    $query .= "$key = ($val)";
}

### We can think about keeping the Connection object open to re-use
# for multiple requests, but that may not get us much.  Same applies
# for the XML parser.
my $conn = new ZOOM::Connection("localhost:1313/IR-Explain---1");
$conn->option(elementSetName => "zeerex");
my $parser = new XML::LibXML();

my $rs = $conn->search(new ZOOM::Query::CQL($query));
my $n = $rs->size();

my $skip = $r->param("_skip") || 0;
my $count = $r->param("_count") || 10;

my $first = $skip+1;
my $last = $first+$count-1;
$last = $n if $last > $n;
</%perl>
     <p>
      <b><% $query %></b>
      <br/>
% if ($n == 0) {
      No matches
% } elsif ($first > $n) {
      Past end of <% $n %> records
% } else {
      Records <% $first %> to <% $last %> of <% $n %>
% }
     </p>
% if ($n > 0 && $first <= $n) {
     <table width="100%">
      <tr class="thleft">
       <th>#</th>
       <th>Host</th>
       <th>Port</th>
       <th>DB</th>
      </tr>
% foreach my $i ($first .. $last) {
<%perl>
my $rec = $rs->record($i-1);
my $xml = $rec->render();
my $doc = $parser->parse_string($xml);
my $root = $doc->getDocumentElement();
my $xc = XML::LibXML::XPathContext->new($root);
$xc->registerNs(e => 'http://explain.z3950.org/dtd/2.0/');
my $host = $xc->find("e:serverInfo/e:host");
my $port = $xc->find("e:serverInfo/e:port");
my $db = $xc->find("e:serverInfo/e:database");
</%perl>
      <tr style="background: <% ($i % 2) ? '#ffffc0' : 'white' %>">
       <td><% $i %></td>
       <td><% $host %></td>
       <td><% $port %></td>
       <td><% $db %></td>
      </tr>
%}
     </table>
% }
