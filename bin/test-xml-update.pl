#!/usr/bin/perl -w

# $Id: test-xml-update.pl,v 1.5 2006-11-09 15:18:14 mike Exp $
#
# Run like this:
#	perl -I ../lib ./test-xml-update.pl bagel.indexdata.dk:210/gils title "Test Database" author "Adam" description "This is a nice database"

use strict;
use warnings;
use Getopt::Std;
use ZOOM;
use ZOOM::IRSpy::Utils qw(irspy_xpath_context modify_xml_document);
use ZOOM::IRSpy;		# For _really_rewrite_record()

# This array copied from ../web/htdocs/details/edit.mc
my @fields =
    (
     [ protocol     => 0, "Protocol", "e:serverInfo/\@protocol" ],
     [ host         => 0, "Host", "e:serverInfo/e:host" ],
     [ port         => 0, "Port", "e:serverInfo/e:port" ],
     [ dbname       => 0, "Database Name", "e:serverInfo/e:database",
       qw(e:host e:port) ],
     [ username     => 0, "Username (if needed)", "e:serverInfo/e:authentication/e:user",
       qw() ],
     [ password     => 0, "Password (if needed)", "e:serverInfo/e:authentication/e:password",
       qw(e:user) ],
     [ title        => 0, "title", "e:databaseInfo/e:title",
       qw() ],
     [ description  => 5, "Description", "e:databaseInfo/e:description",
       qw(e:title) ],
     [ author       => 0, "Author", "e:databaseInfo/e:author",
       qw(e:title e:description) ],
     [ contact      => 0, "Contact", "e:databaseInfo/e:contact",
       qw(e:title e:description) ],
     [ extent       => 3, "Extent", "e:databaseInfo/e:extent",
       qw(e:title e:description) ],
     [ history      => 5, "History", "e:databaseInfo/e:history",
       qw(e:title e:description) ],
     [ language     => 0, "Language of Records", "e:databaseInfo/e:langUsage",
       qw(e:title e:description) ],
     [ restrictions => 2, "Restrictions", "e:databaseInfo/e:restrictions",
       qw(e:title e:description) ],
     [ subjects     => 2, "Subjects", "e:databaseInfo/e:subjects",
       qw(e:title e:description) ],
     );

my %opts;
if (!getopts('wnd', \%opts) || @ARGV % 2 == 0) {
    print STDERR "Usage: %0 [options] <id> [<key1> <value1> ...]\n";
    print STDERR "	-w	Write modified record back to DB\n";
    print STDERR "	-n	Show new values of fields using XPath\n";
    print STDERR "	-d	Show differences between old and new XML\n";
    exit 1;
}
my($id, %data) = @ARGV;

my $conn = new ZOOM::Connection("localhost:3313/IR-Explain---1", 0,
				user => "admin", password => "fruitbat");
$conn->option(elementSetName => "zeerex");
my $qid = $id;
$qid =~ s/"/\\"/g;
my $query = qq[rec.id="$qid"];
my $rs = $conn->search(new ZOOM::Query::CQL($query));
my $n = $rs->size();
if ($n == 0) {
    print STDERR "$0: no record with ID '$id'";
    exit 2;
}

my $rec = $rs->record(0);
my $xc = irspy_xpath_context($rec);
my %fieldsByKey = map { ( $_->[0], $_) } @fields;

my $oldText = $xc->getContextNode()->toString();
my $nchanges = modify_xml_document($xc, \%fieldsByKey, \%data);
my $newText = $xc->getContextNode()->toString();
print "Document modified with $nchanges change", $nchanges==1?"":"s", "\n";

if ($opts{w}) {
    ZOOM::IRSpy::_really_rewrite_record($conn, $xc->getContextNode());
    print "Rewrote record '$id'\n";
}

if ($opts{n}) {
    # For some reason, $xc->find() will not work on newly added nodes
    # -- it returns empty strings -- so we need to make a new
    # XPathContext.  Unfortunately, we can't just go ahead and make it
    # by parsing the new text, since it will in general include
    # references to namespaces that are not explicitly defined in the
    # document.  So in the absence of $parser->registerNamespace() or
    # similar, we are reduced to regexp-hackery to introduce the
    # namespace.  Ouch ouch ouch ouch ouch.
    my $t2 = $newText;
    $t2 =~ s@>@ xmlns:e='http://explain.z3950.org/dtd/2.0/'>@;
    my $newXc = irspy_xpath_context($t2);

    foreach my $key (sort keys %data) {
	my $ref = $fieldsByKey{$key};
	my($name, $nlines, $caption, $xpath, @addAfter) = @$ref;
	my $val = $xc->findvalue($xpath);
	my $val2 = $newXc->findvalue($xpath);
	print "New $caption ($xpath) = '$val' = '$val2'\n";
    }
}

if ($opts{d}) {
    my $oldFile = "/tmp/old.txu.$$";
    my $newFile = "/tmp/new.txu.$$";
    open OLD, ">$oldFile";
    print OLD $oldText;
    close OLD;
    open NEW, ">/tmp/new.txu.$$";
    print NEW $newText;
    close NEW;
    system("diff $oldFile $newFile");
    unlink($oldFile);
    unlink($newFile);
}
