<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:fn="http://www.w3.org/2005/xpath-functions" xmlns:marc="http://www.loc.gov/MARC21/slim"
	xmlns:mods="http://www.loc.gov/mods/v3" xmlns:vra="http://www.vraweb.org/vracore4.htm"
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	xmlns:madsrdf="http://www.loc.gov/mads/rdf/v1#"
	xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">

	<xsl:param name="bibid" select="//marc:controlfield[@tag='001']"/>
	<xsl:param name="pid"/>
	<xsl:param name="work_pid"/>
	<xsl:param name="item_pid"/>
	<xsl:param name="work_or_image"/>

	<xsl:output method="xml" omit-xml-declaration="no" indent="yes" encoding="utf-8"
		media-type="text/xml"/>

	<xsl:template match="/">
		<xsl:processing-instruction name="xml-stylesheet">
			<xsl:text>type="text/css" href="vraCore.css"</xsl:text>
		</xsl:processing-instruction>
		<vra:vra xmlns:vra="http://www.vraweb.org/vracore4.htm"
			xsi:schemaLocation="http://www.vraweb.org/vracore4.htm http://www.vraweb.org/projects/vracore4/vra-4.0-restricted.xsd">
			<xsl:choose>
				<xsl:when test="$work_or_image='image'">
					<xsl:apply-templates select="//marc:record" mode="image"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:apply-templates select="//marc:record" mode="work"/>
				</xsl:otherwise>
			</xsl:choose>
		</vra:vra>
		<xsl:text>
		</xsl:text>
	</xsl:template>

	<!--Added by Karen 4/8/2014-->
	<xsl:variable name="lang008">
		<xsl:value-of select="substring(marc:controlfield[@tag='008'],36,3)"/>
	</xsl:variable>

	<xsl:template match="marc:record" mode="work">
		<vra:work>
			<xsl:attribute name="id">inu-dil-<xsl:value-of select="marc:controlfield[@tag='001']"
				/>_w</xsl:attribute>

			<!-- Updated by Bill -->
			<xsl:choose>
				<xsl:when test="$pid!=''">
					<xsl:attribute name="refid">
						<xsl:value-of select="$pid"/>
					</xsl:attribute>
				</xsl:when>
				<xsl:otherwise>
					<xsl:attribute name="refid">inu:inu-dil-<xsl:value-of
							select="marc:controlfield[@tag='001']"/></xsl:attribute>
				</xsl:otherwise>
			</xsl:choose>

			<xsl:call-template name="marc2vra"/>
		</vra:work>
	</xsl:template>

	<xsl:template match="marc:record" mode="image">
		<vra:image>
			<xsl:attribute name="id">inu-dil-<xsl:value-of select="marc:controlfield[@tag='001']"
				/>_w</xsl:attribute>
			<xsl:attribute name="refid">inu:inu-dil-<xsl:value-of
					select="marc:controlfield[@tag='001']"/></xsl:attribute>
			<xsl:call-template name="marc2vra"/>
		</vra:image>
	</xsl:template>


	<!-- Convert MARC to VRA without the enclosing vra:work or vra:item. These are provided by caller -->
	<!-- Added 100e, 110e, 710e, 710cdne, 711 adcn, 264b Jen 04/08/2014 -->
	<xsl:template name="marc2vra">
		<!-- ______________ Agents ______________ -->
		<xsl:choose>
			<xsl:when
			test="marc:datafield[@tag='100'][marc:subfield/@code='0' or marc:subfield/@code='a' or marc:subfield/@code='b' or marc:subfield/@code='c' or marc:subfield/@code='d' or marc:subfield/@code='e' or marc:subfield/@code='g' or marc:subfield/@code='j' or marc:subfield/@code='q']
			or marc:datafield[@tag='110'][marc:subfield/@code='0' or marc:subfield/@code='a' or marc:subfield/@code='b' or marc:subfield/@code='e' or marc:subfield/@code='g']
			or marc:datafield[@tag='700'][marc:subfield/@code='0' or marc:subfield/@code='a' or marc:subfield/@code='b' or marc:subfield/@code='c' or marc:subfield/@code='d' or marc:subfield/@code='e' or marc:subfield/@code='g' or marc:subfield/@code='j' or marc:subfield/@code='q']
			or marc:datafield[@tag='710'][marc:subfield/@code='0' or marc:subfield/@code='a' or marc:subfield/@code='b' or marc:subfield/@code='c' or marc:subfield/@code='d' or marc:subfield/@code='e' or marc:subfield/@code='g' or marc:subfield/@code='n']
			or marc:datafield[@tag='711'][marc:subfield/@code='0' or marc:subfield/@code='a' or marc:subfield/@code='c' or marc:subfield/@code='d' or marc:subfield/@code='n']
			"	>
			<xsl:call-template name="comment">
				<xsl:with-param name="comment">Agents</xsl:with-param>
			</xsl:call-template>
			<vra:agentSet>
				<vra:display>
					<xsl:for-each
						select="marc:datafield[@tag='100'][marc:subfield/@code='0' or marc:subfield/@code='a' or marc:subfield/@code='b' or
						marc:subfield/@code='c' or marc:subfield/@code='d' or marc:subfield/@code='e' or marc:subfield/@code='g' or
						marc:subfield/@code='j' or marc:subfield/@code='q']
						| marc:datafield[@tag='110'][marc:subfield/@code='0' or marc:subfield/@code='a' or marc:subfield/@code='b' or
						marc:subfield/@code='e' or marc:subfield/@code='g']
						| marc:datafield[@tag='700'][marc:subfield/@code='0' or marc:subfield/@code='a' or marc:subfield/@code='b' or
						marc:subfield/@code='c' or marc:subfield/@code='d' or marc:subfield/@code='e' or marc:subfield/@code='g' or marc:subfield/@code='j' or
						marc:subfield/@code='q']
						| marc:datafield[@tag='710'][marc:subfield/@code='0' or marc:subfield/@code='a' or marc:subfield/@code='b' or marc:subfield/@code='c'
						or marc:subfield/@code='d' or marc:subfield/@code='e' or marc:subfield/@code='g' or marc:subfield/@code='n']
						| marc:datafield[@tag='711'][marc:subfield/@code='0' or marc:subfield/@code='a' or
						marc:subfield/@code='c' or marc:subfield/@code='d' or marc:subfield/@code='n'] ">
						<xsl:call-template name="displaySeparator"/>
						<xsl:apply-templates select="." mode="display"/>
					</xsl:for-each>
				</vra:display>
				<xsl:apply-templates
					select="marc:datafield[@tag='100'][marc:subfield/@code='0' or marc:subfield/@code='a' or marc:subfield/@code='b' or
					marc:subfield/@code='c' or marc:subfield/@code='d' or marc:subfield/@code='e' or marc:subfield/@code='g' or marc:subfield/@code='j'
					or marc:subfield/@code='q']"/>
				<xsl:apply-templates
					select="marc:datafield[@tag='110'][marc:subfield/@code='0' or marc:subfield/@code='a' or marc:subfield/@code='b' or marc:subfield/@code='e'
					or marc:subfield/@code='g']"/>
				<xsl:apply-templates
					select="marc:datafield[@tag='700'][marc:subfield/@code='0' or marc:subfield/@code='a' or marc:subfield/@code='b' or
					marc:subfield/@code='c' or marc:subfield/@code='d' or marc:subfield/@code='g' or marc:subfield/@code='j' or marc:subfield/@code='q']"/>
				<xsl:apply-templates
					select="marc:datafield[@tag='710'][marc:subfield/@code='0' or marc:subfield/@code='a'
					or marc:subfield/@code='b' or marc:subfield/@code='g']"/>
				<xsl:apply-templates
					select="marc:datafield[@tag='711'][marc:subfield/@code='0' or marc:subfield/@code='a'
					or marc:subfield/@code='c' or marc:subfield/@code='d' or marc:subfield/@code='n' ]"/>
				<!--Team decision to remove Publisher from facets as well as from display field-->
				<!--xsl:apply-templates
					select="marc:datafield[@tag='260'][marc:subfield/@code='b']"/-->
				<!--xsl:apply-templates
					select="marc:datafield[@tag='264'][marc:subfield/@code='b']"/-->
			</vra:agentSet>
		</xsl:when>
		<xsl:otherwise>
			<xsl:call-template name="addEmptyAgentSet"/>
		</xsl:otherwise>
		</xsl:choose>

		<!-- added by Mike - 3/12/2012-->
		<xsl:call-template name="addEmptyCulturalContextSet"/>
		<!-- Mike -->

		<!--Karen added test for 260 (and 264) with missing decades & moved previous code to named template publicationDate-->
		<xsl:if
			test="marc:datafield[@tag='046']/marc:subfield[@code='s'] | marc:datafield[@tag='046']/marc:subfield[@code='t']
			| marc:datafield[@tag='260']/marc:subfield[@code='c'] | marc:datafield[@tag='264']/marc:subfield[@code='c'] ">
			<xsl:call-template name="comment">
				<xsl:with-param name="comment">Dates</xsl:with-param>
			</xsl:call-template>
			<vra:dateSet>
				<vra:display>
					<xsl:choose>
						<xsl:when test="marc:datafield[@tag='260']/marc:subfield[@code='c']">
							<xsl:call-template name="publicationDate">
								<xsl:with-param name="thisC">
									<xsl:value-of
										select="marc:datafield[@tag='260']/marc:subfield[@code='c']"/>
								</xsl:with-param>
							</xsl:call-template>
						</xsl:when>
						<!--If there are multiple 264$cs, take only one, in this order of preference: 1,4,0,3,2-->
						<xsl:when test="marc:datafield[@tag='264' and @ind2='1']/marc:subfield[@code='c']">
							<xsl:call-template name="publicationDate">
								<xsl:with-param name="thisC">
									<xsl:value-of select="marc:datafield[@tag='264' and @ind2='1']/marc:subfield[@code='c']"/>
								</xsl:with-param>
							</xsl:call-template>
						</xsl:when>
						<xsl:when test="marc:datafield[@tag='264' and @ind2='4']/marc:subfield[@code='c']">
							<xsl:call-template name="publicationDate">
								<xsl:with-param name="thisC">
									<xsl:value-of select="marc:datafield[@tag='264' and @ind2='4']/marc:subfield[@code='c']"/>
								</xsl:with-param>
							</xsl:call-template>
						</xsl:when>
						<xsl:when test="marc:datafield[@tag='264' and @ind2='0']/marc:subfield[@code='c']">
							<xsl:call-template name="publicationDate">
								<xsl:with-param name="thisC">
									<xsl:value-of select="marc:datafield[@tag='264' and @ind2='0']/marc:subfield[@code='c']"/>
								</xsl:with-param>
							</xsl:call-template>
						</xsl:when>
						<xsl:when test="marc:datafield[@tag='264' and @ind2='3']/marc:subfield[@code='c']">
							<xsl:call-template name="publicationDate">
								<xsl:with-param name="thisC">
									<xsl:value-of select="marc:datafield[@tag='264' and @ind2='3']/marc:subfield[@code='c']"/>
								</xsl:with-param>
							</xsl:call-template>
						</xsl:when>
						<xsl:otherwise>
							<xsl:call-template name="publicationDate">
								<xsl:with-param name="thisC">
									<xsl:value-of select="marc:datafield[@tag='264' and @ind2='2']/marc:subfield[@code='c']"/>
								</xsl:with-param>
							</xsl:call-template>
						</xsl:otherwise>
					</xsl:choose>
				</vra:display>
				<xsl:choose>
					<xsl:when test="marc:datafield[@tag='046'] or marc:datafield[@tag='648']">
						<xsl:apply-templates select="marc:datafield[@tag='046']"/>
						<xsl:apply-templates select="marc:datafield[@tag='648']"/>
					</xsl:when>
					<xsl:otherwise>
						<vra:date type="creation">
							<vra:earliestDate>0000</vra:earliestDate>
							<vra:latestDate>0000</vra:latestDate>
						</vra:date>
					</xsl:otherwise>
				</xsl:choose>
			</vra:dateSet>
		</xsl:if>


		<!-- ______________ Description ______________ -->
		<!-- 505 and 506 added by Brendan, Added 520; 546 notes returned True (Radhi) ; removed 546 & replaced with conditional at bottom (Karen)-->
		<!--Karen added 008, 041, and 562.-->
		<xsl:if test="marc:datafield[@tag='500']/marc:subfield[@code='a'] or marc:datafield[@tag='505']/marc:subfield[@code='a'] or marc:datafield[@tag='520']/marc:subfield[@code='a']
			| marc:controlfield[@tag='008'] | marc:datafield[@tag='041'] | marc:datafield[@tag='546'] | marc:datafield[@tag='562']/marc:subfield[@code='b']">
			<xsl:call-template name="comment">
				<xsl:with-param name="comment">Description</xsl:with-param>
			</xsl:call-template>

			<xsl:variable name="noteCount">
				<xsl:value-of select="count(//marc:datafield[@tag='500' or @tag='505' or @tag='520'])"/>
			</xsl:variable>

			<!--Generate a holding place for 546 notes for records with language code 'bnt'-->
			<xsl:variable name="languageNote">
				<xsl:if test="$lang008='bnt' or marc:datafield[@tag='041']/marc:subfield[@code='a']='bnt' or marc:datafield[@tag='041']/marc:subfield[@code='h']='bnt'">
					<xsl:value-of select="marc:datafield[@tag='546']/marc:subfield[@code='a']"/>
				</xsl:if>
			</xsl:variable>
			<!--Karen-->
			<vra:descriptionSet>
				<vra:display>
					<xsl:for-each select="marc:datafield[@tag='500']/marc:subfield[@code='a'] | marc:datafield[@tag='505']/marc:subfield[@code='a']
						| marc:datafield[@tag='520']/marc:subfield[@code='a'] | marc:datafield[@tag='562']/marc:subfield[@code='b']">
						<xsl:call-template name="displaySeparator"/>
						<xsl:value-of select="."/>
					</xsl:for-each>
					<xsl:if test="$noteCount>0">
						<xsl:text> </xsl:text>;<xsl:text> </xsl:text>
					</xsl:if>
					<xsl:call-template name="buildLanguageNote"/>
					<xsl:if test="$languageNote!=''">
						<xsl:if test="$noteCount>0">
							<xsl:text> </xsl:text>;<xsl:text> </xsl:text>
						</xsl:if>
						<xsl:value-of select="$languageNote"/>
					</xsl:if>
				</vra:display>
				<vra:notes>
					<xsl:for-each select="marc:datafield[@tag='500']/marc:subfield[@code='a'] | marc:datafield[@tag='505']/marc:subfield[@code='a']
						| marc:datafield[@tag='520']/marc:subfield[@code='a'] | marc:datafield[@tag='562']/marc:subfield[@code='b']">
						<xsl:call-template name="displaySeparator"/>
						<xsl:value-of select="."/>
					</xsl:for-each>
					<xsl:if test="$languageNote!=''">
						<xsl:if test="$noteCount>0">
							<xsl:text> </xsl:text>;<xsl:text> </xsl:text>
						</xsl:if>
						<xsl:value-of select="$languageNote"></xsl:value-of>
					</xsl:if>
					<!--new code from April 1-4 ends here-->
					<xsl:if test="$noteCount>0">
						<xsl:text> </xsl:text>;<xsl:text> </xsl:text>
					</xsl:if>
					<xsl:call-template name="buildLanguageNote"/>
				</vra:notes>
				<xsl:apply-templates select="marc:datafield[@tag='500']/marc:subfield[@code='a']"/>
				<xsl:apply-templates select="marc:datafield[@tag='505']/marc:subfield[@code='a']"/>
				<xsl:apply-templates select="marc:datafield[@tag='520']/marc:subfield[@code='a']"/>
				<xsl:apply-templates select="marc:datafield[@tag='546']/marc:subfield[@code='a']"/>
				<xsl:apply-templates select="marc:datafield[@tag='562']/marc:subfield[@code='b']"/>
			</vra:descriptionSet>
		</xsl:if>

        <!-- added by Mike - 3/12/2012-->
		<xsl:call-template name="addEmptyInscriptionSet"/>
		<!-- Mike -->

		<!-- ______________ Location ______________ -->
		<!-- Always have location because we always have a pid and probably have a bibid -->
		<!--Karen added 264$a and 590, 4/17/2014-->
		<!-- Jen removed 752, 4/21/2014 -->
		<xsl:call-template name="comment">
			<xsl:with-param name="comment">Location</xsl:with-param>
		</xsl:call-template>
		<vra:locationSet>
			<vra:display>
				<xsl:for-each
					select="marc:datafield[@tag='260']/marc:subfield[@code='a'][. != '[S.l.] :'][. != '[S.l. :']
					| marc:datafield[@tag='264' and @ind2='1']/marc:subfield[@code='a'][. != '[S.l.] :'][. != '[S.l. :']
				    | marc:datafield[@tag='535']/marc:subfield[@code='a' or @code='b' or @code='c']">
						<xsl:call-template name="displaySeparator"/>
						<xsl:value-of select="normalize-space(translate(.,'[]:?',''))"/>
				</xsl:for-each>
				<xsl:for-each select="marc:datafield[@tag='590']/marc:subfield[@code='a']">
					<xsl:text> ; </xsl:text>
					<xsl:call-template name="stripTrailingPeriod">
						<xsl:with-param name="val">
							<xsl:value-of select="."/>
						</xsl:with-param>
					</xsl:call-template>
				</xsl:for-each>
				<xsl:if test="marc:datafield[@tag='086'][marc:subfield/@code='a']"> ; U.S. Superintendent of Documents Classification number: <xsl:apply-templates select="marc:datafield[@tag='086'][marc:subfield/@code='a']" mode="display"/></xsl:if>
				<xsl:if test="$pid!=''"> ; DIL:<xsl:value-of select="$pid"/></xsl:if>
				<!--xsl:if test="$bibid!=''"> ; Voyager:<xsl:value-of select="$bibid"/></xsl:if-->
				 ; Voyager:<xsl:value-of select="marc:controlfield[@tag='001']"/>
			</vra:display>
			<xsl:for-each
				select="marc:datafield[@tag='260']/marc:subfield[@code='a'][. != '[S.l.] :'][. != '[S.l. :']
				| marc:datafield[@tag='264' and @ind2='1']/marc:subfield[@code='a'][. != '[S.l.] :'][. != '[S.l. :']">
		        <vra:location type="creation">
		        	<vra:name type="geographic">
		        		<xsl:call-template name="displaySeparator"/>
		        		<xsl:value-of select="normalize-space(translate(.,'[]:?',''))"/>
		        	</vra:name>
		        </vra:location>
		    </xsl:for-each>
			<xsl:for-each
				select="marc:datafield[@tag='535'][marc:subfield/@code='a' or marc:subfield/@code='b' or marc:subfield/@code='c']">
				<vra:location type="repository">
					<xsl:apply-templates select="marc:subfield[@code='a' or @code='b' or @code='c']"/>
				</vra:location>
			</xsl:for-each>
			<xsl:for-each select="marc:datafield[@tag='590']/marc:subfield[@code='a']">
				<vra:location source="MARC 590"><vra:refid type="shelfList">
					<xsl:value-of select="."/>
				</vra:refid></vra:location>
			</xsl:for-each>

			<xsl:if test="$pid!='' or $bibid!=''">
				<vra:location>
					<xsl:if test="$pid!=''">
						<vra:refid source="DIL">
							<xsl:value-of select="$pid"/>
						</vra:refid>
					</xsl:if>
					<xsl:if test="$bibid!=''">
						<vra:refid source="Voyager">
							<xsl:value-of select="$bibid"/>
						</vra:refid>
					</xsl:if>
				</vra:location>
			</xsl:if>

		</vra:locationSet>

		<!-- ______________ Materials ______________ -->
	    <!-- 300a added by Brendan -->
		<xsl:if test="marc:datafield[@tag='340']/marc:subfield[@code='a'] | marc:datafield[@tag='300']/marc:subfield[@code='a']">
			<xsl:call-template name="comment">
				<xsl:with-param name="comment">Materials</xsl:with-param>
			</xsl:call-template>
			<vra:materialSet>
				<vra:display>
				    <xsl:for-each select="marc:datafield[@tag='340']/marc:subfield[@code='a'] | marc:datafield[@tag='300']/marc:subfield[@code='a']">
						<xsl:call-template name="displaySeparator"/>
						<xsl:call-template name="stripTrailingColon">
							<xsl:with-param name="val">
								<xsl:value-of select="."/>
							</xsl:with-param>
						</xsl:call-template>
					</xsl:for-each>
				</vra:display>
			    <xsl:apply-templates select="marc:datafield[@tag='300']/marc:subfield[@code='a']"/>
				<xsl:apply-templates select="marc:datafield[@tag='340']/marc:subfield[@code='a']"/>
			</vra:materialSet>
		</xsl:if>

		<!-- ______________ Measurements ______________ -->
	    <!-- 300c added by Brendan -->
		<xsl:if test="marc:datafield[@tag='340']/marc:subfield[@code='b'] | marc:datafield[@tag='300']/marc:subfield[@code='c']">
			<xsl:call-template name="comment">
				<xsl:with-param name="comment">Measurements</xsl:with-param>
			</xsl:call-template>
			<vra:measurementsSet>
				<vra:display>
					<xsl:for-each select="marc:datafield[@tag='340']/marc:subfield[@code='b']">
						<xsl:call-template name="displaySeparator"/>
						<xsl:value-of select="."/>
					</xsl:for-each>
				    <xsl:for-each select="marc:datafield[@tag='300']/marc:subfield[@code='c']">
				        <xsl:call-template name="displaySeparator"/>
				        <xsl:value-of select="."/>
				    </xsl:for-each>
				</vra:display>
				<xsl:apply-templates select="marc:datafield[@tag='340']/marc:subfield[@code='b']"/>
			    <xsl:apply-templates select="marc:datafield[@tag='300']/marc:subfield[@code='c']"/>
			</vra:measurementsSet>
		</xsl:if>


		<!-- ______________ Relation ______________ -->
		<!-- Work and Image records are created from the same Marc record -->
		<xsl:variable name="rel_title">
			<xsl:for-each
				select="marc:datafield[@tag='245'][marc:subfield/@code='a' or marc:subfield/@code='p']">
				<xsl:call-template name="displaySeparator"/>
				<xsl:apply-templates select="." mode="display"/>
			</xsl:for-each>
		</xsl:variable>

		<xsl:variable name="rel_title_wwii"><!--Karen added 800$atv, 730$a, and 700 and 710 if $t 4/16/2014-->
				<xsl:for-each select="marc:datafield[@tag='440']
				| marc:datafield[@tag='830']
				| marc:datafield[@tag='800']
				| marc:datafield[@tag='730']
				| marc:datafield[@tag='700'][marc:subfield[@code='t']]
				| marc:datafield[@tag='710'][marc:subfield[@code='t']]">
					<xsl:call-template name="displaySeparator"/>
					<xsl:call-template name="stripTrailingPeriod">
						<xsl:with-param name="val">
							<xsl:for-each select="marc:subfield[@code='a' or @code='b' or @code='c' or @code='q' or @code='d' or
								 @code='e' or @code='g' or @code='l' or @code='n' or @code='t' or @code='v']">
										<xsl:if test="position()!=1"><xsl:text> </xsl:text></xsl:if>
										<xsl:value-of select="."/>
							</xsl:for-each>
						</xsl:with-param>
					</xsl:call-template>
				</xsl:for-each>
		</xsl:variable>

		<xsl:choose>
			<xsl:when test="$work_or_image='image' and $work_pid!=''">
				<xsl:call-template name="comment">
					<xsl:with-param name="comment">Relation</xsl:with-param>
				</xsl:call-template>
				<vra:relationSet>
					<vra:display>
						<xsl:value-of select="$rel_title_wwii"/>
					</vra:display>
					<vra:relation pref="true" type="imageOf">
						<xsl:attribute name="relids">
							<xsl:value-of select="$work_pid"/>
						</xsl:attribute>
					</vra:relation>
					<xsl:if test="marc:datafield[@tag='440']/marc:subfield[@code='a' or @code='v']
						| marc:datafield[@tag='830']/marc:subfield[@code='a' or @code='v']
						| marc:datafield[@tag='800']/marc:subfield[@code='a' or @code='t' or @code='v']
						| marc:datafield[@tag='730']/marc:subfield[@code='a']
						| marc:datafield[@tag='700']/marc:subfield[@code='t' and (@code='a' or @code='b' or @code='c' or @code='e' or @code='j' or @code='q' or @code='l' or @code='v')]
						| marc:datafield[@tag='710']/marc:subfield[@code='t'and (@code='a' or @code='b')]">
						<vra:relation pref="false">
							<xsl:value-of select="$rel_title_wwii"/>
						</vra:relation>
					</xsl:if>
				</vra:relationSet>
			</xsl:when>

			<xsl:when test="$work_or_image='work' and $item_pid!=''">
				<xsl:call-template name="comment">
					<xsl:with-param name="comment">Relation</xsl:with-param>
				</xsl:call-template>
				<vra:relationSet>
					<vra:display>
						<xsl:value-of select="$rel_title_wwii"/>
					</vra:display>
					<vra:relation pref="true" type="imageIs">
						<xsl:attribute name="relids">
							<xsl:value-of select="$item_pid"/>
						</xsl:attribute>
					</vra:relation>
					<xsl:if test="marc:datafield[@tag='440']/marc:subfield[@code='a' or @code='v']
						| marc:datafield[@tag='830']/marc:subfield[@code='a' or @code='v']
						| marc:datafield[@tag='800']/marc:subfield[@code='a' or @code='t' or @code='v']
						| marc:datafield[@tag='730']/marc:subfield[@code='a']
						| marc:datafield[@tag='700']/marc:subfield[@code='t' and (@code='a' or @code='b' or @code='c' or @code='e' or @code='j' or @code='q' or @code='l' or @code='v')]
						| marc:datafield[@tag='710']/marc:subfield[@code='t'and (@code='a' or @code='b')]">
						<vra:relation pref="false">
							<xsl:value-of select="$rel_title_wwii"/>
						</vra:relation>
					</xsl:if>
				</vra:relationSet>
			</xsl:when>
			<xsl:otherwise/>
		</xsl:choose>

		<!-- ______________ Rights ______________ -->
		<!-- added by group 1/14/14-->
		<xsl:if test="marc:datafield[@tag='540']/marc:subfield[@code='a']">
			<xsl:call-template name="comment">
				<xsl:with-param name="comment">Rights</xsl:with-param>
			</xsl:call-template>
			<vra:rightsSet>
				<vra:display>
					<xsl:for-each select="marc:datafield[@tag='540']/marc:subfield[@code='a']">
						<xsl:call-template name="displaySeparator"/>
						<xsl:value-of select="."/>
					</xsl:for-each>
				</vra:display>
				<xsl:apply-templates select="marc:datafield[@tag='540']/marc:subfield[@code='a']" />
			</vra:rightsSet>
		</xsl:if>

		<!-- ______________ Source ______________ -->
		<!-- Removed 773, Jen 4/21/2014 -->

		<!-- ______________ Edition ______________ -->
		<!-- added by Brendan -->
		<xsl:if test="marc:datafield[@tag='250']/marc:subfield[@code='a']">
			<xsl:call-template name="comment">
				<xsl:with-param name="comment">Edition</xsl:with-param>
			</xsl:call-template>
			<vra:stateEditionSet>
				<vra:display>
					<xsl:for-each select="marc:datafield[@tag='250']/marc:subfield[@code='a']">
						<xsl:call-template name="displaySeparator"/>
						<xsl:value-of select="."/>
					</xsl:for-each>
				</vra:display>
				<xsl:apply-templates select="marc:datafield[@tag='250']/marc:subfield[@code='a']" />
			</vra:stateEditionSet>
		</xsl:if>

		<!-- added by Mike - 1/24/2014-->
		<xsl:call-template name="addEmptyStylePeriodSet"/>
		<!-- Mike -->

		<!-- ______________ SubjectSet ______________ -->
		<!-- or @tag='610' or @tag='650' or @tag='651'-->
	    <!-- 653 added by Brendan -->
		<!-- 043 added by Karen -->
		<!--Additional subfields and 611 added by Karen; entire section reworked by Karen -->
		<xsl:if test="marc:datafield[@tag='600' or @tag='610' or @tag='611' or @tag='650' or @tag='651' or @tag='653' or @tag='043']">
			<xsl:call-template name="comment">
				<xsl:with-param name="comment">Subjects</xsl:with-param>
			</xsl:call-template>
			<vra:subjectSet>
				<vra:display>
					<xsl:for-each select="marc:datafield[@tag='600'] | marc:datafield[@tag='610'] | marc:datafield[@tag='650']
						| marc:datafield[@tag='611'] | marc:datafield[@tag='630']
						| marc:datafield[@tag='651'] | marc:datafield[@tag='653'] | marc:datafield[@tag='043']/marc:subfield[@code='a']">
						<xsl:call-template name="displaySeparator"/>
						<xsl:call-template name="stripTrailingPeriod">
							<xsl:with-param name="val">
								<xsl:choose>
									<xsl:when test="../../marc:datafield[@tag='043']"/> <!--Don't add the 043 text as it is; use the template to look up country name from code-->
									<xsl:otherwise>
										<xsl:for-each select="marc:subfield[@code='a' or @code='b' or @code='c' or @code='q' or @code='d' or @code='t' or @code='n']">
											<xsl:if test="position()!=1"><xsl:text> </xsl:text></xsl:if>
											<xsl:value-of select="."/>
										</xsl:for-each>
										<xsl:for-each select="marc:subfield[@code='x' or @code='y' or @code='v' or @code='z']">
											<xsl:text>--</xsl:text>
											<xsl:value-of select="."></xsl:value-of>
										</xsl:for-each>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:with-param>
						</xsl:call-template>

						<!--xsl:if condition for MARC 043 added by Karen 4/8/2014-->
						<xsl:if test="../../marc:datafield[@tag='043']">
							<xsl:for-each select=".">
								<!--xsl:call-template name="displaySeparator"/-->
								<xsl:call-template name="countryCodes">
									<xsl:with-param name="GAC">
										<xsl:value-of select="."/>
									</xsl:with-param>
								</xsl:call-template>
							</xsl:for-each>
						</xsl:if>
				<!--Karen-->
					</xsl:for-each>
				</vra:display>
				<xsl:apply-templates
					select="marc:datafield[@tag='043']/marc:subfield[@code='a']"/>
				<xsl:apply-templates
					select="marc:datafield[@tag='600']">
					<xsl:with-param name="subjectType">personalName</xsl:with-param>
				</xsl:apply-templates>
				<xsl:apply-templates
					select="marc:datafield[@tag='610'] | marc:datafield[@tag='611']">
					<xsl:with-param name="subjectType">corporateName</xsl:with-param>
				</xsl:apply-templates>
				<xsl:apply-templates
					select="marc:datafield[@tag='630'] | marc:datafield[@tag='650'] | marc:datafield[@tag='653']">
					<xsl:with-param name="subjectType">descriptiveTopic</xsl:with-param>
				</xsl:apply-templates>
				<xsl:apply-templates
					select="marc:datafield[@tag='651']">
					<xsl:with-param name="subjectType">geographicPlace</xsl:with-param>
				</xsl:apply-templates>
			</vra:subjectSet>
		</xsl:if>

		<!-- added by Mike - 3/12/2012-->
		<xsl:call-template name="addEmptyTechniqueSet"/>
		<!-- Mike -->

		<!-- added by Karen - 4/8/2014-->
		<xsl:call-template name="addEmptyTextrefSet"/>
		<!-- Karen -->

		<!-- ______________ Titles ______________ -->
	    <!-- needs more work -BQ -->
		<xsl:if test="marc:datafield[@tag='240' or @tag='245' or @tag='130']">
			<xsl:call-template name="comment">
				<xsl:with-param name="comment"> Titles </xsl:with-param>
			</xsl:call-template>
			<vra:titleSet>
				<vra:display>
					<xsl:for-each
						select="marc:datafield[@tag='245']">
						<xsl:call-template name="stripTrailingForwardSlash"/>
						<xsl:call-template name="displaySeparator"/>
						<xsl:apply-templates select="." mode="display"/>
					</xsl:for-each>
				</vra:display>
				<xsl:apply-templates select="marc:datafield[@tag='130']"/>
				<xsl:apply-templates select="marc:datafield[@tag='240']"/>
				<xsl:apply-templates select="marc:datafield[@tag='245']"/>
				<xsl:apply-templates select="marc:datafield[@tag='246']"/>
			</vra:titleSet>
		</xsl:if>

		<!-- ______________ WorkType ______________ -->
		<xsl:choose>
		<xsl:when test="marc:datafield[@tag='655']/marc:subfield[@code='a']">
			<xsl:call-template name="comment">
				<xsl:with-param name="comment">WorkType</xsl:with-param>
			</xsl:call-template>
			<vra:worktypeSet>
				<vra:display>
					<xsl:for-each select="marc:datafield[@tag='655']/marc:subfield[@code='a']">
						<xsl:call-template name="displaySeparator"/>
						<xsl:call-template name="stripTrailingPeriod">
							<xsl:with-param name="val">
								<xsl:value-of select="."/>
							</xsl:with-param>
						</xsl:call-template>
					</xsl:for-each>
				</vra:display>
				<xsl:for-each select="marc:datafield[@tag='655']/marc:subfield[@code='a']">
					<vra:worktype>
						<xsl:apply-templates select="../marc:subfield[@code='2']"/>
						<xsl:call-template name="stripTrailingPeriod">
							<xsl:with-param name="val">
								<xsl:value-of select="."/>
							</xsl:with-param>
						</xsl:call-template>
					</vra:worktype>
				</xsl:for-each>
			</vra:worktypeSet>
		</xsl:when>
		<xsl:otherwise>
		  <!-- added by Mike - 1/24/2014 -->
		    <xsl:call-template name="addWorktypeSet"/>
		  <!-- Mike -->
		</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<!-- added by Mike - 3/12/2012 -->
	<xsl:template name="addEmptyCulturalContextSet">
		<xsl:call-template name="comment">
			<xsl:with-param name="comment">Cultural Context</xsl:with-param>
		</xsl:call-template>
		<vra:culturalContextSet>
			<vra:display/>
			<vra:culturalContext/>
		</vra:culturalContextSet>
	</xsl:template>

	<xsl:template name="addEmptyInscriptionSet">
		<xsl:call-template name="comment">
			<xsl:with-param name="comment">Inscription</xsl:with-param>
		</xsl:call-template>
		<vra:inscriptionSet>
			<vra:display/>
			<vra:inscription>
				<vra:text/>
			</vra:inscription>
		</vra:inscriptionSet>
	</xsl:template>

	<xsl:template name="addEmptyStylePeriodSet">
		<xsl:call-template name="comment">
			<xsl:with-param name="comment">Style Period</xsl:with-param>
		</xsl:call-template>
		<vra:stylePeriodSet>
			<vra:display/>
			<vra:stylePeriod/>
		</vra:stylePeriodSet>
	</xsl:template>

	<xsl:template name="addEmptyTechniqueSet">
		<xsl:call-template name="comment">
			<xsl:with-param name="comment">Technique</xsl:with-param>
		</xsl:call-template>
		<vra:techniqueSet>
			<vra:display/>
			<vra:technique/>
		</vra:techniqueSet>
	</xsl:template>
	<!-- Mike -->

	<!--Added by Karen 4/8/2014-->
	<xsl:template name="addEmptyTextrefSet">
		<xsl:call-template name="comment">
			<xsl:with-param name="comment">Textref</xsl:with-param>
		</xsl:call-template>
		<vra:textrefSet>
			<vra:display/>
			<vra:textref/>
		</vra:textrefSet>
	</xsl:template>
	<!--Karen-->

 	<!-- Added by Jen, 5/9/2014 -->
	<xsl:template name="addEmptyAgentSet">
		<xsl:call-template name="comment">
			<xsl:with-param name="comment">Agent</xsl:with-param>
		</xsl:call-template>
		<vra:agentSet>
			<vra:display/>
			<vra:agent/>
		</vra:agentSet>
	</xsl:template>
	<!-- Jen -->

    <!-- Mike 1/24/2014; Hardcoded to "Prints" by Karen for Poster, 4/17/2014 -->
    <xsl:template name="addWorktypeSet">
		<xsl:call-template name="comment">
			<xsl:with-param name="comment">Work Type</xsl:with-param>
		</xsl:call-template>
		<vra:worktypeSet>
			<vra:display>Prints</vra:display>
			<vra:worktype>Prints</vra:worktype>
		</vra:worktypeSet>
	</xsl:template>
	<!-- Mike -->

	<!-- agent display -->
	<!-- added subfields, 711. Jen 04/21/2014 -->
	<xsl:template match="marc:datafield[@tag='100']" mode="display">
		<xsl:call-template name="stripTrailingPeriod">
			<xsl:with-param name="val">
				<xsl:value-of
					select="marc:subfield[@code='a' or @code='b' or @code='c' or @code='d' or @code='e' or @code='g' or @code='j' or @code='q']"
				/>
			</xsl:with-param>
		</xsl:call-template>
	</xsl:template>
	<xsl:template match="marc:datafield[@tag='110']" mode="display">
		<xsl:call-template name="stripTrailingPeriod">
			<xsl:with-param name="val">
				<xsl:value-of select="marc:subfield[@code='a' or @code='b' or @code='e' or @code='g']"/>
			</xsl:with-param>
		</xsl:call-template>
	</xsl:template>
	<xsl:template match="marc:datafield[@tag='700']" mode="display">
		<xsl:call-template name="stripTrailingPeriod">
			<xsl:with-param name="val">
				<xsl:value-of
					select="marc:subfield[@code='a' or @code='b' or @code='c' or @code='d' or @code='e' or @code='g' or @code='j' or @code='q']"
				/>
			</xsl:with-param>
		</xsl:call-template>
	</xsl:template>
	<xsl:template match="marc:datafield[@tag='710']" mode="display">
		<xsl:call-template name="stripTrailingPeriod">
			<xsl:with-param name="val">
				<xsl:value-of select="marc:subfield[@code='a' or @code='b' or @code='c' or @code='d' or @code='e' or @code='g' or @code='n']"/>
			</xsl:with-param>
		</xsl:call-template>
	</xsl:template>
	<xsl:template match="marc:datafield[@tag='711']" mode="display">
		<xsl:call-template name="stripTrailingPeriod">
			<xsl:with-param name="val">
				<xsl:value-of select="marc:subfield[@code='a' or @code='c' or @code='d' or @code='n']"/>
			</xsl:with-param>
		</xsl:call-template>
	</xsl:template>

	<!-- agent -->
	<xsl:template match="marc:datafield[@tag='100' or @tag='700']">
		<vra:agent>
			<vra:name type="personal" vocab="lcnaf">
				<xsl:apply-templates select="marc:subfield[@code='0']"/>
				<xsl:call-template name="stripTrailingPeriod">
					<xsl:with-param name="val">
						<xsl:value-of
							select="marc:subfield[@code='a' or @code='b' or @code='c' or @code='d' or @code='g' or @code='j' or @code='q']"
						/>
					</xsl:with-param>
				</xsl:call-template>
			</vra:name>

			<!-- added by Mike 3/12/2012 -->
			<xsl:if
				test="//marc:datafield[@tag='046']/marc:subfield[@code='f'] | //marc:datafield[@tag='046']/marc:subfield[@code='g']">
				<vra:dates type="life">
					<xsl:apply-templates
						select="//marc:datafield[@tag='046']/marc:subfield[@code='f']"/>
					<xsl:apply-templates
						select="//marc:datafield[@tag='046']/marc:subfield[@code='g']"/>
				</vra:dates>
			</xsl:if>
			<xsl:apply-templates select="//marc:datafield[@tag='370']/marc:subfield[@code='a']"/>
			<!-- Jen added RDA 4/17/2014 -->
			<vra:attribution/>
				<vra:role vocab="RDA">
								<xsl:call-template name="stripTrailingPeriod">
					<xsl:with-param name="val">
						<xsl:value-of
							select="marc:subfield[@code='e']"
						/>
					</xsl:with-param>
				</xsl:call-template>
			</vra:role>
			<!-- jen -->
			<!-- Mike -->
		</vra:agent>
	</xsl:template>

	<!-- added by Mike 3/12/2012-->
	<xsl:template match="//marc:datafield[@tag='046']/marc:subfield[@code='f']">
		<vra:earliestDate>
			<xsl:value-of select="//marc:datafield[@tag='046']/marc:subfield[@code='f']"/>
		</vra:earliestDate>
	</xsl:template>

	<!-- added by Mike 3/12/2012-->
	<xsl:template match="//marc:datafield[@tag='046']/marc:subfield[@code='g']">
		<vra:latestDate>
			<xsl:value-of select="//marc:datafield[@tag='046']/marc:subfield[@code='g']"/>
		</vra:latestDate>
	</xsl:template>

	<xsl:template match="//marc:datafield[@tag='370']/marc:subfield[@code='a']">
		<vra:culture>
			<xsl:value-of select="//marc:datafield[@tag='370']/marc:subfield[@code='a']"/>
		</vra:culture>
	</xsl:template>

	<xsl:template match="marc:datafield[@tag='110' or @tag='710']">
		<vra:agent>
			<vra:name type="corporate" vocab="lcnaf">
				<xsl:apply-templates select="marc:subfield[@code='0']"/>
				<xsl:call-template name="stripTrailingPeriod">
					<xsl:with-param name="val">
						<xsl:value-of select="marc:subfield[@code='a' or @code='b' or @code='c' or @code='d' or @code='g' or @code='j' or @code='n'
							or @code='q']"/>
					</xsl:with-param>
				</xsl:call-template>
			</vra:name>
			<!-- start added by Mike -->
			<xsl:if
				test="//marc:datafield[@tag='046']/marc:subfield[@code='f'] | //marc:datafield[@tag='046']/marc:subfield[@code='g']">
				<vra:dates type="life">
					<xsl:apply-templates
						select="//marc:datafield[@tag='046']/marc:subfield[@code='f']"/>
					<xsl:apply-templates
						select="//marc:datafield[@tag='046']/marc:subfield[@code='g']"/>
				</vra:dates>
			</xsl:if>
			<xsl:apply-templates select="//marc:datafield[@tag='370']/marc:subfield[@code='a']"/>
			<!-- Jen added RDA 4/21/2014 -->
			<vra:attribution/>
			<vra:role vocab="RDA">
				<xsl:call-template name="stripTrailingPeriod">
					<xsl:with-param name="val">
						<xsl:value-of
							select="marc:subfield[@code='e']"
						/>
					</xsl:with-param>
				</xsl:call-template>
			</vra:role>
			<!-- Mike -->
		</vra:agent>
	</xsl:template>

	<!-- 711 added by Jen, 4/21/2014 -->
	<xsl:template match="marc:datafield[@tag='711']">
		<vra:agent>
			<vra:name type="corporate" vocab="lcnaf">
				<xsl:apply-templates select="marc:subfield[@code='0']"/>
				<xsl:call-template name="stripTrailingPeriod">
					<xsl:with-param name="val">
						<xsl:value-of select="marc:subfield[@code='a' or @code='c' or @code='d' or @code='n']"/>
					</xsl:with-param>
				</xsl:call-template>
			</vra:name>
			<vra:attribution/>
		</vra:agent>
	</xsl:template>


	<!-- Agent 260$b/264$b -->
	<!-- 264 added by Jen 4/21/2014-->
	<xsl:template match="marc:datafield[@tag='260' or @tag='264']">
		<xsl:for-each select="marc:subfield[@code='b']">
			<vra:agent>
				<vra:name type="corporate" vocab="lcnaf">
					<xsl:choose>
						<xsl:when test="normalize-space(translate(.,'[]','')) = 's.n.,' or normalize-space(translate(.,'[]','')) = 's.n.'">
							<xsl:text>publisher not identified</xsl:text>
						</xsl:when>
						<xsl:otherwise>
						<xsl:call-template name="stripTrailingSemicolon">
							<xsl:with-param name="val">
								<xsl:value-of select="translate(.,'[]?,','')"/>
								</xsl:with-param>
							</xsl:call-template>
						</xsl:otherwise>
					</xsl:choose>
				</vra:name>
			</vra:agent>
		</xsl:for-each>
	</xsl:template>

	<xsl:template match="marc:subfield[@code='0']">
		<xsl:attribute name="refid">
			<xsl:value-of select="."/>
		</xsl:attribute>
	</xsl:template>

	<!-- titles -->
    <!-- added by Brendan Quinn 1/9/2014, needs more work -->
	<xsl:template
		match="marc:datafield[@tag='130'][marc:subfield/@code='a' or marc:subfield/@code='d']">
		<vra:title pref="false">
			<xsl:call-template name="stripTrailingPeriod">
				<xsl:with-param name="val">
					<xsl:value-of select="marc:subfield[@code='a' or @code='d']"/>
				</xsl:with-param>
			</xsl:call-template>
		</vra:title>
	</xsl:template>

	<xsl:template
        match="marc:datafield[@tag='240'][marc:subfield/@code='a' or marc:subfield/@code='g' or marc:subfield/@code='d']">
        <vra:title pref="true">
            <xsl:call-template name="stripTrailingPeriod">
                <xsl:with-param name="val">
                    <xsl:value-of select="marc:subfield[@code='a' or @code='g' or @code='d']"/>
                </xsl:with-param>
            </xsl:call-template>
        </vra:title>
    </xsl:template>

	<xsl:template
		match="marc:datafield[@tag='245']">
		<vra:title pref="true">
			<xsl:call-template name="stripTrailingForwardSlash">
				<xsl:with-param name="val">
					<xsl:value-of select="marc:subfield[@code='a' or @code='b' or @code='p']"/>
				</xsl:with-param>
			</xsl:call-template>
		</vra:title>
	</xsl:template>

	<!-- Added by Bill Parod 1/22/2012 -->
	<xsl:template
		match="marc:datafield[@tag='245'][marc:subfield/@code='a' or marc:subfield/@code='b' or marc:subfield/@code='p']"
		mode="display">
		<xsl:call-template name="stripTrailingForwardSlash">
			<xsl:with-param name="val">
				<xsl:value-of select="marc:subfield[@code='a' or @code='b' or @code='p']"/>
			</xsl:with-param>
		</xsl:call-template>
	</xsl:template>

	<xsl:template match="marc:datafield[@tag='246'][marc:subfield/@code='a' or marc:subfield/@code='b' or marc:subfield/@code='i']">
		<vra:title pref="false">
			<xsl:call-template name="stripTrailingPeriod">
				<xsl:with-param name="val">
					<xsl:value-of select="marc:subfield[@code='i' or @code='a' or @code='b']"/>
				</xsl:with-param>
			</xsl:call-template>
		</vra:title>
	</xsl:template>

