<?xml version="1.0" encoding="UTF-8"?>
<!-- $Id: zeerex2index.xsl,v 1.2 2006-05-12 22:04:34 mike Exp $ -->
<!-- See the ZeeRex profile at http://srw.cheshire3.org/profiles/ZeeRex/ -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:z="http://indexdata.dk/zebra/xslt/1"
                xmlns:e="http://explain.z3950.org/dtd/2.0/"
                version="1.0">
 <xsl:output indent="yes" method="xml" version="1.0" encoding="UTF-8"/>
 <!-- disable all default text node output -->
 <xsl:template match="text()"/>
 <!-- match on alvis xml record -->
 <xsl:template match="//e:explain">
  <z:record id="{concat(
		e:serverInfo/e:host, ':',
		e:serverInfo/e:port, '/',
		e:serverInfo/e:database)}"
	    type="update">

   <z:index name="rec:id" type="0">
    <xsl:value-of select="concat(
			  e:serverInfo/e:host, ':',
			  e:serverInfo/e:port, '/',
			  e:serverInfo/e:database)"/>
   </z:index>
   <z:index name="net:protocol" type="w">
    <xsl:value-of select="e:serverInfo/@protocol"/>
   </z:index>
   <z:index name="net:version" type="0">
    <xsl:value-of select="e:serverInfo/@version"/>
   </z:index>
   <z:index name="net:method" type="w">
    <xsl:value-of select="e:serverInfo/@method"/>
   </z:index>
   <z:index name="net:host" type="0">
    <xsl:value-of select="e:serverInfo/e:host"/>
   </z:index>
   <z:index name="net:port" type="0">
    <xsl:value-of select="e:serverInfo/e:port"/>
   </z:index>
   <z:index name="net:path" type="0">
    <xsl:value-of select="e:serverInfo/e:database"/>
   </z:index>

   <z:index name="dc:title" type="w">
    <xsl:value-of select="e:databaseInfo/e:title"/>
   </z:index>
   <z:index name="dc:creator" type="w">
    <xsl:value-of select="e:databaseInfo/e:author"/>
   </z:index>

   <!-- ### index-name will be wrong -->
   <z:index name="rec:date-modified" type="d">
    <!-- ### Can Zebra handle this ISO-format date? -->
    <xsl:value-of select="e:metaInfo/e:dateModified"/>
   </z:index>

   <!-- ### indexes -->

   <!-- ### index-name will be wrong -->
   <z:index name="zeerex:recordSyntax" type="0">
    <xsl:value-of select="e:recordInfo/recordSyntax/@name"/>
   </z:index>
   <!-- ### schemas -->

   <!-- ### supportsInfo -->
  </z:record>
 </xsl:template>
</xsl:stylesheet>
