%# $Id: link.mc,v 1.5 2006-12-04 17:28:34 mike Exp $
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
	>?</a>
%# <img alt="Help" height="16" width="16" src="/help-16px.png"/></a>
