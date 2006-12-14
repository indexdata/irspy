# $Id: Stats.pm,v 1.1 2006-12-14 17:34:57 mike Exp $

package ZOOM::IRSpy::Stats;

use 5.008;
use strict;
use warnings;

=head1 NAME

ZOOM::IRSpy::Stats - statistics generated for IRSpy about its targets

=head1 SYNOPSIS

 $stats = new ZOOM::IRSpy::Stats($dbname);
 use Data::Dumper; print Dumper($stats);

=head1 DESCRIPTION

Provides a simple API to obtaining statistics about targets registered
in IRSpy.  This is done just by creating a Stats object.  Once this
object is made, it can be crudely dumped, or the application can walk
the structure to produce nice output.

=head1 METHODS

=head2 new()

 $stats = new ZOOM::IRSpy::Stats($dbname, "dc.creator=wedel");
 # Or:
 $stats = new ZOOM::IRSpy::Stats($dbname,
         new ZOOM::Query::PQF('@attr 1=1003 wedel');
 # Or:
 $spy = new ZOOM::IRSpy("target/string/for/irspy/database"); 
 $stats = new ZOOM::IRSpy::Stats($spy, $query);

Creates a new C<ZOOM::IRSpy::Stats> object and populates it with
statistics for the targets in the nominated database.  This process
involves analysing the nominated IRSpy database at some length, and
which therefore takes some time

Either one or two arguments are required:

=over 4

=item $irspy (mandatory)

An indication of the IRSpy database that statistics are required for.
This may be in the form of a C<ZOOM::IRSpy> object or a database-name
string such as C<localhost:3313/IR-Explain---1>.

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
    my($irspy, $query) = @_;

    return bless {
	irspy => $irspy,
	query => $query || "cql.allRecords=1",
    }, $class;
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
