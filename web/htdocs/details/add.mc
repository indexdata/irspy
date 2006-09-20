%# $Id: add.mc,v 1.1 2006-09-20 16:49:46 mike Exp $
<%perl>
if ($r->param("_add")) {
    my $host = $r->param("net.host");
    my $port = $r->param("net.port");
    my $db = $r->param("net.path");
    my $id = "$host:$port/$db";
    $r->param(id => $id);
    $m->comp("check.mc");
} else {
</%perl>
     <p>
      Enter the connection details of the target you wish to add,
      then press the <b>Add</b> button.
     </p>
     <form>
      <table class="searchform">
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
        <th/>
        <th><input type="submit" name="_add" value="Add"/></th>
       </tr>
      </table>
     </form>
% }
