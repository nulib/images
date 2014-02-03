<xsl:transform version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output media-type="text/xml" omit-xml-declaration="no"/>

<xsl:template match="*|@*|text()">
<xsl:copy>
<xsl:apply-templates select="*|@*|text()"/>
</xsl:copy>
</xsl:template>

</xsl:transform>

