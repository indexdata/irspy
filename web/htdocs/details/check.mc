%# $Id: check.mc,v 1.12 2006-11-16 12:15:29 mike Exp $
<%args>
@id
$test => "Quick"
$really => 0
</%args>
<%perl>
my $allTargets = (@id == 1 && $id[0] eq "");
if ($allTargets && !$really) {
</%perl>
     <h2>Warning</h2>
     <p class="error">
      Testing all the targets is a very slow process.
      Are you sure you want to do this?
     </p>
     <p>
      <a href="?really=1">Yes</a>
      <a href="/">No</a>
     </p>
<%perl>
} else {

print "<h2>Testing ...</h2>\n";
print "     <ul>\n", join("", map { "      <li>$_</li>\n" } @id), "</ul>\n"
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
}
</%perl>
