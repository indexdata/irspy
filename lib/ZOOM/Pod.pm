# $Id: Pod.pm,v 1.7 2006-05-11 15:51:36 mike Exp $

package ZOOM::Pod;

use strict;
use warnings;

use ZOOM;

BEGIN {
    # Just register the name
    ZOOM::Log::mask_str("pod");
    ZOOM::Log::mask_str("pod_unhandled");
}

=head1 NAME

ZOOM::Pod - Perl extension for handling pods of concurrent ZOOM connections

=head1 SYNOPSIS

 use ZOOM::Pod;

 $pod = new ZOOM::Pod("bagel.indexdata.com/gils",
                      "bagel.indexdata.com/marc");
 $pod->callback(ZOOM::Event::RECV_SEARCH, \&completed_search);
 $pod->callback(ZOOM::Event::RECV_RECORD, \&got_record);
 $pod->search_pqf("the");
 $err = $pod->wait();
 die "$pod->wait() failed with error $err" if $err;

 sub completed_search {
     ($conn, undef, $rs) = @_;
     print $conn->option("host"), ": found ", $rs->size(), " records\n";
     $rs->records(0, 1, 0); # Queues a request for the record
     return 0;
 }

 sub got_record {
     ($conn, undef, $rs) = @_;
     $rec = $rs->record(0);
     print $conn->option("host"), ": got $rec = '", $rec->render(), "'\n";
     return 0;
 }

=head1 DESCRIPTION

C<ZOOM:Pod> provides an API that simplifies asynchronous programming
using ZOOM.  A pod is a collection of asynchronous connections that
are run simultaneously to achieve broadcast searching and retrieval.
When a pod is created, a set of connections (or target-strings to
connect to) are specified.  Thereafter, they are treated as a unit,
and methods for searching, option-setting, etc. that are invoked on
the pod are delegated to each of its members.

The key method on a pod is C<wait()>, which enters a loop accepting
and dispatching events occurring on any of the connections in the pod.
Unless interrupted,the loop runs until there are no more events left,
i.e. no searches are outstanding and no requested records have still
to be received.

Event dispatching is done by means of callback functions, which can be
registered for each event.  A registered callback is invoked whenever
a corresponding event occurs.  A special callback can be nominated to
handle errors.

=head1 METHODS

=head2 new()

 $pod = new ZOOM::Pod($conn1, $conn2, $conn3);
 $pod = new ZOOM::Pod("bagel.indexdata.com/gils",
                      "bagel.indexdata.com/marc");


Creates a new pod containing one or more connections.  Each connection
may be specified either by an existing C<ZOOM::Connection> object,
which I<must> be asynchronous; or by a ZOOM target string, in which
case the pod module will make the connection object itself.

Returns the new pod.

=cut

sub new {
    my $class = shift();
    my(@conn) = @_;

    die "$class with no connections" if @conn == 0;
    my @state; # Hashrefs with application state associated with connections
    foreach my $conn (@conn) {
	if (!ref $conn) {
	    $conn = new ZOOM::Connection($conn, 0, async => 1);
	    # The $conn object is always made, even if no there's no
	    # server.  Such errors are caught later, by the _check()
	    # call in wait(). 
	}
	push @state, {};
    }

    return bless {
	conn => \@conn,
	state => \@state,
	rs => [],
	callback => {},
    }, $class;
}

=head2 option()

 $oldElemSet = $pod->option("elementSetName");
 $pod->option(elementSetName => "b");

Sets a specified option in all the connections in a pod.  Returns the
old value that the option had in first of the connections in the pod:
be aware that this value was not necessarily shared by all the members
of the pod ... but that is true often enough to be useful.

=cut

sub option {
    my $this = shift();
    my($key, $value) = @_;

    my $old = $this->{conn}->[0]->option($key);
    foreach my $conn (@{ $this->{conn} }) {
	$conn->option($key, $value);
    }

    return $old;
}

=head2 callback()

 $pod->callback(ZOOM::Event::RECV_SEARCH, \&completed_search);
 $pod->callback("exception", sub { print "never mind: $@\n"; return 0 } );

