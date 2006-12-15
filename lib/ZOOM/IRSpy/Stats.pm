# $Id: Stats.pm,v 1.3 2006-12-15 10:40:48 mike Exp $

package ZOOM::IRSpy::Stats;

use 5.008;
use strict;
use warnings;
use ZOOM::IRSpy::Utils qw(irspy_xpath_context);

=head1 NAME

ZOOM::IRSpy::Stats - statistics generated for IRSpy about its targets

=head1 SYNOPSIS

 $stats = new ZOOM::IRSpy::Stats($dbname);
 $stats->print();

=head1 DESCRIPTION

Provides a simple API to obtaining statistics about targets registered
in IRSpy.  This is done just by creating a Stats object.  Once this
object is made, it can be crudely printed using the built-in debugging
C<print()> method, or the application can walk the structure to
produce nice output.

=head1 METHODS

=head2 new()

 $stats = new ZOOM::IRSpy::Stats($dbname, "dc.creator=wedel");
 # Or:
 $stats = new ZOOM::IRSpy::Stats($dbname,
         new ZOOM::Query::PQF('@attr 1=1003 wedel');
 # Or:
 $spy = new ZOOM::Connection("target/string/for/irspy/database"); 
 $stats = new ZOOM::IRSpy::Stats($spy, $query);

Creates a new C<ZOOM::IRSpy::Stats> object and populates it with
statistics for the targets in the nominated database.  This process
involves analysing the nominated IRSpy database at some length, and
which therefore takes some time

Either one or two arguments are required:

=over 4

=item $conn (mandatory)

An indication of the IRSpy database that statistics are required for.
This may be in the form of a C<ZOOM::Connection> object or a
database-name string such as C<localhost:3313/IR-Explain---1>.

=item $query (optional)

The query with which to select a subset of the database to be
analysed.  This may be in the form of a C<ZOOM::Query> object (using
any of the supported subclasses) or a CQL string.  If this is omitted,
then all records in the database are included in the generated
statistics.

=back

=cut

sub new {
    my $class = shift();
    my($conn, $query) = @_;

    $query ||= "cql.allRecords=1",
    $conn = new ZOOM::Connection($conn) if !ref $conn;
    $query = new ZOOM::Query::CQL($query) if !ref $query;

    my $oldSyntax = $conn->option("preferredRecordSyntax");
    my $oldESN = $conn->option("elementSetName");
    my $oldPC = $conn->option("presentChunk");
    $conn->option(preferredRecordSyntax => "xml");
    $conn->option(elementSetName => "zeerex");
#    $conn->option(presentChunk => 10);

    my $rs = $conn->search($query);
    my $n = $rs->size();

    my $this = bless {
	conn => $conn,
	query => $query,
	rs => $rs,
	n => $n,
    }, $class;

    $this->_gather_stats();
    $conn->option(preferredRecordSyntax => $oldSyntax);
    $conn->option(elementSetName => $oldESN);
    $conn->option(presentChunk => $oldPC);

    return $this;
}


sub _gather_stats {
    my $this = shift();

    foreach my $i (0 .. $this->{n}-1) {
	my $rec = $this->{rs}->record($i);
	my $xc = irspy_xpath_context($rec);

	foreach my $node ($xc->findnodes('e:indexInfo/e:index[@search="true"]/e:map/e:attr[@type=1 and @set="bib-1"]')) {
	    $this->{bib1AccessPoints}->{$node->findvalue(".")}++;
	}
    }
}


=head2 print()

 $stats->print();

Prints an ugly but human-readable summary of the statistics on
standard output.

=cut

sub print {
    my $this = shift();

    print "database = '", $this->{conn}->option("host"), "'\n";
    print "query = '", $this->{query}, "'\n";
    print "result set = '", $this->{rs}, "'\n";
    print "count = '", $this->{n}, "'\n";
    print "\n";
    print "BIB-1 ATTRIBUTES\n";
    my $ap = $this->{bib1AccessPoints};
    foreach my $attr (sort { $ap->{$b} <=> $ap->{$a} 
			 || $a <=> $b } keys %$ap) {
	print sprintf("%6d%20s%d (%d%%)\n",
		      $attr, "", $ap->{$attr}, 100*$ap->{$attr}/$this->{n});
    }
}


=head1 SEE ALSO

ZOOM::IRSpy

=head1 AUTHOR

Mike Taylor, E<lt>mike@indexdata.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Index Data ApS.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
