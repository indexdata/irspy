%# $Id: link.mc,v 1.2 2006-12-04 09:26:31 mike Exp $
<%args>
$help
</%args>
      <a title="Pops up in a new window" href="#"
	onclick="window.open('/help.html?help=<% $help %>', 'help',
		'status=0,height=320,width=320')"
	style="font-weight: bold; text-decoration: none;
		color: black; background: #00ff00; 
		padding: 0.2em; margin: 0.2em;
		border: 1px solid black"
	>help</a>
%# It would be nice to make a little icon to use here instead of [help]
