%# $Id: edit.mc,v 1.21 2006-11-29 18:22:08 mike Exp $
<%args>
$op
$id => undef
$update => undef
</%args>
<%doc>
Since this form is used in many different situations, some care is
merited in considering the possibilities:

Situation					Op	ID	Update
----------------------------------------------------------------------
Blank form for adding a new target		new
New target rejected, changes required		new		X
New target accepted and added			new		X
---------------------------------------------------------------------
Existing target to be edited			edit	X
Edit rejected, changes required			edit	X	X
Target successfully updated			edit	X	X
----------------------------------------------------------------------
Existing target to be copied			copy	X
New target rejected, changes required		copy	X	X
New target accepted and added			copy	X	X
----------------------------------------------------------------------

Submissions, whether of new targets, edits or copies, may be rejected
due either to missing mandatory fields or host/name/port that form a
duplicate ID.
</%doc>
<%perl>
# Sanity checking
die "op = new but id defined" if $op eq "new" && defined $id;
die "op != new but id undefined" if $op ne "new" && !defined $id;

my $conn = new ZOOM::Connection("localhost:3313/IR-Explain---1", 0,
				user => "admin", password => "fruitbat",
				elementSetName => "zeerex");
my $rec = '<explain xmlns="http://explain.z3950.org/dtd/2.0/"/>';
if (defined $id && ($op ne "copy" || !$update)) {
    # Existing record
    my $query = 'rec.id="' . cql_quote($id) . '"';
    my $rs = $conn->search(new ZOOM::Query::CQL($query));
    if ($rs->size() > 0) {
	$rec = $rs->record(0);
    } else {
	### Is this an error?  I don't think the UI will ever provoke it
	print qq[<p class="error">(New ID specified.)</p>\n];
	$id = undef;
    }

} else {
    # No ID supplied -- this is a brand new record
    my $host = $r->param("host");
    my $port = $r->param("port");
    my $dbname = $r->param("dbname");
    if (!defined $host || $host eq "" ||
	!defined $port || $port eq "" ||
	!defined $dbname || $dbname eq "") {
	print qq[<p class="error">
You must specify host, port and database name.</p>\n] if $update;
	undef $update;
    } else {
	my $query = cql_target($host, $port, $dbname);
	my $rs = $conn->search(new ZOOM::Query::CQL($query));
	if ($rs->size() > 0) {
	    my $fakeid = xml_encode(uri_escape("$host:$port/$dbname"));
	    print qq[<p class="error">
There is already
<a href='?op=edit&amp;id=$fakeid'>a record</a>
for this host, port and database name.
</p>\n];
	    undef $update;
	}
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

# Update record with submitted data
my %fieldsByKey = map { ( $_->[0], $_) } @fields;
my %data;
foreach my $key ($r->param()) {
    next if grep { $key eq $_ } qw(op id update);
    $data{$key} = $r->param($key);
}
my @changedFields = modify_xml_document($xc, \%fieldsByKey, \%data);
if ($update && @changedFields) {
    my @x = modify_xml_document($xc, { dateModified =>
					   [ dateModified => 0,
					     "Data/time modified",
					     "e:metaInfo/e:dateModified" ] },
				{ dateModified => isodate(time()) });
    die "Didn't set dateModified!" if !@x;
    ZOOM::IRSpy::_really_rewrite_record($conn, $xc->getContextNode());
}

</%perl>
 <h2><% xml_encode($xc->find("e:databaseInfo/e:title"), "[Untitled]") %></h2>
% if ($update && @changedFields) {
%     my $nchanges = @changedFields;
 <p style="font-weight: bold">
  The record has been <% $op ne "edit" ? "created" : "updated" %>.<br/>
  Changed <% $nchanges %> field<% $nchanges == 1 ? "" : "s" %>:
  <% join(", ", map { xml_encode($_->[2]) } @changedFields) %>.
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
% my $rawval = $xc->findvalue($xpath);
% my $val = xml_encode($rawval, "");
% if (ref $nlines) {
     <select name="<% $name %>" size="1">
%     foreach my $option (@$nlines) {
      <option value="<% xml_encode($option) %>"<%
	($rawval eq $option ? ' selected="selected"' : "")
	%>><% xml_encode($option) %></option>
%     }
     </select>
% } elsif ($nlines) {
     <textarea name="<% $name %>" rows="<% $nlines %>" cols="51"><% $val %></textarea>
% } else {
     <input name="<% $name %>" type="text" size="60" value="<% $val %>"/>
% }
    </td>
   </tr>
%   }
   <tr>
    <td align="right" colspan="2">
     <input type="submit" name="update" value="Update"/>
     <input type="hidden" name="op" value="<% xml_encode($op) %>"/>
% if (defined $id) {
     <input type="hidden" name="id" value="<% xml_encode($id) %>"/>
% }
    </td>
   </tr>
  </table>
 </form>
<%perl>
    if (@changedFields && 0) {
	my $x = $xc->getContextNode()->toString();
	$x = xml_encode($x);
	#$x =~ s/$/<br\/>/gm;
	print "<pre>$x</pre>\n";
    }
</%perl>
