# $Id: Record.pm,v 1.7 2006-07-24 15:25:51 mike Exp $

package ZOOM::IRSpy::Record;

use 5.008;
use strict;
use warnings;

use XML::LibXML;
use XML::LibXML::XPathContext;


=head1 NAME

ZOOM::IRSpy::Record - record describing a target for IRSpy

=head1 SYNOPSIS

 ## To follow

=head1 DESCRIPTION

I<## To follow>

=cut

sub new {
    my $class = shift();
    my($target, $zeerex) = @_;

    if (!defined $zeerex) {
	$zeerex = _empty_zeerex_record($target);
    }

    my $parser = new XML::LibXML();
    return bless {
	target => $target,
	parser => $parser,
	zeerex => $parser->parse_string($zeerex)->documentElement(),
    }, $class;
}


sub _empty_zeerex_record {
    my($target) = @_;

    ### Doesn't recognise SRU/SRW URLs
    my($host, $port, $db) = ZOOM::IRSpy::_parse_target_string($target);

    return <<__EOT__;
<explain xmlns="http://explain.z3950.org/dtd/2.0/">
 <serverInfo protocol="Z39.50" version="1995">
  <host>$host</host>
  <port>$port</port>
  <database>$db</database>
 </serverInfo>
</explain>
__EOT__
}


sub append_entry {
    my $this = shift();
    my($xpath, $frag) = @_;

    print STDERR "this=$this, xpath='$xpath', frag='$frag'\n";
    my $root = $this->{zeerex}; # XML::LibXML::Element ISA XML::LibXML::Node
    my $xc = XML::LibXML::XPathContext->new($root);
    $xc->registerNs(zeerex => "http://explain.z3950.org/dtd/2.0/");
    $xc->registerNs(irspy => "http://indexdata.com/irspy/1.0");

    my @nodes = $xc->findnodes($xpath);
    if (@nodes == 0) {
	ZOOM::Log::log("irspy", "no matches for '$xpath': can't append");
	return;
    } elsif (@nodes > 1) {
	ZOOM::Log::log("irspy", scalar(@nodes),
		       " matches for '$xpath': using first");
    }

    my $node = $nodes[0];
    # $node ISA XML::LibXML::ElementXML::LibXML::Element
    $this->_half_decent_appendWellBalancedChunk($node, $frag);
    #print STDERR "POST: zeerex='$root' = \n", $root->toString(), "\n";
}


# *sigh*
#
# _Clearly_ the right way to append a well-balanced chunk of XML to
# a node's children is to call appendWellBalancedChunk() from the
# XML::LibXML::Element class.  However, this fails in the common case
# where the ZeeRex record we're working with doesn't declare the
# "irspy" namespace that the inserted fragments use.
#
# To my utter astonishment it seems that XML::LibXML (as of version
# 1.58, 31st March 2004) doesn't provide ANY way to register a
# namespace for parsing, which makes the parse_balanced_chunk()
# function that appendWellBalancedChunk() uses effectively useless.
# It _is_ possible to use setNamespace() on a node, to register a new
# namespace mapping for that node -- but that only affects pre-parsed
# trees, and is no use for parsing.  Hence the following pair of lines
# DOES NOT WORK:
#	$node->setNamespace("http://indexdata.com/irspy/1.0", "irspy", 0);
#	$node->appendWellBalancedChunk($frag);
#
# Instead I have to go the long way round, hence this method.  I have
# two candidate re-implementations, of which the former is marginally
# less loathsome, but does require that the excess namespace
# declarations be factored out later -- as least, if you want neat
# output.
#
sub _half_decent_appendWellBalancedChunk {
    my $this = shift();
    my($node, $frag) = @_;

    if (1) {
	$frag =~ s,>, xmlns:irspy="http://indexdata.com/irspy/1.0">,;
	$node->appendWellBalancedChunk($frag);
	return;
    }

    # Instead -- and to call this brain-damaged would be an insult
    # to all those fine people out there with actual brain damage
    # -- I have to "parse" the XML fragment myself and insert the
    # resulting hand-build DOM tree.  Someone shoot me now.
    my($open, $content, $close) = $frag =~ /^<(.*?)>(.*)<\/(.*?)>$/;
    die "can't 'parse' XML fragment '$frag'"
	if !defined $open;
    my($tag, $attrs) = $open =~ /(.*?)\s(.*)/;
    $tag = $open if !defined $tag;
    die "mismatched XML start/end <$open>...<$close>"
	if $close ne $tag;
    print STDERR "tag='$tag', attrs=[$attrs], content='$content'\n";
    die "### no code yet to make DOM node";
}


=head1 SEE ALSO

ZOOM::IRSpy

=head1 AUTHOR

Mike Taylor, E<lt>mike@indexdata.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Index Data ApS.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
