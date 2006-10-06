# $Id: IRSpy.pm,v 1.22 2006-10-06 11:33:07 mike Exp $

package ZOOM::IRSpy;

use 5.008;
use strict;
use warnings;

use Data::Dumper; # For debugging only
use ZOOM::IRSpy::Node;
use ZOOM::IRSpy::Connection;
use ZOOM::IRSpy::Record;

our @ISA = qw();
our $VERSION = '0.02';


# Enumeration for callback functions to return
package ZOOM::IRSpy::Status;
sub OK { 29 }			# No problems, task is still progressing
sub TASK_DONE { 18 }		# Task is complete, next task should begin
sub TEST_GOOD { 8 }		# Whole test is complete, and succeeded
sub TEST_BAD { 31 }		# Whole test is complete, and failed
package ZOOM::IRSpy;


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
    ZOOM::Log::mask_str("irspy_event");
    ZOOM::Log::mask_str("irspy_unhandled");
}

sub new {
    my $class = shift();
    my($dbname, $user, $password) = @_;

    my @options;
    push @options, (user => $user, password => $password)
	if defined $user;

    my $conn = new ZOOM::Connection($dbname, 0, @options)
	or die "$0: can't connection to IRSpy database 'dbname'";

    my $this = bless {
	conn => $conn,
	allrecords => 1,	# unless overridden by targets()
	query => undef,		# filled in later
	targets => undef,	# filled in later
	connections => undef,	# filled in later
	tests => [],		# stack of tests currently being executed
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
    my(@targets) = @_;

    $this->log("irspy", "setting explicit list of targets ",
	       join(", ", map { "'$_'" } @targets));
    $this->{allrecords} = 0;
    my @qlist;
    foreach my $target (@targets) {
	my($host, $port, $db, $newtarget) = _parse_target_string($target);
	if ($newtarget ne $target) {
	    $this->log("irspy_debug", "rewriting '$target' to '$newtarget'");
	    $target = $newtarget; # This is written through the ref
	}
	push @qlist, (qq[(host="$host" and port="$port" and path="$db")]);
    }

    $this->{targets} = \@targets;
    $this->{query} = join(" or ", @qlist);
}


# Also used by ZOOM::IRSpy::Record
sub _parse_target_string {
    my($target) = @_;

    my($host, $port, $db) = ($target =~ /(.*?):(.*?)\/(.*)/);
    if (!defined $host) {
	$port = 210;
	($host, $db) = ($target =~ /(.*?)\/(.*)/);
	$target = "$host:$port/$db";
    }
    die "$0: invalid target string '$target'"
	if !defined $host;

    return ($host, $port, $db, $target);
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

    $this->log("irspy_debug", "query '", $this->{query}, "'");
    my $rs = $this->{conn}->search(new ZOOM::Query::CQL($this->{query}));
    delete $this->{query};	# No longer needed at all
    $this->log("irspy_debug", "found ", $rs->size(), " target records");
    foreach my $i (1 .. $rs->size()) {
	my $target = _render_record($rs, $i-1, "id");
	my $zeerex = _render_record($rs, $i-1, "zeerex");
	#print STDERR "making '$target' record with '$zeerex'\n";
	$target2record{lc($target)} =
	    new ZOOM::IRSpy::Record($this, $target, $zeerex);
	push @{ $this->{targets} }, $target
	    if $this->{allrecords};
    }

    # Make records for targets not previously in the database
    foreach my $target (keys %target2record) {
	my $record = $target2record{$target};
	if (!defined $record) {
	    $this->log("irspy_debug", "made new record for '$target'");
	    $target2record{$target} = new ZOOM::IRSpy::Record($this, $target);
	} else {
	    $this->log("irspy_debug", "using existing record for '$target'");
	}
    }

    my @connections;
    foreach my $target (@{ $this->{targets} }) {
	my $conn = new ZOOM::IRSpy::Connection($this, $target, 0, async => 1);
	my $record = delete $target2record{lc($target)};
	$conn->record($record);
	push @connections, $conn;
    }
    die("remaining target2record = { " .
	join(", ", map { "$_ ->'" . $target2record{$_}. "'" }
	     sort keys %target2record) . " }")
	if %target2record;

    $this->{connections} = \@connections;
    delete $this->{targets};	# The information is now in {connections}
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


sub _rewrite_records {
    my $this = shift();

    # Write modified records back to database
    foreach my $conn (@{ $this->{connections} }) {
	my $rec = $conn->record();
	my $p = $this->{conn}->package();
	$p->option(action => "specialUpdate");
	my $xml = $rec->{zeerex}->toString();
	$p->option(record => $xml);
	$p->send("update");
	$p->destroy();

	$p = $this->{conn}->package();
	$p->send("commit");
	$p->destroy();
	if (0) {
	    $xml =~ s/&/&amp/g;
	    $xml =~ s/</&lt;/g;
	    $xml =~ s/>/&gt;/g;
	    print "Updated with xml=<br/>\n<pre>$xml</pre>\n";
	}
    }
}


# New approach:
# 1. Gather declarative information about test hierarchy.
# 2. For each connection, start the initial test -- invokes run().
# 3. Run each connection's first queued task.
# 4. while (1) { wait() }.  Callbacks return a ZOOM::IRSpy::Status value
# No individual test ever calls wait: tests just set up tasks.
#
sub check {
    my $this = shift();
    my($tname) = @_;

    $tname = "Main" if !defined $tname;
    $this->{tree} = $this->_gather_tests($tname)
	or die "No tests defined";
    #$this->{tree}->print(0);

    my @conn = @{ $this->{connections} };
    foreach my $conn (@conn) {
	$this->_start_test($conn, "");
    }

    while ((my $i0 = ZOOM::event(\@conn)) != 0) {
	my $conn = $conn[$i0-1];
	my $target = $conn->option("host");
	my $ev = $conn->last_event();
	my $evstr = ZOOM::event_str($ev);
	$this->log("irspy_event", "$target event $ev ($evstr)");

	my $task = $conn->current_task();
	my $res;
	eval {
	    $conn->_check();
	}; if ($@) {
	    # This is a nasty hack.  An error in, say, a search response,
	    # becomes visible to ZOOM before the Receive Data event is
	    # sent and persists until after the End, which means that
	    # successive events each report the same error.  So we
	    # just ignore errors on "unimportant" events.  Let's hope
	    # this doesn't come back and bite us.
	    if ($ev == ZOOM::Event::RECV_DATA ||
		$ev == ZOOM::Event::RECV_APDU ||
		$ev == ZOOM::Event::ZEND) {
		$this->log("irspy_event", "$target ignoring error ",
			   "on event $ev ($evstr): $@");
	    } else {
		my $sub = $task->{cb}->{exception};
		die $@ if !defined $sub;
		$res = &$sub($conn, $task, $@);
		goto HANDLE_RESULT;
	    }
	}

	my $sub = $task ? $task->{cb}->{$ev} : undef;
	if (!defined $sub) {
	    $conn->log("irspy_unhandled", "event $ev ($evstr)");
	    # Catch the case of a pure-container test ending
	    if ($ev == ZOOM::Event::ZEND && !$conn->current_task()) {
		$conn->log("irspy", "last event, no task queued");
		goto NEXT_TEST;
	    }
	    next;
	}

	$res = &$sub($conn, $task, $ev);
      HANDLE_RESULT:
	if ($res == ZOOM::IRSpy::Status::OK) {
	    # Nothing to do -- life continues

	} elsif ($res == ZOOM::IRSpy::Status::TASK_DONE) {
	    my $task = $conn->current_task();
	    die "can't happen" if !$task;
	    $conn->log("irspy", "completed task $task");
	    my $nexttask = $task->{next};
	    if (defined $nexttask) {
		$conn->log("irspy_debug", "next task is '$nexttask'");
		$conn->start_task($nexttask);
	    } else {
		$conn->log("irspy_debug", "jumping to NEXT_TEST");
		$conn->current_task(0);
		goto NEXT_TEST;
	    }

	} elsif ($res == ZOOM::IRSpy::Status::TEST_GOOD) {
	    $conn->log("irspy", "test completed (GOOD)");
	  NEXT_TEST:
	    my $address = $conn->option("address");
	    my $nextaddr = $this->_next_test($address);
	    if (defined $nextaddr) {
		$this->_start_test($conn, $nextaddr);
	    } else {
		$conn->log("irspy", "has no tests after '$address'");
		# Nothing else to do: we will get no more meaningful
		# events on this connection, and when all the
		# connections have reached this state, ZOOM::event()
		# will return 0 and we will fall out of the loop.
	    }

	} elsif ($res == ZOOM::IRSpy::Status::TEST_BAD) {
	    $conn->log("irspy", "test completed (BAD)");
	    ### Should skip over remaining sibling tests
	    goto NEXT_TEST;
	}
    }

    $this->log("irspy_event", "ZOOM::event() returned 0");

    #$this->_rewrite_records();
    return 0;			# What does this mean?
}


# Preconditions:
# - called only when there no tasks remain for the connection
# - called with valid address
sub _start_test {
    my $this = shift();
    my($conn, $address) = @_;
    {
	my $task = $conn->current_task();
	die "_start_test(): $conn already has task $task"
	    if $task;
    }

    my $node = $this->{tree}->select($address)
	or die "_start_test(): invalid address '$address'";

    $conn->option(address => $address);
    my $tname = $node->name();
    $this->log("irspy", $conn->option("host"),
	       " starting test '$address' = $tname");

    # We will need to find the first of the tasks that are added by
    # the test we're about to start, so we can start that task.  This
    # requires a little trickery: noting the current length of the
    # tasks array first, then fetching the next one off the end.
    my $alltasks = $conn->tasks();
    my $ntasks = defined $alltasks ? @$alltasks : 0;
    my $test = "ZOOM::IRSpy::Test::$tname"->start($conn);

    $alltasks = $conn->tasks();
    if (defined $alltasks && @$alltasks > $ntasks) {
	my $task = $alltasks->[$ntasks];
	$conn->start_task($task);
    } else {
	$this->log("irspy", "no tasks added for test '$address' = $tname");
    }
}


sub _gather_tests {
    my $this = shift();
    my($tname, @ancestors) = @_;

    die("$0: test-hierarchy loop detected: " .
	join(" -> ", @ancestors, $tname))
	if grep { $_ eq $tname } @ancestors;

    eval {
	my $slashSeperatedTname = $tname;
	$slashSeperatedTname =~ s/::/\//g;
	require "ZOOM/IRSpy/Test/$slashSeperatedTname.pm";
    }; if ($@) {
	$this->log("warn", "can't load test '$tname': skipping",
		   $@ =~ /^Can.t locate/ ? () : " ($@)");
	return undef;
    }

    $this->log("irspy", "adding test '$tname'");
    my @subtests;
    foreach my $subtname ("ZOOM::IRSpy::Test::$tname"->subtests($this)) {
	my $subtest = $this->_gather_tests($subtname, @ancestors, $tname);
	push @subtests, $subtest if defined $subtest;
    }

    return new ZOOM::IRSpy::Node($tname, @subtests);
}


sub _next_test {
    my $this = shift();
    my($address, $omit_child) = @_;

    $this->log("irspy", "checking for next test after '$address'");

    # Try first child
    if (!$omit_child) {
	my $maybe = $address eq "" ? "0" : "$address:0";
	return $maybe if $this->{tree}->select($maybe);
    }

    # The top-level node has no successor or parent
    return undef if $address eq "";

    # Try next sibling child
    my @components = split /:/, $address;
    my $last = pop @components;
    my $maybe = join(":", @components, $last+1);
    return $maybe if $this->{tree}->select($maybe);

    # This node is exhausted: try the parent's successor
    return $this->_next_test(join(":", @components), 1)
}


=head1 SEE ALSO

ZOOM::IRSpy::Record,
ZOOM::IRSpy::Web,
ZOOM::IRSpy::Test,
ZOOM::IRSpy::Maintenance.

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