Registers a callback to be invoked by the pod when an event happens.
Callback functions are invoked by C<wait()> (q.v.).

When registering a callback, the first argument is an event-code - one
of those defined in the C<ZOOM::Event> enumeration - and the second is
a function reference, or equivalently an inline code-fragment.  It is
acceptable to nominate the same function as the callback for multiple
events, by multiple invocations of C<callback()>.

When an event occurs during the execution of C<wait()>, the relevant
callback function is passed four arguments: the connection that the
event happened on; a state hash-reference associated with the
connection; the result-set associated with the connection; and the
event-type (so that a single function that handles events of multiple
types can switch on the code where necessary).  The callback function
can handle the event as it wishes, finishing up by returning an
integer.  If this is zero, then C<wait()> continues as normal; if it
is anything else, then that value is immediately returned from
C<wait()>.

So a typical, simple, event-handler might look like this:

 sub got_event {
      ($conn, $state, $rs, $event) = @_;
      print "event $event on connection ", $conn->option("host"), "\n";
      print "Found ", $rs->size(), " records\n"
	  if $event == ZOOM::Event::RECV_SEARCH;
      return 0;
 }

In addition to the event-type callbacks discussed above, there is a
special callback, C<"exception">, which is invoked if an exception
occurs.  This will nearly always be a ZOOM error, but this can be
tested using C<ref($@) eq "ZOOM::Exception">.  This callback is
invoked with the same arguments as described above, except that
instead of the event-type, the fourth argument is a copy of the
exception, C<$@>.  Exception-handling callbacks may of course re-throw
the exception using C<die $@>.

So a simple error-handler might look like this:

 sub got_error {
      ($conn, $state, $rs, $exception) = @_;
      if ($exception->isa("ZOOM::Exception")) {
          print "Caught error $exception -- continuing";
          return 0;
      }
      die $exception;
 }

I<### state>

=cut

sub callback {
    my $this = shift();
    my($event, $sub) = @_;

    my $old = $this->{callback}->{$event};
    $this->{callback}->{$event} = $sub
	if defined $sub;

    return $old;
}

=head2 search_pqf()

I<###>

B<WARNING!>
An important simplifying assumption is that each connection can only
have one search active on it at a time - this allows the pod to
maintain a one-to-one mapping between connections and result-sets.  

=cut

sub search_pqf {
    my $this = shift();
    my($pqf) = @_;

    foreach my $i (0..@{ $this->{conn} }-1) {
	$this->{rs}->[$i] = $this->{conn}->[$i]->search_pqf($pqf);
    }
}

=head2 wait()

I<###>

=cut

sub wait {
    my $this = shift();
    my $res = 0;

    while ((my $i = ZOOM::event($this->{conn})) != 0) {
	my $conn = $this->{conn}->[$i-1];
	my $ev = $conn->last_event();
	my $evstr = ZOOM::event_str($ev);
	ZOOM::Log::log("pod", "connection ", $i-1, ": $evstr");

	eval {
	    $conn->_check();
	}; if ($@) {
	    my $sub = $this->{callback}->{exception};
	    die $@ if !defined $sub;
	    $res = &$sub($conn, $this->{state}->[$i-1],
			 $this->{rs}->[$i-1], $@);
	    last if $res != 0;
	    next;
	}

	my $sub = $this->{callback}->{$ev};
	if (defined $sub) {
	    $res = &$sub($conn, $this->{state}->[$i-1],
			 $this->{rs}->[$i-1], $ev);
	    last if $res != 0;
	} else {
	    ZOOM::Log::log("pod_unhandled", "unhandled event $ev ($evstr)");
	}
    }

    return $res;
}


=head1 SEE ALSO

The underlying
C<ZOOM>
module (part of the
C<Net::Z3950::ZOOM>
distribution).

=head1 AUTHOR

Mike Taylor, E<lt>mike@indexdata.comE<gt>

=head1 COPYRIGHT AND LICENCE

Copyright (C) 2006 by Index Data.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut


1;
