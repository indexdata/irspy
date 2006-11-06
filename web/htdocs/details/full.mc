%# $Id: full.mc,v 1.8 2006-11-06 17:01:03 mike Exp $
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
		  [ "Last Checked" => "i:status/i:probe[last()]" ],
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
		  [ "Implementation ID" => "i:status/i:implementationId" ],
		  [ "Implementation Name" => "i:status/i:implementationName" ],
		  [ "Implementation Version" => "i:status/i:implementationVersion" ],
		  [ "Reliability" => \&calc_reliability, $xc ],
		  [ "Services" => sub { "### IRSpy does not yet check for search, present, delSet, concurrentOperations, namedResultSets, etc. and store the information is a usable form." } ],
		  [ "Bib-1 Use attributes" => \&calc_bib1, $xc ],
		  [ "Operators" => sub { "### and, or, not" } ],
		  [ "Record syntaxes" => sub { "### SUTRS, USmarc, Danmarc" } ],
		  [ "Explain" => sub { "### CategoryList, TargetInfo, DatabaseInfo, RecordSyntaxInfo, AttributeSetInfo, AttributeDetails" } ],
		  );
</%perl>
     <h2><% xml_encode($xc->find("e:databaseInfo/e:title")) %></h2>
     <table class="fullrecord" border="1" cellspacing="0" cellpadding="5" width="100%">
<%perl>
    foreach my $ref (@fields) {
	my($caption, $xpath, @args) = @$ref;
	my $data;
	if (ref $xpath && ref($xpath) eq "CODE") {
	    $data = &$xpath(@args);
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
% }
<%perl>

sub calc_reliability {
    my($xc) = @_;

    my @allpings = $xc->findnodes("i:status/i:probe");
    my $nall = @allpings;
    return "[untested]" if $nall == 0;
    my @okpings = $xc->findnodes('i:status/i:probe[@ok = "1"]');
    my $nok = @okpings;
    return "$nok/$nall = " . int(100*$nok/$nall) . "%";
}

sub calc_bib1 {
    my($xc) = @_;

    my @bib1nodes = $xc->findnodes('e:indexInfo/e:index/e:map/e:attr[
	@set = "bib-1" and @type = "1"]');
    my $nbib1 = @bib1nodes;
    return "[none]" if $nbib1 == 0;

    my $res = "";
    my($first, $last);
    @bib1nodes = sort { $a->findvalue(".") <=> $b->findvalue(".") } @bib1nodes;
    foreach my $node (@bib1nodes) {
	my $ap .= $node->findvalue(".");
	if (!defined $first) {
	    $first = $ap;
	} elsif (!defined $last || $last == $ap-1) {
	    $last = $ap;
	} else {
	    # Got a complete range
	    $res .= ", " if $res ne "";
	    $res .= "$first";
	    $res .= "-$last" if defined $last;
	    $first = $ap;
	    $last = undef;
	}
    }

    # Leftovers
    if (defined $first) {
	$res .= ", " if $res ne "";
	$res .= "$first";
	$res .= "-$last" if defined $last;
    }

    return "$nbib1 access points: $res";
}

</%perl>
