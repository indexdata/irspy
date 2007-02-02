#!/usr/bin/perl -w

# $Id: irspy_xsltproc.pl,v 1.2 2007-02-02 12:40:51 sondberg Exp $

use strict;
use warnings;
use lib '../lib';
use ZOOM::IRSpy;

if (@ARGV && $ARGV[0] eq "-d") {
    shift;
    XML::LibXSLT->debug_callback(\&xslt_debug);
}

my $dbname = 'localhost:8018/IR-Explain---1';
my $spy = new ZOOM::IRSpy($dbname, "admin", "fruitbat");
my $source_file = shift || die("$0: Please specify xml instance file");
my $source_doc = $spy->{libxml}->parse_file($source_file);
my $results = $spy->{irspy_to_zeerex_style}->transform($source_doc);

print $results->toString();
