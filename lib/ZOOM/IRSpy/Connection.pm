# $Id: Connection.pm,v 1.10 2007-03-09 08:57:12 mike Exp $

package ZOOM::IRSpy::Connection;

use 5.008;
use strict;
use warnings;

use ZOOM;
our @ISA = qw(ZOOM::Connection);

use ZOOM::IRSpy::Record;
use ZOOM::IRSpy::Utils qw(cql_target render_record);

use ZOOM::IRSpy::Task::Connect;
use ZOOM::IRSpy::Task::Search;
use ZOOM::IRSpy::Task::Retrieve;


=head1 NAME

ZOOM::IRSpy::Connection - ZOOM::Connection subclass with IRSpy functionality

=head1 DESCRIPTION

This class provides some additional private data and methods that are
used by IRSpy but which would be useless in any other application.
Keeping the private data in these objects removes the need for ugly
mappings in the IRSpy object itself; adding the methods makes the
application code cleaner.

The constructor takes an two additional leading arguments: a reference
to the IRSpy object that it is associated with, and the target ID of
the connection.

=cut

sub create {
    my $class = shift();
    my $irspy = shift();
    my $target = shift();

    my $this = $class->SUPER::create(@_);
    $this->option(host => $target);
    $this->{irspy} = $irspy;
    $this->{tasks} = [];

    my $query = cql_target($target);
    my $rs = $irspy->{conn}->search(new ZOOM::Query::CQL($query));
    my $n = $rs->size();
    $this->log("irspy", "query '$query' found $n records");
    my $zeerex;
    $zeerex = render_record($rs, 0, "zeerex") if $n > 0;
    $this->{record} = new ZOOM::IRSpy::Record($this, $target, $zeerex);

    return $this;
}


sub destroy {
    my $this = shift();
    $this->SUPER::destroy(@_);
    $this->{rs}->destroy() if defined $this->{rs};
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
	$this->log("irspy_task", "set current task to $new");
    }

    return $old;
}


sub next_task {
    my $this = shift();
    my($new) = @_;

    my $old = $this->{next_task};
    if (defined $new) {
	$this->{next_task} = $new;
	$this->log("irspy_task", "set next task to $new");
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
    my($udata, $options, %cb) = @_;

    $this->add_task(new ZOOM::IRSpy::Task::Connect
		    ($this, $udata, $options, %cb));
}


sub irspy_search_pqf {
    my $this = shift();
    my($query, $udata, $options, %cb) = @_;

    $this->add_task(new ZOOM::IRSpy::Task::Search
		    ($query, $this, $udata, $options, %cb));
}


sub irspy_rs_record {
    my $this = shift();
    my($rs, $index0, $udata, $options, %cb) = @_;

    $this->add_task(new ZOOM::IRSpy::Task::Retrieve
		    ($rs, $index0, $this, $udata, $options, %cb));
}


sub add_task {
    my $this = shift();
    my($task) = @_;

    my $tasks = $this->{tasks};
    $tasks->[-1]->{next} = $task if @$tasks > 0;
    push @$tasks, $task;
    $this->log("irspy_task", "added task $task");
}


sub render {
    my $this = shift();
    return ref($this) . "(" . $this->option("host") . ")";
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
