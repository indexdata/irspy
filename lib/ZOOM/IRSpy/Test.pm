# $Id: Test.pm,v 1.6 2006-10-13 10:08:57 sondberg Exp $

package ZOOM::IRSpy::Test;

use 5.008;
use strict;
use warnings;

use Exporter 'import';
our @EXPORT = qw(isodate);

=head1 NAME

ZOOM::IRSpy::Test - base class for tests in IRSpy

=head1 SYNOPSIS

 ## To follow

=head1 DESCRIPTION

I<## To follow>

=cut

sub subtests { () }

sub start {
    my $class = shift();
    my($conn) = @_;

    die "can't start the base-class test";
}



# Utility function, really nothing to do with IRSpy
sub isodate {
    my($time) = @_;

    my($sec, $min, $hour, $mday, $mon, $year) = localtime($time);
    return sprintf("%04d-%02d-%02dT%02d:%02d:%02d",
		   $year+1900, $mon+1, $mday, $hour, $min, $sec);
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
