# $Id: Connect.pm,v 1.2 2006-10-11 16:47:44 mike Exp $

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
    $conn->log("irspy_test", "connecting");
    $conn->connect($conn->option("host"));
}

sub render {
    my $this = shift();
    return ref($this) . " " . $this->conn()->option("host");
}

use overload '""' => \&render;

1;
