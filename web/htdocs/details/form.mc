%# $Id: form.mc,v 1.2 2006-11-14 16:00:28 mike Exp $
<%args>
$id => undef
$conn
$rec
</%args>
<%perl>
my $xc = irspy_xpath_context($rec);
my @fields =
    (
     [ protocol     => 0, "Protocol", "e:serverInfo/\@protocol" ],
     [ host         => 0, "Host", "e:serverInfo/e:host" ],
     [ port         => 0, "Port", "e:serverInfo/e:port" ],
     [ dbname       => 0, "Database Name", "e:serverInfo/e:database",
       qw(e:host e:port) ],
     [ username     => 0, "Username (if needed)", "e:serverInfo/e:authentication/e:user",
       qw() ],
     [ password     => 0, "Password (if needed)", "e:serverInfo/e:authentication/e:password",
       qw(e:user) ],
     [ title        => 0, "title", "e:databaseInfo/e:title",
       qw() ],
     [ description  => 5, "Description", "e:databaseInfo/e:description",
       qw(e:title) ],
     [ author       => 0, "Author", "e:databaseInfo/e:author",
       qw(e:title e:description) ],
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
	next if grep { $key eq $_ } qw(id update);
	$data{$key} = $r->param($key);
    }

    $nchanges = modify_xml_document($xc, \%fieldsByKey, \%data);
    if ($nchanges) {
	### Set e:metaInfo/e:dateModified
    }
    ZOOM::IRSpy::_really_rewrite_record($conn, $xc->getContextNode());
}
</%perl>
 <h2><% xml_encode($xc->find("e:databaseInfo/e:title")) %></h2>
% if ($nchanges) {
 <p style="font-weight: bold">
  The record has been updated.<br/>
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
% my $data = $xc->find($xpath);
% $data = defined $data ? xml_encode($data) : "";
% if ($nlines) {
     <textarea name="<% $name %>" rows="<% $nlines %>" cols="61"><% $data %></textarea>
% } else {
     <input name="<% $name %>" type="text" size="60" value="<% $data %>">
% }
    </td>
   </tr>
%   }
   <tr>
    <td align="right" colspan="2">
     <input type="submit" name="update" value="Update"/>
     <input type="hidden" name="id" value="<% xml_encode($id) %>"/>
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
