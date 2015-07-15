<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:fn="http://www.w3.org/2005/xpath-functions" xmlns:marc="http://www.loc.gov/MARC21/slim"
	xmlns:mods="http://www.loc.gov/mods/v3" xmlns:vra="http://www.vraweb.org/vracore4.htm"
	xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">

	<xsl:param name="bibid"/>
	<xsl:param name="pid"/>
	<xsl:param name="work_pid"/>
	<xsl:param name="item_pid"/>
	<xsl:param name="work_or_image"/>

	<xsl:output method="xml" omit-xml-declaration="no" indent="yes" encoding="utf-8"
		media-type="text/xml"/>

	<xsl:template match="/">
		<vra:vra xmlns:vra="http://www.vraweb.org/vracore4.htm" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
			xsi:schemaLocation="http://www.vraweb.org/vracore4.htm http://www.loc.gov/standards/vracore/vra-strict.xsd">

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

	<xsl:template match="marc:record" mode="work">
		<vra:work>
			<!--xsl:attribute name="xml:id">inu:inu-dil-<xsl:value-of select="marc:controlfield[@tag='001']"/>_w</xsl:attribute-->
			<xsl:attribute name="id">inu-dil-<xsl:value-of select="marc:controlfield[@tag='001']"/>_w</xsl:attribute>
			<!--xsl:attribute name="vra:refid">inu:inu-dil-<xsl:value-of select="marc:controlfield[@tag='001']"/></xsl:attribute-->

			<!-- Updated by Bill -->
			<!-- <xsl:attribute name="refid">inu:inu-dil-<xsl:value-of select="marc:controlfield[@tag='001']"/></xsl:attribute> -->

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
			<!--xsl:attribute name="xml:id">inu:inu-dil-<xsl:value-of select="marc:controlfield[@tag='001']"/>_w</xsl:attribute-->
			<xsl:attribute name="id">inu-dil-<xsl:value-of select="marc:controlfield[@tag='001']"
				/>_w</xsl:attribute>
			<!--xsl:attribute name="vra:refid">inu:inu-dil-<xsl:value-of select="marc:controlfield[@tag='001']"/></xsl:attribute-->

			<!--Updated by Mike 12/2012, match the work logic for pid being refid-->
			<!--<xsl:attribute name="refid">inu:inu-dil-<xsl:value-of select="marc:controlfield[@tag='001']"/></xsl:attribute>-->
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
			<!-- End Mike update  -->

			<xsl:call-template name="marc2vra"/>
		</vra:image>
	</xsl:template>


	<!-- Convert MARC to VRA without the enclosing vra:work or vra:item. These are provided by caller -->

	<xsl:template name="marc2vra">

		<!-- ______________ AGENTS ______________ -->
		<!-- Added subfields for 100, 110, 700, 710 and added 711 field Jen 07/30/2014 -->
		<xsl:if
			test="marc:datafield[@tag='100'][marc:subfield/@code='0' or marc:subfield/@code='a' or marc:subfield/@code='b'
		or marc:subfield/@code='c' or marc:subfield/@code='d' or marc:subfield/@code='e' or marc:subfield/@code='g' or marc:subfield/@code='j'
		or marc:subfield/@code='p' or marc:subfield/@code='q']
		or marc:datafield[@tag='110'][marc:subfield/@code='0' or marc:subfield/@code='a' or marc:subfield/@code='b' or marc:subfield/@code='d'
		or marc:subfield/@code='g' or marc:subfield/@code='p']
		or marc:datafield[@tag='700'][marc:subfield/@code='0' or marc:subfield/@code='a' or marc:subfield/@code='b'
		or marc:subfield/@code='c' or marc:subfield/@code='d' or marc:subfield/@code='e' or marc:subfield/@code='g' or marc:subfield/@code='j'
		or marc:subfield/@code='p' or marc:subfield/@code='q' or marc:subfield/@code='r' or marc:subfield/@code='t' or marc:subfield/@code='x']
		or marc:datafield[@tag='710'][marc:subfield/@code='0' or marc:subfield/@code='a' or marc:subfield/@code='b' or marc:subfield/@code='d'
		or marc:subfield/@code='g' or marc:subfield/@code='p']
		or marc:datafield[@tag='711'][marc:subfield/@code='a' or marc:subfield/@code='c' or marc:subfield/@code='d' or
		marc:subfield/@code='g' or marc:subfield/@code='n']">
			<xsl:call-template name="comment">
				<xsl:with-param name="comment">Agents</xsl:with-param>
			</xsl:call-template>
			<vra:agentSet>
				<vra:display>
					<xsl:for-each
						select="marc:datafield[@tag='100'][marc:subfield/@code='0' or marc:subfield/@code='a' or marc:subfield/@code='b'
				or marc:subfield/@code='c' or marc:subfield/@code='d' or marc:subfield/@code='e' or marc:subfield/@code='g' or marc:subfield/@code='j'
				or marc:subfield/@code='p' or marc:subfield/@code='q']
				| marc:datafield[@tag='110'][marc:subfield/@code='0' or marc:subfield/@code='a' or marc:subfield/@code='b' or marc:subfield/@code='d'
				or marc:subfield/@code='g' or marc:subfield/@code='p']
			| marc:datafield[@tag='700'][marc:subfield/@code='0' or marc:subfield/@code='a' or marc:subfield/@code='b' or marc:subfield/@code='c'
			or marc:subfield/@code='d' or marc:subfield/@code='e' or marc:subfield/@code='g' or marc:subfield/@code='j' or marc:subfield/@code='p'
			or marc:subfield/@code='q' or marc:subfield/@code='r' or marc:subfield/@code='t' or marc:subfield/@code='x']
			| marc:datafield[@tag='710'][marc:subfield/@code='0' or marc:subfield/@code='a' or marc:subfield/@code='b' or marc:subfield/@code='d'
			or marc:subfield/@code='g' or marc:subfield/@code='p'] | marc:datafield[@tag='711'][marc:subfield/@code='a' or marc:subfield/@code='c' or marc:subfield/@code='d' or
			marc:subfield/@code='g' or marc:subfield/@code='n']">
						<!--xsl:if test="position()!=1">;</xsl:if-->
						<xsl:if test="position()!=1"> ; </xsl:if>
						<xsl:apply-templates select="." mode="display"/>
					</xsl:for-each>
				</vra:display>
				<xsl:apply-templates
					select="marc:datafield[@tag='100'][marc:subfield/@code='0' or marc:subfield/@code='a' or marc:subfield/@code='b'
				or marc:subfield/@code='c' or marc:subfield/@code='d' or marc:subfield/@code='e' or marc:subfield/@code='g' or marc:subfield/@code='j'
				or marc:subfield/@code='p' or marc:subfield/@code='q']"/>
				<xsl:apply-templates
					select="marc:datafield[@tag='110'][marc:subfield/@code='0' or marc:subfield/@code='a' or marc:subfield/@code='b' or marc:subfield/@code='d'
				or marc:subfield/@code='g' or marc:subfield/@code='p']"/>
				<xsl:apply-templates
					select="marc:datafield[@tag='700'][marc:subfield/@code='0' or marc:subfield/@code='a' or marc:subfield/@code='b' or marc:subfield/@code='c'
				or marc:subfield/@code='d' or marc:subfield/@code='e' or marc:subfield/@code='g' or marc:subfield/@code='j' or marc:subfield/@code='p'
				or marc:subfield/@code='q' or marc:subfield/@code='r' or marc:subfield/@code='t' or marc:subfield/@code='x']"/>
				<xsl:apply-templates
					select="marc:datafield[@tag='710'][marc:subfield/@code='0' or marc:subfield/@code='a' or marc:subfield/@code='b' or marc:subfield/@code='d'
				or marc:subfield/@code='g' or marc:subfield/@code='p']"/>
				<xsl:apply-templates
					select="marc:datafield[@tag='711'][marc:subfield/@code='a' or marc:subfield/@code='c' or marc:subfield/@code='d' or
				marc:subfield/@code='g' or marc:subfield/@code='n']"
				/>
			</vra:agentSet>
		</xsl:if>

        <!-- _______________CULTURAL CONTEXT_________________ -->
		<!-- added by Mike - 3/12/2012-->
		<xsl:call-template name="addEmptyCulturalContextSet"/>
		<!-- Mike -->

		<!-- ______________ DATES ______________ -->
		<!-- Now getting dates from 046/648; Bill Parod 1/31/2012; Commenting out 260/650/652 usage. Removed commented section (Jen 11/18/2014) -->
		<!-- Removed 650/651 y from dateSet, Jen 07/30/2014; removed 648, Jen 8/20/2014; -->
		<!-- Reworked to allow for missing 260 $c mapping to Unknown, Jen, 8/25/2014 -->


		<xsl:call-template name="dates"/>


		<!-- ______________ DESCRIPTION ______________ -->
		<xsl:if test="marc:datafield[@tag='500']/marc:subfield[@code='a']">
			<xsl:call-template name="comment">
				<xsl:with-param name="comment">Description</xsl:with-param>
			</xsl:call-template>
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

		<!-- ___________INSCRIPTION______________ -->
		<!-- added by Mike - 3/12/2012-->
		<xsl:call-template name="addEmptyInscriptionSet"/>
		<!-- Mike -->

		<!-- ______________ LOCATION ______________ -->
		<!-- Always have location because we always have a pid and probably have a bibid (Note: "bibid" is really the image id, not a Voyager number -Jen 7/30/2014)-->
		<!-- Added 773 18 to go into Location, Jen 8/26/2014 -->

		<xsl:call-template name="comment">
			<xsl:with-param name="comment">Location</xsl:with-param>
		</xsl:call-template>
		<vra:locationSet>
			<vra:display>

				<xsl:if test="marc:datafield[@tag='752']/marc:subfield[@code!='g']
					| marc:datafield[@tag='535']/marc:subfield[@code='a' or @code='b']
					| marc:datafield[@tag='773' and @ind1='1' and @ind2='8']/marc:subfield[@code='a' or @code='g']">
				<xsl:for-each
					select="marc:datafield[@tag='752']/marc:subfield[@code!='g']
					| marc:datafield[@tag='535']/marc:subfield[@code='a' or @code='b']
					| marc:datafield[@tag='773' and @ind1='1' and @ind2='8']/marc:subfield[@code='a' or @code='g']">
					<xsl:call-template name="displaySeparator"/>
					<xsl:call-template name="stripTrailingPeriod">
						<xsl:with-param name="val">
							<xsl:apply-templates select="." mode="display"/>
						</xsl:with-param>
					</xsl:call-template>

				</xsl:for-each>

					<xsl:if test="$pid!=''"> ; </xsl:if>
				</xsl:if>

				<xsl:if test="$pid!=''">DIL:<xsl:value-of select="$pid"/></xsl:if>
				<xsl:if test="$bibid!=''"> ; Voyager:<xsl:value-of select="$bibid"/></xsl:if>

				<!-- added if 773 18 not in record, add one containing Digital Image Library. Jen 10/3/2014 -->
				<xsl:choose>
					<xsl:when test="marc:datafield[@tag='773' and @ind1='1' and @ind2='8']/marc:subfield[@code='a' or @code='g']"/>
					<xsl:otherwise>
						<xsl:text> ; Digital Image Library</xsl:text>
					</xsl:otherwise>
				</xsl:choose>

			</vra:display>

			<xsl:for-each select="marc:datafield[@tag='752'][marc:subfield/@code!='g']">
				<vra:location type="discovery">
					<xsl:apply-templates select="marc:subfield[not(@code='g')]"/>
				</vra:location>
			</xsl:for-each>

			<xsl:for-each
				select="marc:datafield[@tag='535'][marc:subfield/@code='a' or marc:subfield/@code='b']">
				<vra:location type="repository">
					<xsl:apply-templates select="marc:subfield[@code='a' or @code='b']"/>
				</vra:location>
			</xsl:for-each>

			<xsl:for-each select="marc:datafield[@tag='773' and @ind1='1'
				and @ind2='8']/marc:subfield[@code='a' or @code='g']">
				<vra:location type="repository">
					<xsl:apply-templates select="."/>
				</vra:location>
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

		<!-- ______________ MATERIALS ______________ -->
		<xsl:if test="marc:datafield[@tag='340']/marc:subfield[@code='a']">
			<xsl:call-template name="comment">
				<xsl:with-param name="comment">Materials</xsl:with-param>
			</xsl:call-template>
			<vra:materialSet>
				<vra:display>
					<xsl:for-each select="marc:datafield[@tag='340']/marc:subfield[@code='a']">
						<xsl:call-template name="displaySeparator"/>
						<xsl:call-template name="stripTrailingPeriod">
							<xsl:with-param name="val">
								<xsl:value-of select="."/>
							</xsl:with-param>
						</xsl:call-template>
					</xsl:for-each>
				</vra:display>
				<xsl:apply-templates select="marc:datafield[@tag='340']/marc:subfield[@code='a']"/>
			</vra:materialSet>
		</xsl:if>

		<!-- ______________ MEASUREMENTS ______________ -->
		<xsl:if test="marc:datafield[@tag='340']/marc:subfield[@code='b']">
			<xsl:call-template name="comment">
				<xsl:with-param name="comment">Measurements</xsl:with-param>
			</xsl:call-template>
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


		<!-- ______________ RELATION ______________ -->
		<!-- Work and Image records are created from the same MARC record -->
		<!-- removed 245 $p from going into Relation, Jen 8/20/2014 -->
		<!-- added 800 fields, Jen 8/25/2014 -->
		<xsl:variable name="rel_title">
			<xsl:for-each
				select="marc:datafield[@tag='245']/marc:subfield[@code='a']
				| marc:datafield[@tag='800']">
				<xsl:call-template name="comment">
					<xsl:with-param name="comment">Relation</xsl:with-param>
				</xsl:call-template>
				<xsl:call-template name="displaySeparator"/>
				<xsl:call-template name="stripTrailingPeriod">
					<xsl:with-param name="val">
						<xsl:for-each select="marc:datafield[@tag='245']/marc:subfield[@code='a']
							| marc:datafield[@tag='800']/marc:subfield[@code='a'  or @code='q' or @code='d' or
							 @code='t']">
							<xsl:if test="position()!=1"><xsl:text> </xsl:text></xsl:if>
							<xsl:value-of select="."/>
						</xsl:for-each>
					</xsl:with-param>
				</xsl:call-template>
				<xsl:apply-templates select="." mode="display"/>
			</xsl:for-each>
		</xsl:variable>

		<xsl:choose>
			<!--<xsl:when test="$rel_title">-->

			<!-- CHANGE THIS BACK BEFORE TESTING ON CECIL uncomment out the text below // to test locally comment out the first when with $work, etc.
			and uncomment out above line with $rel Need to do this to test Relation-->

			<xsl:when test="$work_or_image='image' and $work_pid!=''">
			<xsl:call-template name="comment">
					<xsl:with-param name="comment">Relation</xsl:with-param>
			</xsl:call-template>
			<vra:relationSet>
					<vra:display>
						<xsl:value-of select="normalize-space($rel_title)"/>
					</vra:display>
					<vra:relation pref="true" type="imageOf">
						<xsl:attribute name="relids">
							<xsl:value-of select="$work_pid"/>
						</xsl:attribute>
						<xsl:value-of select="normalize-space($rel_title)"/>
					</vra:relation>
				</vra:relationSet>
			</xsl:when>
			<xsl:when test="$work_or_image='work' and $item_pid!=''">
				<xsl:call-template name="comment">
					<xsl:with-param name="comment">Relation</xsl:with-param>
				</xsl:call-template>
				<vra:relationSet>
					<vra:display>
						<xsl:value-of select="normalize-space($rel_title)"/>
					</vra:display>
					<vra:relation pref="true" type="imageIs">
						<xsl:attribute name="relids">
							<xsl:value-of select="$item_pid"/>
						</xsl:attribute>
						<xsl:value-of select="normalize-space($rel_title)"/>
					</vra:relation>
				</vra:relationSet>
			</xsl:when>
			<xsl:otherwise/>
		</xsl:choose>

		<!-- _______________RIGHTS_____________ -->
		<!-- added by jen 8/20/2014 -->
		<xsl:call-template name="addEmptyRightsSet"/>

		<!-- ______________ SOURCE ______________ -->
		<!-- Mapped 773 0_ to Source, Jen, 8/26/2014 -->
		<xsl:if test="marc:datafield[@tag='773' and @ind1='0' and @ind2=' ']">
			<xsl:call-template name="comment">
				<xsl:with-param name="comment">Source</xsl:with-param>
			</xsl:call-template>
			<vra:sourceSet>
				<vra:display>
					<xsl:for-each
						select="marc:datafield[@tag='773' and @ind1='0' and @ind2=' ']/marc:subfield[@code='a']">
						<xsl:value-of select="."/>
						<xsl:text> </xsl:text>
					</xsl:for-each>
					<xsl:for-each
						select="marc:datafield[@tag='773' and @ind1='0' and @ind2=' ']/marc:subfield[@code='t']">
						<xsl:value-of select="."/>
						<xsl:text> </xsl:text>
					</xsl:for-each>
					<xsl:for-each select="marc:datafield[@tag='773' and @ind1='0' and @ind2=' ']/marc:subfield[@code='g']">
						<xsl:value-of select="."/>
					</xsl:for-each>
				</vra:display>
				<xsl:call-template name="displaySeparator"/>
				<xsl:apply-templates select="marc:datafield[@tag='773' and @ind1='0' and @ind2=' ']/marc:subfield[@code='a' or @code='g' or @code='t']"/>
			</vra:sourceSet>
		</xsl:if>

		<!-- ______________STATE EDITION______________ -->
		<!-- added by jen 8/20/2014 -->
		<xsl:call-template name="addEmptyStateEditionSet"/>

		<!-- ______________ STYLE/PERIOD ______________ -->
		<xsl:if test="marc:datafield[@tag='653']/marc:subfield[@code='a']">
			<xsl:call-template name="comment">
				<xsl:with-param name="comment">Style/Period</xsl:with-param>
			</xsl:call-template>
			<vra:stylePeriodSet>
				<vra:display>
					<xsl:for-each select="marc:datafield[@tag='653']/marc:subfield[@code='a']">
						<xsl:call-template name="displaySeparator"/>
						<xsl:call-template name="stripTrailingPeriod">
							<xsl:with-param name="val">
								<xsl:choose>
									<xsl:when
										test="../marc:subfield[@code='v' or @code='x' or @code='y' or @code='z']">
										<xsl:value-of
											select="string-join((.,../marc:subfield[@code='v' or @code='x' or @code='y' or @code='z']),'--')"
										/>
									</xsl:when>
									<xsl:otherwise>
										<xsl:value-of select="."/>
									</xsl:otherwise>
								</xsl:choose>
							</xsl:with-param>
						</xsl:call-template>
					</xsl:for-each>
				</vra:display>
				<xsl:for-each select="marc:datafield[@tag='653']/marc:subfield[@code='a']">
					<vra:stylePeriod>
						<xsl:value-of select="."/>
					</vra:stylePeriod>
				</xsl:for-each>
			</vra:stylePeriodSet>
		</xsl:if>


		<!-- ______________ SUBJECTSET______________ -->
		<!-- or @tag='610' or @tag='650' or @tag='651'-->
		<!-- Added subfields, 611, 630 fields. Also changed parsing of $y and of the strings in general. Jen 7/30/2014 -->

		<xsl:if
			test="marc:datafield[@tag='600' or @tag='610' or @tag='611' or @tag='630' or @tag='650' or @tag='651']">
			<xsl:call-template name="comment">
				<xsl:with-param name="comment">Subjects</xsl:with-param>
			</xsl:call-template>
			<vra:subjectSet>
				<vra:display>
					<xsl:for-each
						select="marc:datafield[@tag='600'] | marc:datafield[@tag='610'] | marc:datafield[@tag='650']
						| marc:datafield[@tag='611'] | marc:datafield[@tag='630']
						| marc:datafield[@tag='651']">
						<xsl:call-template name="displaySeparator"/>
						<xsl:call-template name="stripTrailingPeriod">
							<xsl:with-param name="val">
								<xsl:for-each
									select="marc:subfield[@code='a' or @code='b' or @code='c' or @code='d' or @code='q' or @code='t' or @code='n']">
									<xsl:if test="position()!=1">
										<xsl:text> </xsl:text>
									</xsl:if>
									<xsl:value-of select="."/>
								</xsl:for-each>
								<xsl:for-each
									select="marc:subfield[@code='x' or @code='y' or @code='v' or @code='z']">
									<xsl:text>--</xsl:text>
									<xsl:value-of select="."/>
								</xsl:for-each>
							</xsl:with-param>
						</xsl:call-template>
					</xsl:for-each>
				</vra:display>
				<xsl:apply-templates select="marc:datafield[@tag='600']">
					<xsl:with-param name="subjectType">personalName</xsl:with-param>
				</xsl:apply-templates>
				<xsl:apply-templates select="marc:datafield[@tag='610'] | marc:datafield[@tag='611']">
					<xsl:with-param name="subjectType">corporateName</xsl:with-param>
				</xsl:apply-templates>
				<xsl:apply-templates select="marc:datafield[@tag='630'] | marc:datafield[@tag='650']">
					<xsl:with-param name="subjectType">descriptiveTopic</xsl:with-param>
				</xsl:apply-templates>
				<xsl:apply-templates select="marc:datafield[@tag='651']">
					<xsl:with-param name="subjectType">geographicPlace</xsl:with-param>
				</xsl:apply-templates>
			</vra:subjectSet>
		</xsl:if>

		<!--_____________TECHNIQUE___________________ -->
		<!-- added by Mike - 3/12/2012-->
		<xsl:call-template name="addEmptyTechniqueSet"/>
		<!-- Mike -->

		<!-- ____________TEXTREF___________________ -->
		<!-- added by jen 8/20/2014 -->
		<xsl:call-template name="addEmptyTextrefSet"/>

		<!-- ______________ TITLES ______________ -->
		<xsl:if test="marc:datafield[@tag='245' or @tag='246']">
			<xsl:call-template name="comment">
				<xsl:with-param name="comment"> Titles </xsl:with-param>
			</xsl:call-template>
			<vra:titleSet>
				<vra:display>
					<xsl:for-each
							select="marc:datafield[@tag='245'][marc:subfield/@code='a' or marc:subfield/@code='p']">
						<xsl:call-template name="displaySeparator"/>

						<!-- Changed by Bill Parod 1/22/2012 -->
						<!-- <xsl:apply-templates select="." /> -->
						<xsl:apply-templates select="." mode="display"/>
					</xsl:for-each>
				</vra:display>
				<xsl:apply-templates
					select="marc:datafield[@tag='245'][marc:subfield/@code='a' or marc:subfield/@code='p']"/>
				<xsl:apply-templates select="marc:datafield[@tag='246'][marc:subfield/@code='a']"/>
			</vra:titleSet>
		</xsl:if>

		<!--Added by Karen-->
		<!-- ______________ WORKTYPE ______________ -->
		<xsl:if test="marc:datafield[@tag='655']/marc:subfield[@code='a']">
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
		</xsl:if>
	</xsl:template>

	<!-- added by Mike - 3/12/2012 -->
	<!-- added empty rights, state edition and text ref sets. jen, 8/20/2014 -->
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

	<xsl:template name="addEmptyRightsSet">
		<xsl:call-template name="comment">
			<xsl:with-param name="comment">Rights</xsl:with-param>
		</xsl:call-template>
		<vra:rightsSet>
			<vra:display/>
			<vra:rights>
				<vra:text/>
			</vra:rights>
		</vra:rightsSet>
	</xsl:template>

	<xsl:template name="addEmptyStateEditionSet">
		<xsl:call-template name="comment">
			<xsl:with-param name="comment">State Edition</xsl:with-param>
		</xsl:call-template>
		<vra:stateEditionSet>
			<vra:display/>
			<vra:stateEdition/>
		</vra:stateEditionSet>
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

	<xsl:template name="addEmptyTextrefSet">
		<xsl:call-template name="comment">
			<xsl:with-param name="comment">Textref</xsl:with-param>
		</xsl:call-template>
		<vra:textrefSet>
			<vra:display/>
			<vra:textref/>
		</vra:textrefSet>
	</xsl:template>



