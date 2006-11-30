/* $Id: style.mc,v 1.12 2006-11-30 12:50:20 mike Exp $ */
body {
  color: black;
  background: white;
}

blockquote {
  background: #ffffc0;
  margin: 1em 3em;
  padding: 0.5em;
}

.banner { background: url(/beach.jpeg) }
.logo { text-decoration: none; color: white; margin-left: 1em }
.title { color: black; margin-right: 1em }
.panel1 { background: #d4e7f3; padding: 0em 1em; }
.panel1 a { text-decoration: none }
.panel3 { background: #b4c7d3 }

<%doc>Fixing the layout</%doc>
.panel1 { width: 9em }
.spacer { width: 1em }

.panel2 {
  background: #b0d0ff;
  margin: -0.5em;
  padding: 0.5em;
}

<%doc>Why isn't this the default?</%doc>
img { border: 0 }

<%doc>These are just so we can set alignment in an XHTMLish way</%doc>
.left   { text-align: left }
.center { text-align: center }
.right  { text-align: right }

.searchform tr th { text-align: right; padding-right: 0.5em }
.searchform tr td input { background: #ffffc0 }
.searchform tr td select { background: #ffffc0 }

.fullrecord { background: #ffffee }
.fullrecord th { text-align: left }

.thleft th { text-align: left }

.disabled { color: grey }
.error { color: red; font-weight: bold }
