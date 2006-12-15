%# $Id: stats.mc,v 1.2 2006-12-15 10:37:29 mike Exp $
<%doc>
Here are the headings in the Z-Spy version:
	The ten most commonly supported Bib-1 Use attributes
	Record syntax support by database
	Explain support
	Z39.50 Protocol Services Support
	Z39.50 Server Atlas
	Top Domains
	Implementation
You can see his version live at
	http://targettest.indexdata.com/stat.php
Or a static local copy at ../../../archive/stats.html

There may be way to generate some of this information by cleverly
couched searchges, but it would still be necessary to trawl the
records in order to find all the results, so we just take the path of
least resistance and look at all the records by hand.
</%doc>
<%perl>
my $stats = new ZOOM::IRSpy::Stats("localhost:3313/IR-Explain---1");
print "<pre>";
$stats->print();
print "</pre>\n";
</%perl>
