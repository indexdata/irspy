%# $Id: menu.mc,v 1.7 2006-09-20 14:11:03 mike Exp $
     <p>
      <a href="/"><b>Home</b></a><br/>
      <a href="/all.html">Test&nbsp;all&nbsp;targets</a><br/>
      <a href="/find.html">Find a target</a><br/>
      <a href="/add.html">Add a target</a><br/>
     </p>
     <p>
      <b>Show targets</b>
      <br/>
% foreach my $i ('a' .. 'z') {
      <a href="/find.html?dc.title=^<% $i %>*&amp;_sort=dc.title&amp;_count=9999&amp;_search=Search"><% uc($i) %></a>
% }
     </p>
     <p>
      <a href="http://validator.w3.org/check?uri=referer"><img
        src="/valid-xhtml10.png"
        alt="Valid XHTML 1.0 Strict" height="31" width="88" /></a>
      <br/>
      <a href="http://jigsaw.w3.org/css-validator/"><img
	src="/vcss.png"
	alt="Valid CSS!" height="31" width="88" /></a>
     </p>
