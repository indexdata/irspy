#!/usr/bin/perl -w

# $Id: irspy_xsltproc.pl,v 1.3 2007-02-02 12:44:43 sondberg Exp $
# ------------------------------------------------------------------
# This script is only for debugging purposes - it takes a raw IRspy
# xml output document as argument and executes the irspy2zeerex.xsl
# transformation right in front of you:
#
# ./irspy_xsltproc.pl irspy_output_raw.xml
#

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
