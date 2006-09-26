# $Id: Web.pm,v 1.1 2006-09-26 09:31:10 mike Exp $

package ZOOM::IRSpy::Web;

use 5.008;
use strict;
use warnings;

use ZOOM::IRSpy;
our @ISA = qw(ZOOM::IRSpy);

use ZOOM::IRSpy::Record qw(xml_encode);

=head1 NAME

ZOOM::IRSpy::Web - subclass of ZOOM::IRSpy for use by Web UI

=head1 DESCRIPTION

This behaves exactly the same as the base C<ZOOM::IRSpy> class except
that the Clog()> method does not call YAZ log, but outputs
HTML-formatted messages on standard output.

=cut

sub log {
    my $this = shift();
    my($level, @s) = @_;

    # We should only produce output if $level is turned on
    my $message = "[$level] " . join("", @s);
    $| = 1;			# 
    print xml_encode($message), "<br/>\n";
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