<!-- TEMPLATE MATCHES BELOW, SETS ABOVE -->

	<!-- AGENT DISPLAY -->
	<!-- added subfields, 711 Jen 7/30/2014 -->
	<xsl:template match="marc:datafield[@tag='100']" mode="display">
		<xsl:call-template name="stripTrailingPeriod">
			<xsl:with-param name="val">
				<xsl:value-of
					select="marc:subfield[@code='a' or @code='b' or @code='c' or @code='d' or @code='e' or @code='g'
			or @code='j' or @code='p' or @code='q']"
				/>
			</xsl:with-param>
		</xsl:call-template>
	</xsl:template>
	<xsl:template match="marc:datafield[@tag='110']" mode="display">
		<xsl:call-template name="stripTrailingPeriod">
			<xsl:with-param name="val">
				<xsl:value-of
					select="marc:subfield[@code='a' or @code='b' or @code='d' or @code='g' or @code='p']"
				/>
			</xsl:with-param>
		</xsl:call-template>
	</xsl:template>
	<xsl:template match="marc:datafield[@tag='700']" mode="display">
		<xsl:call-template name="stripTrailingPeriod">
			<xsl:with-param name="val">
				<xsl:value-of
					select="marc:subfield[@code='a' or @code='b' or @code='c' or @code='d' or @code='e' or @code='g'
			or @code='j' or @code='p' or @code='q' or @code='r' or @code='t' or @code='x']"
				/>
			</xsl:with-param>
		</xsl:call-template>
	</xsl:template>
	<xsl:template match="marc:datafield[@tag='710']" mode="display">
		<xsl:call-template name="stripTrailingPeriod">
			<xsl:with-param name="val">
				<xsl:value-of
					select="marc:subfield[@code='a' or @code='b' or @code='d' or @code='g' or @code='p']"
				/>
			</xsl:with-param>
		</xsl:call-template>
	</xsl:template>
	<xsl:template match="marc:datafield[@tag='711']" mode="display">
		<xsl:call-template name="stripTrailingPeriod">
			<xsl:with-param name="val">
				<xsl:value-of
					select="marc:subfield[@code='a' or @code='c' or @code='d' or @code='n']"/>
			</xsl:with-param>
		</xsl:call-template>
	</xsl:template>

	<!-- AGENT -->
	<xsl:template match="marc:datafield[@tag='100'or @tag='700']">
		<vra:agent>
			<vra:name type="personal" vocab="ulan">
				<xsl:apply-templates select="marc:subfield[@code='0']"/>
				<xsl:call-template name="stripTrailingPeriod">
					<xsl:with-param name="val">
						<xsl:value-of
							select="marc:subfield[@code='a' or @code='b' or @code='c' or @code='d' or @code='g' or @code='j' or @code='q']"
						/>
					</xsl:with-param>
				</xsl:call-template>
			</vra:name>

			<!-- added by Mike 3/12/2012-->
			<xsl:if
				test="//marc:datafield[@tag='046']/marc:subfield[@code='f']
				| //marc:datafield[@tag='046']/marc:subfield[@code='g']">
				<vra:dates type="life">
					<xsl:apply-templates
						select="//marc:datafield[@tag='046']/marc:subfield[@code='f']"/>
					<xsl:apply-templates
						select="//marc:datafield[@tag='046']/marc:subfield[@code='g']"/>
				</vra:dates>
			</xsl:if>
			<xsl:apply-templates select="//marc:datafield[@tag='370']/marc:subfield[@code='a']"/>
			<vra:attribution/>
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

	<!-- IS THIS USED? (370) -->
	<xsl:template match="//marc:datafield[@tag='370']/marc:subfield[@code='a']">
		<vra:culture>
			<xsl:value-of select="//marc:datafield[@tag='370']/marc:subfield[@code='a']"/>
		</vra:culture>
	</xsl:template>

	<xsl:template match="marc:datafield[@tag='110' or @tag='710']">
		<vra:agent>
			<vra:name type="corporate" vocab="ulan">
				<xsl:apply-templates select="marc:subfield[@code='0']"/>
				<xsl:call-template name="stripTrailingPeriod">
					<xsl:with-param name="val">
						<xsl:value-of select="marc:subfield[@code='a' or @code='b' or @code='g']"/>
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
			<vra:attribution/>
			<!-- Mike -->
		</vra:agent>
	</xsl:template>

	<xsl:template match="marc:subfield[@code='0']">
		<xsl:attribute name="refid">
			<xsl:value-of select="."/>
		</xsl:attribute>
	</xsl:template>

	<!-- AGENT DATE-->
	<!-- Removed this long commented out section, available in git, 11/18/2014 Jen -->

	<!-- TITLES -->
	<xsl:template
		match="marc:datafield[@tag='245'][marc:subfield/@code='a' or marc:subfield/@code='p']">
		<vra:title pref="true">
			<xsl:call-template name="stripTrailingPeriod">
				<xsl:with-param name="val">
					<xsl:value-of select="marc:subfield[@code='a' or @code='p']"/>
				</xsl:with-param>
			</xsl:call-template>
		</vra:title>
	</xsl:template>

	<!-- Added by Bill Parod 1/22/2012 -->
	<xsl:template
		match="marc:datafield[@tag='245'][marc:subfield/@code='a' or marc:subfield/@code='p']"
		mode="display">
		<xsl:call-template name="stripTrailingPeriod">
			<xsl:with-param name="val">
				<xsl:value-of select="marc:subfield[@code='a' or @code='p']"/>
			</xsl:with-param>
		</xsl:call-template>
	</xsl:template>

	<xsl:template match="marc:datafield[@tag='246'][marc:subfield/@code='a']">
		<vra:title pref="false">
			<xsl:call-template name="stripTrailingPeriod">
				<xsl:with-param name="val">
					<xsl:value-of select="marc:subfield[@code='a']"/>
				</xsl:with-param>
			</xsl:call-template>
		</vra:title>
	</xsl:template>


	<!-- 260 $c DATE added by Jen 8/28/2014; added capitalizing first letter of date field, jen 10/3/2014-->
	<xsl:template name="dates">
		<xsl:call-template name="comment">
			<xsl:with-param name="comment">Dates</xsl:with-param>
		</xsl:call-template>
		<vra:dateSet>
			<vra:display>
				<xsl:choose>
					<xsl:when test="marc:datafield[@tag='260'][marc:subfield/@code='c']">
						<xsl:call-template name="publicationDate">
							<xsl:with-param name="thisC">
								<xsl:value-of
									select="concat(upper-case(substring(normalize-space(marc:datafield[@tag='260']/marc:subfield[@code='c']),1,1)),
									substring(normalize-space(marc:datafield[@tag='260']/marc:subfield[@code='c']),2))"/>
							</xsl:with-param>
						</xsl:call-template>
					</xsl:when>
					<xsl:otherwise>
						<xsl:text>Unknown</xsl:text>
					</xsl:otherwise>
				</xsl:choose>
			</vra:display>
			<xsl:apply-templates select="marc:datafield[@tag='046']"/>
		</vra:dateSet>
	</xsl:template>


	<xsl:template name="publicationDate">
		<xsl:param name="thisC"/>

		<xsl:choose>
			<xsl:when test="contains($thisC,' - ')">

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
							<xsl:matching-substring><xsl:value-of select="."/>0s</xsl:matching-substring>
						</xsl:analyze-string>
					</xsl:matching-substring>
				</xsl:analyze-string>

				<xsl:analyze-string select="$thisC" regex=" - ">
					<xsl:matching-substring>
						<xsl:value-of select="translate(replace($thisC,' - ','-'),'[]?.','')"/>
					</xsl:matching-substring>
				</xsl:analyze-string>
			</xsl:when>

			<xsl:otherwise>
				<xsl:value-of select="translate($thisC,'[]?.','')"/>
			</xsl:otherwise>

		</xsl:choose>
		<xsl:call-template name="displaySeparator"/>
	</xsl:template>


	<!-- date 046$s, 046$t, 648$s, and 648$t; 648 information removed 8/20/2014 by Jen -->

	<xsl:template match="marc:datafield[@tag='046']">
		<vra:date type="creation">
			<xsl:apply-templates select="marc:subfield[@code='s']" mode="earliestDate"/>
			<xsl:apply-templates select="marc:subfield[@code='t']" mode="latestDate"/>
		</vra:date>
	</xsl:template>

	<!--<xsl:template match="marc:datafield[@tag='648']">
		<vra:date type="view">
			<xsl:apply-templates select="marc:subfield[@code='s']" mode="earliestDate"/>
			<xsl:apply-templates select="marc:subfield[@code='t']" mode="latestDate"/>
		</vra:date>
	</xsl:template>-->


	<xsl:template match="marc:subfield[@code='s']" mode="earliestDate">
		<vra:earliestDate>
			<xsl:value-of select="."/>
		</vra:earliestDate>

	<!--<xsl:choose>
		<xsl:when test="contains(.,'/')">
			<vra:earliestDate><xsl:value-of select="substring-before(.,'/')"/></vra:earliestDate>
		</xsl:when>
		<xsl:otherwise>
			<vra:earliestDate><xsl:value-of select="."/></vra:earliestDate>
		</xsl:otherwise>
	</xsl:choose>-->

	</xsl:template>

	<xsl:template match="marc:subfield[@code='t']" mode="latestDate">
		<vra:latestDate>
			<xsl:value-of select="."/>
		</vra:latestDate>
		<!--	<xsl:choose>
		<xsl:when test="contains(.,'/')">
			<vra:latestDate><xsl:value-of select="substring-after(.,'/')"/></vra:latestDate>
		</xsl:when>
		<xsl:otherwise>
			<vra:latestDate><xsl:value-of select="."/></vra:latestDate>
		</xsl:otherwise>
	</xsl:choose>-->

	</xsl:template>

	<!-- DESCRIPTION -->
	<xsl:template match="marc:datafield[@tag='500']/marc:subfield[@code='a']">
		<vra:description>
			<xsl:value-of select="."/>
		</vra:description>
	</xsl:template>

	<!-- DESCRIPTION -->
	<xsl:template match="marc:datafield[@tag='500']">
		<vra:descriptionSet>
			<vra:description type="creation">
				<xsl:value-of select="marc:subfield[@code='a']"/>
			</vra:description>
		</vra:descriptionSet>
	</xsl:template>

	<!-- LOCATION 752 display mode -->
	<xsl:template match="marc:datafield[@tag='752'][marc:subfield/@code!='g']" mode="display">
		<xsl:value-of select="marc:subfield[not(@code='g')]"/>
	</xsl:template>

	<!-- LOCATION 752$a -->
	<xsl:template match="marc:datafield[@tag='752']/marc:subfield[@code='a']">
		<vra:name type="geographic" extent="Country or larger entity">
			<xsl:call-template name="stripTrailingPeriod">
				<xsl:with-param name="val">
					<xsl:value-of select="."/>
				</xsl:with-param>
			</xsl:call-template>
		</vra:name>
	</xsl:template>
	<!-- LOCATION 752$b -->
	<xsl:template match="marc:datafield[@tag='752']/marc:subfield[@code='b']">
		<vra:name type="geographic" extent="First-order political jurisdiction">
			<xsl:call-template name="stripTrailingPeriod">
				<xsl:with-param name="val">
					<xsl:value-of select="."/>
				</xsl:with-param>
			</xsl:call-template>
		</vra:name>
	</xsl:template>
	<!-- LOCATION 752$c -->
	<xsl:template match="marc:datafield[@tag='752']/marc:subfield[@code='c']">
		<vra:name type="geographic" extent="Intermediate political jurisdiction">
			<xsl:call-template name="stripTrailingPeriod">
				<xsl:with-param name="val">
					<xsl:value-of select="."/>
				</xsl:with-param>
			</xsl:call-template>
		</vra:name>
	</xsl:template>
	<!-- LOCATION 752$d -->
	<xsl:template match="marc:datafield[@tag='752']/marc:subfield[@code='d']">
		<vra:name type="geographic" extent="City">
			<xsl:call-template name="stripTrailingPeriod">
				<xsl:with-param name="val">
					<xsl:value-of select="."/>
				</xsl:with-param>
			</xsl:call-template>
		</vra:name>
	</xsl:template>


	<!-- LOCATION 535 display mode -->
	<xsl:template
		match="marc:datafield[@tag='535'][marc:subfield/@code='a' or marc:subfield/@code='b']"
		mode="display">
		<xsl:value-of select="marc:subfield[@code='a' or @code='b']"/>
		<xsl:call-template name="displaySeparator"/>
	</xsl:template>

	<!-- LOCATION 535$a -->
	<xsl:template match="marc:datafield[@tag='535']/marc:subfield[@code='a']">
		<vra:name type="corporate">
			<xsl:call-template name="stripTrailingPeriod">
				<xsl:with-param name="val">
					<xsl:value-of select="."/>
				</xsl:with-param>
			</xsl:call-template>
		</vra:name>
	</xsl:template>
	<!-- LOCATION 535$b -->
	<xsl:template match="marc:datafield[@tag='535']/marc:subfield[@code='b']">
		<vra:name type="geographic">
			<xsl:call-template name="stripTrailingPeriod">
				<xsl:with-param name="val">
					<xsl:value-of select="."/>
				</xsl:with-param>
			</xsl:call-template>
		</vra:name>
	</xsl:template>

	<!-- LOCATION 773 18 display mode -->
	<xsl:template
		match="marc:datafield[@tag='773' and @ind1='1' and @ind2='8']
		[marc:subfield/@code='a' or marc:subfield/@code='g']"
		mode="display">
		<xsl:value-of select="marc:subfield[@code='a' or @code='g']"/>
	</xsl:template>

	<!-- LOCATION 773 18  -->
	<xsl:template match="marc:datafield[@tag='773' and @ind1='1' and @ind2='8']/marc:subfield[@code='a' or @code='g']">
		<vra:name type="other">
			<xsl:call-template name="stripTrailingPeriod">
				<xsl:with-param name="val">
					<xsl:value-of select="."/>
				</xsl:with-param>
			</xsl:call-template>
		</vra:name>
	</xsl:template>

	<!-- MATERIAL -->
	<xsl:template match="marc:datafield[@tag='340']/marc:subfield[@code='a']">
		<vra:material>
			<xsl:call-template name="stripTrailingPeriod">
				<xsl:with-param name="val">
					<xsl:value-of select="."/>
				</xsl:with-param>
			</xsl:call-template>
		</vra:material>
	</xsl:template>

	<!-- MEASUREMENTS -->
	<xsl:template match="marc:datafield[@tag='340']/marc:subfield[@code='b']">
		<vra:measurements>
			<xsl:value-of select="."/>
		</vra:measurements>
	</xsl:template>

	<!-- RELATIONS -->

	<!-- STYLE/PERIOD vocab attribute -->
	<xsl:template match="marc:subfield[@code='2']">
		<xsl:attribute name="vocab">
			<xsl:value-of select="."/>
		</xsl:attribute>
	</xsl:template>

	<!-- SUBJECTS -->
	<!-- reworked section. Jen 7/31/2014 -->

	<xsl:template
		match="marc:datafield[@tag='600'] | marc:datafield[@tag='610'] | marc:datafield[@tag='611']
		| marc:datafield[@tag='630'] | marc:datafield[@tag='650'] | marc:datafield[@tag='651']">
		<xsl:param name="subjectType"/>
		<vra:subject>
			<vra:term>
				<xsl:attribute name="type">
					<xsl:value-of select="$subjectType"/>
				</xsl:attribute>
				<xsl:choose>
					<xsl:when test="marc:subfield[@code='2']">
						<xsl:apply-templates select="marc:subfield[@code='2']"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:choose>
							<xsl:when
								test="($subjectType='corporateName' or $subjectType='personalName')">
								<xsl:attribute name="vocab">lcnaf</xsl:attribute>
							</xsl:when>
							<xsl:otherwise>
								<xsl:attribute name="vocab">lcsh</xsl:attribute>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:otherwise>
				</xsl:choose>
				<xsl:for-each
					select="marc:subfield[@code='a' or @code='b' or @code='c' or @code='d' or @code='q' or @code='p'
					or @code='n' or @code='t']">
					<xsl:if test="position()!=1">
						<xsl:text> </xsl:text>
					</xsl:if>
					<xsl:choose>
						<xsl:when test="position()=last()">
							<xsl:call-template name="stripTrailingPeriod">
								<xsl:with-param name="val">
									<xsl:value-of select="."/>
								</xsl:with-param>
							</xsl:call-template>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="."/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:for-each>
			</vra:term>
		</vra:subject>

		<xsl:for-each select="marc:subfield[@code='v']">
			<vra:subject>
				<vra:term>
					<xsl:attribute name="type">otherTopic</xsl:attribute>
					<xsl:call-template name="stripTrailingPeriod">
						<xsl:with-param name="val">
							<xsl:value-of select="."/>
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
							<xsl:value-of select="."/>
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
							<xsl:value-of select="."/>
						</xsl:with-param>
					</xsl:call-template>
				</vra:term>
			</vra:subject>
		</xsl:for-each>

	</xsl:template>

	<!-- LOCATION -->
	<!-- No longer want this mapped to location, Jen 7/30/2014 -->
	<!--<xsl:template match="marc:datafield[@tag='650']">
		<vra:location><vra:name>
			<xsl:value-of select="marc:subfield[@code='a' or @code='d' or @code='v' or @code='x' or @code='y' or @code='z']"/>
		</vra:name></vra:location>
</xsl:template>
<xsl:template match="marc:datafield[@tag='651']">-->
	<vra:location>
		<vra:name>
			<xsl:value-of select="marc:subfield[@code='a' or @code='g']"/>
		</vra:name>
	</vra:location>
	<!--</xsl:template>-->

	<!-- SOURCE -->
	<xsl:template match="marc:datafield[@tag='773' and @ind1='0' and @ind2=' ']/marc:subfield[@code='a' or @code='g' or @code='t']">
		<vra:source>
			<vra:name>
				<xsl:value-of select="."/>
			</vra:name>
		</vra:source>
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

	<xsl:template match="*|text()"/>

</xsl:stylesheet>
