# $Id: Node.pm,v 1.1 2006-10-06 11:33:07 mike Exp $

package ZOOM::IRSpy::Node;

use 5.008;
use strict;
use warnings;


sub new {
    my $class = shift();
    my($name, @subtests) = @_;
    return bless {
	name => $name,
	subtests => \@subtests,
    }, $class;
}

sub name {
    my $this = shift();
    return $this->{name};
}

sub subtests {
    my $this = shift();
    return @{ $this->{subtests} };
}

sub print {
    my $this = shift();
    my($level) = @_;

    print "\t" x $level, $this->name();
    if (my @sub = $this->subtests()) {
	print " = {\n";
	foreach my $sub (@sub) {
	    $sub->print($level+1);
	}
	print "\t" x $level, "}";
    }
    print "\n";
}

# Addresses are of the form:
#	(empty) - the root
#	2 - subtree #2 (i.e. the third subtree) of the root
#	2:1 - subtree #1 of subtree #2, etc
sub select {
    my $this = shift();
    my($address) = @_;

    my @sub = $this->subtests();
    if ($address eq "") {
	return $this;
    } elsif (my($head, $tail) = $address =~ /(.*):(.*)/) {
	return $sub[$head]->select($tail);
    } else {
	return $sub[$address];
    }
}


1;
