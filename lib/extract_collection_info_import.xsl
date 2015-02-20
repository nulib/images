<xsl:stylesheet version="1.0"
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  
  <xsl:output method="xml" omit-xml-declaration="no" encoding="utf-8"/>
  <xsl:template match="/">
    <importXml>
      <xsl:apply-templates/>
    </importXml>
  </xsl:template>
  <xsl:template match="MDID/SlideshowProperties">	
    <title>
      <xsl:value-of select="title"/>
    </title>
    <owner>
      <xsl:value-of select="owner"/>
    </owner>
  </xsl:template>
  <xsl:template match="MDID/Slides/Slide/catalogdata/fields/field[@name='Accession Number']">
    <accessionNumber>
        <xsl:value-of select="."/>
      </accessionNumber>
  </xsl:template>
  <xsl:template match="text()|@*"></xsl:template>
  
</xsl:stylesheet>
