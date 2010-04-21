
package ZOOM::IRSpy::Test;

use 5.008;
use strict;
use warnings;

use Scalar::Util;

=head1 NAME

ZOOM::IRSpy::Test - base class for tests in IRSpy

=head1 SYNOPSIS

 ## To follow

=head1 DESCRIPTION

I<## To follow>

=cut

sub subtests { () }

sub timeout { undef }

sub start {
    my $class = shift();
    my($conn) = @_;

    die "can't start the base-class test";
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
