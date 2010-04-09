<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:z="http://indexdata.com/zebra-2.0"
                xmlns:e="http://explain.z3950.org/dtd/2.0/"
                xmlns:i="http://indexdata.com/irspy/1.0"
                version="1.0">
 <xsl:output indent="yes" method="xml" version="1.0" encoding="UTF-8"/>
 <xsl:template match="text()"/>
 <xsl:template match="//e:explain">
  <xsl:variable name="id"><xsl:value-of select="concat(
	e:serverInfo/@protocol, ':',
	e:serverInfo/e:host, ':',
	e:serverInfo/e:port, '/',
	e:serverInfo/e:database)"/></xsl:variable>
  <z:record z:id="{$id}" type="update">
   <z:index name="dc:title:w">
    <xsl:value-of select="e:databaseInfo/e:title"/>
   </z:index>
  </z:record>
 </xsl:template>
</xsl:stylesheet>
