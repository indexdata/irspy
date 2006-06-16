#! /usr/bin/perl -w

# $Id: ezeerex2pqfproperties.pl,v 1.2 2006-06-16 15:28:46 mike Exp $

use strict;
use warnings;
use XML::LibXML;
use XML::LibXML::XPathContext;

my $text = join("", <>);
my $parser = new XML::LibXML();
my $doc = $parser->parse_string($text);
my $root = $doc->getDocumentElement();
my $xc = XML::LibXML::XPathContext->new($root);
$xc->registerNs(zeerex => "http://explain.z3950.org/dtd/2.0/");
print "root=$root, xc=$xc\n";
my(@nodes) = $xc->findnodes('zeerex:serverInfo/zeerex:host');
print "found ", scalar(@nodes), " values\n";
for (my $i = 0; $i < @nodes; $i++) {
    my $node = $nodes[$i];
    print $i+1, ": ", $node->toString();
}
