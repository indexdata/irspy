# $Id: Utils.pm,v 1.22 2007-03-01 13:51:18 mike Exp $

package ZOOM::IRSpy::Utils;

use 5.008;
use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw(isodate
		    xml_encode 
		    cql_quote
		    irspy_xpath_context
		    modify_xml_document
		    bib1_access_point);

use XML::LibXML;
use XML::LibXML::XPathContext;

our $IRSPY_NS = 'http://indexdata.com/irspy/1.0';


# Utility functions follow, exported for use of web UI
sub isodate {
    my($time) = @_;

    my($sec, $min, $hour, $mday, $mon, $year) = localtime($time);
    return sprintf("%04d-%02d-%02dT%02d:%02d:%02d",
		   $year+1900, $mon+1, $mday, $hour, $min, $sec);
}


# I can't -- just can't, can't, can't -- believe that this function
# isn't provided by one of the core XML modules.  But the evidence all
# says that it's not: among other things, XML::Generator and
# Template::Plugin both roll their own.  So I will do likewise.  D'oh!
#
sub xml_encode {
    my($text, $fallback, $opts) = @_;
    if (!defined $opts && ref $fallback) {
	# The second and third arguments are both optional
	$opts = $fallback;
	$fallback = undef;
    }
    $opts = {} if !defined $opts;

    $text = $fallback if !defined $text;
    use Carp;
    confess "xml_encode(): text and fallback both undefined"
	if !defined $text;

    $text =~ s/&/&amp;/g;
    $text =~ s/</&lt;/g;
    $text =~ s/>/&gt;/g;
    # Internet Explorer can't display &apos; (!) so don't create it
    #$text =~ s/['']/&apos;/g;
    $text =~ s/[""]/&quot;/g;
    $text =~ s/ /&nbsp;/g if $opts->{nbsp};

    return $text;
}


# Quotes a term for use in a CQL query
sub cql_quote {
    my($term) = @_;

    $term =~ s/([""\\])/\\$1/g;
    $term = qq["$term"] if $term =~ /\s/;
    return $term;
}


# PRIVATE to irspy_namespace() and irspy_xpath_context()
my %_namespaces = (
		   e => 'http://explain.z3950.org/dtd/2.0/',
		   i => $IRSPY_NS,
		   );


sub irspy_namespace {
    my($prefix) = @_;

    use Carp;
    confess "irspy_namespace(undef)" if !defined $prefix;
    my $uri = $_namespaces{$prefix};
    die "irspy_namespace(): no URI for namespace prefix '$prefix'"
	if !defined $uri;

    return $uri;
}


sub irspy_xpath_context {
    my($record) = @_;

    my $xml = ref $record ? $record->render() : $record;
    my $parser = new XML::LibXML();
    my $doc = $parser->parse_string($xml);
    my $root = $doc->getDocumentElement();
    my $xc = XML::LibXML::XPathContext->new($root);
    foreach my $prefix (keys %_namespaces) {
	$xc->registerNs($prefix, $_namespaces{$prefix});
    }
    return $xc;
}


sub modify_xml_document {
    my($xc, $fieldsByKey, $data) = @_;

    my @changes = ();
    foreach my $key (keys %$data) {
	my $value = $data->{$key};
	my $ref = $fieldsByKey->{$key} or die "no field '$key'";
	my($name, $nlines, $caption, $xpath, @addAfter) = @$ref;
	#print "Considering $key='$value' ($xpath)<br/>\n";
	my @nodes = $xc->findnodes($xpath);
	if (@nodes) {
	    warn scalar(@nodes), " nodes match '$xpath'" if @nodes > 1;
	    my $node = $nodes[0];

	    if ($node->isa("XML::LibXML::Attr")) {
		if ($value ne $node->getValue()) {
		    $node->setValue($value);
		    push @changes, $ref;
		    #print "Attr $key: '", $node->getValue(), "' -> '$value' ($xpath)<br/>\n";
		}
	    } elsif ($node->isa("XML::LibXML::Element")) {
		# The contents could be any mixture of text and
		# comments and maybe even other crud such as processing
		# instructions.  The simplest thing is just to throw it all
		# away and start again, making a single Text node the
		# canonical representation.  But before we do that,
		# we'll check whether the element is already
		# canonical, to determine whether our change is a
		# no-op.
		my $old = "???";
		my @children = $node->childNodes();
		if (@children == 1) {
		    my $child = $node->firstChild();
		    if (ref $child && ref $child eq "XML::LibXML::Text") {
			$old = $child->getData();
			next if $value eq $old;
		    }
		}

		$node->removeChildNodes();
		my $child = new XML::LibXML::Text($value);
		$node->appendChild($child);
		push @changes, $ref;
		#print "Elem $key: '$old' -> '$value' ($xpath)<br/>\n";
	    } else {
		warn "unexpected node type $node";
	    }

	} else {
	    next if !$value; # No need to create a new empty node
	    my($ppath, $selector) = $xpath =~ /(.*)\/(.*)/;
	    dom_add_node($xc, $ppath, $selector, $value, @addAfter);
	    #print "New $key ($xpath) = '$value'<br/>\n";
	    push @changes, $ref;
	}
    }

    return @changes;
}


