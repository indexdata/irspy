# $Id: Search.pm,v 1.2 2006-10-11 16:48:19 mike Exp $

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

    # I want to catch the situation where a search is attempted on a
    # not-yet opened connection (e.g. the Search::Title test is run
    # before Ping) but since this situation doesn't involve the
    # generation of a ZOOM event, the main loop won't see an error.
    # So I check for it immediately:
    $conn->_check();
    # ### Unfortunately, this also fails to detect the condition I'm
    # concerned with, so I think I am out of luck.
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
