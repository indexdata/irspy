%# $Id: full.mc,v 1.2 2006-10-26 17:23:13 mike Exp $
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
    my @fields = (
		  [ Protocol => "e:serverInfo/\@protocol" ],
		  [ Host => "e:serverInfo/e:host" ],
		  [ Port => "e:serverInfo/e:port" ],
		  [ "Database Name" => "e:serverInfo/e:database" ],
		  [ "Username (if needed)" =>
		    "e:serverInfo/e:authentication/e:user" ],
		  [ "Password (if needed)" =>
		    "e:serverInfo/e:authentication/e:password" ],
		  [ Title => "e:databaseInfo/e:title",
		    lang => "en", primary => "true" ],
		  [ Description => "e:databaseInfo/e:description",
		    lang => "en", primary => "true" ],
		  [ Author => "e:databaseInfo/e:author" ],
		  [ Contact => "e:databaseInfo/e:contact" ],
		  [ Extent => "e:databaseInfo/e:extent" ],
		  [ History => "e:databaseInfo/e:history" ],
		  [ "Language of Records" => "e:databaseInfo/e:langUsage" ],
		  [ Restrictions => "e:databaseInfo/e:restrictions" ],
		  [ Subjects => "e:databaseInfo/e:subjects" ],
		  [ "Server ID" => sub { "CNIDR zserver v2.07g" } ],
		  [ "Reliability" => sub { "97%" } ],
		  [ "Services" => sub { "search, present, delSet, concurrentOperations, namedResultSets" } ],
		  [ "Bib-1 Use attributes" => sub { "4-5, 7-8, 12, 21, 31, 54, 58, 63, 1003-1005, 1009, 1011-1012, 1016, 1031" } ],
		  [ "Operators" => sub { "and, or, not" } ],
		  [ "Record syntaxes" => sub { "SUTRS, USmarc, Danmarc" } ],
		  [ "Explain" => sub { "CategoryList, TargetInfo, DatabaseInfo, RecordSyntaxInfo, AttributeSetInfo, AttributeDetails" } ],
		  );
</%perl>
     <h2><% xml_encode($id) %></h2>
     <table class="fullrecord" border="1" cellspacing="0" cellpadding="5" width="100%">
<%perl>
    foreach my $ref (@fields) {
	my($caption, $xpath, %attrs) = @$ref;
	my $data;
	if (ref $xpath && ref($xpath) eq "CODE") {
	    $data = &$xpath();
	} else {
	    $data = $xc->find($xpath);
	}
	if ($data) {
</%perl>
      <tr>
       <th><% xml_encode($caption) %></th>
       <td><% xml_encode($data) %></td>
      </tr>
%	}
%   }
     </table>
     <p>
      <a href="<% xml_encode("/raw.html?id=" . uri_escape($id))
		%>">Raw XML record</a>
     </p>
% }
