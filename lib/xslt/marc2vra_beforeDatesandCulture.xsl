<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:fn="http://www.w3.org/2005/xpath-functions"
	xmlns:marc="http://www.loc.gov/MARC21/slim"
	xmlns:mods="http://www.loc.gov/mods/v3"
	xmlns:vra="http://www.vraweb.org/vracore4.htm"
	xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
	
<xsl:param name="bibid"></xsl:param>
<xsl:param name="pid"></xsl:param>
<xsl:param name="work_pid"></xsl:param>
<xsl:param name="item_pid"></xsl:param>
<xsl:param name="work_or_image"></xsl:param>

<xsl:output method="xml" omit-xml-declaration="no" indent="yes"  encoding = "utf-8"  media-type="text/xml"/>

<xsl:template match="/">
	<vra:vra xmlns:vra="http://www.vraweb.org/vracore4.htm">
	<xsl:choose>
		<xsl:when test="$work_or_image='image'">
			<xsl:apply-templates select="//marc:record" mode="image"/>
		</xsl:when>
		<xsl:otherwise>
			<xsl:apply-templates select="//marc:record" mode="work"/>
		</xsl:otherwise>
	</xsl:choose>
</vra:vra><xsl:text>
</xsl:text>
</xsl:template>

<xsl:template match="marc:record" mode="work">
	<vra:work>
		<!--xsl:attribute name="xml:id">inu:inu-dil-<xsl:value-of select="marc:controlfield[@tag='001']"/>_w</xsl:attribute-->
		<xsl:attribute name="id">inu-dil-<xsl:value-of select="marc:controlfield[@tag='001']"/>_w</xsl:attribute>
		<!--xsl:attribute name="vra:refid">inu:inu-dil-<xsl:value-of select="marc:controlfield[@tag='001']"/></xsl:attribute-->
		
		<!-- Updated by Bill -->
		<!-- <xsl:attribute name="refid">inu:inu-dil-<xsl:value-of select="marc:controlfield[@tag='001']"/></xsl:attribute> -->

		<xsl:choose>
			<xsl:when test="$pid!=''"><xsl:attribute name="refid"><xsl:value-of select="$pid"/></xsl:attribute></xsl:when>
			<xsl:otherwise><xsl:attribute name="refid">inu:inu-dil-<xsl:value-of select="marc:controlfield[@tag='001']"/></xsl:attribute></xsl:otherwise>
		</xsl:choose>

		<xsl:call-template name="marc2vra"/>
	</vra:work>
</xsl:template>

<xsl:template match="marc:record" mode="image">
	<vra:image>
		<!--xsl:attribute name="xml:id">inu:inu-dil-<xsl:value-of select="marc:controlfield[@tag='001']"/>_w</xsl:attribute-->
		<xsl:attribute name="id">inu-dil-<xsl:value-of select="marc:controlfield[@tag='001']"/>_w</xsl:attribute>
		<!--xsl:attribute name="vra:refid">inu:inu-dil-<xsl:value-of select="marc:controlfield[@tag='001']"/></xsl:attribute-->
		<xsl:attribute name="refid">inu:inu-dil-<xsl:value-of select="marc:controlfield[@tag='001']"/></xsl:attribute>
		<xsl:call-template name="marc2vra"/>
	</vra:image>
</xsl:template>


