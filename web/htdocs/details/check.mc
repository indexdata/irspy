%# $Id: check.mc,v 1.1 2006-09-18 19:27:21 mike Exp $
<%perl>
my $id = $r->param("id");
if (!$id) {
    print "No 'id' specified!\n";
} else {
    print "<h2>'$id'</h2>\n";
    my $spy = new ZOOM::IRSpy("localhost:1313/IR-Explain---1");
    ZOOM::Log::mask_str("irspy,irspy_test"); # Do we need this?
    ZOOM::Log::init_level(ZOOM::Log::module_level("irspy,irspy_test"));
    ZOOM::Log::time_format("%F %T"); # ISO-8601 format
    ### capture logging output ... somehow.
    $spy->targets($id);
    $spy->initialise();
    my $res = 0;#$spy->check();
    if ($res == 0) {
	print "All tests were run\n";
    } else {
	print "Some tests were skipped\n";
    }
}
</%perl>
