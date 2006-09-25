%# $Id: found.mc,v 1.11 2006-09-25 16:52:30 mike Exp $
<%once>
use XML::LibXML;
use XML::LibXML::XPathContext;
use URI::Escape;

sub print_navlink {
    my($params, $cond, $caption, $skip) = @_;

    if ($cond) {
	print('     <a href="', navlink($params, $caption, $skip),
	      '"', ">$caption</a>\n");
    } else {
	print qq[     <span class="disabled">$caption</span>\n];
    }
}

sub navlink {
    my($params, $caption, $skip) = @_;
    local $params->{_skip} = $skip;
    my $url = "?" . join("&", map { "$_=" . $params->{$_}  } sort keys %$params);
    $url = xml_encode($url);
    return $url;
}

</%once>
<%perl>
my %params = map { ( $_, $r->param($_)) } grep { $r->param($_) } $r->param();
my $query = "";
foreach my $key (keys %params) {
    next if $key =~ /^_/;
    my $val = $params{$key};
    next if $val eq "";
    $query .= " and " if $query ne "";
    $query .= "$key = ($val)";
}
$query = 'cql.allRecords=x' if $query eq "";

my $sort = $params{"_sort"};
if ($sort) {
    my $modifiers = "";
    if ($sort =~ s/(\/.*)//) {
	$modifiers = $1;
    }
    $query .= " or $sort=/sort";
    $query .= "-desc" if $params{_desc};
    $query .= $modifiers;
    $query .= " 0";
}

### We can think about keeping the Connection object open to re-use
# for multiple requests, but that may not get us much.  Same applies
# for the XML parser.
my $conn = new ZOOM::Connection("localhost:3313/IR-Explain---1");
$conn->option(elementSetName => "zeerex");
my $parser = new XML::LibXML();

my $rs = $conn->search(new ZOOM::Query::CQL($query));
my $n = $rs->size();

my $skip = $params{"_skip"} || 0;
my $count = $params{"_count"} || 10;

my $first = $skip+1;
my $last = $first+$count-1;
$last = $n if $last > $n;
</%perl>
     <h2><% xml_encode($query) %></h2>
     <p>
% if ($n == 0) {
      No matches
% } elsif ($first > $n) {
%# "Can't happen"
      Past end of <% $n %> records
% } else {
      Records <% $first %> to <% $last %> of <% $n %><br/>
<%perl>
print_navlink(\%params, $skip > 0, "Prev", $count < $skip ? $skip-$count : 0);
print_navlink(\%params, $last < $n, "Next", $skip+$count);
</%perl>
% }
     </p>
% if ($n > 0 && $first <= $n) {
     <table width="100%">
      <tr class="thleft">
       <th>#</th>
       <th>Title</th>
       <th>Author</th>
       <th>Host</th>
       <th>Port</th>
       <th>DB</th>
       <th></th>
       <th></th>
      </tr>
% my @ids;
% foreach my $i ($first .. $last) {
<%perl>
my $rec = $rs->record($i-1);
my $xml = $rec->render();
my $doc = $parser->parse_string($xml);
my $root = $doc->getDocumentElement();
my $xc = XML::LibXML::XPathContext->new($root);
$xc->registerNs(e => 'http://explain.z3950.org/dtd/2.0/');
my $title = $xc->find("e:databaseInfo/e:title");
my $author = $xc->find("e:databaseInfo/e:author");
my $host = $xc->find("e:serverInfo/e:host");
my $port = $xc->find("e:serverInfo/e:port");
my $db = $xc->find("e:serverInfo/e:database");
my $id = $xc->find("concat(e:serverInfo/e:host, ':',
                           e:serverInfo/e:port, '/',
                           e:serverInfo/e:database)");
push @ids, $id;
</%perl>
      <tr style="background: <% ($i % 2) ? '#ffffc0' : 'white' %>">
       <td><% $i %></td>
       <td><% xml_encode($title) %></td>
       <td><% xml_encode($author) %></td>
       <td><% xml_encode($host) %></td>
       <td><% xml_encode($port) %></td>
       <td><% xml_encode($db) %></td>
       <td><a href="<% xml_encode("/check.html?id=" . uri_escape($id))
	%>">[Test]</a></td>
       <td><a href="<% xml_encode("/raw.html?id=" . uri_escape($id))
	%>">[Raw]</a></td>
      </tr>
% }
     </table>
<%perl>
print_navlink(\%params, $skip > 0, "Prev", $count < $skip ? $skip-$count : 0);
print_navlink(\%params, $last < $n, "Next", $skip+$count);
</%perl>
     <p>
      <a href="<% "/check.html?" .
	xml_encode(join("&", map { "id=" . uri_escape($_) } @ids))
	%>">[Test all targets on this list]</a>
     </p>
% }
