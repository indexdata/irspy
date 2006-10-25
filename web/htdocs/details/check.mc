%# $Id: check.mc,v 1.10 2006-10-25 09:54:16 mike Exp $
<%args>
@id
$test => "Quick"
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
$spy->log_init_level("irspy,irspy_test");
$spy->targets(@id) if !$allTargets;
$spy->initialise();
my $res = $spy->check($test);
print "<p>\n";
if ($res == 0) {
    print "<b>All tests were run</b>\n";
} else {
    print "<b>$res tests were skipped</b>\n";
}
print "</p>\n";
</%perl>
