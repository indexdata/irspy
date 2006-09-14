%# $Id: bannerrow.mc,v 1.1 2006-09-14 15:17:48 mike Exp $
<%args>
$title
</%args>
% my $agent = $m->notes("agent");
   <tr class="banner">
    <td align="left">
    </td>
    <td align="center">
     <h1><a style="text-decoration: none" href="/"><% $title %></a></h1>
    </td>
    </td>
   </tr>
