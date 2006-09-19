%# $Id: layout.mc,v 1.3 2006-09-19 11:13:58 mike Exp $
<%args>
$debug => undef
$title
$component
</%args>
<%once>
use lib "/usr/local/src/cvs/irspy/lib";
use ZOOM::IRSpy;
</%once>
<%perl>
my $text = $m->scomp($component, %ARGS);
</%perl>
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
    <td class="spacer"></td>
    <td valign="top">
     <% $text %>
   </tr>
  </table>
<& /chrome/tail.mc &>
