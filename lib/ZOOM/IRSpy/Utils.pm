# $Id: Utils.pm,v 1.3 2006-10-31 09:26:11 mike Exp $

package ZOOM::IRSpy::Utils;

use 5.008;
use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw(xml_encode 
		    irspy_xpath_context
		    dom_add_element
		    inheritance_tree);


# Utility functions follow, exported for use of web UI

# I can't -- just can't, can't, can't -- believe that this function
# isn't provided by one of the core XML modules.  But the evidence all
# says that it's not: among other things, XML::Generator and
# Template::Plugin both roll their own.  So I will do likewise.  D'oh!
#
sub xml_encode {
    my ($text) = @_;
    $text =~ s/&/&amp;/g;
    $text =~ s/</&lt;/g;
    $text =~ s/>/&gt;/g;
    $text =~ s/['']/&apos;/g;
    $text =~ s/[""]/&quot;/g;
    return $text;
}


sub irspy_xpath_context {
    my($zoom_record) = @_;

    my $xml = $zoom_record->render();
    my $parser = new XML::LibXML();
    my $doc = $parser->parse_string($xml);
    my $root = $doc->getDocumentElement();
    my $xc = XML::LibXML::XPathContext->new($root);
    $xc->registerNs(e => 'http://explain.z3950.org/dtd/2.0/');
    $xc->registerNs(i => $ZOOM::IRSpy::irspy_ns);
    return $xc;
}


sub dom_add_element {
    my($xc, $ppath, $element, $value, @addAfter) = @_;

    print "Adding '$value' at '$ppath' after (", join(", ", map { "'$_'" } @addAfter), ")<br/>\n";
    my @nodes = $xc->findnodes($ppath);
    if (@nodes == 0) {
	# Oh dear, the parent node doesn't exist.  We could make it,
	# but for now let's not and say we did.
	warn "no parent node '$ppath': not adding '$element'='$value'";
	return;
    }

    warn scalar(@nodes), " nodes match parent '$ppath'" if @nodes > 1;
    my $node = $nodes[0];

    if (1) {
	my $text = xml_encode(inheritance_tree($xc));
	$text =~ s/\n/<br\/>$1/sg;
	print "<pre>$text</pre>\n";
    }
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


#print "Loaded ZOOM::IRSpy::Utils.pm";


1;