sub dom_add_node {
    my($xc, $ppath, $selector, $value, @addAfter) = @_;

    #print "Adding $selector='$value' at '$ppath' after (", join(", ", map { "'$_'" } @addAfter), ")<br/>\n";
    my $node = find_or_make_node($xc, $ppath, 0);
    die "couldn't find or make node '$node'" if !defined $node;

    my $is_attr = ($selector =~ s/^@//);
    my(undef, $prefix, $simpleSel) = $selector =~ /((.*?):)?(.*)/;
    #warn "selector='$selector', prefix='$prefix', simpleSel='$simpleSel'";
    if ($is_attr) {
	if (defined $prefix) {
	    ### This seems to no-op (thank, DOM!) but I have have no
	    # idea, and it's not needed for IRSpy, so I am not going
	    # to debug it now.
	    $node->setAttributeNS(irspy_namespace($prefix),
				  $simpleSel, $value);
	} else {
	    $node->setAttribute($simpleSel, $value);
	}
	return;
    }

    my $new = new XML::LibXML::Element($simpleSel);
    $new->setNamespace(irspy_namespace($prefix), $prefix)
	if defined $prefix;

    $new->appendText($value);
    foreach my $predecessor (reverse @addAfter) {
	my($child) = $xc->findnodes($predecessor, $node);
	if (defined $child) {
	    $node->insertAfter($new, $child);
	    #warn "Added after '$predecessor'";
	    return;
	}
    }

    # Didn't find any of the nodes that are supposed to precede the
    # new one, so we need to insert the new node as the first of the
    # parent's children.  However *sigh* there is no prependChild()
    # analogous to appendChild(), so we have to go the long way round.
    my @children = $node->childNodes();
    if (@children) {
	$node->insertBefore($new, $children[0]);
	#warn "Added new first child";
    } else {
	$node->appendChild($new);
	#warn "Added new only child";
    }

    if (0) {
	my $text = xml_encode(inheritance_tree($xc));
	$text =~ s/\n/<br\/>$&/sg;
	print "<pre>$text</pre>\n";
    }
}


sub find_or_make_node {
    my($xc, $path, $recursion_level) = @_;

    die "deep recursion in find_or_make_node($path)"
	if $recursion_level == 10;
    $path = "." if $path eq "";

    my @nodes = $xc->findnodes($path);
    if (@nodes == 0) {
	# Oh dear, the parent node doesn't exist.  We could make it,
	my(undef, $ppath, $element) = $path =~ /((.*)\/)?(.*)/;
	$ppath = "" if !defined $ppath;
	#warn "path='$path', ppath='$ppath', element='$element'";
	#warn "no node '$path': making it";
	my $parent = find_or_make_node($xc, $ppath, $recursion_level-1);

	my(undef, $prefix, $nsElem) = $element =~ /((.*?):)?(.*)/;
	#warn "element='$element', prefix='$prefix', nsElem='$nsElem'";
	my $new = new XML::LibXML::Element($nsElem);
	if (defined $prefix) {
	    #warn "setNamespace($prefix)";
	    $new->setNamespace(irspy_namespace($prefix), $prefix);
	}

	$parent->appendChild($new);
	return $new;
    }
    warn scalar(@nodes), " nodes match parent '$path'" if @nodes > 1;
    return $nodes[0];
}


sub inheritance_tree {
    my($type, $level) = @_;
    $level = 0 if !defined $level;
    return "Woah!  Too deep, man!\n" if $level > 20;

    $type = ref $type if ref $type;
    my $text = "";
    $text = "--> " if $level == 0;
    $text .= ("\t" x $level) . "$type\n";
    my @ISA = eval "\@${type}::ISA";
    foreach my $superclass (@ISA) {
	$text .= inheritance_tree($superclass, $level+1);
    }

    return $text;
}


# This function is made available in xslt using the register_function call
sub xslt_strcmp {
    my ($arg1, $arg2) = @_;
    return ($arg1->to_literal()) cmp ($arg2->to_literal());
}


### It feels like this should be in YAZ, exported via ZOOM-Perl.
my %_bib1_access_point = (
	1 =>	"Personal name",
	2 =>	"Corporate name",
	3 =>	"Conference name",
	4 =>	"Title",
	5 =>	"Title series",
	6 =>	"Title uniform",
	7 =>	"ISBN",
	8 =>	"ISSN",
	9 =>	"LC card number",
	10 =>	"BNB card no.",
	11 =>	"BGF number",
	12 =>	"Local number",
	13 =>	"Dewey classification",
	14 =>	"UDC classification",
	15 =>	"Bliss classification",
	16 =>	"LC call number",
	17 =>	"NLM call number",
	18 =>	"NAL call number",
	19 =>	"MOS call number",
	20 =>	"Local classification",
	21 =>	"Subject heading",
	22 =>	"Subject Rameau",
	23 =>	"BDI index subject",
	24 =>	"INSPEC subject",
	25 =>	"MESH subject",
	26 =>	"PA subject",
	27 =>	"LC subject heading",
	28 =>	"RVM subject heading",
	29 =>	"Local subject index",
	30 =>	"Date",
	31 =>	"Date of publication",
	32 =>	"Date of acquisition",
	33 =>	"Title key",
	34 =>	"Title collective",
	35 =>	"Title parallel",
	36 =>	"Title cover",
	37 =>	"Title added title page",
	38 =>	"Title caption",
	39 =>	"Title running",
	40 =>	"Title spine",
	41 =>	"Title other variant",
	42 =>	"Title former",
	43 =>	"Title abbreviated",
	44 =>	"Title expanded",
	45 =>	"Subject precis",
	46 =>	"Subject rswk",
	47 =>	"Subject subdivision",
	48 =>	"No. nat'l biblio.",
	49 =>	"No. legal deposit",
	50 =>	"No. govt pub.",
	51 =>	"No. music publisher",
	52 =>	"Number db",
	53 =>	"Number local call",
	54 =>	"Code--language",
	55 =>	"Code--geographic area",
	56 =>	"Code--institution",
	57 =>	"Name and title *",
	58 =>	"Name geographic",
	59 =>	"Place publication",
	60 =>	"CODEN",
	61 =>	"Microform generation",
	62 =>	"Abstract",
	63 =>	"Note",
	1000 =>	"Author-title",
	1001 =>	"Record type",
	1002 =>	"Name",
	1003 =>	"Author",
	1004 =>	"Author-name personal",
	1005 =>	"Author-name corporate",
	1006 =>	"Author-name conference",
	1007 =>	"Identifier--standard",
	1008 =>	"Subject--LC children's",
	1009 =>	"Subject name -- personal",
	1010 =>	"Body of text",
	1011 =>	"Date/time added to db",
	1012 =>	"Date/time last modified",
	1013 =>	"Authority/format id",
	1014 =>	"Concept-text",
	1015 =>	"Concept-reference",
	1016 =>	"Any",
	1017 =>	"Server-choice",
	1018 =>	"Publisher",
	1019 =>	"Record-source",
	1020 =>	"Editor",
	1021 =>	"Bib-level",
	1022 =>	"Geographic-class",
	1023 =>	"Indexed-by",
	1024 =>	"Map-scale",
	1025 =>	"Music-key",
	1026 =>	"Related-periodical",
	1027 =>	"Report-number",
	1028 =>	"Stock-number",
	1030 =>	"Thematic-number",
	1031 =>	"Material-type",
	1032 =>	"Doc-id",
	1033 =>	"Host-item",
	1034 =>	"Content-type",
	1035 =>	"Anywhere",
	1036 =>	"Author-Title-Subject",
	1032 =>	"Doc-id (semantic definition change)",
	1037 =>	"SICI",
	1038 =>	"Abstract-language",
	1039 =>	"Application-kind",
	1040 =>	"Classification",
	1041 =>	"Classification-basic",
	1042 =>	"Classification-local-record",
	1043 =>	"Enzyme",
	1044 =>	"Possessing-institution",
	1045 =>	"Record-linking",
	1046 =>	"Record-status",
	1047 =>	"Treatment",
	1048 =>	"Control-number-GKD",
	1049 =>	"Control-number-linking",
	1050 =>	"Control-number-PND",
	1051 =>	"Control-number-SWD",
	1052 =>	"Control-number-ZDB",
	1053 =>	"Country-publication (country of Publication)",
	1054 =>	"Date-conference (meeting date)",
	1055 =>	"Date-record-status",
	1056 =>	"Dissertation-information",
	1057 =>	"Meeting-organizer",
	1058 =>	"Note-availability",
	1059 =>	"Number-CAS-registry (CAS registry number)",
	1060 =>	"Number-document (document number)",
	1061 =>	"Number-local-accounting",
	1062 =>	"Number-local-acquisition",
	1063 =>	"Number-local-call-copy-specific",
	1064 =>	"Number-of-reference (reference count)",
	1065 =>	"Number-norm",
	1066 =>	"Number-volume",
	1067 =>	"Place-conference (meeting location)",
	1068 =>	"Reference (references and footnotes)",
	1069 =>	"Referenced-journal (reference work)",
	1070 =>	"Section-code",
	1071 =>	"Section-heading",
	1072 =>	"Subject-GOO",
	1073 =>	"Subject-name-conference",
	1074 =>	"Subject-name-corporate",
	1075 =>	"Subject-genre/form",
	1076 =>	"Subject-name-geographical",
	1077 =>	"Subject--chronological",
	1078 =>	"Subject--title",
	1079 =>	"Subject--topical",
	1080 =>	"Subject-uncontrolled",
	1081 =>	"Terminology-chemical (chemical name)",
	1082 =>	"Title-translated",
	1083 =>	"Year-of-beginning",
	1084 =>	"Year-of-ending",
	1085 =>	"Subject-AGROVOC",
	1086 =>	"Subject-COMPASS",
	1087 =>	"Subject-EPT",
	1088 =>	"Subject-NAL",
	1089 =>	"Classification-BCM",
	1090 =>	"Classification-DB",
	1091 =>	"Identifier-ISRC",
	1092 =>	"Identifier-ISMN",
	1093 =>	"Identifier-ISRN",
	1094 =>	"Identifier-DOI",
	1095 =>	"Code-language-original",
	1096 =>	"Title-later",
	1097 =>	"DC-Title",
	1098 =>	"DC-Creator",
	1099 =>	"DC-Subject",
	1100 =>	"DC-Description",
	1101 =>	"DC-Publisher",
	1102 =>	"DC-Date",
	1103 =>	"DC-ResourceType",
	1104 =>	"DC-ResourceIdentifier",
	1105 =>	"DC-Language",
	1106 =>	"DC-OtherContributor",
	1107 =>	"DC-Format",
	1108 =>	"DC-Source",
	1109 =>	"DC-Relation",
	1110 =>	"DC-Coverage",
	1111 =>	"DC-RightsManagement",
	1112 =>	"Controlled Subject Index",
	1113 =>	"Subject Thesaurus",
	1114 =>	"Index Terms -- Controlled",
	1115 =>	"Controlled Term",
	1116 =>	"Spatial Domain",
	1117 =>	"Bounding Coordinates",
	1118 =>	"West Bounding Coordinate",
	1119 =>	"East Bounding Coordinate",
	1120 =>	"North Bounding Coordinate",
	1121 =>	"South Bounding Coordinate",
	1122 =>	"Place",
	1123 =>	"Place Keyword Thesaurus",
	1124 =>	"Place Keyword",
	1125 =>	"Time Period",
	1126 =>	"Time Period Textual",
	1127 =>	"Time Period Structured",
	1128 =>	"Beginning Date",
	1129 =>	"Ending Date",
	1130 =>	"Availability",
	1131 =>	"Distributor",
	1132 =>	"Distributor Name",
	1133 =>	"Distributor Organization",
	1134 =>	"Distributor Street Address",
	1135 =>	"Distributor City",
	1136 =>	"Distributor State or Province",
	1137 =>	"Distributor Zip or Postal Code",
	1138 =>	"Distributor Country",
	1139 =>	"Distributor Network Address",
	1140 =>	"Distributor Hours of Service",
	1141 =>	"Distributor Telephone",
	1142 =>	"Distributor Fax",
	1143 =>	"Resource Description",
	1144 =>	"Order Process",
	1145 =>	"Order Information",
	1146 =>	"Cost",
	1147 =>	"Cost Information",
	1148 =>	"Technical Prerequisites",
	1149 =>	"Available Time Period",
	1150 =>	"Available Time Textual",
	1151 =>	"Available Time Structured",
	1152 =>	"Available Linkage",
	1153 =>	"Linkage Type",
	1154 =>	"Linkage",
	1155 =>	"Sources of Data",
	1156 =>	"Methodology",
	1157 =>	"Access Constraints",
	1158 =>	"General Access Constraints",
	1159 =>	"Originator Dissemination Control",
	1160 =>	"Security Classification Control",
	1161 =>	"Use Constraints",
	1162 =>	"Point of Contact",
	1163 =>	"Contact Name",
	1164 =>	"Contact Organization",
	1165 =>	"Contact Street Address",
	1166 =>	"Contact City",
	1167 =>	"Contact State or Province",
	1168 =>	"Contact Zip or Postal Code",
	1169 =>	"Contact Country",
	1170 =>	"Contact Network Address",
	1171 =>	"Contact Hours of Service",
	1172 =>	"Contact Telephone",
	1173 =>	"Contact Fax",
	1174 =>	"Supplemental Information",
	1175 =>	"Purpose",
	1176 =>	"Agency Program",
	1177 =>	"Cross Reference",
	1178 =>	"Cross Reference Title",
	1179 =>	"Cross Reference Relationship",
	1180 =>	"Cross Reference Linkage",
	1181 =>	"Schedule Number",
	1182 =>	"Original Control Identifier",
	1183 =>	"Language of Record",
	1184 =>	"Record Review Date",
	1185 =>	"Performer",
	1186 =>	"Performer-Individual",
	1187 =>	"Performer-Group",
	1188 =>	"Instrumentation",
	1189 =>	"Instrumentation-Original",
	1190 =>	"Instrumentation-Current",
	1191 =>	"Arrangement",
	1192 =>	"Arrangement-Original",
	1193 =>	"Arrangement-Current",
	1194 =>	"Musical Key-Original",
	1195 =>	"Musical Key-Current",
	1196 =>	"Date-Composition",
	1197 =>	"Date-Recording",
	1198 =>	"Place-Recording",
	1199 =>	"Country-Recording",
	1200 =>	"Number-ISWC",
	1201 =>	"Number-Matrix",
	1202 =>	"Number-Plate",
	1203 =>	"Classification-McColvin",
	1204 =>	"Duration",
	1205 =>	"Number-Copies",
	1206 =>	"Musical Theme",
	1207 =>	"Instruments - total number",
	1208 =>	"Instruments - distinct number",
	1209 =>	"Identifier - URN",
	1210 =>	"Sears Subject Heading",
	1211 =>	"OCLC Number",
	1212 =>	"Composition",
	1213 =>	"Intellectual level",
	1214 =>	"EAN",
	1215 =>	"NLC",
	1216 =>	"CRCS",
	1217 =>	"Nationality",
	1218 =>	"Equinox",
	1219 =>	"Compression",
	1220 =>	"Format",
	1221 =>	"Subject - occupation",
	1222 =>	"Subject - function",
	1223 =>	"Edition",
);

sub bib1_access_point {
    my($ap) = @_;

    return $_bib1_access_point{$ap} ||
	"unknown BIB-1 attribute '$ap'";
}


1;
