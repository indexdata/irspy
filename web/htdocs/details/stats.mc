%# $Id: stats.mc,v 1.4 2006-12-15 18:18:46 mike Exp $
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
<%args>
$query => undef
</%args>
<%perl>
my $key = defined $query ? $query : "";
my $from_cache = 1;
my $stats = $m->cache->get($key);
if (defined $stats) {
} else {
    $from_cache = 0;
    $stats = new ZOOM::IRSpy::Stats("localhost:3313/IR-Explain---1", $query);
    $m->cache->set($key, $stats, "1 minute");
}
</%perl>
     <h2>Statistics for <% $stats->{conn}->option("host") %></h2>
     <h3><% $stats->{n} %> targets analysed
      <% defined $query ? "for '" . xml_encode($query) . "'" : "" %></h3>
% if ($from_cache) {
     <p>Reusing cached result</p>
% } else {
     <p>Recalculating stats</p>
% }

     <h3>Top 10 Bib-1 Attributes</h3>
     <table border="1">
      <tr>
       <th>Attribute</th>
       <th>Name</th>
       <th># Db</th>
      </tr>
<%perl>
my $hr;
$hr = $stats->{bib1AccessPoints};
foreach my $key ((sort { $hr->{$b} <=> $hr->{$a} 
			 || $a <=> $b } keys %$hr)[0..9]) {
</%perl>
      <tr>
       <td><% xml_encode($key) %></td>
       <td><i>unknown</i></td>
       <td><% xml_encode($hr->{$key}) . " (" .
	100*$hr->{$key}/$stats->{n} . "%)" %></td>
      </tr>
% }
</table>

<%doc>
    print "\nRECORD SYNTAXES\n";
    $hr = $stats->{recordSyntaxes};
    foreach my $key (sort { $hr->{$b} <=> $hr->{$a} 
			    || $a cmp $b } keys %$hr) {
	print sprintf("%-26s%5d (%d%%)\n",
		      $key, $hr->{$key}, 100*$hr->{$key}/$stats->{n});
    }

    print "\nEXPLAIN SUPPORT\n";
    $hr = $stats->{explain};
    foreach my $key (sort { $hr->{$b} <=> $hr->{$a} 
			    || $a cmp $b } keys %$hr) {
	print sprintf("%-26s%5d (%d%%)\n",
		      $key, $hr->{$key}, 100*$hr->{$key}/$stats->{n});
    }

    print "\nTOP-LEVEL DOMAINS\n";
    $hr = $stats->{domains};
    foreach my $key (sort { $hr->{$b} <=> $hr->{$a} 
			    || $a cmp $b } keys %$hr) {
	print sprintf("%-26s%5d (%d%%)\n",
		      $key, $hr->{$key}, 100*$hr->{$key}/$stats->{n});
    }
</%doc>
