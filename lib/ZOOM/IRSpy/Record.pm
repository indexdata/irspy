# $Id: Record.pm,v 1.6 2006-07-21 16:50:20 mike Exp $

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
    print "Record='", $root->toString(), "'\n";
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

    print STDERR "zeerex='$root'\n";
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
