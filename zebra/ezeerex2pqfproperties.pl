#! /usr/bin/perl -w

# $Id: ezeerex2pqfproperties.pl,v 1.3 2006-06-19 08:15:37 mike Exp $

use strict;
use warnings;
use XML::LibXML;
use XML::LibXML::XPathContext;

my $text = join('', <>);
my $parser = new XML::LibXML();
my $doc = $parser->parse_string($text);
my $root = $doc->getDocumentElement();
my $xc = XML::LibXML::XPathContext->new($root);
$xc->registerNs(zeerex => 'http://explain.z3950.org/dtd/2.0/');

print_sets($xc);
print_default_set($xc);
print_indexes($xc);
#print_relations($xc);
#print_relation_modifiers($xc);
#print_positions($xc);
#print_structures($xc);
#print_truncations($xc);

# We could limit the sets output to those that are actually used by an
# SRU index: that way we could avoid defining
#	set.bib1 = 1.2.840.10003.3.1
# which is a Z39.50 attribute set that we don't need for CQL.  But
# doing that would be a marginal gain.
#
sub print_sets {
    my($xc) = @_;

    my(@nodes) = $xc->findnodes('zeerex:indexInfo/zeerex:set');
    print "found ", scalar(@nodes), " values\n";
    foreach my $node (@nodes) {
	my $name = $node->findvalue('@name');
	my $identifier = $node->findvalue('@identifier');
	print "set.$name = $identifier\n";
    }
}

sub print_default_set {
    my($xc) = @_;

    my (@nodes) = $xc->findnodes('zeerex:configInfo/' .
				 'zeerex:default[@type="contextSet"]');
    foreach my $node (@nodes) {
	print "set = ", $node->findvalue('.'), "\n";
    }
}

sub print_indexes {
    my($xc) = @_;

    foreach my $node ($xc->findnodes('zeerex:indexInfo/' .
				     'zeerex:index[@search="true"]')) {
	print "node=$node = ", $node->toString(), "\n";
	foreach my $map ($node->findnodes("zeerex:map")) {
	    print "map=$map = ", $map->toString(), "\n";
	    print("index.", $map->findvalue('@set'),
		  " = ",  $map->findvalue('.'));
	}
    }
}
