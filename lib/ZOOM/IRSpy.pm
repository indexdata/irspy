# $Id: IRSpy.pm,v 1.54 2006-12-14 17:24:29 mike Exp $

package ZOOM::IRSpy;

use 5.008;
use strict;
use warnings;

use Data::Dumper;		# For debugging only
use File::Basename;
use XML::LibXSLT;
use XML::LibXML;
use XML::LibXML::XPathContext;
use ZOOM;
use Net::Z3950::ZOOM 1.13;	# For the ZOOM version-check only
use ZOOM::IRSpy::Node;
use ZOOM::IRSpy::Connection;
use ZOOM::IRSpy::Record;
use ZOOM::IRSpy::Stats;
use ZOOM::IRSpy::Utils qw(cql_target);

our @ISA = qw();
our $VERSION = '0.02';
our $irspy_to_zeerex_xsl = dirname(__FILE__) . '/../../xsl/irspy2zeerex.xsl';


# Enumeration for callback functions to return
package ZOOM::IRSpy::Status;
sub OK { 29 }			# No problems, task is still progressing
sub TASK_DONE { 18 }		# Task is complete, next task should begin
sub TEST_GOOD { 8 }		# Whole test is complete, and succeeded
sub TEST_BAD { 31 }		# Whole test is complete, and failed
sub TEST_SKIPPED { 12 }		# Test couldn't be run
package ZOOM::IRSpy;


=head1 NAME

ZOOM::IRSpy - Perl extension for discovering and analysing IR services

=head1 SYNOPSIS

 use ZOOM::IRSpy;
 $spy = new ZOOM::IRSpy("target/string/for/irspy/database");
 $spy->targets(@targets);
 $spy->initialise();
 $res = $spy->check("Main");

=head1 DESCRIPTION

This module exists to implement the IRspy program, which discovers,
analyses and monitors IR servers implementing the Z39.50 and SRU/W
protocols.  It is a successor to the ZSpy program.

=cut

BEGIN {
    ZOOM::Log::mask_str("irspy");
    ZOOM::Log::mask_str("irspy_debug");
    ZOOM::Log::mask_str("irspy_event");
    ZOOM::Log::mask_str("irspy_unhandled");
    ZOOM::Log::mask_str("irspy_test");
    ZOOM::Log::mask_str("irspy_task");
}

