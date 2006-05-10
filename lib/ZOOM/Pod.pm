# $Id: Pod.pm,v 1.5 2006-05-10 16:01:04 mike Exp $

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

I<###>

=head1 METHODS

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

sub option {
    my $this = shift();
    my($key, $value) = @_;

    foreach my $conn (@{ $this->{conn} }) {
	$conn->option($key, $value);
    }
}

sub callback {
    my $this = shift();
    my($event, $sub) = @_;

    my $old = $this->{callback}->{$event};
    $this->{callback}->{$event} = $sub
	if defined $sub;

    return $old;
}

sub search_pqf {
    my $this = shift();
    my($pqf) = @_;

    foreach my $i (0..@{ $this->{conn} }-1) {
	$this->{rs}->[$i] = $this->{conn}->[$i]->search_pqf($pqf);
    }
}

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
