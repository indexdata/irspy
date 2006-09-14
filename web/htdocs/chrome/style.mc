/* $Id: style.mc,v 1.1 2006-09-14 15:17:48 mike Exp $ */
body {
  color: darkblue;
  background: white;
}

.banner { background: yellow }
.panel1 { background: lightblue }
.panel2 { background: lightgreen }
.panel3 { background: pink }

<%doc>Fixing the layout</%doc>
.panel1, .panel2 { width: 100px }
.spacer { width: 1em }

<%doc>Why isn't this the default?</%doc>
img { border: 0 }

<%doc>These are just so we can set alignment in an XHTMLish way</%doc>
.left   { text-align: left }
.center { text-align: center }
.right  { text-align: right }
