# $Id: Test.pm,v 1.1 2006-06-20 16:32:42 mike Exp $

package ZOOM::IRSpy::Test;

use 5.008;
use strict;
use warnings;

=head1 NAME

ZOOM::IRSpy::Test - base class for tests in IRSpy

=head1 SYNOPSIS

 ### To follow

=head1 DESCRIPTION

I<### To follow>

=cut

sub new {
    my $class = shift();
    my($irspy) = @_;

    return bless {
	irspy => $irspy,
    }, $class;
}


sub irspy {
    my $this = shift();
    return $this->{irspy};
}


sub run {
    my $this = shift();
    die "can't run the base-class test";
}

### Could include loop detection
sub run_tests {
    my $this = shift();
    my @tname = @_;

    my $res = 0;
    foreach my $tname (@tname) {
	my $sub = $this->irspy()->_run_test($tname);
	$res = $sub if $sub > $res;
    }

    return $res;
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
