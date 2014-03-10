<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:fn="http://www.w3.org/2005/xpath-functions" xmlns:marc="http://www.loc.gov/MARC21/slim"
	xmlns:mods="http://www.loc.gov/mods/v3" xmlns:vra="http://www.vraweb.org/vracore4.htm"
	xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">

	<xsl:param name="bibid" select="//marc:controlfield[@tag='001']"/>
	<xsl:param name="pid"/>
	<xsl:param name="work_pid"/>
	<xsl:param name="item_pid"/>
	<xsl:param name="work_or_image"/>

	<xsl:output method="xml" omit-xml-declaration="no" indent="yes" encoding="utf-8"
		media-type="text/xml"/>

	<xsl:template match="/">
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
	<xsl:template name="marc2vra">
		<!-- ______________ Agents ______________ -->
		<xsl:if
			test="marc:datafield[@tag='100'][marc:subfield/@code='0' or marc:subfield/@code='a' or marc:subfield/@code='b' or marc:subfield/@code='c' or marc:subfield/@code='d' or marc:subfield/@code='g' or marc:subfield/@code='j' or marc:subfield/@code='q']
			or marc:datafield[@tag='110'][marc:subfield/@code='0' or marc:subfield/@code='a' or marc:subfield/@code='b' or marc:subfield/@code='g'] 
			or marc:datafield[@tag='700'][marc:subfield/@code='0' or marc:subfield/@code='a' or marc:subfield/@code='b' or marc:subfield/@code='c' or marc:subfield/@code='d' or marc:subfield/@code='g' or marc:subfield/@code='j' or marc:subfield/@code='q']
			or marc:datafield[@tag='710'][marc:subfield/@code='0' or marc:subfield/@code='a' or marc:subfield/@code='b' or marc:subfield/@code='g']
			or marc:datafield[@tag='260']/marc:subfield[@code='b']">
			<xsl:call-template name="comment">
				<xsl:with-param name="comment">Agents</xsl:with-param>
			</xsl:call-template>
			<vra:agentSet>
				<vra:display>
					<xsl:for-each
						select="marc:datafield[@tag='100'][marc:subfield/@code='0' or marc:subfield/@code='a' or marc:subfield/@code='b' or marc:subfield/@code='c' or marc:subfield/@code='d' or marc:subfield/@code='g' or marc:subfield/@code='j' or marc:subfield/@code='q'] 
						| marc:datafield[@tag='110'][marc:subfield/@code='0' or marc:subfield/@code='a' or marc:subfield/@code='b' or marc:subfield/@code='g']
						| marc:datafield[@tag='700'][marc:subfield/@code='0' or marc:subfield/@code='a' or marc:subfield/@code='b' or marc:subfield/@code='c' or marc:subfield/@code='d' or marc:subfield/@code='g' or marc:subfield/@code='j' or marc:subfield/@code='q']
						| marc:datafield[@tag='710'][marc:subfield/@code='a' or marc:subfield/@code='b' or marc:subfield/@code='g'] ">
						<xsl:call-template name="displaySeparator"/>
						<xsl:apply-templates select="." mode="display"/>													
					</xsl:for-each>
					<xsl:if test="marc:datafield[@tag='260']/marc:subfield[@code='b']"> ; <xsl:analyze-string select="marc:datafield[@tag='260']/marc:subfield[@code='b']" regex="(,| :|\],)$">
							<xsl:non-matching-substring>
								<xsl:value-of select="."/>
							</xsl:non-matching-substring>
						</xsl:analyze-string>
					</xsl:if>
				</vra:display>
				<xsl:apply-templates
					select="marc:datafield[@tag='100'][marc:subfield/@code='0' or marc:subfield/@code='a' or marc:subfield/@code='b' or marc:subfield/@code='c' or marc:subfield/@code='d' or marc:subfield/@code='g' or marc:subfield/@code='j' or marc:subfield/@code='q']"/>
				<xsl:apply-templates
					select="marc:datafield[@tag='110'][marc:subfield/@code='0' or marc:subfield/@code='a' or marc:subfield/@code='b' or marc:subfield/@code='g']"/>
				<xsl:apply-templates
					select="marc:datafield[@tag='700'][marc:subfield/@code='0' or marc:subfield/@code='a' or marc:subfield/@code='b' or marc:subfield/@code='c' or marc:subfield/@code='d' or marc:subfield/@code='g' or marc:subfield/@code='j' or marc:subfield/@code='q']"/>
				<xsl:apply-templates
					select="marc:datafield[@tag='710'][marc:subfield/@code='0' or marc:subfield/@code='a' or marc:subfield/@code='b' or marc:subfield/@code='g']"/>
				<xsl:if test="marc:datafield[@tag='260']/marc:subfield[@code='b']">
					<vra:agent>
						<vra:name type="corporate" vocab="lcnaf">
							<xsl:if test="marc:datafield[@tag='710'][marc:subfield/@code='0']">
								<xsl:attribute name="refid">
									<xsl:value-of select="marc:datafield[@tag='710'][marc:subfield/@code='0']"/>
								</xsl:attribute>							
							</xsl:if>
							<xsl:analyze-string select="marc:datafield[@tag='260']/marc:subfield[@code='b']" regex="(,| :|\],)$">
								<xsl:non-matching-substring>
									<xsl:value-of select="."/>
								</xsl:non-matching-substring>
							</xsl:analyze-string>
						</vra:name>
					</vra:agent>
				</xsl:if>		
			</vra:agentSet>
		</xsl:if>



		<!-- added by Mike - 3/12/2012-->
		<xsl:call-template name="addEmptyCulturalContextSet"/>
		<!-- Mike -->


		<xsl:if
			test="marc:datafield[@tag='046']/marc:subfield[@code='s'] | marc:datafield[@tag='046']/marc:subfield[@code='t'] | marc:datafield[@tag='260']/marc:subfield[@code='c']">
			<xsl:call-template name="comment">
				<xsl:with-param name="comment">Dates</xsl:with-param>
			</xsl:call-template>
			<vra:dateSet>
				<vra:display>
					<xsl:analyze-string select="marc:datafield[@tag='260']/marc:subfield[@code='c']" regex="\d\d\d-\?">
						<xsl:matching-substring>
							<xsl:analyze-string select="." regex="\d\d\d">
								<xsl:matching-substring>
									<xsl:value-of select="."/>0s</xsl:matching-substring>
							</xsl:analyze-string>
						</xsl:matching-substring>
					</xsl:analyze-string>
					<xsl:analyze-string select="marc:datafield[@tag='260']/marc:subfield[@code='c']" regex="\d{{4}}">
						<xsl:matching-substring>
							<xsl:value-of select="."/>
						</xsl:matching-substring>
					</xsl:analyze-string>
					<xsl:call-template name="displaySeparator"/>
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
		<!-- 505 and 506 added by Brendan, Added 520; 546 notes returned True (Radhi) -->
		<xsl:if test="marc:datafield[@tag='500']/marc:subfield[@code='a'] or marc:datafield[@tag='505']/marc:subfield[@code='a'] or marc:datafield[@tag='520']/marc:subfield[@code='a'] or marc:datafield[@tag='546']/marc:subfield[@code='a']">
			<xsl:call-template name="comment">
				<xsl:with-param name="comment">Description</xsl:with-param>
			</xsl:call-template>
			<vra:descriptionSet>
				<vra:display>
					<xsl:for-each select="marc:datafield[@tag='500']/marc:subfield[@code='a'] | marc:datafield[@tag='505']/marc:subfield[@code='a'] | marc:datafield[@tag='520']/marc:subfield[@code='a'] | marc:datafield[@tag='546']/marc:subfield[@code='a']">
						<xsl:call-template name="displaySeparator"/>
						<xsl:value-of select="."/>
					</xsl:for-each>
				</vra:display>
				<vra:notes>
					<xsl:for-each select="marc:datafield[@tag='500']/marc:subfield[@code='a'] | marc:datafield[@tag='505']/marc:subfield[@code='a'] | marc:datafield[@tag='520']/marc:subfield[@code='a'] | marc:datafield[@tag='546']/marc:subfield[@code='a']">
						<xsl:call-template name="displaySeparator"/>
						<xsl:value-of select="."/>
					</xsl:for-each> 
				</vra:notes>
				<xsl:apply-templates select="marc:datafield[@tag='500']/marc:subfield[@code='a']"/>
				<xsl:apply-templates select="marc:datafield[@tag='505']/marc:subfield[@code='a']"/>
				<xsl:apply-templates select="marc:datafield[@tag='520']/marc:subfield[@code='a']"/>
			</vra:descriptionSet>
		</xsl:if>
        
        <!-- added by Mike - 3/12/2012-->
		<xsl:call-template name="addEmptyInscriptionSet"/>
		<!-- Mike -->
		
		<!-- ______________ Location ______________ -->
		<!-- Always have location because we always have a pid and probably have a bibid -->
		<xsl:call-template name="comment">
			<xsl:with-param name="comment">Location</xsl:with-param>
		</xsl:call-template>
		<vra:locationSet>
			<vra:display>
				<xsl:for-each
				    select="marc:datafield[@tag='260']/marc:subfield[@code='a'] | marc:datafield[@tag='752'][marc:subfield/@code!='g'] | marc:datafield[@tag='535'][marc:subfield/@code='a' or marc:subfield/@code='b' or marc:subfield/@code='c'] ">
					<xsl:call-template name="displaySeparator"/>
					<xsl:call-template name="stripBrackets">
						<xsl:with-param name="val">
							<xsl:apply-templates select="." mode="display"/>
						</xsl:with-param>
					</xsl:call-template>							
				</xsl:for-each>
				<xsl:if test="marc:datafield[@tag='086'][marc:subfield/@code='a']"> ; U.S. Superintendent of Documents Classification number: <xsl:apply-templates select="marc:datafield[@tag='086'][marc:subfield/@code='a']" mode="display"/></xsl:if>
				<xsl:if test="$pid!=''"> ; DIL:<xsl:value-of select="$pid"/></xsl:if>
				<xsl:if test="$bibid!=''"> ; Voyager:<xsl:value-of select="$bibid"/></xsl:if>
			</vra:display>
		    <xsl:for-each select="marc:datafield[@tag='260']/marc:subfield[@code='a']">
		        <vra:location type="creation">
		        	<vra:name type="geographic">
		        		<xsl:call-template name="displaySeparator"/>
		        		<xsl:call-template name="stripBrackets">
		        			<xsl:with-param name="val">
		        				<xsl:apply-templates select="." mode="creation"/>
		        			</xsl:with-param>
		        		</xsl:call-template>
		        	</vra:name>
		        </vra:location>
		    </xsl:for-each>
			<xsl:for-each select="marc:datafield[@tag='752'][marc:subfield/@code!='g']">
				<vra:location type="discovery">
					<xsl:apply-templates select="marc:subfield[not(@code='g')]"/>
				</vra:location>
			</xsl:for-each>
			<xsl:for-each
				select="marc:datafield[@tag='535'][marc:subfield/@code='a' or marc:subfield/@code='b' or marc:subfield/@code='c']">
				<vra:location type="repository">
					<xsl:apply-templates select="marc:subfield[@code='a' or @code='b' or @code='c']"/>
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

		<xsl:variable name="rel_title_wwii">
				<xsl:for-each select="marc:datafield[@tag='440']/marc:subfield[@code='a' or @code='v']
				| marc:datafield[@tag='830']/marc:subfield[@code='a' or @code='v']">
					<xsl:apply-templates select="." mode="display"/>
				</xsl:for-each>
			<!-- <xsl:call-template name="displaySeparator"/> -->
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
						| marc:datafield[@tag='490']/marc:subfield[@code='a' or @code='v']
						| marc:datafield[@tag='830']/marc:subfield[@code='a' or @code='v']">
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
						| marc:datafield[@tag='830']/marc:subfield[@code='a' or @code='v']">
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
		<xsl:if test="marc:datafield[@tag='773']/marc:subfield[@code='a']">
			<xsl:call-template name="comment">
				<xsl:with-param name="comment">Source</xsl:with-param>
			</xsl:call-template>
			<vra:sourceSet>
				<vra:display>
					<xsl:for-each
						select="marc:datafield[@tag='773']/marc:subfield[@code='a' or @code='g']">
						<xsl:value-of select="."/>
						<xsl:text> </xsl:text>
					</xsl:for-each>
				</vra:display>
				<xsl:apply-templates select="marc:datafield[@tag='773']/marc:subfield[@code='a']"/>
			</vra:sourceSet>
		</xsl:if>
        
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
		<xsl:if test="marc:datafield[@tag='600' or @tag='610' or @tag='650' or @tag='651' or @tag='653']">
			<xsl:call-template name="comment">
				<xsl:with-param name="comment">Subjects</xsl:with-param>
			</xsl:call-template>
			<vra:subjectSet>
				<vra:display>
					<xsl:for-each
					    select="marc:datafield[@tag='600']/marc:subfield[@code='a' or @code='b' or @code='c' or @code='d' or @code='q'] | marc:datafield[@tag='610']/marc:subfield[@code='a' or @code='g'] | marc:datafield[@tag='650']/marc:subfield[@code='a' or @code='d'] | marc:datafield[@tag='651']/marc:subfield[@code='a'] | marc:datafield[@tag='653']/marc:subfield[@code='a']">
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
				<xsl:apply-templates
					select="marc:datafield[@tag='600']/marc:subfield[@code='a' or @code='b' or @code='c' or @code='d' or @code='q']"/>
				<xsl:apply-templates
					select="marc:datafield[@tag='610']/marc:subfield[@code='a' or @code='g']"/>
				<xsl:apply-templates
					select="marc:datafield[@tag='650']/marc:subfield[@code='a' or @code='d']"/>
				<xsl:apply-templates
					select="marc:datafield[@tag='651']/marc:subfield[@code='a' or @code='x']"/>
			    <xsl:apply-templates
			        select="marc:datafield[@tag='653']/marc:subfield[@code='a']"/>
			</vra:subjectSet>
		</xsl:if>

		<!-- added by Mike - 3/12/2012-->
		<xsl:call-template name="addEmptyTechniqueSet"/>
		<!-- Mike -->

		<!-- ______________ Titles ______________ -->
	    <!-- needs more work -BQ -->
		<xsl:if test="marc:datafield[@tag='240' or @tag='245' or @tag='246' or @tag='130']">
			<xsl:call-template name="comment">
				<xsl:with-param name="comment"> Titles </xsl:with-param>
			</xsl:call-template>
			<vra:titleSet>
				<vra:display>
					<xsl:for-each
						select="marc:datafield[@tag='245'][marc:subfield/@code='a' or marc:subfield/@code='p'] | marc:datafield[@tag='246'][marc:subfield/@code='a' or marc:subfield/@code='i']">
						<xsl:call-template name="displaySeparator"/>

						<!-- Changed by Bill Parod 1/22/2012 -->
						<xsl:apply-templates select="." mode="display"/>
					</xsl:for-each>
				</vra:display>
				<xsl:apply-templates select="marc:datafield[@tag='130'][marc:subfield/@code='a' or marc:subfield/@code='d']"/>
				<xsl:apply-templates select="marc:datafield[@tag='240'][marc:subfield/@code='a' or marc:subfield/@code='g' or marc:subfield/@code='d']"/>
				<xsl:apply-templates select="marc:datafield[@tag='245'][marc:subfield/@code='a' or marc:subfield/@code='p']"/>
				<xsl:apply-templates select="marc:datafield[@tag='246'][marc:subfield/@code='a']"/>
			</vra:titleSet>
		</xsl:if>

		<!--Added by Karen-->
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
		<vra:culturalContextSet>
			<vra:display/>
			<vra:culturalContext/>
		</vra:culturalContextSet>
	</xsl:template>

	<xsl:template name="addEmptyInscriptionSet">
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
		<vra:techniqueSet>
			<vra:display/>
			<vra:technique/>
		</vra:techniqueSet>
	</xsl:template>
	<!-- Mike -->

    <!-- Mike 1/24/2014 -->
    <xsl:template name="addWorktypeSet">
		<vra:worktypeSet>
			<vra:display/>
			<vra:worktype/>
		</vra:worktypeSet>
	</xsl:template>
	<!-- Mike -->
	
	<!-- agent display -->
	<xsl:template match="marc:datafield[@tag='100']" mode="display">
		<xsl:call-template name="stripTrailingPeriod">
			<xsl:with-param name="val">
				<xsl:value-of
					select="marc:subfield[@code='a' or @code='b' or @code='c' or @code='d' or @code='g' or @code='j' or @code='q']"
				/>
			</xsl:with-param>
		</xsl:call-template>
	</xsl:template>
	<xsl:template match="marc:datafield[@tag='110']" mode="display">
		<xsl:call-template name="stripTrailingPeriod">
			<xsl:with-param name="val">
				<xsl:value-of select="marc:subfield[@code='a' or @code='b' or @code='g']"/>
			</xsl:with-param>
		</xsl:call-template>
	</xsl:template>
	<xsl:template match="marc:datafield[@tag='700']" mode="display">
		<xsl:call-template name="stripTrailingPeriod">
			<xsl:with-param name="val">
				<xsl:value-of
					select="marc:subfield[@code='a' or @code='b' or @code='c' or @code='d' or @code='g' or @code='j' or @code='q']"
				/>
			</xsl:with-param>
		</xsl:call-template>
	</xsl:template>
	<xsl:template match="marc:datafield[@tag='710']" mode="display">
		<xsl:call-template name="stripTrailingPeriod">
			<xsl:with-param name="val">
				<xsl:value-of select="marc:subfield[@code='a' or @code='b' or @code='g']"/>
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
							select="marc:subfield[@code='a' or @code='b' or @code='c' or @code='g' or @code='j' or @code='q']"
						/>
					</xsl:with-param>
				</xsl:call-template>
			</vra:name>
			<xsl:apply-templates select="marc:subfield[@code='d']" mode="agent"/>
			<!-- added by Mike 3/12/2012-->
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
	
	<!-- Agent 260$b -->
	<xsl:template match="marc:datafield[@tag='260'][marc:subfield/@code='b']">
		<vra:agent>
			<vra:name type="corporate" vocab="lcnaf">
				<xsl:if test="marc:datafield[@tag='710'][marc:subfield/@code='0']">
					<xsl:attribute name="refid">
						<xsl:value-of select="marc:datafield[@tag='710'][marc:subfield/@code='0']"/>
					</xsl:attribute>
				</xsl:if>
				<xsl:call-template name="stripTrailingPeriod">
					<xsl:with-param name="val">
						<xsl:value-of select="marc:datafield[@tag='260'][marc:subfield/@code='b']"/>
					</xsl:with-param>
				</xsl:call-template>		
			</vra:name>
		</vra:agent>
	</xsl:template>

	<xsl:template match="marc:subfield[@code='0']">
		<xsl:attribute name="refid">
			<xsl:value-of select="."/>
		</xsl:attribute>
	</xsl:template>

	<!-- agent date -->
	<!-- 	If there are two dates (i.e., 1942-2006), the first one goes in earliestDate. If there is only one date and it is followed by a single hypen (i.e., 1942-) then it goes here. 
		If there is only one date and it is preceded by text "b. " (i.e., b. 1889) then it goes in earliestDate. 
		If there are two dates (i.e., 1942-2006), the second one goes in latestDate. 
		If there is only one date and it is preceded by text "d. " (i.e., d. 1956) then it goes in latestDate.
		-->
	<xsl:template match="marc:subfield[@code='d']" mode="agent">
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
		match="marc:datafield[@tag='245'][marc:subfield/@code='a' or marc:subfield/@code='p']">
		<vra:title pref="true">
			<xsl:call-template name="stripTrailingForwardSlash">
				<xsl:with-param name="val">
					<xsl:value-of select="marc:subfield[@code='a' or @code='p']"/>
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

	<xsl:template match="marc:datafield[@tag='246'][marc:subfield/@code='i' or marc:subfield/@code='a']">
		<vra:title pref="false">
			<xsl:call-template name="stripTrailingPeriod">
				<xsl:with-param name="val">
					<xsl:value-of select="marc:subfield[@code='i' or @code='a']"/>
				</xsl:with-param>
			</xsl:call-template>
		</vra:title>
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
<xsl:value-of select="."/>
</xsl:template>

	
	<!-- location 752 display mode -->
	<xsl:template match="marc:datafield[@tag='752'][marc:subfield/@code!='g']" mode="display">
		<xsl:value-of select="marc:subfield[not(@code='g')]"/>
	</xsl:template>

	<!-- location 535 display mode -->
	<xsl:template
		match="marc:datafield[@tag='535'][marc:subfield/@code='a' or marc:subfield/@code='b' or marc:subfield/@code='c']"
		mode="display">
		<xsl:value-of select="marc:subfield[@code='a' or @code='b' or @code='c']"/>
	</xsl:template>

	<!-- rights -->
	<xsl:template match="marc:datafield[@tag='540']/marc:subfield[@code='a']">
		<vra:rights type="publicDomain">
			<vra:rightsHolder>Public Domain</vra:rightsHolder><vra:text><xsl:value-of select="."/></vra:text>

		</vra:rights>
	</xsl:template>

	<!-- location 752$a -->
	<xsl:template match="marc:datafield[@tag='752']/marc:subfield[@code='a']">
		<vra:name type="geographic" extent="Country or larger entity">
			<xsl:call-template name="stripTrailingPeriod">
				<xsl:with-param name="val">
					<xsl:value-of select="."/>
				</xsl:with-param>
			</xsl:call-template>
		</vra:name>
	</xsl:template>
	<!-- location 752$b -->
	<xsl:template match="marc:datafield[@tag='752']/marc:subfield[@code='b']">
		<vra:name type="geographic" extent="First-order political jurisdiction">
			<xsl:call-template name="stripTrailingPeriod">
				<xsl:with-param name="val">
					<xsl:value-of select="."/>
				</xsl:with-param>
			</xsl:call-template>
		</vra:name>
	</xsl:template>
	<!-- location 752$c -->
	<xsl:template match="marc:datafield[@tag='752']/marc:subfield[@code='c']">
		<vra:name type="geographic" extent="Intermediate political jurisdiction">
			<xsl:call-template name="stripTrailingPeriod">
				<xsl:with-param name="val">
					<xsl:value-of select="."/>
				</xsl:with-param>
			</xsl:call-template>
		</vra:name>
	</xsl:template>
	<!-- location 752$d -->
	<xsl:template match="marc:datafield[@tag='752']/marc:subfield[@code='d']">
		<vra:name type="geographic" extent="City">
			<xsl:call-template name="stripTrailingPeriod">
				<xsl:with-param name="val">
					<xsl:value-of select="."/>
				</xsl:with-param>
			</xsl:call-template>
		</vra:name>
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
    <xsl:template match="marc:datafield[@tag='260']/marc:subfield[@code='a']">
        <vra:name type="geographic">
        	<xsl:value-of select="marc:datafield[@tag='260']/marc:subfield[@code='a']"/>
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

	<!-- subjects -->
	<xsl:template
		match="marc:datafield[@tag='600']/marc:subfield[@code='a' or @code='b' or @code='c' or @code='d' or @code='q']">
		<vra:subject>
			<vra:term type="personalName">
				<xsl:apply-templates select="marc:subfield[@code='0']"/>
				<xsl:apply-templates select="../marc:subfield[@code='2']"/>
				<xsl:call-template name="stripTrailingPeriod">
					<xsl:with-param name="val">
						<xsl:value-of select="."/>
					</xsl:with-param>
				</xsl:call-template>
			</vra:term>
		</vra:subject>
	</xsl:template>
	<xsl:template match="marc:datafield[@tag='610']/marc:subfield[@code='a' or @code='g']">
		<vra:subject>
			<vra:term type="corporateName">
				<xsl:apply-templates select="marc:subfield[@code='0']"/>
				<xsl:apply-templates select="../marc:subfield[@code='2']"/>
				<xsl:call-template name="stripTrailingPeriod">
					<xsl:with-param name="val">
						<xsl:value-of select="."/>
					</xsl:with-param>
				</xsl:call-template>
			</vra:term>
		</vra:subject>
	</xsl:template>
	<xsl:template match="marc:datafield[@tag='650']/marc:subfield[@code='a']">
		<vra:subject>
			<vra:term type="descriptiveTopic">
				<xsl:apply-templates select="marc:subfield[@code='0']"/>
				<xsl:apply-templates select="../marc:subfield[@code='2']"/>
				<xsl:call-template name="stripTrailingPeriod">
					<xsl:with-param name="val">
						<xsl:value-of select="."/>
					</xsl:with-param>
				</xsl:call-template>
			</vra:term>
		</vra:subject>
	</xsl:template>
	<xsl:template match="marc:datafield[@tag='650']/marc:subfield[@code='d' or @code='v']">
		<vra:subject>
			<vra:term type="otherTopic">
				<xsl:apply-templates select="marc:subfield[@code='0']"/>
				<xsl:apply-templates select="../marc:subfield[@code='2']"/>
				<xsl:call-template name="stripTrailingPeriod">
					<xsl:with-param name="val">
						<xsl:value-of select="."/>
					</xsl:with-param>
				</xsl:call-template>
			</vra:term>
		</vra:subject>
	</xsl:template>
	<xsl:template match="marc:datafield[@tag='650']/marc:subfield[@code='x']">
		<vra:subject>
			<vra:term type="conceptTopic">
				<xsl:apply-templates select="marc:subfield[@code='0']"/>
				<xsl:apply-templates select="../marc:subfield[@code='2']"/>
				<xsl:call-template name="stripTrailingPeriod">
					<xsl:with-param name="val">
						<xsl:value-of select="."/>
					</xsl:with-param>
				</xsl:call-template>
			</vra:term>
		</vra:subject>
	</xsl:template>
	<xsl:template match="marc:datafield[@tag='651']/marc:subfield[@code='a']">
		<vra:subject>
			<vra:term type="geographicPlace">
				<xsl:apply-templates select="marc:subfield[@code='0']"/>
				<xsl:apply-templates select="../marc:subfield[@code='2']"/>
				<xsl:call-template name="stripTrailingPeriod">
					<xsl:with-param name="val">
						<xsl:value-of select="."/>
					</xsl:with-param>
				</xsl:call-template>
			</vra:term>
		</vra:subject>
	</xsl:template>
	<xsl:template match="marc:datafield[@tag='651']/marc:subfield[@code='v']">
		<vra:subject>
			<vra:term type="otherTopic">
				<xsl:apply-templates select="marc:subfield[@code='0']"/>
				<xsl:apply-templates select="../marc:subfield[@code='2']"/>
				<xsl:call-template name="stripTrailingPeriod">
					<xsl:with-param name="val">
						<xsl:value-of select="."/>
					</xsl:with-param>
				</xsl:call-template>
			</vra:term>
		</vra:subject>
	</xsl:template>
	<xsl:template match="marc:datafield[@tag='651']/marc:subfield[@code='x']">
		<vra:subject>
			<vra:term type="conceptTopic">
				<xsl:apply-templates select="marc:subfield[@code='0']"/>
				<xsl:apply-templates select="../marc:subfield[@code='2']"/>
				<xsl:call-template name="stripTrailingPeriod">
					<xsl:with-param name="val">
						<xsl:value-of select="."/>
					</xsl:with-param>
				</xsl:call-template>
			</vra:term>
		</vra:subject>
	</xsl:template>
	<xsl:template match="marc:datafield[@tag='651']/marc:subfield[@code='z']">
		<vra:subject>
			<vra:term type="geographicPlace">
				<xsl:apply-templates select="marc:subfield[@code='0']"/>
				<xsl:apply-templates select="../marc:subfield[@code='2']"/>
				<xsl:call-template name="stripTrailingPeriod">
					<xsl:with-param name="val">
						<xsl:value-of select="."/>
					</xsl:with-param>
				</xsl:call-template>
			</vra:term>
		</vra:subject>
	</xsl:template>
    <xsl:template match="marc:datafield[@tag='653']/marc:subfield[@code='a']">
        <vra:subject>
            <vra:term type="descriptiveTopic">
                <xsl:call-template name="stripTrailingPeriod">
                    <xsl:with-param name="val">
                        <xsl:value-of select="."/>
                    </xsl:with-param>
                </xsl:call-template>
            </vra:term>
        </vra:subject>
    </xsl:template>

	<!-- location -->
	<xsl:template match="marc:datafield[@tag='650']">
		<vra:location>
			<vra:name>
				<xsl:value-of
					select="marc:subfield[@code='a' or @code='d' or @code='v' or @code='x' or @code='y' or @code='z']"
				/>
			</vra:name>
		</vra:location>
	</xsl:template>
	<xsl:template match="marc:datafield[@tag='651']">
		<vra:location>
			<vra:name>
				<xsl:value-of select="marc:subfield[@code='a']"/>
			</vra:name>
		</vra:location>
	</xsl:template>

	<!-- source -->
	<xsl:template match="marc:datafield[@tag='773']/marc:subfield[@code='a']">
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
	
	<xsl:template name="stripTrailingForwardSlash">
		<xsl:param name="val"/>
		<xsl:analyze-string select="$val" regex="(.*)\s/$" flags="i">
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

	<xsl:template match="*|text()"/>

</xsl:stylesheet>
