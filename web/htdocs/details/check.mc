%# $Id: check.mc,v 1.6 2006-09-26 10:16:15 mike Exp $
<%args>
@id
</%args>
<%perl>
my $allTargets = (@id == 1 && $id[0] eq "");
print "<h2>Testing ...</h2>\n";
print "     <ul>\n", join("", map { "      <li>$_\n" } @id), "</ul>\n"
    if !$allTargets;
$m->flush_buffer();

# Turning on autoflush with $m->autoflush() doesn't seem to work if
# even if the "MasonEnableAutoflush" configuration parameter is turned
# on in the HTTP configuration, so we donb't even try -- instead,
# having ZOOM::IRSpy::Web::log() explicitly calling $m->flush_buffer()

my $spy = new ZOOM::IRSpy::Web("localhost:3313/IR-Explain---1",
			       admin => "fruitbat");
$spy->targets(@id) if !$allTargets;
$spy->initialise();
my $res = $spy->check();
print "<p>\n";
if ($res == 0) {
    print "<b>All tests were run</b>\n";
} else {
    print "<b>Some tests were skipped</b>\n";
}
print "</p>\n";
</%perl>
