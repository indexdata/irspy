# $Id: Record.pm,v 1.2 2006-06-20 12:36:14 mike Exp $

package ZOOM::IRSpy::Record;

use 5.008;
use strict;
use warnings;

=head1 NAME

ZOOM::IRSpy::Record - record describing a target for IRSpy

=head1 SYNOPSIS

 ### To follow

=head1 DESCRIPTION

I<### To follow>

=cut

sub new {
    my $class = shift();
    my($target, $zeerex) = @_;

    ### Should compile the ZeeRex record into something useful.
    return bless {
	target => $target,
	zeerex => $zeerex,
    }, $class;
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
