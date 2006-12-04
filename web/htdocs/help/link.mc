%# $Id: link.mc,v 1.3 2006-12-04 09:34:32 mike Exp $
<%args>
$help
</%args>
      <a title="Pops up in a new window" href="#"
	onclick="window.open('/help.html?help=<% $help %>', 'help',
		'status=0,height=320,width=320')"
	style="font-size: small; font-weight: bold; text-decoration: none;
		color: black; background: #00ff00; 
		padding: 0.2em; margin: 0.2em;
		border: 1px solid black"
	>HELP</a>