<!-- Convert MARC to VRA without the enclosing vra:work or vra:item. These are provided by caller -->
<xsl:template name="marc2vra">
	<!-- ______________ Agents ______________ -->
	<xsl:if test="marc:datafield[@tag='100'][marc:subfield/@code='0' or marc:subfield/@code='a' or marc:subfield/@code='b' or marc:subfield/@code='c' or marc:subfield/@code='d' or marc:subfield/@code='g' or marc:subfield/@code='j' or marc:subfield/@code='q']
			or marc:datafield[@tag='110'][marc:subfield/@code='0' or marc:subfield/@code='a' or marc:subfield/@code='b' or marc:subfield/@code='g'] 
			or marc:datafield[@tag='700'][marc:subfield/@code='0' or marc:subfield/@code='a' or marc:subfield/@code='b' or marc:subfield/@code='c' or marc:subfield/@code='d' or marc:subfield/@code='g' or marc:subfield/@code='j' or marc:subfield/@code='q']
			or marc:datafield[@tag='710'][marc:subfield/@code='0' or marc:subfield/@code='a' or marc:subfield/@code='b' or marc:subfield/@code='g']"> 
		<xsl:call-template name="comment"><xsl:with-param name="comment">Agents</xsl:with-param></xsl:call-template>
		<vra:agentSet>
			<vra:display>
			<xsl:for-each select="marc:datafield[@tag='100'][marc:subfield/@code='0' or marc:subfield/@code='a' or marc:subfield/@code='b' or marc:subfield/@code='c' or marc:subfield/@code='d' or marc:subfield/@code='g' or marc:subfield/@code='j' or marc:subfield/@code='q']
			| marc:datafield[@tag='110'][marc:subfield/@code='0' or marc:subfield/@code='a' or marc:subfield/@code='b' or marc:subfield/@code='g'] 
			| marc:datafield[@tag='700'][marc:subfield/@code='0' or marc:subfield/@code='a' or marc:subfield/@code='b' or marc:subfield/@code='c' or marc:subfield/@code='d' or marc:subfield/@code='g' or marc:subfield/@code='j' or marc:subfield/@code='q']
			| marc:datafield[@tag='710'][marc:subfield/@code='0' or marc:subfield/@code='a' or marc:subfield/@code='b' or marc:subfield/@code='g']">
				<!--xsl:if test="position()!=1">;</xsl:if-->
				<xsl:if test="position()!=1"> ; </xsl:if>
				<xsl:apply-templates select="." mode="display"/>
			</xsl:for-each>
			</vra:display>
			<xsl:apply-templates select="marc:datafield[@tag='100'][marc:subfield/@code='0' or marc:subfield/@code='a' or marc:subfield/@code='b' or marc:subfield/@code='c' or marc:subfield/@code='d' or marc:subfield/@code='g' or marc:subfield/@code='j' or marc:subfield/@code='q']"/>
			<xsl:apply-templates select="marc:datafield[@tag='110'][marc:subfield/@code='0' or marc:subfield/@code='a' or marc:subfield/@code='b' or marc:subfield/@code='g']"/> 
			<xsl:apply-templates select="marc:datafield[@tag='700'][marc:subfield/@code='0' or marc:subfield/@code='a' or marc:subfield/@code='b' or marc:subfield/@code='c' or marc:subfield/@code='d' or marc:subfield/@code='g' or marc:subfield/@code='j' or marc:subfield/@code='q']"/>
			<xsl:apply-templates select="marc:datafield[@tag='710'][marc:subfield/@code='0' or marc:subfield/@code='a' or marc:subfield/@code='b' or marc:subfield/@code='g']"/>
		</vra:agentSet>
	</xsl:if>

	<!-- ______________ Dates ______________ -->
<!-- Now getting dates from 046/648; Bill Parod 1/31/2012; Commenting out 260/650/652 usage -->
<!--
	<xsl:if test="marc:datafield[@tag='260']/marc:subfield[@code='c'] | marc:datafield[@tag='650']/marc:subfield[@code='y'] | marc:datafield[@tag='651']/marc:subfield[@code='y']">
		<xsl:call-template name="comment"><xsl:with-param name="comment">Dates</xsl:with-param></xsl:call-template>
		<vra:dateSet>
			<vra:display>
			<xsl:for-each select="marc:datafield[@tag='260']/marc:subfield[@code='c']  | marc:datafield[@tag='650']/marc:subfield[@code='y']  | marc:datafield[@tag='651']/marc:subfield[@code='y']">
				<xsl:call-template name="displaySeparator"/>
				<xsl:call-template name="stripTrailingPeriod"><xsl:with-param name="val"><xsl:value-of select="."/></xsl:with-param></xsl:call-template>
			</xsl:for-each>
			</vra:display>
			<xsl:apply-templates select="marc:datafield[@tag='260']/marc:subfield[@code='c']"/>
			<xsl:apply-templates select="marc:datafield[@tag='650']/marc:subfield[@code='y']"/>
			<xsl:apply-templates select="marc:datafield[@tag='651']/marc:subfield[@code='y']"/>
		</vra:dateSet>
	</xsl:if>

-->
	<xsl:if test="marc:datafield[@tag='046']/marc:subfield[@code='s'] | marc:datafield[@tag='046']/marc:subfield[@code='t'] | marc:datafield[@tag='648']/marc:subfield[@code='s'] | marc:datafield[@tag='648']/marc:subfield[@code='t']
		| marc:datafield[@tag='260']/marc:subfield[@code='c'] | marc:datafield[@tag='650']/marc:subfield[@code='y'] | marc:datafield[@tag='651']/marc:subfield[@code='y']">
		<xsl:call-template name="comment"><xsl:with-param name="comment">Dates</xsl:with-param></xsl:call-template>
		<vra:dateSet>
			<vra:display>
			<xsl:for-each select="marc:datafield[@tag='260']/marc:subfield[@code='c']  | marc:datafield[@tag='650']/marc:subfield[@code='y']  | marc:datafield[@tag='651']/marc:subfield[@code='y']">
				<xsl:call-template name="displaySeparator"/>
				<xsl:call-template name="stripTrailingPeriod"><xsl:with-param name="val"><xsl:value-of select="."/></xsl:with-param></xsl:call-template>
			</xsl:for-each>
			</vra:display>

			<xsl:apply-templates select="marc:datafield[@tag='046']"/>
			<xsl:apply-templates select="marc:datafield[@tag='648']"/>
		</vra:dateSet>
	</xsl:if>

	<!-- ______________ Description ______________ -->
	<xsl:if test="marc:datafield[@tag='500']/marc:subfield[@code='a']">
		<xsl:call-template name="comment"><xsl:with-param name="comment">Description</xsl:with-param></xsl:call-template>
		<vra:descriptionSet>
			<vra:display>
			<xsl:for-each select="marc:datafield[@tag='500']/marc:subfield[@code='a']">
				<xsl:call-template name="displaySeparator"/>
				<xsl:value-of select="."/>
			</xsl:for-each>
			</vra:display>
			<xsl:apply-templates select="marc:datafield[@tag='500']/marc:subfield[@code='a']"/>
		</vra:descriptionSet>
	</xsl:if>

	<!-- ______________ Location ______________ -->
	<!-- Always have location because we always have a pid and probably have a bibid -->
