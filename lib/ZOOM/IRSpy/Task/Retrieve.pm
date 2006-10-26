# $Id: Retrieve.pm,v 1.2 2006-10-25 17:16:14 mike Exp $

package ZOOM::IRSpy::Task::Retrieve;

use 5.008;
use strict;
use warnings;

use ZOOM::IRSpy::Task;
our @ISA = qw(ZOOM::IRSpy::Task);

=head1 NAME

ZOOM::IRSpy::Task::Retrieve - a searching task for IRSpy

=head1 SYNOPSIS

 ## to follow

=head1 DESCRIPTION

 ## to follow

=cut

sub new {
    my $class = shift();
    my($rs) = shift();
    my($index0) = shift();

    my $this = $class->SUPER::new(@_);
    $this->{rs} = $rs;
    $this->{index0} = $index0;
    return $this;
}

sub run {
    my $this = shift();

    $this->set_options();

    my $conn = $this->conn();
    my $rs = $this->{rs};
    my $index0 = $this->{index0};
    $this->irspy()->log("irspy_task", $conn->option("host"),
			" retrieving record $index0 from $rs");
    $rs->records($index0, 1, 0); # requests record

    $this->set_options();
}

sub render {
    my $this = shift();
    my $syntax = $this->{options}->{preferredRecordSyntax};
    $syntax = defined $syntax ? "'$syntax'" : "undef";
    return ref($this) . "(" . $this->{index0} . ", $syntax)";
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