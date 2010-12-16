#!/usr/bin/perl

# Execute a specific XPath against provided XML, having established
# prefixes for the namespaces used in IRSpy.

use ZOOM::IRSpy::Utils qw(irspy_xpath_context);

use strict;
use warnings;

my $xpath = shift();
my $xml = join("", <>);
my $xc = irspy_xpath_context($xml)
    or die "$0: can't make XPath context";
my @nodes = $xc->findnodes($xpath);
print scalar(@nodes), " hits\n";
print join("", map { $_->to_literal() . "\n" } @nodes);
