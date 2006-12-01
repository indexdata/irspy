%# $Id: find.mc,v 1.7 2006-12-01 14:51:19 mike Exp $
% if ($r->param("_search")) {
%     $m->comp("found.mc");
% } else {
     <p>
      Choose one or more critera by which to search for registered
      targets, then press the <b>Search</b> button.
     </p>
     <form method="get" action="">
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
        <th>Author</th>
	<td><input type="text" name="dc.creator" size="40"/></td>
       </tr>
       <tr>
        <th>Description</th>
	<td><input type="text" name="dc.description" size="40"/></td>
       </tr>
       <tr><td colspan="2">&nbsp;</td></tr>
       <tr>
        <th>Sort by</th>
	<td>
         <select name="_sort" size="1">
	  <option value="">[Do not sort]</option>
	  <option value="dc.title">Title</option>
	  <option value="dc.creator">Author</option>
	  <option value="net.host">Host</option>
	  <option value="net.port/numeric">Port</option>
	  <option value="net.path">Database</option>
	 </select>
	 <input type="checkbox" id="desc" name="_desc" value="1"/>
	 <label for="desc">descending?</label>
        </td>
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
