# $Id: Record.pm,v 1.20 2006-11-29 18:17:16 mike Exp $

package ZOOM::IRSpy::Record;

use 5.008;
use strict;
use warnings;

use XML::LibXML;
use XML::LibXML::XPathContext;
use ZOOM::IRSpy::Utils qw(xml_encode isodate);

=head1 NAME

ZOOM::IRSpy::Record - record describing a target for IRSpy

=head1 SYNOPSIS

 ## To follow

=head1 DESCRIPTION

I<## To follow>

=cut

sub new {
    my $class = shift();
    my($irspy, $target, $zeerex) = @_;

    if (!defined $zeerex) {
	$zeerex = _empty_zeerex_record($target);
    }

    my $parser = new XML::LibXML();
    return bless {
	irspy => $irspy,
	target => $target,
	parser => $parser,
	zeerex => $parser->parse_string($zeerex)->documentElement(),
    }, $class;
}


sub _empty_zeerex_record {
    my($target) = @_;

    ### Doesn't recognise SRU/SRW URLs
    my($host, $port, $db) = ZOOM::IRSpy::_parse_target_string($target);

    my $xhost = xml_encode($host);
    my $xport = xml_encode($port);
    my $xdb = xml_encode($db);
    return <<__EOT__;
<explain xmlns="http://explain.z3950.org/dtd/2.0/">
 <serverInfo protocol="Z39.50" version="1995">
  <host>$xhost</host>
  <port>$xport</port>
  <database>$xdb</database>
 </serverInfo>
</explain>
__EOT__
}


sub append_entry {
    my $this = shift();
    my($xpath, $frag) = @_;

    #print STDERR "this=$this, xpath='$xpath', frag='$frag'\n";
    my $root = $this->{zeerex}; # XML::LibXML::Element ISA XML::LibXML::Node
    my $xc = XML::LibXML::XPathContext->new($root);
    $xc->registerNs(zeerex => "http://explain.z3950.org/dtd/2.0/");
    $xc->registerNs(irspy => $ZOOM::IRSpy::Utils::IRSPY_NS);

    my @nodes = $xc->findnodes($xpath);
    if (@nodes == 0) {
	# Make the node that we're inserting into, if possible.  A
	# fully general version would work its way through each
	# component of the XPath, but for now we just treat it as a
	# single chunk to go inside the top-level node.
	$this->_half_decent_appendWellBalancedChunk($root,
						    "<$xpath></$xpath>");
	@nodes = $xc->findnodes($xpath);
	die("still no matches for '$xpath' after creating: can't append")
	    if @nodes == 0;
    }

    $this->{irspy}->log("warn",
			scalar(@nodes), " matches for '$xpath': using first")
	if @nodes > 1;

    $this->_half_decent_appendWellBalancedChunk($nodes[0], $frag);
}

sub store_result {
    my ($this, $type, %info) = @_;
    my $xml = "<irspy:$type";

    foreach my $key (keys %info) {
        $xml .= " $key=\"" . $this->_string2cdata($info{$key}) . "\"";
    }

    $xml .= ">" . isodate(time()) . "</irspy:$type>\n";

    $this->append_entry('irspy:status', $xml);
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
#	$node->setNamespace($ZOOM::IRSpy::Utils::IRSPY_NS, "irspy", 0);
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
	$frag =~ s,>, xmlns:irspy="$ZOOM::IRSpy::Utils::IRSPY_NS">,;
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
    die "## no code yet to make DOM node";
}


# Yes, I know that this is already implemented in IRSpy.pm. I suggest that we
# introduce a toolkit package with such subroutines...
#
sub _string2cdata {
    my ($this, $buffer) = @_;
    $buffer =~ s/&/&amp;/gs;
    $buffer =~ s/</&lt;/gs;
    $buffer =~ s/>/&gt;/gs;
    $buffer =~ s/"/&quot;/gs;
    $buffer =~ s/'/&apos;/gs;

    return $buffer;
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
