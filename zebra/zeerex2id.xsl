<?xml version="1.0" encoding="UTF-8"?>
<!-- $Id: zeerex2id.xsl,v 1.1 2006-05-24 16:17:12 mike Exp $ -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:e="http://explain.z3950.org/dtd/2.0/"
                version="1.0">
 <xsl:output method="text" encoding="UTF-8" omit-xml-declaration="yes"/>
 <xsl:template match="text()"/>
 <xsl:template match="//e:explain">
  <xsl:value-of select="concat(e:serverInfo/e:host, ':',
                               e:serverInfo/e:port, '/',
                               e:serverInfo/e:database)"/>
 </xsl:template>
</xsl:stylesheet>
