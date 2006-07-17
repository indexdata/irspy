# $Id: Simple.pm,v 1.1 2006-07-17 15:37:33 mike Exp $

package ZOOM::XML::Simple;

use 5.008;
use strict;
use warnings;

use XML::LibXML;


=head1 NAME

ZOOM::XML::Simple - read XML files into memory and play them out again

=head1 SYNOPSIS

 $doc = ZOOM::XML::Simple::XMLin("foo.xml");
 $doc->[0]->{beenRead} = 1;
 print ZOOM::XML::Simple::XMLout($doc);

=head1 DESCRIPTION

Ever used the C<XML::Simple> module?  That's what I wanted.  Read its
manual for details, but basically it lets you read a document into a
nice, simple in-memory format, fiddle with it to your heart's content,
then render it back out again.  This is nice because the in-memory
format is so very much simpler than a DOM tree.

Unfortunately, it turns out that C<XML::Simple> messes with your data
too much to be used if your XML needs to conform to a fixed pattern,
such as a DTD or XML Schema.  Some of its damage can be prevented by
passing a hatful of attributes to its C<XMLin()> and C<XMLout()>
methods, but I've not found any way to prevent it from reordering the
subelements of each element into alphabetical order, which is of
course completely unacceptable in many cases.

For the IRSpy project's C<ZOOM::IRSpy::Record> module, I need
something like C<XML::Simple> to handle the ZeeRex records -- but it
has to keep elements in their original order.  Hence this module.
Because of its ordering requirement, it has to make a different
data-structure from the original.  It also implements only a tiny
subset of the full C<XML::Simple> functionality - the parts that I
need, natch.

=cut

### But will what I make actually be all that much simpler than DOM?


#use XML::Simple qw(:strict);
#my %attr = (KeyAttr => [], KeepRoot => 1);
#my $config = XMLin("foo.xml", %attr, ForceArray => 1, ForceContent => 1);
#print XMLout($config, %attr);


=head1 SEE ALSO

XML::Simple - the module that I hoped I'd be able to use, but wasn't
able to, hence my having had to write this one.

ZOOM::IRSpy::Record - the module I was writing that I wanted to use
XML::Simple for, and found that it wouldn't do.

The ZeeRex XML format is described at
http://explain.z3950.org/

=head1 AUTHOR

Mike Taylor, E<lt>mike@indexdata.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Index Data ApS.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
