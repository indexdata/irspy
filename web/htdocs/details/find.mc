%# $Id: find.mc,v 1.1 2006-09-15 16:51:51 mike Exp $
% if ($r->param("_search")) {
%     $m->comp("found.mc");
% } else {
     <p>
      Choose one or more critera by which to search for registered
      databases, then press the <b>Search</b> button.
     </p>
     <form>
      <table class="searchform">
       <tr>
        <th>(Anywhere)</th>
	<td><input type="text" name="cql.anywhere" size="40"/></td>
       </tr>
       <tr><td colspan="2">&nbsp;</td></tr>
       <tr>
        <th>Protocol</th>
	<td>
         <select name="net.protocol" size="1">
	  <option value="">[No preference]</option>
	  <option value="z39.50">Z39.50</option>
	  <option value="sru">SRU</option>
	  <option value="srw">SRW</option>
	 </select>
        </td>
       </tr>
       <tr>
        <th>Version</th>
	<td><input type="text" name="net.version" size="5"/></td>
       </tr>
       <tr>
        <th>Method</th>
	<td>
         <select name="net.method" size="1">
	  <option value="">[No preference]</option>
	  <option value="get">GET</option>
	  <option value="post">POST</option>
	 </select>
        </td>
       </tr>
       <tr><td colspan="2">&nbsp;</td></tr>
       <tr>
        <th>Host</th>
	<td><input type="text" name="net.host" size="40"/></td>
       </tr>
       <tr>
        <th>Port</th>
	<td><input type="text" name="net.port" size="5"/></td>
       </tr>
       <tr>
        <th>Database</th>
	<td><input type="text" name="net.path" size="20"/></td>
       </tr>
       <tr><td colspan="2">&nbsp;</td></tr>
       <tr>
        <th>Title</th>
	<td><input type="text" name="dc.title" size="40"/></td>
       </tr>
       <tr>
        <th>Creator</th>
	<td><input type="text" name="dc.creator" size="40"/></td>
       </tr>
       <tr><td colspan="2">&nbsp;</td></tr>
       <tr>
        <th/>
        <th><input type="submit" name="_search" value="Search"/></th>
       </tr>
      </table>
      <p>
       <small>
	Show
	<input type="text" name="_count" size="4" value="10"/>
	records, skipping the first
	<input type="text" name="_skip" size="4" value="0"/>
       </small>
      </p>
     </form>
% }
