#! /usr/bin/perl -w

# $Id: ezeerex2pqfproperties.pl,v 1.1 2006-06-05 09:18:58 mike Exp $

use strict;
use warnings;
use XML::LibXML;

my $text = join("", <>);
my $parser = new XML::LibXML();
my $doc = $parser->parse_string($text);
my $root = $doc->getDocumentElement();
print "root=$root, ISA=(", join(", ", @XML::LibXML::Element::ISA), ")\n";
$root->registerDefaultNs("/.//")
my (@nodes) = $root->findnodes('serverInfo/host');
print "found ", scalar(@nodes), " values\n";

## From http://plasmasturm.org/log/259/
#use XML::LibXML;
#use XML::LibXML::XPathContext;
#my $p = XML::LibXML->new();
#my $doc = $p->parse_file( $ARGV[ 0 ] );
#my $xc = XML::LibXML::XPathContext->new( $doc->documentElement() );
#$xc->registerNs( atom => 'http://purl.org/atom/ns#' );
#print $xc->findvalue( q{ /xsl:stylesheet/xsl:template[ @match = '/' ]/atom:feed/atom:link[ @rel = 'alternate' ]/@href } );
