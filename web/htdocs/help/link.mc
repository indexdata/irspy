%# $Id: link.mc,v 1.4 2006-12-04 10:02:43 mike Exp $
<%args>
$help
</%args>
      <a title="Pops up in a new window" href="#"
	onclick="window.open('/help.html?help=<% $help %>', 'help',
		'status=0,height=320,width=320')"
	style="font-size: small; font-weight: bold; text-decoration: none;
		color: white; background: #00c000; 
		padding: 0.2em; margin: 0.2em;
		border: 1px solid #008000"
	>HELP</a>