<!--	<xsl:if test="marc:datafield[@tag='752']/marc:subfield[not(@code='g')] | marc:datafield[@tag='535']/marc:subfield[@code='a' or @code='b' ] "> -->
		<xsl:call-template name="comment"><xsl:with-param name="comment">Location</xsl:with-param></xsl:call-template>
		<vra:locationSet>
			<vra:display>
			<xsl:for-each select="marc:datafield[@tag='752'][marc:subfield/@code!='g'] | marc:datafield[@tag='535'][marc:subfield/@code='a' or marc:subfield/@code='b']">
				<xsl:call-template name="displaySeparator"/>
				<xsl:call-template name="stripTrailingPeriod"><xsl:with-param name="val"><xsl:apply-templates select="." mode="display"/></xsl:with-param></xsl:call-template>
			</xsl:for-each>

			<xsl:if test="$pid!=''"> ; DIL:<xsl:value-of select="$pid"/></xsl:if>
			<xsl:if test="$bibid!=''"> ; Voyager:<xsl:value-of select="$bibid"/></xsl:if>

			</vra:display>
			<xsl:for-each select="marc:datafield[@tag='752'][marc:subfield/@code!='g']">
				<vra:location type="discovery"><xsl:apply-templates select="marc:subfield[not(@code='g')]"/></vra:location>
			</xsl:for-each>
			<xsl:for-each select="marc:datafield[@tag='535'][marc:subfield/@code='a' or marc:subfield/@code='b']">
				<vra:location type="repository"><xsl:apply-templates select="marc:subfield[@code='a' or @code='b']"/></vra:location>
			</xsl:for-each>

			<xsl:if test="$pid!='' or $bibid!=''">
				<vra:location>
					<xsl:if test="$pid!=''"><vra:refid source="DIL"><xsl:value-of select="$pid"/></vra:refid></xsl:if>
					<xsl:if test="$bibid!=''"><vra:refid source="Voyager"><xsl:value-of select="$bibid"/></vra:refid></xsl:if>
				</vra:location>
            </xsl:if>

		</vra:locationSet>
	
	<!-- ______________ Materials ______________ -->
	<xsl:if test="marc:datafield[@tag='340']/marc:subfield[@code='a']">
		<xsl:call-template name="comment"><xsl:with-param name="comment">Materials</xsl:with-param></xsl:call-template>
		<vra:materialSet>
			<vra:display>
			<xsl:for-each select="marc:datafield[@tag='340']/marc:subfield[@code='a']">
				<xsl:call-template name="displaySeparator"/>
				<xsl:call-template name="stripTrailingPeriod"><xsl:with-param name="val"><xsl:value-of select="."/></xsl:with-param></xsl:call-template>
			</xsl:for-each>
			</vra:display>
			<xsl:apply-templates select="marc:datafield[@tag='340']/marc:subfield[@code='a']"/>
		</vra:materialSet>
	</xsl:if>

	<!-- ______________ Measurements ______________ -->
	<xsl:if test="marc:datafield[@tag='340']/marc:subfield[@code='b']">
		<xsl:call-template name="comment"><xsl:with-param name="comment">Measurements</xsl:with-param></xsl:call-template>
		<vra:measurementsSet>
			<vra:display>
			<xsl:for-each select="marc:datafield[@tag='340']/marc:subfield[@code='b']">
				<xsl:call-template name="displaySeparator"/>
				<xsl:value-of select="."/>
			</xsl:for-each>
			</vra:display>
			<xsl:apply-templates select="marc:datafield[@tag='340']/marc:subfield[@code='b']"/>
		</vra:measurementsSet>
	</xsl:if>


	<!-- ______________ Relation ______________ -->
   		<!-- Work and Image records are created from the same Marc record -->
		<xsl:variable name="rel_title"><xsl:for-each select="marc:datafield[@tag='245'][marc:subfield/@code='a' or marc:subfield/@code='p']">
				<xsl:call-template name="displaySeparator"/>
				<xsl:apply-templates select="."  mode="display"/>
			</xsl:for-each>
		</xsl:variable>

		<xsl:choose>
			<xsl:when test="$work_or_image='image' and $work_pid!=''">
				<xsl:call-template name="comment"><xsl:with-param name="comment">Relation</xsl:with-param></xsl:call-template>
   				<vra:relationSet>
					<vra:display><xsl:value-of select="$rel_title"/></vra:display>
      				<vra:relation pref="true" type="imageOf"><xsl:attribute name="relids"><xsl:value-of select="$work_pid"/></xsl:attribute><xsl:value-of select="$rel_title"/></vra:relation>
    			</vra:relationSet>
			</xsl:when>
			<xsl:when test="$work_or_image='work' and $item_pid!=''">
				<xsl:call-template name="comment"><xsl:with-param name="comment">Relation</xsl:with-param></xsl:call-template>
   				<vra:relationSet>
					<vra:display><xsl:value-of select="$rel_title"/></vra:display>
      				<vra:relation pref="true" type="imageIs"><xsl:attribute name="relids"><xsl:value-of select="$item_pid"/></xsl:attribute><xsl:value-of select="$rel_title"/></vra:relation>
    			</vra:relationSet>
			</xsl:when>
			<xsl:otherwise></xsl:otherwise>
		</xsl:choose>

	<!-- ______________ Source ______________ -->
	<xsl:if test="marc:datafield[@tag='773']/marc:subfield[@code='a']">
		<xsl:call-template name="comment"><xsl:with-param name="comment">Source</xsl:with-param></xsl:call-template>
		<vra:sourceSet>
			<vra:display>
			<xsl:for-each select="marc:datafield[@tag='773']/marc:subfield[@code='a' or @code='g']">
				<!--xsl:call-template name="displaySeparator"/-->
				<xsl:value-of select="."/>
				<xsl:text> </xsl:text>
			</xsl:for-each>
			</vra:display>
			<xsl:apply-templates select="marc:datafield[@tag='773']/marc:subfield[@code='a']"/>
		</vra:sourceSet>
	</xsl:if>

	<!-- ______________ Style/Period ______________ -->
	<!--xsl:if test="marc:datafield[@tag='653']/marc:subfield[@code='a'] or marc:datafield[@tag='655']/marc:subfield[@code='a']"-->
	<xsl:if test="marc:datafield[@tag='653']/marc:subfield[@code='a']">
		<xsl:call-template name="comment"><xsl:with-param name="comment">Style/Period</xsl:with-param></xsl:call-template>
		<vra:stylePeriodSet>
			<vra:display>
			<!--xsl:for-each select="marc:datafield[@tag='653']/marc:subfield[@code='a'] | marc:datafield[@tag='655']/marc:subfield[@code='a']"-->
			<xsl:for-each select="marc:datafield[@tag='653']/marc:subfield[@code='a']">
				<xsl:call-template name="displaySeparator"/>
				<xsl:call-template name="stripTrailingPeriod"><xsl:with-param name="val"><xsl:choose><xsl:when test="../marc:subfield[@code='v' or @code='x' or @code='y' or @code='z']"><xsl:value-of select="string-join((.,../marc:subfield[@code='v' or @code='x' or @code='y' or @code='z']),'--')"/></xsl:when><xsl:otherwise><xsl:value-of select="."/></xsl:otherwise></xsl:choose></xsl:with-param></xsl:call-template>
			</xsl:for-each>
			</vra:display>
			<!--xsl:for-each select="marc:datafield[@tag='655']/marc:subfield[@code='a' or @code='y' or @code='z']">
				<vra:stylePeriod><xsl:apply-templates select="../marc:subfield[@code='2']"/><xsl:call-template name="stripTrailingPeriod"><xsl:with-param name="val"><xsl:value-of select="."/></xsl:with-param></xsl:call-template></vra:stylePeriod>
			</xsl:for-each-->
			<xsl:for-each select="marc:datafield[@tag='653']/marc:subfield[@code='a']">
				<vra:stylePeriod><xsl:value-of select="."/></vra:stylePeriod>
			</xsl:for-each>
		</vra:stylePeriodSet>
	</xsl:if>


	<!-- ______________ SubjectSet ______________ --> <!-- or @tag='610' or @tag='650' or @tag='651'-->
	<xsl:if test="marc:datafield[@tag='600' or @tag='610' or @tag='650' or @tag='651']">
		<xsl:call-template name="comment"><xsl:with-param name="comment">Subjects</xsl:with-param></xsl:call-template>
		<vra:subjectSet>
			<vra:display>
			<xsl:for-each select="marc:datafield[@tag='600']/marc:subfield[@code='a' or @code='b' or @code='c' or @code='d' or @code='q'] | marc:datafield[@tag='610']/marc:subfield[@code='a' or @code='g'] | marc:datafield[@tag='650']/marc:subfield[@code='a' or @code='d'] | marc:datafield[@tag='651']/marc:subfield[@code='a']">
				<xsl:call-template name="displaySeparator"/>
				<xsl:call-template name="stripTrailingPeriod"><xsl:with-param name="val"><xsl:choose><xsl:when test="../marc:subfield[@code='v' or @code='x' or @code='y' or @code='z']"><xsl:value-of select="string-join((.,../marc:subfield[@code='v' or @code='x' or @code='y' or @code='z']),'--')"/></xsl:when><xsl:otherwise><xsl:value-of select="."/></xsl:otherwise></xsl:choose></xsl:with-param></xsl:call-template>
			</xsl:for-each>
			</vra:display>
			<xsl:apply-templates select="marc:datafield[@tag='600']/marc:subfield[@code='a' or @code='b' or @code='c' or @code='d' or @code='q']"/>
			<xsl:apply-templates select="marc:datafield[@tag='610']/marc:subfield[@code='a' or @code='g']"/>
			<xsl:apply-templates select="marc:datafield[@tag='650']/marc:subfield[@code='a' or @code='d']"/>
			<xsl:apply-templates select="marc:datafield[@tag='651']/marc:subfield[@code='a' or @code='x']"/>
		</vra:subjectSet>
	</xsl:if>

	<!-- ______________ Titles ______________ -->
	<xsl:if test="marc:datafield[@tag='245' or @tag='246']">
		<xsl:call-template name="comment"><xsl:with-param name="comment"> Titles </xsl:with-param></xsl:call-template>
		<vra:titleSet>
			<vra:display>
			<xsl:for-each select="marc:datafield[@tag='245'][marc:subfield/@code='a' or marc:subfield/@code='p']">
				<xsl:call-template name="displaySeparator"/>

				<!-- Changed by Bill Parod 1/22/2012 -->
				<!-- <xsl:apply-templates select="." /> -->
				<xsl:apply-templates select="."  mode="display"/>
			</xsl:for-each>
			</vra:display>
			<xsl:apply-templates select="marc:datafield[@tag='245'][marc:subfield/@code='a' or marc:subfield/@code='p']"/>
			<xsl:apply-templates select="marc:datafield[@tag='246'][marc:subfield/@code='a']"/>
		</vra:titleSet>
	</xsl:if>

