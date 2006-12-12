#!/usr/bin/perl -w

# $Id: xslt_process.pl,v 1.1 2006-12-12 10:45:04 sondberg Exp $

use strict;
use warnings;
use lib '../lib';
use Getopt::Std;
use ZOOM::IRSpy;
use XML::LibXSLT;

XML::LibXSLT->debug_callback(\&xslt_debug);

my $dbname = 'localhost:3313/IR-Explain---1';
my $spy = new ZOOM::IRSpy($dbname, "admin", "fruitbat");
my $source_file = shift || die("$0: Please specify xml instance file");
my $source_doc = $spy->libxml->parse_file($source_file);
my $results = $spy->irspy_to_zeerex_style->transform($source_doc);

print $results->toString(), "\n\n";



sub xslt_debug {
    my ($msg) = @_;

    print STDERR $msg;
}
