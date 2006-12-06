%# $Id: link.mc,v 1.7 2006-12-06 14:12:17 mike Exp $
<%args>
$help
</%args>
      <a title="Pops up in a new window" href=""
	onclick="window.open('/help.html?help=<% $help %>', 'help',
		'status=0,scrollbars=1,height=320,width=320')"
	><img alt="Help" height="16" width="16" src="/help-16px.png"/></a>
