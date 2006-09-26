%# $Id: check.mc,v 1.5 2006-09-26 09:30:20 mike Exp $
<%args>
@id
</%args>
<%perl>
my $allTargets = (@id == 1 && $id[0] eq "");
print "<h2>Testing ...</h2>\n";
print "     <ul>\n", join("", map { "      <li>$_\n" } @id), "</ul>\n"
    if !$allTargets;

my $spy = new ZOOM::IRSpy::Web("localhost:3313/IR-Explain---1",
			       admin => "fruitbat");
$spy->targets(@id) if !$allTargets;
$spy->initialise();
my $res = $spy->check();
if ($res == 0) {
    print "All tests were run\n";
} else {
    print "Some tests were skipped\n";
}
</%perl>
