%# $Id: bannerrow.mc,v 1.3 2006-09-15 16:48:43 mike Exp $
<%args>
$title
</%args>
% my $agent = $m->notes("agent");
   <tr class="banner">
    <td align="left">
     <h1><a style="text-decoration: none" href="/">IRSpy</a></h1>
    </td>
    <td align="right">
     <h1><% $title %></h1>
    </td>
   </tr>
