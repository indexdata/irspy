%# $Id: full.mc,v 1.20 2006-12-18 15:37:06 mike Exp $
<%args>
$id
</%args>
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
    my $xc = irspy_xpath_context($rs->record(0));
    my @fields = (
		  [ Name => "e:databaseInfo/e:title",
		    lang => "en", primary => "true" ],
		  [ Country => "i:status/i:country" ],
		  [ "Last Checked" => "i:status/i:probe[last()]" ],
		  [ Protocol => "e:serverInfo/\@protocol" ],
		  [ Host => "e:serverInfo/e:host" ],
		  [ Port => "e:serverInfo/e:port" ],
		  [ "Database Name" => "e:serverInfo/e:database" ],
		  [ "Type of Library" => "i:status/i:libraryType" ],
		  [ "Username (if needed)" =>
		    "e:serverInfo/e:authentication/e:user" ],
		  [ "Password (if needed)" =>
		    "e:serverInfo/e:authentication/e:password" ],
		  [ "Server ID" => 'i:status/i:serverImplementationId/@value' ],
		  [ "Server Name" => 'i:status/i:serverImplementationName/@value' ],
		  [ "Server Version" => 'i:status/i:serverImplementationVersion/@value' ],
		  [ Description => "e:databaseInfo/e:description",
		    lang => "en", primary => "true" ],
		  [ Author => "e:databaseInfo/e:author" ],
		  [ Contact => "e:databaseInfo/e:contact" ],
		  [ "URL to Hosting Organisation" => "i:status/i:hostURL" ],
		  [ Extent => "e:databaseInfo/e:extent" ],
		  [ History => "e:databaseInfo/e:history" ],
		  [ "Language of Records" => "e:databaseInfo/e:langUsage" ],
		  [ Restrictions => "e:databaseInfo/e:restrictions" ],
		  [ Subjects => "e:databaseInfo/e:subjects" ],
		  [ "Implementation ID" => "i:status/i:implementationId" ],
		  [ "Implementation Name" => "i:status/i:implementationName" ],
		  [ "Implementation Version" => "i:status/i:implementationVersion" ],
		  [ "Reliability" => \&calc_reliability, $xc ],
		  [ "Services" => \&calc_init_options, $xc ],
		  [ "Bib-1 Use attributes" => \&calc_ap, $xc, "bib-1" ],
		  [ "Dan-1 Use attributes" => \&calc_ap, $xc, "dan-1" ],
		  [ "Operators" => \&calc_boolean, $xc ],
		  [ "Named Result Sets" => \&calc_nrs, $xc ],
		  [ "Record syntaxes" => \&calc_recsyn, $xc ],
		  [ "Explain" => \&calc_explain, $xc ],
		  );
</%perl>
     <h2><% xml_encode($xc->find("e:databaseInfo/e:title"), "") %></h2>
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

sub calc_init_options {
    my($xc) = @_;

    my @ops;
    my @nodes = $xc->findnodes('e:configInfo/e:supports/@type');
    foreach my $node (@nodes) {
	my $type = $node->value();
	if ($type =~ s/^z3950_//) {
	    push @ops, $type;
	}
    }

    return join(", ", @ops);
}

sub calc_ap {
    my($xc, $set) = @_;

    my $expr = 'e:indexInfo/e:index/e:map/e:attr[
	@set = "'.$set.'" and @type = "1"]';
    my @bib1nodes = $xc->findnodes($expr);
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

sub calc_boolean {
    my($xc) = @_;

    ### Note that we are currently interrogating an IRSpy extension.
    #	The standard ZeeRex record should be extended with a
    #	"supports" type for this.
    my @nodes = $xc->findnodes('i:status/i:boolean[@ok = "1"]');
    my $res = join(", ", map { $_->findvalue('@operator') } @nodes);
    $res = "[none]" if $res eq "";
    return $res;
}

sub calc_nrs {
    my($xc) = @_;

    my @nodes = $xc->findnodes('i:status/i:named_resultset[@ok = "1"]');
    return @nodes ? "Yes" : "No";
}

sub calc_recsyn {
    my($xc) = @_;

    my @nodes = $xc->findnodes('e:recordInfo/e:recordSyntax');
    my $res = join(", ", map { $_->findvalue('@name') } @nodes);
    $res = "[none]" if $res eq "";
    return $res;
}

sub calc_explain {
    my($xc) = @_;

    my @nodes = $xc->findnodes('i:status/i:explain[@ok = "1"]');
    my $res = join(", ", map { $_->findvalue('@category') } @nodes);
    $res = "[none]" if $res eq "";
    return $res;
}

</%perl>
