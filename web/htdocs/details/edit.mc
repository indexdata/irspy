%# $Id: edit.mc,v 1.15 2006-11-16 12:26:26 mike Exp $
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

my $xc = irspy_xpath_context($rec);
my @fields =
    (
     [ protocol     => [ qw(Z39.50 SRW SRU SRW/U) ],
       "Protocol", "e:serverInfo/\@protocol" ],
     [ host         => 0, "Host", "e:serverInfo/e:host" ],
     [ port         => 0, "Port", "e:serverInfo/e:port" ],
     [ dbname       => 0, "Database Name", "e:serverInfo/e:database",
       qw(e:host e:port) ],
     [ type         => [ qw(Academic Public Corporate Special National Education Other) ],
       "Type of Library", "i:status/i:libraryType" ],
     [ country      => 0, "Country", "i:status/i:country" ],
     [ username     => 0, "Username (if needed)", "e:serverInfo/e:authentication/e:user",
       qw() ],
     [ password     => 0, "Password (if needed)", "e:serverInfo/e:authentication/e:password",
       qw(e:user) ],
     [ title        => 0, "Title", "e:databaseInfo/e:title",
       qw() ],
     [ description  => 5, "Description", "e:databaseInfo/e:description",
       qw(e:title) ],
     [ author       => 0, "Author", "e:databaseInfo/e:author",
       qw(e:title e:description) ],
     [ hosturl       => 0, "URL to Hosting Organisation", "i:status/i:hostURL" ],
     [ contact      => 0, "Contact", "e:databaseInfo/e:contact",
       qw(e:title e:description) ],
     [ extent       => 3, "Extent", "e:databaseInfo/e:extent",
       qw(e:title e:description) ],
     [ history      => 5, "History", "e:databaseInfo/e:history",
       qw(e:title e:description) ],
     [ language     => 0, "Language of Records", "e:databaseInfo/e:langUsage",
       qw(e:title e:description) ],
     [ restrictions => 2, "Restrictions", "e:databaseInfo/e:restrictions",
       qw(e:title e:description) ],
     [ subjects     => 2, "Subjects", "e:databaseInfo/e:subjects",
       qw(e:title e:description) ],
     );

my $nchanges = 0;
my $update = $r->param("update");
if (defined $update) {
    # Update record with submitted data
    my %fieldsByKey = map { ( $_->[0], $_) } @fields;
    my %data;
    foreach my $key ($r->param()) {
	next if grep { $key eq $_ } qw(id update new copy);
	$data{$key} = $r->param($key);
    }

    $nchanges = modify_xml_document($xc, \%fieldsByKey, \%data);
    if ($nchanges) {
	### Set e:metaInfo/e:dateModified
    }
    ZOOM::IRSpy::_really_rewrite_record($conn, $xc->getContextNode());
}
</%perl>
 <h2><% xml_encode($xc->find("e:databaseInfo/e:title"), "[Untitled]") %></h2>
% if ($nchanges) {
 <p style="font-weight: bold">
  The record has been <% $r->param("new") ? "created" : "updated" %>.<br/>
  Changed <% $nchanges %> field<% $nchanges == 1 ? "" : "s" %>.
 </p>
% }
 <form method="get" action="">
  <table class="fullrecord" border="1" cellspacing="0" cellpadding="5" width="100%">
<%perl>
foreach my $ref (@fields) {
    my($name, $nlines, $caption, $xpath, @addAfter) = @$ref;
</%perl>
   <tr>
    <th><% $caption %></th>
    <td>
% my $rawdata = $xc->findvalue($xpath);
% my $data = xml_encode($rawdata, "");
% if (ref $nlines) {
     <select name="<% $name %>" size="1">
%     foreach my $val (@$nlines) {
      <option value="<% $val %>"
% print ' selected="selected"' if $rawdata eq $val;
	><% $val %></option>
%     }
     </select>
% } elsif ($nlines) {
     <textarea name="<% $name %>" rows="<% $nlines %>" cols="51"><% $data %></textarea>
% } else {
     <input name="<% $name %>" type="text" size="60" value="<% $data %>"/>
% }
    </td>
   </tr>
%   }
   <tr>
    <td align="right" colspan="2">
     <input type="submit" name="update" value="Update"/>
% if (defined $id) {
     <input type="hidden" name="id" value="<% xml_encode($id) %>"/>
% } else {
     <input type="hidden" name="new" value="1"/>
% }
    </td>
   </tr>
  </table>
 </form>
<%perl>
    if ($nchanges && 0) {
	my $x = $xc->getContextNode()->toString();
	$x = xml_encode($x);
	#$x =~ s/$/<br\/>/gm;
	print "<pre>$x</pre>\n";
    }
</%perl>
