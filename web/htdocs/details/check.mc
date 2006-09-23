%# $Id: check.mc,v 1.4 2006-09-23 07:13:43 mike Exp $
<%args>
@id
</%args>
<%perl>
my $allTargets = (@id == 1 && $id[0] eq "");
print "<h2>Testing ...</h2>\n";
my $spy = new ZOOM::IRSpy("localhost:3313/IR-Explain---1",
			  admin => "fruitbat");
print "     <ul>\n", join("", map { "      <li>$_\n" } @id), "</ul>\n"
    if !$allTargets;

ZOOM::Log::mask_str("irspy,irspy_test"); # Do we need this?
ZOOM::Log::init_level(ZOOM::Log::module_level("irspy,irspy_test"));
ZOOM::Log::time_format("%F %T"); # ISO-8601 format
### Arrange to capture logging output ... somehow.

$spy->targets(@id) if !$allTargets;
$spy->initialise();
my $res = $spy->check();
if ($res == 0) {
    print "All tests were run\n";
} else {
    print "Some tests were skipped\n";
}
</%perl>
