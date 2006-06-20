# $Id: IRSpy.pm,v 1.1 2006-06-20 12:27:12 mike Exp $

package Net::Z3950::IRSpy;

use 5.008;
use strict;
use warnings;
use Net::Z3950::IRSpy::Record;
use ZOOM::Pod;

our @ISA = qw();
our $VERSION = '0.02';

=head1 NAME

Net::Z3950::IRSpy - Perl extension for discovering and analysing IR services

=head1 SYNOPSIS

 use Net::Z3950::IRSpy;
 $spy = new Net::Z3950::IRSpy("target/string/for/irspy/database");
 print $spy->report_status();

=head1 DESCRIPTION

This module exists to implement the IRspy program, which discovers,
analyses and monitors IR servers implementing the Z39.50 and SRU/W
protocols.  It is a successor to the ZSpy program.

=cut

BEGIN { ZOOM::Log::mask_str("irspy") }

sub new {
    my $class = shift();
    my($dbname) = @_;

    my $conn = new ZOOM::Connection($dbname)
	or die "$0: can't connection to IRSpy database 'dbname'";

    my $this = bless {
	conn => $conn,
	allrecords => 1,	# unless overridden by targets()
	# query and targets will be filled in later
    }, $class;
    $this->log("irspy", "starting up with database '$dbname'");

    return $this;
}


sub log {
    my $this = shift();
    ZOOM::Log::log(@_);
}


# Explicitly nominate a set of targets to check, overriding the
# default which is to re-check everything in the database.  Each
# target already in the database results in the existing record being
# updated; each new target causes a new record to be added.
#
sub targets {
    my $this = shift();
    my($targetList) = @_;

    $this->log("irspy", "setting explicit list of targets '$targetList'");
    $this->{allrecords} = 0;
    my @targets = split /\s+/, $targetList;
    my @qlist;
    foreach my $target (@targets) {
	my($host, $port, $db) = ($target =~ /(.*?):(.*?)\/(.*)/);
	if (!defined $host) {
	    $port = 210;
	    ($host, $db) = ($target =~ /(.*?)\/(.*)/);
	    $this->log("irspy", "rewrote '$target' to '$host:$port/$db'");
	    $target = "$host:$port/$db";
	}
	die "invalid target string '$target'"
	    if !defined $host;
	push @qlist,
	    (qq[(host = "$host" and port = "$port" and path="$db")]);
    }

    $this->{targets} = \@targets;
    $this->{query} = join(" or ", @qlist);
}


# There are two cases.
#
# 1. A specific set of targets is nominated on the command line.
#	- Records must be fetched for those targets that are in the DB
#	- New, empty records must be made for those that are not.
#	- Updated records written to the DB may or may not be new.
#
# 2. All records in the database are to be checked.
#	- Records must be fetched for all targets in the DB
#	- Updated records written to the DB may not be new.
#
# That's all -- what could be simpler?
#
sub initialise {
    my $this = shift();

    my %target2record;
    if ($this->{allrecords}) {
	# We need to check on every target in the database, which
	# means we need to do a "find all".  According to the BIB-1
	# semantics document at
	#	http://www.loc.gov/z3950/agency/bib1.html
	# the query
	#	@attr 2=103 @attr 1=1035 x
	# should find all records, but it seems that Zebra doesn't
	# support this.  Furthermore, when using the "alvis" filter
	# (as we do for IRSpy) it doesn't support the use of any BIB-1
	# access point -- not even 1035 "everywhere" -- so instead we
	# hack together a search that we know will find all records.
	$this->{query} = "port=?*";
    } else {
	# Prepopulate the target map with nulls so that after we fill
	# in what we can from the database query, we know which target
	# IDs we need new records for.
	foreach my $target (@{ $this->{targets} }) {
	    $target2record{lc($target)} = undef;
	}
    }

    my $rs = $this->{conn}->search(new ZOOM::Query::CQL($this->{query}));
    foreach my $i (1 .. $rs->size()) {
	my $target = _render_record($rs, $i-1, "id");
	my $zeerex = _render_record($rs, $i-1, "zeerex");
	$target2record{lc($target)} =
	    new Net::Z3950::IRSpy::Record($target, $zeerex);
    }

    foreach my $target (keys %target2record) {
	my $record = $target2record{$target};
	if (!defined $record) {
	    $this->log("irspy", "new record for '$target'");
	    $target2record{$target} = new Net::Z3950::IRSpy::Record($target);
	} else {
	    $this->log("irspy", "existing record for '$target' $record");
	}
    }
}


sub check {
    my $this = shift();

    $this->{pod} = new ZOOM::Pod(@{ $this->{targets} })
}


sub _render_record {
    my($rs, $which, $elementSetName) = @_;

    # There is a slight race condition here on the element-set name,
    # but it shouldn't be a problem as this is (currently) only called
    # from parts of the program that run single-threaded.
    my $old = $rs->option(elementSetName => $elementSetName);
    my $rec = $rs->record($which);
    $rs->option(elementSetName => $old);

    return $rec->render();
}


#my $pod = new ZOOM::Pod(@ARGV);
#$pod->option(elementSetName => "b");
#$pod->callback(ZOOM::Event::RECV_SEARCH, \&completed_search);
#$pod->callback(ZOOM::Event::RECV_RECORD, \&got_record);
##$pod->callback(exception => \&exception_thrown);
#$pod->search_pqf("the");
#my $err = $pod->wait();
#die "$pod->wait() failed with error $err" if $err;
#
#sub completed_search {
#    my($conn, $state, $rs, $event) = @_;
#    print $conn->option("host"), ": found ", $rs->size(), " records\n";
#    $state->{next_to_fetch} = 0;
#    $state->{next_to_show} = 0;
#    request_records($conn, $rs, $state, 2);
#    return 0;
#}
#
#sub got_record {
#    my($conn, $state, $rs, $event) = @_;
#
#    {
#	# Sanity-checking assertions.  These should be impossible
#	my $ns = $state->{next_to_show};
#	my $nf = $state->{next_to_fetch};
#	if ($ns > $nf) {
#	    die "next_to_show > next_to_fetch ($ns > $nf)";
#	} elsif ($ns == $nf) {
#	    die "next_to_show == next_to_fetch ($ns)";
#	}
#    }
#
#    my $i = $state->{next_to_show}++;
#    my $rec = $rs->record($i);
#    print $conn->option("host"), ": record $i is ", render_record($rec), "\n";
#    request_records($conn, $rs, $state, 3)
#	if $i == $state->{next_to_fetch}-1;
#
#    return 0;
#}
#
#sub exception_thrown {
#    my($conn, $state, $rs, $exception) = @_;
#    print "Uh-oh!  $exception\n";
#    return 0;
#}
#
#sub request_records {
#    my($conn, $rs, $state, $count) = @_;
#
#    my $i = $state->{next_to_fetch};
#    ZOOM::Log::log("irspy", "requesting $count records from $i");
#    $rs->records($i, $count, 0);
#    $state->{next_to_fetch} += $count;
#}
#
#sub render_record {
#    my($rec) = @_;
#
#    return "undefined" if !defined $rec;
#    return "'" . $rec->render() . "'";
#}


=head1 SEE ALSO

Net::Z3950::IRSpy::Record

The ZOOM-Perl module,
http://search.cpan.org/~mirk/Net-Z3950-ZOOM/

The Zebra Database,
http://indexdata.com/zebra/

=head1 AUTHOR

Mike Taylor, E<lt>mike@indexdata.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Index Data ApS.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