<!--Added by Karen-->
<!-- ______________ WorkType ______________ -->
	<xsl:if test="marc:datafield[@tag='655']/marc:subfield[@code='a']">
		<xsl:call-template name="comment"><xsl:with-param name="comment">WorkType</xsl:with-param></xsl:call-template>
		<vra:worktypeSet>
			<vra:display>
			<xsl:for-each select="marc:datafield[@tag='655']/marc:subfield[@code='a']">
				<xsl:call-template name="displaySeparator"/>
				<xsl:call-template name="stripTrailingPeriod"><xsl:with-param name="val"><xsl:value-of select="."/></xsl:with-param></xsl:call-template>
			</xsl:for-each>
			</vra:display>
			<xsl:for-each select="marc:datafield[@tag='655']/marc:subfield[@code='a']">
				<vra:worktype><xsl:apply-templates select="../marc:subfield[@code='2']"/><xsl:call-template name="stripTrailingPeriod"><xsl:with-param name="val"><xsl:value-of select="."/></xsl:with-param></xsl:call-template></vra:worktype>
			</xsl:for-each>
		</vra:worktypeSet>
	</xsl:if>
</xsl:template>



<!-- agent display -->
<xsl:template match="marc:datafield[@tag='100']" mode="display">
	<xsl:call-template name="stripTrailingPeriod"><xsl:with-param name="val"><xsl:value-of select="marc:subfield[@code='a' or @code='b' or @code='c' or @code='d' or @code='g' or @code='j' or @code='q']"/></xsl:with-param></xsl:call-template>
