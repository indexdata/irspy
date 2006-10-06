# $Id: Search.pm,v 1.1 2006-10-06 11:33:08 mike Exp $

package ZOOM::IRSpy::Task::Search;

use 5.008;
use strict;
use warnings;

use ZOOM::IRSpy::Task;
our @ISA = qw(ZOOM::IRSpy::Task);

=head1 NAME

ZOOM::IRSpy::Task::Search - a searching task for IRSpy

=head1 SYNOPSIS

 ## to follow

=head1 DESCRIPTION

 ## to follow

=cut

sub new {
    my $class = shift();
    my($query) = shift();

    my $this = $class->SUPER::new(@_);
    $this->{query} = $query;
    $this->{rs} = undef;
    return $this;
}

sub run {
    my $this = shift();

    my $conn = $this->conn();
    my $query = $this->{query};
    $this->irspy()->log("irspy_test", $conn->option("host"),
			" searching for '$query'");
    $this->{rs} = $conn->search_pqf($query);
    # Wow -- that's it.
}

sub render {
    my $this = shift();
    return ref($this) . " " . $this->{query};
}

use overload '""' => \&render;


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
