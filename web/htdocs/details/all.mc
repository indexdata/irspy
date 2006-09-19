%# $Id: all.mc,v 1.2 2006-09-19 16:30:07 mike Exp $
<%perl>
print "IRSpy version $ZOOM::IRSpy::VERSION<br/>\n";
my $spy = new ZOOM::IRSpy("localhost:1313/IR-Explain---1");
if (1) {
    # Testing all targets would take much too long for testing
    my @targets = qw(bagel.indexdata.dk/gils z3950.loc.gov:7090/Voyager);
    $spy->targets(join(" ", @targets));
}
$spy->initialise();
my $res = $spy->check();
if ($res == 0) {
    print "All tests were run\n";
} else {
    print "Some tests were skipped\n";
}
</%perl>
