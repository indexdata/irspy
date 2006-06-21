# $Id: IRSpy.pm,v 1.6 2006-06-21 16:24:55 mike Exp $

package ZOOM::IRSpy;

use 5.008;
use strict;
use warnings;
use ZOOM::IRSpy::Record;
use ZOOM::Pod;

our @ISA = qw();
our $VERSION = '0.02';

=head1 NAME

ZOOM::IRSpy - Perl extension for discovering and analysing IR services

=head1 SYNOPSIS

 use ZOOM::IRSpy;
 $spy = new ZOOM::IRSpy("target/string/for/irspy/database");
 print $spy->report_status();

=head1 DESCRIPTION

This module exists to implement the IRspy program, which discovers,
analyses and monitors IR servers implementing the Z39.50 and SRU/W
protocols.  It is a successor to the ZSpy program.

=cut

BEGIN {
    ZOOM::Log::mask_str("irspy");
    ZOOM::Log::mask_str("irspy_test");
    ZOOM::Log::mask_str("irspy_debug");
}

sub new {
    my $class = shift();
    my($dbname) = @_;

    my $conn = new ZOOM::Connection($dbname)
	or die "$0: can't connection to IRSpy database 'dbname'";

    my $this = bless {
	conn => $conn,
	allrecords => 1,	# unless overridden by targets()
	query => undef,		# filled in later
	targets => undef,	# filled in later
	target2record => undef,	# filled in later
	pod => undef,		# filled in later
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
	    my $new = "$host:$port/$db";
	    $this->log("irspy_debug", "rewriting '$target' to '$new'");
	    $target = $new;
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
	    new ZOOM::IRSpy::Record($target, $zeerex);
    }

    foreach my $target (keys %target2record) {
	my $record = $target2record{$target};
	if (!defined $record) {
	    $this->log("irspy_debug", "made new record for '$target'");
	    $target2record{$target} = new ZOOM::IRSpy::Record($target);
	} else {
	    $this->log("irspy_debug", "using existing record for '$target'");
	}
    }

    $this->{target2record} = \%target2record;
    $this->{pod} = new ZOOM::Pod(@{ $this->{targets} });
    delete $this->{targets};	# The information is now in the Pod.
    delete $this->{query};	# Not needed at all
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


# Returns:
#	0 all tests successfully run
#	1 some tests skipped
#
sub check {
    my $this = shift();

    return $this->_run_test("Main");
}


sub _run_test {
    my $this = shift();
    my($tname) = @_;

    eval {
	my $slashSeperatedTname = $tname;
	$slashSeperatedTname =~ s/::/\//g;
	require "ZOOM/IRSpy/Test/$slashSeperatedTname.pm";
    }; if ($@) {
	$this->log("warn", "can't load test '$tname': skipping",
		   $@ =~ /^Can.t locate/ ? () : " ($@)");
	return 1;
    }

    $this->log("irspy", "running test '$tname'");
    my $test = "ZOOM::IRSpy::Test::$tname"->new($this);
    return $test->run();
}


# Access methods for the use of Test modules
sub pod {
    my $this = shift();
    return $this->{pod};
}

sub record {
    my $this = shift();
    my($target) = @_;

    if (ref($target) && $target->isa("ZOOM::Connection")) {
	# Can be called with a Connection instead of a target-name
	my $conn = $target;
	$target = $conn->option("host");
	$this->log("irspy_debug", "record() resolved $conn to '$target'");
    }

    return $this->{target2record}->{lc($target)};
}



=head1 SEE ALSO

ZOOM::IRSpy::Record

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