</xsl:template>
<xsl:template match="marc:datafield[@tag='110']" mode="display">
	<xsl:call-template name="stripTrailingPeriod"><xsl:with-param name="val"><xsl:value-of select="marc:subfield[@code='a' or @code='b' or @code='g']"/></xsl:with-param></xsl:call-template>
</xsl:template>
<xsl:template match="marc:datafield[@tag='700']" mode="display">
	<xsl:call-template name="stripTrailingPeriod"><xsl:with-param name="val"><xsl:value-of select="marc:subfield[@code='a' or @code='b' or @code='c' or @code='d' or @code='g' or @code='j' or @code='q']"/></xsl:with-param></xsl:call-template>
</xsl:template>
<xsl:template match="marc:datafield[@tag='710']" mode="display">
	<xsl:call-template name="stripTrailingPeriod"><xsl:with-param name="val"><xsl:value-of select="marc:subfield[@code='a' or @code='b' or @code='g']"/></xsl:with-param></xsl:call-template>
</xsl:template>

<!-- agent -->
<xsl:template match="marc:datafield[@tag='100'or @tag='700']">
	<vra:agent>
		<vra:name type="personal" vocab="ulan"><xsl:apply-templates select="marc:subfield[@code='0']"/><xsl:call-template name="stripTrailingPeriod"><xsl:with-param name="val"><xsl:value-of select="marc:subfield[@code='a' or @code='b' or @code='c' or @code='g' or @code='j' or @code='q']"/></xsl:with-param></xsl:call-template></vra:name>
		<xsl:apply-templates select="marc:subfield[@code='d']" mode="agent"/>
	</vra:agent>
</xsl:template>
<xsl:template match="marc:datafield[@tag='110' or @tag='710']">
	<vra:agent>
		<vra:name type="corporate" vocab="ulan"><xsl:apply-templates select="marc:subfield[@code='0']"/><xsl:call-template name="stripTrailingPeriod"><xsl:with-param name="val"><xsl:value-of select="marc:subfield[@code='a' or @code='b' or @code='g']"/></xsl:with-param></xsl:call-template></vra:name>
	</vra:agent>
