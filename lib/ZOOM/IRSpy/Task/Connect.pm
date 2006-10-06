# $Id: Connect.pm,v 1.1 2006-10-06 11:33:08 mike Exp $

# See ZOOM/IRSpy/Task/Search.pm for documentation

package ZOOM::IRSpy::Task::Connect;

use 5.008;
use strict;
use warnings;

use ZOOM::IRSpy::Task;
our @ISA = qw(ZOOM::IRSpy::Task);

sub new {
    my $class = shift();

    return $class->SUPER::new(@_);
}

sub run {
    my $this = shift();

    my $conn = $this->conn();
    $this->irspy()->log("irspy_test", $conn->option("host"),
			" connecting");
    # Actually, connections have already been connected.  Redoing this
    # won't hurt -- in fact, it's a no-op.  But because it's a no-op,
    # it doesn't cause any events, which means that the very next call
    # of ZOOM::event() will return 0, and IRSpy will fall through the
    # event loop.  Not good.  Not sure how to fix this.
    $conn->connect($conn->option("host"));
}

sub render {
    my $this = shift();
    return ref($this) . " " . $this->conn()->option("host");
}

use overload '""' => \&render;

1;
