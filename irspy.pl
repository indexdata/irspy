#!/usr/bin/perl -w

# $Id: irspy.pl,v 1.1 2006-05-18 11:45:16 mike Exp $
#
# Run like this:
#	YAZ_LOG=irspy perl -I lib irspy.pl -t "bagel.indexdata.dk/gils z3950.loc.gov:7090/Voyager" localhost:1313/IR-Explain---1

use strict;
use warnings;
use Getopt::Std;
use ZOOM::Pod;

my %opts;
if (!getopts('t:au', \%opts) || @ARGV != 1) {
    print STDERR qq[Usage: $0 [options] <IRSpy-database>
	-t <t1 t2 ...>	Space-separated list of targets to check
	-a		Check all targets registered in database
	-u		Update information in database
];
    exit 1;
}

my $targetList = $opts{t};
my $allTargets = $opts{a};
if (!$targetList && !$allTargets) {
    print STDERR "$0: neither -t nor -a specified\n";
    exit 2;
}


ZOOM::Log::mask_str("irspy");
sub zlog { ZOOM::Log::log(@_) }

my $dbname = $ARGV[0];
my $conn = new ZOOM::Connection($dbname)
    or die "$0: can't connection to IRSpy database 'dbname'";
zlog("irspy", "starting up with database '$dbname'");

my $query;
if ($allTargets) {
    # According to the BIB-1 semantics document at
    #	http://www.loc.gov/z3950/agency/bib1.html
    # the query
    #	@attr 2=103 @attr 1=1035 x
    # should find all records.  But it seems that Zebra doesn't
    # support this.  Furthermore, when using the "alvis" filter (as we
    # do for IRSpy) it doesn't support the use of any BIB-1 access
    # point -- not even 1035 "everywhere" -- so instead we hack
    # together a search that we know will find all records:
    $query = "port=?*";
} else {
    my @qlist;
    foreach my $target (split /\s+/, $targetList) {
	my($host, $port, $db) = ($target =~ /(.*?):(.*?)\/(.*)/);
	if (!defined $host) {
	    $port = 210;
	    ($host, $db) = ($target =~ /(.*?)\/(.*)/);
	}
	die "invalid target string '$target'"
	    if !defined $host;
	push @qlist, (qq[(host = "$host" and port = "$port" and path="$db")]);
    }
    $query = join(" or ", @qlist);
}

my $rs = $conn->search(new ZOOM::Query::CQL($query));
print "query is: $query\n";
print "found ", $rs->size(), " records\n";
exit;

my $pod = new ZOOM::Pod(@ARGV);
$pod->option(elementSetName => "b");
$pod->callback(ZOOM::Event::RECV_SEARCH, \&completed_search);
$pod->callback(ZOOM::Event::RECV_RECORD, \&got_record);
#$pod->callback(exception => \&exception_thrown);
$pod->search_pqf("the");
my $err = $pod->wait();
die "$pod->wait() failed with error $err" if $err;

sub completed_search {
    my($conn, $state, $rs, $event) = @_;
    print $conn->option("host"), ": found ", $rs->size(), " records\n";
    $state->{next_to_fetch} = 0;
    $state->{next_to_show} = 0;
    request_records($conn, $rs, $state, 2);
    return 0;
}

sub got_record {
    my($conn, $state, $rs, $event) = @_;

    {
	# Sanity-checking assertions.  These should be impossible
	my $ns = $state->{next_to_show};
	my $nf = $state->{next_to_fetch};
	if ($ns > $nf) {
	    die "next_to_show > next_to_fetch ($ns > $nf)";
	} elsif ($ns == $nf) {
	    die "next_to_show == next_to_fetch ($ns)";
	}
    }

    my $i = $state->{next_to_show}++;
    my $rec = $rs->record($i);
    print $conn->option("host"), ": record $i is ", render_record($rec), "\n";
    request_records($conn, $rs, $state, 3)
	if $i == $state->{next_to_fetch}-1;

    return 0;
}

sub exception_thrown {
    my($conn, $state, $rs, $exception) = @_;
    print "Uh-oh!  $exception\n";
    return 0;
}

sub request_records {
    my($conn, $rs, $state, $count) = @_;

    my $i = $state->{next_to_fetch};
    ZOOM::Log::log("irspy", "requesting $count records from $i");
    $rs->records($i, $count, 0);
    $state->{next_to_fetch} += $count;
}

sub render_record {
    my($rec) = @_;

    return "undefined" if !defined $rec;
    return "'" . $rec->render() . "'";
}