</xsl:template>

<xsl:template match="marc:subfield[@code='0']"><xsl:attribute name="refid"><xsl:value-of select="."/></xsl:attribute></xsl:template>

<!-- agent date -->
<!-- 	If there are two dates (i.e., 1942-2006), the first one goes in earliestDate. If there is only one date and it is followed by a single hypen (i.e., 1942-) then it goes here. 
		If there is only one date and it is preceded by text "b. " (i.e., b. 1889) then it goes in earliestDate. 
		If there are two dates (i.e., 1942-2006), the second one goes in latestDate. 
		If there is only one date and it is preceded by text "d. " (i.e., d. 1956) then it goes in latestDate.
		-->
<xsl:template match="marc:subfield[@code='d']" mode="agent">
<!-- <vra:dates type="life">
	<xsl:choose>
	<xsl:when test="contains(.,'-')">
		<xsl:variable name="uno"><xsl:value-of select="substring-before(.,'-')"/></xsl:variable>
		<xsl:variable name="dos"><xsl:value-of select="substring-after(.,'-')"/></xsl:variable>
		<xsl:if test="$uno!=''"><vra:earliestDate><xsl:value-of select="$uno"/></vra:earliestDate></xsl:if>
		<xsl:variable name="theDate"><xsl:call-template name="stripTrailingPeriod"><xsl:with-param name="val"><xsl:value-of select="$dos"/></xsl:with-param></xsl:call-template></xsl:variable>
		<xsl:if test="$theDate!=''"><vra:latestDate><xsl:value-of select="$theDate"/></vra:latestDate></xsl:if>
	</xsl:when>
	<xsl:when test="starts-with(.,'b')"><vra:earliestDate><xsl:value-of select="."/></vra:earliestDate></xsl:when>
	<xsl:when test="starts-with(.,'d')"><vra:latestDate><xsl:value-of select="."/></vra:latestDate></xsl:when>
	<xsl:otherwise><vra:earliestDate><xsl:value-of select="."/></vra:earliestDate></xsl:otherwise>
	</xsl:choose>
</vra:dates>
-->
</xsl:template>


<!-- titles -->
<xsl:template match="marc:datafield[@tag='245'][marc:subfield/@code='a' or marc:subfield/@code='p']">
	<vra:title pref="true"><xsl:call-template name="stripTrailingPeriod"><xsl:with-param name="val"><xsl:value-of select="marc:subfield[@code='a' or @code='p']"/></xsl:with-param></xsl:call-template></vra:title>
</xsl:template>

<!-- Added by Bill Parod 1/22/2012 -->
<xsl:template match="marc:datafield[@tag='245'][marc:subfield/@code='a' or marc:subfield/@code='p']" mode="display">
	<xsl:call-template name="stripTrailingPeriod"><xsl:with-param name="val"><xsl:value-of select="marc:subfield[@code='a' or @code='p']"/></xsl:with-param></xsl:call-template>
</xsl:template>

<xsl:template match="marc:datafield[@tag='246'][marc:subfield/@code='a']">
	<vra:title pref="false"><xsl:call-template name="stripTrailingPeriod"><xsl:with-param name="val"><xsl:value-of select="marc:subfield[@code='a']"/></xsl:with-param></xsl:call-template></vra:title>
</xsl:template>

<!-- date 046$s, 046$t, 648$s, and 648$t -->

<xsl:template match="marc:datafield[@tag='046']">
	<vra:date type="creation">
		<xsl:apply-templates select="marc:subfield[@code='s']" mode="earliestDate"/>
		<xsl:apply-templates select="marc:subfield[@code='t']" mode="latestDate"/>
	</vra:date>
</xsl:template>

<xsl:template match="marc:datafield[@tag='648']">
	<vra:date type="view">
		<xsl:apply-templates select="marc:subfield[@code='s']" mode="earliestDate"/>
		<xsl:apply-templates select="marc:subfield[@code='t']" mode="latestDate"/>
	</vra:date>
</xsl:template>


<xsl:template match="marc:subfield[@code='s']" mode="earliestDate">
		<vra:earliestDate><xsl:value-of select="."/></vra:earliestDate>
<!--
	<xsl:choose>
		<xsl:when test="contains(.,'/')">
			<vra:earliestDate><xsl:value-of select="substring-before(.,'/')"/></vra:earliestDate>
		</xsl:when>
		<xsl:otherwise>
			<vra:earliestDate><xsl:value-of select="."/></vra:earliestDate>
		</xsl:otherwise>
	</xsl:choose>
-->
</xsl:template>

<xsl:template match="marc:subfield[@code='t']" mode="latestDate">
			<vra:latestDate><xsl:value-of select="."/></vra:latestDate>
<!--	<xsl:choose>
		<xsl:when test="contains(.,'/')">
			<vra:latestDate><xsl:value-of select="substring-after(.,'/')"/></vra:latestDate>
		</xsl:when>
		<xsl:otherwise>
			<vra:latestDate><xsl:value-of select="."/></vra:latestDate>
		</xsl:otherwise>
	</xsl:choose>
