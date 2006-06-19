#! /usr/bin/perl -w

# $Id: ezeerex2pqfproperties.pl,v 1.5 2006-06-19 16:45:18 mike Exp $
#
# Run like this:
#	./ezeerex2pqfproperties.pl zeerex.xml

use strict;
use warnings;
use XML::LibXML;
use XML::LibXML::XPathContext;

my $text = join('', <>);
my $parser = new XML::LibXML();
my $doc = $parser->parse_string($text);
my $root = $doc->getDocumentElement();
my $xc = XML::LibXML::XPathContext->new($root);
$xc->registerNs(z => 'http://explain.z3950.org/dtd/2.0/');

print_sets($xc);
print_default_set($xc);
print_indexes($xc);
print_relations($xc);
print_relation_modifiers($xc);
print_positions($xc);
print_structures($xc);
print_truncations($xc);

# We could limit the sets output to those that are actually used by an
# SRU index: that way we could avoid defining
#	set.bib1 = 1.2.840.10003.3.1
# which is a Z39.50 attribute set that we don't need for CQL.  But
# doing that would be a marginal gain.
#
sub print_sets {
    my($xc) = @_;

    my(@nodes) = $xc->findnodes('z:indexInfo/z:set');
    foreach my $node (@nodes) {
	my $name = $node->findvalue('@name');
	my $identifier = $node->findvalue('@identifier');
	print "set.$name = $identifier\n";
    }
}

sub print_default_set {
    my($xc) = @_;

    my (@nodes) = $xc->findnodes('z:configInfo/' .
				 'z:default[@type="contextSet"]');
    foreach my $node (@nodes) {
	### Look this up and render as a URI
	print "set = ", $node->findvalue('.'), "\n";
    }
}

sub print_indexes {
    my($xc) = @_;

    foreach my $node ($xc->findnodes('z:indexInfo/' .
				     'z:index[@search="true"]')) {
	my @pqf = $xc->findnodes("z:map/z:attr", $node);
	die("no PQF mapping for index '" .
	    $xc->findvalue("z:title", $node) . "'")
	    if @pqf == 0;
	my $ptype = $xc->findvalue('@type', $pqf[0]);
	my $pval = $xc->findvalue(".", $pqf[0]);

	foreach my $map ($xc->findnodes("z:map", $node)) {
	    my $setname = $xc->findvalue('z:name/@set', $map);
	    my $indexname = $xc->findvalue('z:name', $map);
	    ### We need a way for the ZeeRex record to specify other
	    #   attributes to be specified along with the access-point,
	    #   e.g. @attr 4=3 for whole-field indexes.
	    print "index.$setname.$indexname = $ptype=$pval\n"
		if $indexname ne "";
	}
    }
}

# I don't think these are affected by the ZeeRex record
sub print_relations {
    my($xc) = @_;

    print <<__EOT__;
relation.< = 2=1
relation.le = 2=2
relation.eq = 2=3
relation.exact = 2=3
relation.ge = 2=4
relation.> = 2=5
relation.<> = 2=6
relation.scr = 2=3
__EOT__
}

# I don't think these are affected by the ZeeRex record
sub print_relation_modifiers {
    my($xc) = @_;

    print <<__EOT__;
relationModifier.relevant = 2=102
relationModifier.fuzzy = 5=103
relationModifier.stem = 2=101
relationModifier.phonetic = 2=100
relationModifier.regexp = 5=102
__EOT__
}

# I don't think these are affected by the ZeeRex record
sub print_positions {
    my($xc) = @_;

    print <<__EOT__;
position.first = 3=1 6=1
position.any = 3=3 6=1
position.last = 3=4 6=1
position.firstAndLast = 3=3 6=3
__EOT__
}

# I don't think these are affected by the ZeeRex record
sub print_structures {
    my($xc) = @_;

    print <<__EOT__;
structure.exact = 4=108
structure.all = 4=2
structure.any = 4=2
structure.* = 4=1
__EOT__
}

# I don't think these are affected by the ZeeRex record
sub print_truncations {
    my($xc) = @_;

    print <<__EOT__;
truncation.right = 5=1
truncation.left = 5=2
truncation.both = 5=3
truncation.none = 5=100
truncation.regexp = 5=102
truncation.z3958 = 5=104
__EOT__
}
