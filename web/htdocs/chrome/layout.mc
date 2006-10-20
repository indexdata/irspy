%# $Id: layout.mc,v 1.10 2006-10-20 16:56:07 mike Exp $
<%args>
$debug => undef
$title
$component
</%args>
<%once>
BEGIN {
    use vars qw($LIBDIR);
    $LIBDIR = $r->dir_config("IRSpyLibDir");
}
use lib $LIBDIR;
use ZOOM::IRSpy::Web;
use ZOOM::IRSpy qw(irspy_xpath_context xml_encode);
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