-->
</xsl:template>

<!-- description -->
<xsl:template match="marc:datafield[@tag='500']/marc:subfield[@code='a']">
		<vra:description><xsl:value-of select="."/></vra:description>
</xsl:template>

<!-- location 752 display mode -->
<xsl:template match="marc:datafield[@tag='752'][marc:subfield/@code!='g']" mode="display"><xsl:value-of select="marc:subfield[not(@code='g')]"/></xsl:template>

<!-- location 535 display mode -->
<xsl:template match="marc:datafield[@tag='535'][marc:subfield/@code='a' or marc:subfield/@code='b']" mode="display"><xsl:value-of select="marc:subfield[@code='a' or @code='b']"/></xsl:template>


<!-- location 752$a -->
<xsl:template match="marc:datafield[@tag='752']/marc:subfield[@code='a']">
		<vra:name type="geographic" extent="Country or larger entity"><xsl:call-template name="stripTrailingPeriod"><xsl:with-param name="val"><xsl:value-of select="."/></xsl:with-param></xsl:call-template></vra:name>
</xsl:template>
<!-- location 752$b -->
<xsl:template match="marc:datafield[@tag='752']/marc:subfield[@code='b']">
		<vra:name type="geographic" extent="First-order political jurisdiction"><xsl:call-template name="stripTrailingPeriod"><xsl:with-param name="val"><xsl:value-of select="."/></xsl:with-param></xsl:call-template></vra:name>
</xsl:template>
<!-- location 752$c -->
<xsl:template match="marc:datafield[@tag='752']/marc:subfield[@code='c']">
		<vra:name type="geographic" extent="Intermediate political jurisdiction"><xsl:call-template name="stripTrailingPeriod"><xsl:with-param name="val"><xsl:value-of select="."/></xsl:with-param></xsl:call-template></vra:name>
</xsl:template>
<!-- location 752$d -->
<xsl:template match="marc:datafield[@tag='752']/marc:subfield[@code='d']">
		<vra:name type="geographic" extent="City"><xsl:call-template name="stripTrailingPeriod"><xsl:with-param name="val"><xsl:value-of select="."/></xsl:with-param></xsl:call-template></vra:name>
</xsl:template>


<!-- location 535$a -->
<xsl:template match="marc:datafield[@tag='535']/marc:subfield[@code='a']">
		<vra:name type="corporate"><xsl:call-template name="stripTrailingPeriod"><xsl:with-param name="val"><xsl:value-of select="."/></xsl:with-param></xsl:call-template></vra:name>
</xsl:template>
<!-- location 535$b -->
<xsl:template match="marc:datafield[@tag='535']/marc:subfield[@code='b']">
		<vra:name type="geographic"><xsl:call-template name="stripTrailingPeriod"><xsl:with-param name="val"><xsl:value-of select="."/></xsl:with-param></xsl:call-template></vra:name>
</xsl:template>


<!-- material -->
<xsl:template match="marc:datafield[@tag='340']/marc:subfield[@code='a']">
		<vra:material><xsl:call-template name="stripTrailingPeriod"><xsl:with-param name="val"><xsl:value-of select="."/></xsl:with-param></xsl:call-template></vra:material>
</xsl:template>

<!-- measurements -->
<xsl:template match="marc:datafield[@tag='340']/marc:subfield[@code='b']">
		<vra:measurements><xsl:value-of select="."/></vra:measurements>
</xsl:template>

<!-- description -->
<xsl:template match="marc:datafield[@tag='500']">
	<vra:descriptionSet>
		<vra:description type="creation"><xsl:value-of select="marc:subfield[@code='a']"/></vra:description>
	</vra:descriptionSet>
</xsl:template>


<!-- style/period vocab attribute -->
<xsl:template match="marc:subfield[@code='2']">
<xsl:attribute name="vocab"><xsl:value-of select="."/></xsl:attribute>
</xsl:template>

<!-- subjects -->
<xsl:template match="marc:datafield[@tag='600']/marc:subfield[@code='a' or @code='b' or @code='c' or @code='d' or @code='q']">
		<vra:subject><vra:term type="personalName"><xsl:apply-templates select="marc:subfield[@code='0']"/><xsl:apply-templates select="../marc:subfield[@code='2']"/><xsl:call-template name="stripTrailingPeriod"><xsl:with-param name="val"><xsl:value-of select="."/></xsl:with-param></xsl:call-template></vra:term></vra:subject>
</xsl:template>
<xsl:template match="marc:datafield[@tag='610']/marc:subfield[@code='a' or @code='g']">
		<vra:subject><vra:term type="corporateName"><xsl:apply-templates select="marc:subfield[@code='0']"/><xsl:apply-templates select="../marc:subfield[@code='2']"/><xsl:call-template name="stripTrailingPeriod"><xsl:with-param name="val"><xsl:value-of select="."/></xsl:with-param></xsl:call-template></vra:term></vra:subject>
