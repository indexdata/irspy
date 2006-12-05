# $Id: Utils.pm,v 1.19 2006-12-05 17:19:35 mike Exp $

package ZOOM::IRSpy::Utils;

use 5.008;
use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw(isodate
		    xml_encode 
		    cql_quote
		    cql_target
		    irspy_xpath_context
		    modify_xml_document);

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


# Makes a CQL query that finds a specified target
sub cql_target {
    my($host, $port, $db) = @_;

    return ("host=" . cql_quote($host) . " and " .
	    "port=" . cql_quote($port) . " and " .
	    "path=" . cql_quote($db));
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


#print "Loaded ZOOM::IRSpy::Utils.pm";


1;
