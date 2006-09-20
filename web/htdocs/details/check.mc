%# $Id: check.mc,v 1.3 2006-09-20 16:36:07 mike Exp $
<%perl>
my $id = $r->param("id");
if (!$id) {
    print "No 'id' specified!\n";
} else {
    print "<h2>$id</h2>\n";
    my $spy = new ZOOM::IRSpy("localhost:3313/IR-Explain---1", admin => "fruitbat");
    ZOOM::Log::mask_str("irspy,irspy_test"); # Do we need this?
    ZOOM::Log::init_level(ZOOM::Log::module_level("irspy,irspy_test"));
    ZOOM::Log::time_format("%F %T"); # ISO-8601 format
    ### capture logging output ... somehow.
    $spy->targets($id);
    $spy->initialise();
    my $res = $spy->check();
    if ($res == 0) {
	print "All tests were run\n";
    } else {
	print "Some tests were skipped\n";
    }
}
</%perl>