</xsl:template>
<xsl:template match="marc:datafield[@tag='650']/marc:subfield[@code='a']">
		<vra:subject><vra:term type="descriptiveTopic"><xsl:apply-templates select="marc:subfield[@code='0']"/><xsl:apply-templates select="../marc:subfield[@code='2']"/><xsl:call-template name="stripTrailingPeriod"><xsl:with-param name="val"><xsl:value-of select="."/></xsl:with-param></xsl:call-template></vra:term></vra:subject>
</xsl:template>
<xsl:template match="marc:datafield[@tag='650']/marc:subfield[@code='d' or @code='v']">
		<vra:subject><vra:term type="otherTopic"><xsl:apply-templates select="marc:subfield[@code='0']"/><xsl:apply-templates select="../marc:subfield[@code='2']"/><xsl:call-template name="stripTrailingPeriod"><xsl:with-param name="val"><xsl:value-of select="."/></xsl:with-param></xsl:call-template></vra:term></vra:subject>
</xsl:template>
<xsl:template match="marc:datafield[@tag='650']/marc:subfield[@code='x']">
		<vra:subject><vra:term type="conceptTopic"><xsl:apply-templates select="marc:subfield[@code='0']"/><xsl:apply-templates select="../marc:subfield[@code='2']"/><xsl:call-template name="stripTrailingPeriod"><xsl:with-param name="val"><xsl:value-of select="."/></xsl:with-param></xsl:call-template></vra:term></vra:subject>
</xsl:template>
<xsl:template match="marc:datafield[@tag='651']/marc:subfield[@code='a']">
		<vra:subject><vra:term type="geographicPlace"><xsl:apply-templates select="marc:subfield[@code='0']"/><xsl:apply-templates select="../marc:subfield[@code='2']"/><xsl:call-template name="stripTrailingPeriod"><xsl:with-param name="val"><xsl:value-of select="."/></xsl:with-param></xsl:call-template></vra:term></vra:subject>
</xsl:template>
<xsl:template match="marc:datafield[@tag='651']/marc:subfield[@code='v']">
		<vra:subject><vra:term type="otherTopic"><xsl:apply-templates select="marc:subfield[@code='0']"/><xsl:apply-templates select="../marc:subfield[@code='2']"/><xsl:call-template name="stripTrailingPeriod"><xsl:with-param name="val"><xsl:value-of select="."/></xsl:with-param></xsl:call-template></vra:term></vra:subject>
</xsl:template>
<xsl:template match="marc:datafield[@tag='651']/marc:subfield[@code='x']">
		<vra:subject><vra:term type="conceptTopic"><xsl:apply-templates select="marc:subfield[@code='0']"/><xsl:apply-templates select="../marc:subfield[@code='2']"/><xsl:call-template name="stripTrailingPeriod"><xsl:with-param name="val"><xsl:value-of select="."/></xsl:with-param></xsl:call-template></vra:term></vra:subject>
</xsl:template>
<xsl:template match="marc:datafield[@tag='651']/marc:subfield[@code='z']">
		<vra:subject><vra:term type="geographicPlace"><xsl:apply-templates select="marc:subfield[@code='0']"/><xsl:apply-templates select="../marc:subfield[@code='2']"/><xsl:call-template name="stripTrailingPeriod"><xsl:with-param name="val"><xsl:value-of select="."/></xsl:with-param></xsl:call-template></vra:term></vra:subject>
</xsl:template>


<!-- location -->
<xsl:template match="marc:datafield[@tag='650']">
		<vra:location><vra:name><xsl:value-of select="marc:subfield[@code='a' or @code='d' or @code='v' or @code='x' or @code='y' or @code='z']"/></vra:name></vra:location>
</xsl:template>
<xsl:template match="marc:datafield[@tag='651']">
		<vra:location><vra:name><xsl:value-of select="marc:subfield[@code='a']"/></vra:name></vra:location>
</xsl:template>

<!-- source -->
<xsl:template match="marc:datafield[@tag='773']/marc:subfield[@code='a']">
		<vra:source><vra:name><xsl:value-of select="."/></vra:name></vra:source>
</xsl:template>

<!-- comment -->
<xsl:template name="comment">
<xsl:param name="comment"/>
<xsl:text>

</xsl:text>
				<xsl:comment> 				<xsl:value-of select="$comment"/> 				</xsl:comment>
				<xsl:text>
      </xsl:text>
</xsl:template>

<xsl:template name="displaySeparator">
<xsl:if test="position()!=1"><xsl:text> </xsl:text>;<xsl:text> </xsl:text></xsl:if>
</xsl:template>


<xsl:template name="stripTrailingPeriod">
<!--	<xsl:param name="val"/><xsl:analyze-string select="$val" regex="(.+)\.\s*$" flags="i"> -->
	<xsl:param name="val"/><xsl:analyze-string select="$val" regex="(.*)\.\s*$" flags="i">
	<xsl:matching-substring><xsl:value-of select="regex-group(1)"/></xsl:matching-substring>
 	<xsl:non-matching-substring><xsl:value-of select="$val"/></xsl:non-matching-substring>
	</xsl:analyze-string></xsl:template>



<xsl:template match="*|text()"/>

</xsl:stylesheet>

