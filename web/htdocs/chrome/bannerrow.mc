%# $Id: bannerrow.mc,v 1.6 2006-09-25 19:52:20 mike Exp $
<%args>
$title
</%args>
   <tr class="banner">
    <td align="left">
     <br/>
     <h1><a class="logo" href="/">IRSpy</a></h1>
    </td>
    <td align="right">
     <br/>
     <h1 class="title"><% xml_encode($title) %></h1>
    </td>
   </tr>