<!--publication Date from 260$c or 264$c. Added by Karen 4/16/2014-->
	<xsl:template name="publicationDate">
		<xsl:param name="thisC"/>

		<xsl:choose>
			<xsl:when test="contains($thisC,'-')">
				<xsl:analyze-string select="$thisC" regex="\d\d\--\?*">
					<xsl:matching-substring>
						<xsl:analyze-string select="." regex="\d\d">
							<xsl:matching-substring><xsl:value-of select="."/>00s</xsl:matching-substring>
						</xsl:analyze-string>
					</xsl:matching-substring>
				</xsl:analyze-string>
				<xsl:analyze-string select="$thisC" regex="\d\d\d-\?*">
					<xsl:matching-substring>
						<xsl:analyze-string select="." regex="\d\d\d">
							<xsl:matching-substring>
								<xsl:value-of select="."/>0s</xsl:matching-substring>
						</xsl:analyze-string>
					</xsl:matching-substring>
				</xsl:analyze-string>
				<xsl:analyze-string select="$thisC" regex="\d{{4}}">
					<xsl:matching-substring>
						<xsl:value-of select="."/>
					</xsl:matching-substring>
				</xsl:analyze-string>
			</xsl:when>
			<xsl:otherwise>
				<xsl:choose>
					<xsl:when test="substring-after(translate($thisC,'[]?.',''),'c')">
						<xsl:value-of select="substring-after(translate($thisC,'[]?.',''),'c')"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="translate($thisC,'[]?.','')"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:call-template name="displaySeparator"/>
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
		<vra:earliestDate>
			<xsl:value-of select="."/>
		</vra:earliestDate>
	</xsl:template>

	<xsl:template match="marc:subfield[@code='t']" mode="latestDate">
		<vra:latestDate>
			<xsl:value-of select="."/>
		</vra:latestDate>
	</xsl:template>

	<!-- description -->
	<xsl:template match="marc:datafield[@tag='500']/marc:subfield[@code='a']">
		<vra:description>
			<xsl:value-of select="."/>
		</vra:description>
	</xsl:template>

	<xsl:template match="marc:datafield[@tag='505']/marc:subfield[@code='a']">
		<vra:description>
			<xsl:value-of select="."/>
		</vra:description>
	</xsl:template>

	<xsl:template match="marc:datafield[@tag='520']/marc:subfield[@code='a']">
		<vra:description>
			<xsl:value-of select="."/>
		</vra:description>
	</xsl:template>

	<xsl:template match="marc:datafield[@tag='546']/marc:subfield[@code='a']">
		<vra:description>
			<xsl:value-of select="."/>
		</vra:description>
	</xsl:template>

	<xsl:template match="marc:datafield[@tag='562']/marc:subfield[@code='b']">
		<vra:description>
			<xsl:value-of select="."/>
		</vra:description>
	</xsl:template>

	<!-- removed 752 information, Jen 4/21/2014 -->

	<!-- location 535 display mode -->
	<xsl:template
		match="marc:datafield[@tag='535'][marc:subfield/@code='a' or marc:subfield/@code='b' or marc:subfield/@code='c']"
		mode="display">
		<xsl:value-of select="marc:subfield[@code='a' or @code='b' or @code='c']"/>
	</xsl:template>

	<!-- rights -->
	<xsl:template match="marc:datafield[@tag='540']/marc:subfield[@code='a']">
		<vra:rights type="undetermined">
			<vra:rightsHolder>Undetermined</vra:rightsHolder>
			<vra:text><xsl:value-of select="."/></vra:text>
		</vra:rights>
	</xsl:template>



	<!-- location 535$a -->
	<xsl:template match="marc:datafield[@tag='535']/marc:subfield[@code='a']">
		<vra:name type="corporate">
			<xsl:call-template name="stripTrailingPeriod">
				<xsl:with-param name="val">
					<xsl:value-of select="."/>
				</xsl:with-param>
			</xsl:call-template>
		</vra:name>
	</xsl:template>
	<!-- location 535$b -->
	<xsl:template match="marc:datafield[@tag='535']/marc:subfield[@code='b']">
		<vra:name type="geographic">
			<xsl:call-template name="stripTrailingPeriod">
				<xsl:with-param name="val">
					<xsl:value-of select="."/>
				</xsl:with-param>
			</xsl:call-template>
		</vra:name>
	</xsl:template>
	<!-- location 535$c -->
	<xsl:template match="marc:datafield[@tag='535']/marc:subfield[@code='c']">
		<vra:name type="geographic">
			<xsl:call-template name="stripTrailingPeriod">
				<xsl:with-param name="val">
					<xsl:value-of select="."/>
				</xsl:with-param>
			</xsl:call-template>
		</vra:name>
	</xsl:template>

    <!-- edition -->
    <xsl:template match="marc:datafield[@tag='250']/marc:subfield[@code='a']">
       <vra:stateEdition type="edition">
           <vra:name>
             <xsl:value-of select="."/>
           </vra:name>
       </vra:stateEdition>
    </xsl:template>

    <!-- Publication, Distribution, etc -->
	<!-- added 264, Jen 4/21/2014 -->
    <xsl:template match="marc:datafield[@tag='260' or @tag='264']/marc:subfield[@code='a']">
       	<vra:name type="geographic">
       		<xsl:value-of select="marc:datafield[@tag='260' or @tag='264']/marc:subfield[@code='a']"/>
       	</vra:name>
    </xsl:template>

    <!-- physical description -->
    <xsl:template match="marc:datafield[@tag='300']/marc:subfield[@code='a']">
        <vra:material>
            <xsl:call-template name="stripTrailingPeriod">
                <xsl:with-param name="val">
                    <xsl:value-of select="."/>
                </xsl:with-param>
            </xsl:call-template>
        </vra:material>
    </xsl:template>

    <!-- dimensions -->
    <xsl:template match="marc:datafield[@tag='300']/marc:subfield[@code='c']">
        <vra:measurements>
            <xsl:call-template name="stripTrailingPeriod">
                <xsl:with-param name="val">
                    <xsl:value-of select="."/>
                </xsl:with-param>
            </xsl:call-template>
        </vra:measurements>
    </xsl:template>

	<!-- material -->
	<xsl:template match="marc:datafield[@tag='340']/marc:subfield[@code='a']">
		<vra:material>
			<xsl:call-template name="stripTrailingPeriod">
				<xsl:with-param name="val">
					<xsl:value-of select="."/>
				</xsl:with-param>
			</xsl:call-template>
		</vra:material>
	</xsl:template>

	<!-- measurements -->
	<xsl:template match="marc:datafield[@tag='340']/marc:subfield[@code='b']">
		<vra:measurements>
			<xsl:value-of select="."/>
		</vra:measurements>
	</xsl:template>

	<!-- style/period vocab attribute -->
	<xsl:template match="marc:subfield[@code='2']">
		<xsl:attribute name="vocab">
			<xsl:value-of select="."/>
		</xsl:attribute>
	</xsl:template>

	<!-- subject vocab attribute -->
	<xsl:template match="marc:subfield[@code='0']">
		<xsl:attribute name="vocab">

		</xsl:attribute>
	</xsl:template>

	<!-- subjects --><!-- 043 added by Karen-->
	<xsl:template
		match="marc:datafield[@tag='043']/marc:subfield[@code='a']">
		<vra:subject>
			<vra:term type="geographicPlace" vocab="lcnaf">
				<xsl:for-each select=".">
					<xsl:call-template name="displaySeparator"/>
					<xsl:call-template name="countryCodes">
						<xsl:with-param name="GAC">
							<xsl:value-of select="."/>
						</xsl:with-param>
					</xsl:call-template>
				</xsl:for-each>
			</vra:term>
		</vra:subject>
	</xsl:template>


	<!--reworked by Karen--><!--Puts each subject term into a separate element; probably better for faceting.-->
	<xsl:template match="marc:datafield[@tag='600'] | marc:datafield[@tag='610'] | marc:datafield[@tag='611']
		| marc:datafield[@tag='630'] | marc:datafield[@tag='650'] | marc:datafield[@tag='651'] | marc:datafield[@tag='653']">
		<xsl:param name="subjectType"/>
		<vra:subject>
			<vra:term>
				<xsl:attribute name="type"><xsl:value-of select="$subjectType"/></xsl:attribute>
				<xsl:choose>
					<xsl:when test="marc:subfield[@code='2']">
						<xsl:apply-templates select="marc:subfield[@code='2']"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:choose>
							<xsl:when test="($subjectType='corporateName' or $subjectType='personalName')">
								<xsl:attribute name="vocab">lcnaf</xsl:attribute>
							</xsl:when>
							<xsl:otherwise>
								<xsl:attribute name="vocab">lcsh</xsl:attribute>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:otherwise>
				</xsl:choose>
				<xsl:for-each select="marc:subfield[@code='a' or @code='b' or @code='c' or @code='q' or @code='d' or @code='n' or @code='t']">
					<xsl:if test="position()!=1"><xsl:text> </xsl:text></xsl:if>
					<xsl:choose>
						<xsl:when test="position()=last()">
							<xsl:call-template name="stripTrailingPeriod">
								<xsl:with-param name="val">
									<xsl:value-of select="."></xsl:value-of>
								</xsl:with-param>
							</xsl:call-template>
						</xsl:when>
						<xsl:otherwise>
								<xsl:value-of select="."></xsl:value-of>
						</xsl:otherwise>
						</xsl:choose>



					<!--xsl:value-of select="."></xsl:value-of-->
				</xsl:for-each>
			</vra:term>
		</vra:subject>

		<xsl:for-each select="marc:subfield[@code='v']">
			<vra:subject>
				<vra:term>
					<xsl:attribute name="type">otherTopic</xsl:attribute>
					<xsl:call-template name="stripTrailingPeriod">
						<xsl:with-param name="val">
							<xsl:value-of select="."></xsl:value-of>
						</xsl:with-param>
					</xsl:call-template>
				</vra:term>
			</vra:subject>
		</xsl:for-each>

		<xsl:for-each select="marc:subfield[@code='x' or @code='y']">
			<vra:subject>
				<vra:term>
					<xsl:attribute name="type">descriptiveTopic</xsl:attribute>
					<xsl:call-template name="stripTrailingPeriod">
						<xsl:with-param name="val">
							<xsl:value-of select="."></xsl:value-of>
						</xsl:with-param>
					</xsl:call-template>
				</vra:term>
			</vra:subject>
		</xsl:for-each>

		<xsl:for-each select="marc:subfield[@code='z']">
			<vra:subject>
				<vra:term>
					<xsl:attribute name="type">geographicPlace</xsl:attribute>
					<xsl:call-template name="stripTrailingPeriod">
						<xsl:with-param name="val">
							<xsl:value-of select="."></xsl:value-of>
						</xsl:with-param>
					</xsl:call-template>
				</vra:term>
			</vra:subject>
		</xsl:for-each>

	</xsl:template>

