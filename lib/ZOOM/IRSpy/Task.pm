# $Id: Task.pm,v 1.4 2006-10-25 13:34:56 mike Exp $

package ZOOM::IRSpy::Task;

use 5.008;
use strict;
use warnings;

=head1 NAME

ZOOM::IRSpy::Task - base class for tasks in IRSpy

=head1 SYNOPSIS

 use ZOOM::IRSpy::Task;
 package ZOOM::IRSpy::Task::SomeTask;
 our @ISA = qw(ZOOM::IRSpy::Task);
 # ... override methods

=head1 DESCRIPTION

This class provides a base-class from which individual IRSpy task
classes can be derived.  For example, C<ZOOM::IRSpy::Task::Search>
will represent a searching task, carrying with it a query, a pointer
to a result-set, etc.

The base class provides nothing more exciting than a link to a
callback function to be called when the task is complete, and a
pointer to the next task to be performed after this.

=cut

sub new {
    my $class = shift();
    my($conn, $udata, $options, %cb) = @_;

    return bless {
	irspy => $conn->{irspy},
	conn => $conn,
	udata => $udata,
	options => $options,
	cb => \%cb,
	timeRegistered => time(),
    }, $class;
}


sub irspy {
    my $this = shift();
    return $this->{irspy};
}

sub conn {
    my $this = shift();
    return $this->{conn};
}

sub udata {
    my $this = shift();
    return $this->{udata};
}

sub run {
    my $this = shift();
    die "can't run base-class task $this";
}

sub set_options {
    my $this = shift();

    foreach my $key (sort keys %{ $this->{options} }) {
	my $value = $this->{options}->{$key};
	$value = "" if !defined $value;
	$this->conn()->log("irspy_debug", "$this setting option '$key' -> ",
			   defined $value ? "'$value'" : "undefined");
	$this->{options}->{$key} = $this->conn()->option($key, $value);
	#Net::Z3950::ZOOM::connection_option_set($this->conn()->_conn(), $key, $value);
    }
}

sub render {
    my $this = shift();
    return "[base-class] " . ref($this);
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