sub new {
    my $class = shift();
    my($dbname, $user, $password) = @_;

    my @options;
    push @options, (user => $user, password => $password)
	if defined $user;

    my $conn = new ZOOM::Connection($dbname, 0, @options)
	or die "$0: can't connection to IRSpy database 'dbname'";

    my $xslt = new XML::LibXSLT;

    $xslt->register_function($ZOOM::IRSpy::Utils::IRSPY_NS, 'strcmp',
                             \&ZOOM::IRSpy::Utils::xslt_strcmp);

    my $libxml = new XML::LibXML;
    my $xsl_doc = $libxml->parse_file($irspy_to_zeerex_xsl);
    my $irspy_to_zeerex_style = $xslt->parse_stylesheet($xsl_doc);

    my $this = bless {
	conn => $conn,
	allrecords => 1,	# unless overridden by targets()
	query => undef,		# filled in later
	targets => undef,	# filled in later
	connections => undef,	# filled in later
        libxml => $libxml,
        irspy_to_zeerex_style => $irspy_to_zeerex_style,
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
	push @qlist, cql_target($host, $port, $db);
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
	my $conn = create ZOOM::IRSpy::Connection($this, async => 1);
	$conn->option(host => $target);
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


sub _irspy_to_zeerex {
    my ($this, $conn) = @_;
    my $irspy_doc = $conn->record()->{zeerex}->ownerDocument;
    #open FH, '>/tmp/irspy_orig.xml';
    #print FH $irspy_doc->toString();
    #close FH;
    my %params = ();
    my $result = $this->{irspy_to_zeerex_style}->transform($irspy_doc, %params);

    #open FH, '>/tmp/irspy_transformed.xml';
    #print FH $result->toString();
    #close FH;

    return $result->documentElement();
}


sub _rewrite_record {
    my $this = shift();
    my($conn) = @_;

    $conn->log("irspy", "rewriting XML record");
    my $rec = $this->_irspy_to_zeerex($conn);
    _really_rewrite_record($this->{conn}, $rec);
}


sub _really_rewrite_record {
    my($conn, $rec) = @_;

    my $p = $conn->package();
    $p->option(action => "specialUpdate");
    my $xml = $rec->toString();
    $p->option(record => $xml);
    $p->send("update");
    $p->destroy();

    $p = $conn->package();
    $p->send("commit");
    $p->destroy();
    if (0) {
	$xml =~ s/&/&amp/g;
	$xml =~ s/</&lt;/g;
	$xml =~ s/>/&gt;/g;
	print "Updated $conn with xml=<br/>\n<pre>$xml</pre>\n";
    }
}


# The approach: gather declarative information about test hierarchy,
# then go into a loop.  In the loop, we ensure that each connection is
# running a test, and within that test a task, until its list of tests
# is exhausted.  No individual test ever calls wait(): tests just queue
# up tasks and return immediately.  When the tasks are run (one at a
# time on each connection) they generate events, and it is these that
# are harvested by ZOOM::event().  Since each connection knows what
# task it is running, it can invoke the appropriate callbacks.
# Callbacks return a ZOOM::IRSpy::Status value which tells the main
# loop how to continue.
#
# Invariants:
#	While a connection is running a task, its current_task()
#	points at the task structure.  When it finishes its task, 
#	next_task() is pointed at the next task to execute (if there
#	is one), and its current_task() is set to zero.  When the next
#	task is executed, the connection's next_task() is set to zero
#	and its current_task() pointed to the task structure.
#	current_task() and next_task() are both zero only when there
#	are no more queued tasks, which is when a new test is
#	started.
#
#	Each connection's current test is stored in its
#	"current_test_address" option.  The next test to execute is
#	calculated by walking the declarative tree of tests.  This
#	option begins empty; the "next test" after this is of course
#	the root test.
#
sub check {
    my $this = shift();
    my($tname) = @_;

    $tname = "Main" if !defined $tname;
    $this->{tree} = $this->_gather_tests($tname)
	or die "No tests defined for '$tname'";
    #$this->{tree}->print(0);
    my $nskipped = 0;

    my @conn = @{ $this->{connections} };

    while (1) {
	my @copy_conn = @conn;	# avoid alias problems after splice()
	my $nconn = scalar(@copy_conn);
	foreach my $i0 (0 .. $#copy_conn) {
	    my $conn = $copy_conn[$i0];
	    #print "connection $i0 of $nconn/", scalar(@conn), " is $conn\n";
	    if (!$conn->current_task()) {
		if (!$conn->next_task()) {
		    # Out of tasks: we need a new test
		  NEXT_TEST:
		    my $address = $conn->option("current_test_address");
		    my $nextaddr;
		    if (!defined $address) {
			$nextaddr = "";
		    } else {
			$this->log("irspy_test",
				   "checking for next test after '$address'");
			$nextaddr = $this->_next_test($address);
		    }
		    if (!defined $nextaddr) {
			$conn->log("irspy", "has no more tests: removing");
			splice @conn, $i0, 1;
			$this->_rewrite_record($conn);
			$conn->option(rewrote_record => 1);
			next;
		    }

		    my $node = $this->{tree}->select($nextaddr)
			or die "invalid nextaddr '$nextaddr'";
		    $conn->option(current_test_address => $nextaddr);
		    my $tname = $node->name();
		    $conn->log("irspy_test",
			       "starting test '$nextaddr' = $tname");
		    my $tasks = $conn->tasks();
		    my $oldcount = @$tasks;
		    "ZOOM::IRSpy::Test::$tname"->start($conn);
		    $tasks = $conn->tasks();
		    if (@$tasks > $oldcount) {
			# Prepare to start the first of the newly added tasks
			$conn->next_task($tasks->[$oldcount]);
		    } else {
			$conn->log("irspy_task",
				   "no tasks added by new test $tname");
			goto NEXT_TEST;
		    }
		}

		my $task = $conn->next_task();
		die "no next task queued for $conn" if !defined $task;
		$conn->log("irspy_task", "preparing task $task");
		$conn->next_task(0);
		$conn->current_task($task);
		$task->run();
	    }

	    # Do we need to test $conn->is_idle()?  I don't think so!
	}

	my $i0 = ZOOM::event(\@conn);
	$this->log("irspy_event",
		   "ZOOM_event(", scalar(@conn), " connections) = $i0");
	last if $i0 == 0 || $i0 == -3; # no events or no connections
	my $conn = $conn[$i0-1];
	my $ev = $conn->last_event();
	my $evstr = ZOOM::event_str($ev);
	$conn->log("irspy_event", "event $ev ($evstr)");

	my $task = $conn->current_task();
	die "$conn has no current task for event $ev ($evstr)" if !$task;
	eval { $conn->_check() };
	if ($@ &&
	    ($ev == ZOOM::Event::RECV_DATA ||
	     $ev == ZOOM::Event::RECV_APDU ||
	     $ev == ZOOM::Event::ZEND)) {
	    # An error in, say, a search response, becomes visible to
	    # ZOOM before the Receive Data event is sent and persists
	    # until after the End, which means that successive events
	    # each report the same error.  So we just ignore errors on
	    # "unimportant" events.  ### But this doesn't work for,
	    # say, a Connection Refused, as the only event that shows
	    # us this error is the End.
	    $conn->log("irspy_event", "ignoring error ",
		       "on event $ev ($evstr): $@");
	    next;
	}

	my $res;
	if ($@) {
	    my $sub = $task->{cb}->{exception};
	    die $@ if !defined $sub;
	    $res = &$sub($conn, $task, $task->udata(), $@);
	} else {
	    my $sub = $task->{cb}->{$ev};
	    if (!defined $sub) {
		$conn->log("irspy_unhandled", "event $ev ($evstr)");
		next;
	    }

	    $res = &$sub($conn, $task, $task->udata(), $ev);
	}

	if ($res == ZOOM::IRSpy::Status::OK) {
	    # Nothing to do -- life continues

	} elsif ($res == ZOOM::IRSpy::Status::TASK_DONE) {
	    my $task = $conn->current_task();
	    die "no task for TASK_DONE on $conn" if !$task;
	    die "next task already defined for $conn" if $conn->next_task();
	    $conn->log("irspy_task", "completed task $task");
	    $conn->next_task($task->{next});
	    $conn->current_task(0);

	} elsif ($res == ZOOM::IRSpy::Status::TEST_GOOD ||
		 $res == ZOOM::IRSpy::Status::TEST_BAD) {
	    my $x = ($res == ZOOM::IRSpy::Status::TEST_GOOD) ? "good" : "bad";
	    $conn->log("irspy_task", "test ended during task $task ($x)");
	    $conn->log("irspy_test", "test completed ($x)");
	    $conn->current_task(0);
	    $conn->next_task(0);
	    if ($res == ZOOM::IRSpy::Status::TEST_BAD) {
		my $address = $conn->option('current_test_address');
		($address, my $n) = $this->_last_sibling_test($address);
		if (defined $address) {
		    $conn->log("irspy_test", "skipped $n tests");
		    $conn->option(current_test_address => $address);
		    $nskipped += $n;
		}
	    }

	} elsif ($res == ZOOM::IRSpy::Status::TEST_SKIPPED) {
	    $conn->log("irspy_task", "test skipped during task $task");
	    $conn->current_task(0);
	    $conn->next_task(0);
	    # I think that's all we need to do

	} else {
	    die "unknown callback return-value '$res'";
	}
    }

    $this->log("irspy", "exiting main loop");
    # Sanity checks: none of the following should ever happen
    foreach my $conn (@{ $this->{connections} }) {
	my $test = $conn->option("current_test_address");
	my $next = $this->_next_test($test);
	if (defined $next) {
	    warn "$conn (in test '$test') has queued test '$next'";
	}
	if (my $task = $conn->current_task()) {
	    warn "$conn still has an active task $task";
	}
	if (my $task = $conn->next_task()) {
	    warn "$conn still has a queued task $task";
	}
	if (!$conn->is_idle()) {
	    warn "$conn still has ZOOM-C level tasks queued: see below";
	}
	if (!$conn->option("rewrote_record")) {
	    warn "$conn did not rewrite its ZeeRex record";
	}
    }

    # This shouldn't happen emit anything either:
    @conn = @{ $this->{connections} };
    while (my $i1 = ZOOM::event(\@conn)) {
	my $conn = $conn[$i1-1];
	my $ev = $conn->last_event();
	my $evstr = ZOOM::event_str($ev);
	warn "$conn still has ZOOM-C level task queued: $ev ($evstr)"
	    if $ev != ZOOM::Event::ZEND;
    }

    return $nskipped;
}


sub _gather_tests {
    my $this = shift();
    my($tname, @ancestors) = @_;

    die("$0: test-hierarchy loop detected: " .
	join(" -> ", @ancestors, $tname))
	if grep { $_ eq $tname } @ancestors;

    my $slashSeperatedTname = $tname;
    $slashSeperatedTname =~ s/::/\//g;
    my $fullName = "ZOOM/IRSpy/Test/$slashSeperatedTname.pm";

    eval {
	require $fullName;
	$this->log("irspy", "successfully required '$fullName'");
    }; if ($@) {
	$this->log("irspy", "couldn't require '$fullName': $@");
	$this->log("warn", "can't load test '$tname': skipping",
		   $@ =~ /^Can.t locate/ ? () : " ($@)");
	return undef;
    }

    $this->log("irspy", "adding test '$tname'");
    my @subnodes;
    foreach my $subtname ("ZOOM::IRSpy::Test::$tname"->subtests($this)) {
	my $subtest = $this->_gather_tests($subtname, @ancestors, $tname);
	push @subnodes, $subtest if defined $subtest;
    }

    return new ZOOM::IRSpy::Node($tname, @subnodes);
}


# These next three should arguably be Node methods
sub _next_test {
    my $this = shift();
    my($address, $omit_child) = @_;

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


sub _last_sibling_test {
    my $this = shift();
    my($address) = @_;

    return undef
	if !defined $this->_next_sibling_test($address);

    my $nskipped = 0;
    while (1) {
	my $maybe = $this->_next_sibling_test($address);
	last if !defined $maybe;
	$nskipped++;
	$address = $maybe;
	$this->log("irspy", "skipping $nskipped tests to '$address'");
    }

    return ($address, $nskipped);
}


sub _next_sibling_test {
    my $this = shift();
    my($address) = @_;

    my @components = split /:/, $address;
    my $last = pop @components;
    my $maybe = join(":", @components, $last+1);
    return $maybe if $this->{tree}->select($maybe);
    return undef;
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