<!--Mapping of 650 into Location removed by Karen, 4/10/2014.-->

<!-- removed 773 information, Jen 4/21/2014 -->

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
		<xsl:param name="val"/>
		<xsl:analyze-string select="$val" regex="(.*)\.\s*$" flags="i">
			<xsl:matching-substring>
				<xsl:value-of select="regex-group(1)"/>
			</xsl:matching-substring>
			<xsl:non-matching-substring>
				<xsl:value-of select="$val"/>
			</xsl:non-matching-substring>
		</xsl:analyze-string>
	</xsl:template>

	<xsl:template name="stripTrailingForwardSlash">
		<xsl:param name="val"/>
		<xsl:analyze-string select="$val" regex="(.*)\s/\s*$" flags="i">
			<xsl:matching-substring>
				<xsl:value-of select="regex-group(1)"/>
			</xsl:matching-substring>
			<xsl:non-matching-substring>
				<xsl:value-of select="$val"/>
			</xsl:non-matching-substring>
		</xsl:analyze-string>
	</xsl:template>

	<xsl:template name="stripTrailingColon">
		<xsl:param name="val"/>
		<xsl:analyze-string select="$val" regex="(.*)\s:\s*$" flags="i">
			<xsl:matching-substring>
				<xsl:value-of select="regex-group(1)"/>
			</xsl:matching-substring>
			<xsl:non-matching-substring>
				<xsl:value-of select="$val"/>
			</xsl:non-matching-substring>
		</xsl:analyze-string>
	</xsl:template>

	<xsl:template name="stripTrailingSemicolon">
		<xsl:param name="val"/>
		<xsl:analyze-string select="$val" regex="(.*)\s;\s*$" flags="i">
			<xsl:matching-substring>
				<xsl:value-of select="regex-group(1)"/>
			</xsl:matching-substring>
			<xsl:non-matching-substring>
				<xsl:value-of select="$val"/>
			</xsl:non-matching-substring>
		</xsl:analyze-string>
	</xsl:template>

	<xsl:template name="stripBrackets">
		<xsl:param name="val"/>
		<xsl:analyze-string select="$val" regex="^\[*(.*?)\]?\s:$" flags="i">
			<xsl:matching-substring>
				<xsl:value-of select="regex-group(1)"/>
			</xsl:matching-substring>
			<xsl:non-matching-substring>
				<xsl:value-of select="$val"/>
			</xsl:non-matching-substring>
		</xsl:analyze-string>
	</xsl:template>

	<!--Added by Karen, April 1, 2014-->
	<xsl:template name="countryCodes">
		<xsl:param name="GAC"/>
		<xsl:variable name="countryCODE"> <!--Strip off the trailing dashes in order to build a correct URL.-->
			<xsl:choose> <!--OK, I know this bit is inelegant, but it is the path of least resistance.-->
				<xsl:when test="ends-with(.,'------')">
					<xsl:value-of select="substring(.,1,string-length(.)-6)"/>
				</xsl:when>
				<xsl:when test="ends-with(.,'-----')">
					<xsl:value-of select="substring(.,1,string-length(.)-5)"/>
				</xsl:when>
				<xsl:when test="ends-with(.,'----')">
					<xsl:value-of select="substring(.,1,string-length(.)-4)"/>
				</xsl:when>
				<xsl:when test="ends-with(.,'---')">
					<xsl:value-of select="substring(.,1,string-length(.)-3)"/>
				</xsl:when>
				<xsl:when test="ends-with(.,'--')">
					<xsl:value-of select="substring(.,1,string-length(.)-2)"/>
				</xsl:when>
				<xsl:when test="ends-with(.,'-')">
					<xsl:value-of select="substring(.,1,string-length(.)-1)"/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:value-of select="."/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:variable>
		<xsl:variable name="CountryURL">
			<xsl:value-of select="concat('http://id.loc.gov/vocabulary/geographicAreas/', $countryCODE, '.rdf')"/>
		</xsl:variable>
		<xsl:value-of select="document($CountryURL)/rdf:RDF/madsrdf:Geographic/madsrdf:authoritativeLabel[@xml:lang='en']"/>
	</xsl:template>

	<xsl:template name="languageCodes">
		<xsl:param name="lang"/>
		<xsl:variable name="LanguageURL">
			<xsl:value-of select="concat('http://id.loc.gov/vocabulary/languages/', $lang, '.rdf')"/>
		</xsl:variable>
		<xsl:value-of select="document($LanguageURL)/rdf:RDF/madsrdf:Language/madsrdf:authoritativeLabel[@xml:lang='en']"/>
	</xsl:template>

	<xsl:template name="buildLanguageNote">
		<xsl:text>Language(s): </xsl:text>
		<xsl:call-template name="languageCodes">
			<xsl:with-param name="lang">
				<xsl:value-of select="substring(marc:controlfield[@tag='008'],36,3)"/>
			</xsl:with-param>
		</xsl:call-template>
		<xsl:for-each select="marc:datafield[@tag='041']/marc:subfield[@code='a'] | marc:datafield[@tag='041']/marc:subfield[@code='h']">
			<xsl:if test="normalize-space(.) != substring(../../marc:controlfield[@tag='008'],36,3)">
				<xsl:text> ; </xsl:text>
				<xsl:call-template name="languageCodes">
					<xsl:with-param name="lang">
						<xsl:value-of select="."/>
					</xsl:with-param>
				</xsl:call-template>
			</xsl:if>
		</xsl:for-each>
	</xsl:template>
	<!--Karen-->

	<xsl:template match="*|text()"/>

</xsl:stylesheet>
