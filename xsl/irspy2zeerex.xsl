<?xml version="1.0"?>
<!--
    $Id: irspy2zeerex.xsl,v 1.4 2006-10-27 12:27:38 sondberg Exp $

    This stylesheet is used by IRSpy to map the internal mixed Zeerex/IRSpy
    record format into the Zeerex record which we store.

-->
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:irspy="http://indexdata.com/irspy/1.0"
    xmlns="http://explain.z3950.org/dtd/2.0/"
    xmlns:explain="http://explain.z3950.org/dtd/2.0/"
    exclude-result-prefixes="irspy explain"
    version="1.0">

  <xsl:output indent="yes"
      method="xml"
      version="1.0"
      encoding="UTF-8"/>

  <xsl:preserve-space elements="*"/>

  <xsl:variable name="old_indexes" select="/*/explain:indexInfo/explain:index"/>
  <xsl:variable name="old_syntaxes" select="/*/explain:recordInfo"/>


  <xsl:template match="node() | @*">
    <xsl:copy>
      <xsl:apply-templates select="@* | node()"/>
    </xsl:copy>
  </xsl:template>


  <xsl:template match="explain:indexInfo">
    <indexInfo>
      <xsl:for-each select="/*/irspy:status/irspy:search">
        <xsl:variable name="set" select="@set"/>
        <xsl:variable name="ap" select="@ap"/>
        <xsl:variable name="old"
            select="$old_indexes[explain:map/explain:attr/@set = $set and
                                 explain:map/explain:attr/text() = $ap]"/>
        <xsl:choose>
          <xsl:when test="$old">
            <xsl:call-template name="insert-index-section">
              <xsl:with-param name="title" select="$old/explain:title"/>
            </xsl:call-template>
          </xsl:when>
          <xsl:otherwise>
            <xsl:call-template name="insert-index-section"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:for-each>
    </indexInfo>
  </xsl:template>


  <xsl:template match="explain:recordInfo">
    <recordInfo>
      <xsl:for-each select="/*/irspy:status/irspy:record_fetch[@ok = 1]">
        <recordSyntax name="{@syntax}">
          <elementSet name="F"/> <!-- FIXME: This should be probed too -->
        </recordSyntax>
      </xsl:for-each>
    </recordInfo>
  </xsl:template>


  <xsl:template name="insert-index-section">
    <xsl:param name="update" select="."/>
    <xsl:param name="title">
      <xsl:call-template name="insert-index-title">
        <xsl:with-param name="update" select="$update"/>
      </xsl:call-template>
    </xsl:param>

    <index>
      <xsl:attribute name="search">
        <xsl:choose>
          <xsl:when test="$update/@ok = 1">true</xsl:when>
          <xsl:otherwise>false</xsl:otherwise>
        </xsl:choose>
      </xsl:attribute>
      <title primary="true" lang="en">
        <xsl:value-of select="$title"/>
      </title>
      <map primary="true">
        <attr type="1" set="{$update/@set}">
          <xsl:value-of select="$update/@ap"/>
        </attr>
      </map>
    </index>
  </xsl:template>


  <xsl:template name="insert-index-title">
    <xsl:param name="update"/>
    <xsl:value-of select="$update/@ap"/>
  </xsl:template>


  <xsl:template match="explain:dateModified">
    <dateModified><xsl:value-of
                    select="/*/irspy:status/*[last()]"/></dateModified>
  </xsl:template>


</xsl:stylesheet>
