%# $Id: edit.mc,v 1.2 2006-10-27 00:47:24 mike Exp $
<%args>
$id
</%args>
<%once>
use ZOOM;
</%once>
<%perl>
my $conn = new ZOOM::Connection("localhost:3313/IR-Explain---1");
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
    my $xc = irspy_xpath_context($rec);
    my @fields =
	(
	 [ protocol     => 0, "Protocol", "e:serverInfo/\@protocol" ],
	 [ host         => 0, "Host", "e:serverInfo/e:host" ],
	 [ port         => 0, "Port", "e:serverInfo/e:port" ],
	 [ dbname       => 0, "Database Name", "e:serverInfo/e:database" ],
	 [ username     => 0, "Username (if needed)", "e:serverInfo/e:authentication/e:user" ],
	 [ password     => 0, "Password (if needed)", "e:serverInfo/e:authentication/e:password" ],
	 [ title        => 0, "title", "e:databaseInfo/e:title", lang => "en", primary => "true" ],
	 [ description  => 5, "Description", "e:databaseInfo/e:description", lang => "en", primary => "true" ],
	 [ author       => 0, "Author", "e:databaseInfo/e:author" ],
	 [ contact      => 0, "Contact", "e:databaseInfo/e:contact" ],
	 [ extent       => 3, "Extent", "e:databaseInfo/e:extent" ],
	 [ history      => 5, "History", "e:databaseInfo/e:history" ],
	 [ language     => 0, "Language of Records", "e:databaseInfo/e:langUsage" ],
	 [ restrictions => 2, "Restrictions", "e:databaseInfo/e:restrictions" ],
	 [ subjects     => 2, "Subjects", "e:databaseInfo/e:subjects" ],
	 ### Remember to set e:metaInfo/e:dateModified
	 );
</%perl>
     <h2><% xml_encode($id) %></h2>
     <form method="get" action="">
      <table class="fullrecord" border="1" cellspacing="0" cellpadding="5" width="100%">
<%perl>
    foreach my $ref (@fields) {
	my($name, $nlines, $caption, $xpath, %attrs) = @$ref;
</%perl>
       <tr>
	<th><% $caption %></th>
	<td>
% my $data = xml_encode($xc->find($xpath));
% if ($nlines) {
	 <textarea name="<% $name %>" rows="<% $nlines %>" cols="61"><% $data %></textarea>
% } else {
	 <input name="<% $name %>" type="text" size="60" value="<% $data %>">
% }
	</td>
       </tr>
%   }
       <tr>
        <td></td>
        <td align="right">
	 <input type="submit" name="update" value="Update"/>
	 <input type="hidden" name="id" value="<% xml_encode($id) %>"/>
        </td>
       </tr>
      </table>
     </form>
% }
