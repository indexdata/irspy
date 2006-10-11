# $Id: Connection.pm,v 1.2 2006-10-11 16:46:01 mike Exp $

package ZOOM::IRSpy::Connection;

use 5.008;
use strict;
use warnings;

use ZOOM;
our @ISA = qw(ZOOM::Connection);

use ZOOM::IRSpy::Task::Connect;
use ZOOM::IRSpy::Task::Search;


=head1 NAME

ZOOM::IRSpy::Connection - ZOOM::Connection subclass with IRSpy functionality

=head1 DESCRIPTION

This class provides some additional private data and methods that are
used by IRSpy but which would be useless in any other application.
Keeping the private data in these objects removes the need for ugly
mappings in the IRSpy object itself; adding the methods makes the
application code cleaner.

The constructor takes an additional first argument, a reference to the
IRSpy object that it is associated with.

=cut

sub create {
    my $class = shift();
    my $irspy = shift();

    my $this = $class->SUPER::create(@_);
    $this->{irspy} = $irspy;
    $this->{record} = undef;
    $this->{tasks} = [];

    return $this;
}


sub irspy {
    my $this = shift();
    return $this->{irspy};
}


sub record {
    my $this = shift();
    my($new) = @_;

    my $old = $this->{record};
    $this->{record} = $new if defined $new;
    return $old;
}


sub tasks {
    my $this = shift();

    return $this->{tasks};
}


sub current_task {
    my $this = shift();
    my($new) = @_;

    my $old = $this->{current_task};
    if (defined $new) {
	$this->{current_task} = $new;
	$this->log("irspy_debug", "set current task to $new");
    }

    return $old;
}


sub next_task {
    my $this = shift();
    my($new) = @_;

    my $old = $this->{next_task};
    if (defined $new) {
	$this->{next_task} = $new;
	$this->log("irspy_debug", "set next task to $new");
    }

    return $old;
}


sub log {
    my $this = shift();
    my($level, @msg) = @_;

    $this->irspy()->log($level, $this->option("host"), " ", @msg);
}


sub irspy_connect {
    my $this = shift();
    my(%cb) = @_;

    $this->add_task(new ZOOM::IRSpy::Task::Connect($this, %cb));
    $this->log("irspy", "registered connect()");
}


sub irspy_search_pqf {
    my $this = shift();
    my($query, %cb) = @_;

    $this->add_task(new ZOOM::IRSpy::Task::Search($query, $this, %cb));
    $this->log("irspy", "registered search_pqf($query)");
}


sub add_task {
    my $this = shift();
    my($task) = @_;

    my $tasks = $this->{tasks};
    $tasks->[-1]->{next} = $task if @$tasks > 0;
    push @$tasks, $task;
    $this->log("irspy", "added task $task");
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
