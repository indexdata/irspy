/* $Id: style.mc,v 1.6 2006-09-20 11:37:33 mike Exp $ */
body {
  color: black;
  background: white;
}

.banner { background: white }
.panel1, .panel2 { background: #d4e7f3; padding: 0em 1em; }
.panel3 { background: #b4c7d3 }

<%doc>Fixing the layout</%doc>
.panel1, .panel2 { width: 100px }
.spacer { width: 1em }

<%doc>Why isn't this the default?</%doc>
img { border: 0 }

<%doc>These are just so we can set alignment in an XHTMLish way</%doc>
.left   { text-align: left }
.center { text-align: center }
.right  { text-align: right }

.searchform tr th { text-align: right; padding-right: 0.5em }
.searchform tr td input { background: #ffffc0 }
.searchform tr td select { background: #ffffc0 }

.thleft th { text-align: left }

.disabled { color: grey }
.error { color: red; font-weight: bold }
