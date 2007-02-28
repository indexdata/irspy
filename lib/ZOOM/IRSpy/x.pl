#!/usr/bin/perl -w

# $Id: x.pl,v 1.1 2007-02-28 16:52:34 mike Exp $

### This should be massaged into a test-suite script in ../../../t

use strict;
use warnings;
use lib '../..';
use ZOOM::IRSpy::Node;

#my $phylogeny = <<__EOT__;
#Dinosauria
# Saurischia
#  Theropoda
#  Sauropoda
# Ornithischia
#  Thyreophora
#   Stegosauria
#   Ankylosauria
#  Cerapoda
#   Marginocephalia
#    Ceratopsia
#    Pachycephalosauria
#   Ornithopoda
#    Hadrosauria
#__EOT__
#
#my @stack;
#foreach my $line (reverse split /\n/, $phylogeny) {
#    $line =~ s/( *)//;
#    my $level = length($1);
#    print "level $level: $line\n";
#}

    my $n1 = new ZOOM::IRSpy::Node("Hadrosauria");
   my $n2 = new ZOOM::IRSpy::Node("Ornithopoda", $n1);
    my $n3 = new ZOOM::IRSpy::Node("Pachycephalosauria");
    my $n4 = new ZOOM::IRSpy::Node("Ceratopsia");
   my $n5 = new ZOOM::IRSpy::Node("Marginocephalia", $n3, $n4);
  my $n6 = new ZOOM::IRSpy::Node("Cerapoda", $n2, $n5);
   my $n7 = new ZOOM::IRSpy::Node("Ankylosauria");
   my $n8 = new ZOOM::IRSpy::Node("Stegosauria");
  my $n9 = new ZOOM::IRSpy::Node("Thyreophora", $n7, $n8);
 my $n10 = new ZOOM::IRSpy::Node("Ornithischia", $n6, $n9);
  my $n11 = new ZOOM::IRSpy::Node("Sauropoda");
  my $n12 = new ZOOM::IRSpy::Node("Theropoda");
 my $n13 = new ZOOM::IRSpy::Node("Saurischia", $n11, $n12);
my $root = new ZOOM::IRSpy::Node("Dinosauria", $n10, $n13);

$root->resolve();
assert(!defined $root->parent());

my $count = 0;
for (my $node = $root; defined $node; $node = $node->{next}) {
    print "'", $node->address(), "' = ", $node->name(), "\n";
    assert($node eq $root->select($node->address()));
    assert($node eq $node->next()->previous())
	if defined $node->next();
    assert($node eq $node->previous()->next())
	if defined $node->previous();
    $count++;
}
assert($count == 14);

sub assert {
    my($ok) = @_;
    die "assert failed" if !$ok;
}
