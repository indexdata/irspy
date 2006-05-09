# $Id: Pod.pm,v 1.2 2006-05-09 12:03:37 mike Exp $

package ZOOM::Pod;

use strict;
use warnings;

use ZOOM;

=head1 SYNOPSIS

 $conn1 = new ZOOM::Connection("bagel.indexdata.com/gils");
 $conn2 = new ZOOM::Connection("z3950.loc.gov:7090/Voyager");
 $pod = new ZOOM::Pod($conn1, $conn2);
 $pod->callback(ZOOM::Event::RECV_SEARCH, \&show_result);
 $pod->search_pqf("mineral");
 $pod->wait();

 sub show_result {
     ($conn, $rs, $event) = @_;
     print "$conn: found ", $rs->size(), " records\n";
 }

=cut

sub new {
    my $class = shift();
    my(@conn) = @_;

    foreach my $conn (@conn) {
	if (!ref $conn) {
	    $conn = new ZOOM::Connection($conn, 0, async => 1);
	}
    }

    return bless {
	conn => \@conn,
	rs => [],
	callback => {},
    }, $class;
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
	print("connection ", $i-1, ": ", ZOOM::event_str($ev), "\n");
	my $sub = $this->{callback}->{$ev};
	if (defined $sub) {
	    $res = &$sub($conn, $this->{rs}->[$i-1], $ev);
	    last if $res != 0;
	}
    }

    return $res;
}


1;
