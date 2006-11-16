%# $Id: layout.mc,v 1.17 2006-11-16 11:49:30 mike Exp $
<%args>
$debug => undef
$title
$component
</%args>
<%perl>
{
    # Make up ID for newly created records.  It would be more
    # rigorously correct, but insanely inefficient, to submit the
    # record to Zebra and then search for it; but since we know the
    # formula for IDs anyway, we just build one by hand.
    my $id = $r->param("id");
    my $host = $r->param("host");
    my $port = $r->param("port");
    my $dbname = $r->param("dbname");
    #warn "id='$id', host='$host', port='$port', dbname='$dbname'";
    #warn "%ARGS = {\n" . join("", map { "\t'$_' => '" . $ARGS{$_} . ",'\n" } sort keys %ARGS) . "}\n";
    if ((!defined $id || $id eq "") &&
	defined $host && defined $port && defined $dbname) {
	$id = "$host:$port/$dbname";
	$r->param(id => $id);
	$ARGS{id} = $id;
	#warn "id set to '$id'";
    }
}
</%perl>
<%once>
use URI::Escape;
use ZOOM;
use ZOOM::IRSpy::Web;
use ZOOM::IRSpy::Utils qw(irspy_xpath_context xml_encode modify_xml_document);
</%once>
<& /chrome/head.mc, title => $title &>
  <table border="0" cellpadding="0" cellspacing="0" width="100%">
<& /chrome/bannerrow.mc, title => $title &>
  </table>
  <table border="0" cellpadding="0" cellspacing="0" width="100%">
<& /chrome/lmenu.mc &>
  </table>
  <p></p>
  <table border="0" cellpadding="0" cellspacing="0" width="100%">
   <tr>
    <td valign="top" class="panel1">
<& /chrome/menu.mc &>
    </td>
    <td class="spacer">&nbsp;</td>
    <td valign="top">
<& $component, %ARGS &>
    </td>
   </tr>
  </table>
<& /chrome/tail.mc &>
