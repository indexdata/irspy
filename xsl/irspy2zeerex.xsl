<?xml version="1.0"?>
<!-- $Id: irspy2zeerex.xsl,v 1.1 2006-10-26 13:39:13 sondberg Exp $ -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    version="1.0">

  <xsl:output indent="yes"
      method="xml"
      version="1.0"
      encoding="UTF-8"/>

  <!-- identity stylesheet -->
  <xsl:template match="/">
    <xsl:copy-of select="/"/>
  </xsl:template>


</xsl:stylesheet>
