# $Id: Search.pm,v 1.9 2007-03-07 11:41:01 mike Exp $

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

    $this->set_options();

    my $conn = $this->conn();
    ### Note that adding this next line DOES NOT HELP at the moment --
    #   perhaps because of a ZOOM-C bug?
    $conn->connect($conn->option("host"));

    my $query = $this->{query};
    $this->irspy()->log("irspy_task", $conn->option("host"),
			" searching for '$query'");
    $this->{rs} = $conn->search_pqf($query);
    warn "no ZOOM-C level events queued by $this"
	if $conn->is_idle();

    $this->set_options();
}

sub render {
    my $this = shift();
    return ref($this) . "(" . $this->{query} . ")";
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
