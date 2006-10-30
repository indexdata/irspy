# $Id: Utils.pm,v 1.2 2006-10-30 16:13:49 mike Exp $

package ZOOM::IRSpy::Utils;

use 5.008;
use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw(xml_encode irspy_xpath_context);


# Utility functions follow, exported for use of web UI

# I can't -- just can't, can't, can't -- believe that this function
# isn't provided by one of the core XML modules.  But the evidence all
# says that it's not: among other things, XML::Generator and
# Template::Plugin both roll their own.  So I will do likewise.  D'oh!
#
sub xml_encode {
    my ($text) = @_;
    $text =~ s/&/&amp;/g;
    $text =~ s/</&lt;/g;
    $text =~ s/>/&gt;/g;
    $text =~ s/['']/&apos;/g;
    $text =~ s/[""]/&quot;/g;
    return $text;
}


sub irspy_xpath_context {
    my($zoom_record) = @_;

    my $xml = $zoom_record->render();
    my $parser = new XML::LibXML();
    my $doc = $parser->parse_string($xml);
    my $root = $doc->getDocumentElement();
    my $xc = XML::LibXML::XPathContext->new($root);
    $xc->registerNs(e => 'http://explain.z3950.org/dtd/2.0/');
    $xc->registerNs(i => $ZOOM::IRSpy::irspy_ns);
    return $xc;
}


1;
