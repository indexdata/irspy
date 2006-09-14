%# $Id: bannerrow.mc,v 1.2 2006-09-14 16:13:36 mike Exp $
<%args>
$title
</%args>
% my $agent = $m->notes("agent");
   <tr class="banner">
    <td align="left">
    </td>
    <td align="center">
     <h1><a style="text-decoration: none" href="/"
	>IRSpy: <% $title %></a></h1>
    </td>
   </tr>
