#!/usr/bin/perl -w

# $Id: irspy_xsltproc.pl,v 1.1 2007-02-02 12:38:48 sondberg Exp $

use strict;
use warnings;
use lib '../lib';
use ZOOM::IRSpy;

my $dbname = 'localhost:8018/IR-Explain---1';
my $spy = new ZOOM::IRSpy($dbname, "admin", "fruitbat");
my $source_file = shift || die("$0: Please specify xml instance file");
my $source_doc = $spy->{libxml}->parse_file($source_file);
my $results = $spy->{irspy_to_zeerex_style}->transform($source_doc);

print $results->toString();
