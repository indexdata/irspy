%# $Id: bannerrow.mc,v 1.4 2006-09-21 13:13:49 mike Exp $
<%args>
$title
</%args>
% my $agent = $m->notes("agent");
   <tr class="banner">
    <td align="left">
     <br/>
     <h1><a class="logo" href="/">IRSpy</a></h1>
    </td>
    <td align="right">
     <br/>
     <h1 class="title"><% $title %></h1>
    </td>
   </tr>
