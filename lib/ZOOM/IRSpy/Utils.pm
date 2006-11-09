# $Id: Utils.pm,v 1.9 2006-11-09 16:09:35 mike Exp $

package ZOOM::IRSpy::Utils;

use 5.008;
use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw(xml_encode 
		    irspy_xpath_context
		    modify_xml_document
		    inheritance_tree);

use XML::LibXML;
use XML::LibXML::XPathContext;

our $IRSPY_NS = 'http://indexdata.com/irspy/1.0';


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


# PRIVATE to irspy_namespace() and irspy_xpath_context()
my %_namespaces = (
		   e => 'http://explain.z3950.org/dtd/2.0/',
		   i => $IRSPY_NS,
		   );


sub irspy_namespace {
    my($prefix) = @_;

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

    my $nchanges = 0;
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
		    $nchanges++;
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
		$nchanges++;
		#print "Elem $key: '$old' -> '$value' ($xpath)<br/>\n";
	    } else {
		warn "unexpected node type $node";
	    }

	} else {
	    next if !$value; # No need to create a new empty node
	    my($ppath, $element) = $xpath =~ /(.*)\/(.*)/;
	    dom_add_element($xc, $ppath, $element, $value, @addAfter);
	    #print "New $key ($xpath) = '$value'<br/>\n";
	    $nchanges++;
	}
    }

    return $nchanges;
}


sub dom_add_element {
    my($xc, $ppath, $element, $value, @addAfter) = @_;

    #print "Adding $element='$value' at '$ppath' after (", join(", ", map { "'$_'" } @addAfter), ")<br/>\n";
    my @nodes = $xc->findnodes($ppath);
    if (@nodes == 0) {
	# Oh dear, the parent node doesn't exist.  We could make it,
	# but for now let's not and say we did.
	warn "no parent node '$ppath': not adding '$element'='$value'";
	return;
    }
    warn scalar(@nodes), " nodes match parent '$ppath'" if @nodes > 1;
    my $node = $nodes[0];

    my(undef, $prefix, $nsElem) = $element =~ /((.*?):)?(.*)/;
    my $new = new XML::LibXML::Element($nsElem);
    $new->setNamespace(irspy_namespace($prefix), $prefix)
	if $prefix ne "";

    $new->appendText($value);
    foreach my $predecessor (reverse @addAfter) {
	my($child) = $xc->findnodes($predecessor, $node);
	if (defined $child) {
	    $node->insertAfter($new, $child);
	    #print "Added after '$predecessor'<br/>\n";
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
	#print "Added new first child<br/>\n";
    } else {
	$node->appendChild($new);
	#print "Added new only child<br/>\n";
    }

    if (0) {
	my $text = xml_encode(inheritance_tree($xc));
	$text =~ s/\n/<br\/>$&/sg;
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
