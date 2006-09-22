%# $Id: all.mc,v 1.4 2006-09-22 15:39:14 mike Exp $
<%perl>
print "IRSpy version $ZOOM::IRSpy::VERSION<br/>\n";
my $spy = new ZOOM::IRSpy("localhost:3313/IR-Explain---1");
if (1) {
    # Testing all targets would take much too long for testing
    $spy->targets(qw(bagel.indexdata.dk/gils z3950.loc.gov:7090/Voyager));
}
$spy->initialise();
my $res = $spy->check();
if ($res == 0) {
    print "All tests were run\n";
} else {
    print "Some tests were skipped\n";
}
</%perl>
