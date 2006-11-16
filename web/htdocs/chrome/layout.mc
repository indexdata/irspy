%# $Id: layout.mc,v 1.18 2006-11-16 17:02:30 mike Exp $
<%args>
$debug => undef
$title
$component
</%args>
<%once>
use URI::Escape;
use ZOOM;
use ZOOM::IRSpy::Web;
use ZOOM::IRSpy::Utils qw(xml_encode cql_quote cql_target
                          irspy_xpath_context modify_xml_document);
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
