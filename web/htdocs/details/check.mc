%# $Id: check.mc,v 1.15 2007-01-24 09:28:02 mike Exp $
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
      <a href="?really=1&amp;test=Quick">Yes: Quick Test</a><br/>
      <a href="?really=1&amp;test=Main">Yes: Full Test</a><br/>
      <a href="/">No</a><br/>
     </p>
<%perl>
} else {

print "<h2>Testing ...</h2>\n";
print "     <ul>\n", join("", map { "      <li>$_</li>\n" } @id), "</ul>\n"
    if !$allTargets;
$m->flush_buffer();

# Turning on autoflush with $m->autoflush() doesn't seem to work if
# even if the "MasonEnableAutoflush" configuration parameter is turned
# on in the HTTP configuration, so we don't even try -- instead,
# having ZOOM::IRSpy::Web::log() explicitly calling $m->flush_buffer()

my $spy = new ZOOM::IRSpy::Web("localhost:8018/IR-Explain---1",
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
