%# $Id: link.mc,v 1.1 2006-12-01 16:51:33 mike Exp $
<%args>
$help
</%args>
      <a title="Pops up in a new window" href="#"
	onclick="window.open('/help.html?help=<% $help %>', 'help',
		'status=0,height=320,width=320')"
	>[help]</a>
%# It would be nice to make a little icon to use here instead of [help]
