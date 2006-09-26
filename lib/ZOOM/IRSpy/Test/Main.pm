# $Id: Main.pm,v 1.5 2006-09-26 13:34:38 sondberg Exp $

package ZOOM::IRSpy::Test::Main;

use 5.008;
use strict;
use warnings;

use ZOOM::IRSpy::Test;
our @ISA;
@ISA = qw(ZOOM::IRSpy::Test);


=head1 NAME

ZOOM::IRSpy::Test::Main - a single test for IRSpy

=head1 SYNOPSIS

 ## To follow

=head1 DESCRIPTION

I<## To follow>

=cut

sub run {
    my $this = shift();

    return $this->run_tests(qw(Ping Search::Bib1));
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
