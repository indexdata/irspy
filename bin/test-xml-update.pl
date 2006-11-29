#!/usr/bin/perl -w

# $Id: test-xml-update.pl,v 1.7 2006-11-29 17:22:32 mike Exp $
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
     [ title        => 0, "Title", "e:databaseInfo/e:title",
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
if (!getopts('wnxd', \%opts) || @ARGV % 2 == 0) {
    print STDERR "Usage: %0 [options] <id> [<key1> <value1> ...]\n";
    print STDERR "	-w	Write modified record back to DB\n";
    print STDERR "	-n	Show new values of fields using XPath\n";
    print STDERR "	-x	Show new XML document with changes made\n";
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
my @changedFields = modify_xml_document($xc, \%fieldsByKey, \%data);
my $nchanges = @changedFields;
my $newText = $xc->getContextNode()->toString();
print("Document modified with $nchanges change", $nchanges == 1 ? "" : "s",
      ": ", join(", ", map { $_->[2] } @changedFields), "\n");

if ($opts{w}) {
    ZOOM::IRSpy::_really_rewrite_record($conn, $xc->getContextNode());
    print "Rewrote record '$id'\n";
}

if ($opts{n}) {
    foreach my $key (sort keys %data) {
	my $ref = $fieldsByKey{$key};
	my($name, $nlines, $caption, $xpath, @addAfter) = @$ref;
	print "New $caption ($xpath) = '", $xc->findvalue($xpath), "'\n";
    }
}

if ($opts{x}) {
    print $newText;
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
