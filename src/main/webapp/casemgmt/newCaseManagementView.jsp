
<%--


    Copyright (c) 2005-2012. Centre for Research on Inner City Health, St. Michael's Hospital, Toronto. All Rights Reserved.
    This software is published under the GPL GNU General Public License.
    This program is free software; you can redistribute it and/or
    modify it under the terms of the GNU General Public License
    as published by the Free Software Foundation; either version 2
    of the License, or (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

    This software was written for
    Centre for Research on Inner City Health, St. Michael's Hospital,
    Toronto, Ontario, Canada

--%>



<%@page import="oscar.Misc"%>
<%@page import="oscar.util.UtilMisc"%>
<%@include file="/casemgmt/taglibs.jsp"%>
<%@taglib uri="/WEB-INF/caisi-tag.tld" prefix="caisi"%>
<%@page import="java.util.Enumeration"%>
<%@page import="oscar.oscarEncounter.pageUtil.NavBarDisplayDAO"%>
<%@page	import="java.util.Arrays,java.util.Properties,java.util.List,java.util.Set,java.util.ArrayList,java.util.Enumeration,java.util.HashSet,java.util.Iterator,java.text.SimpleDateFormat,java.util.Calendar,java.util.Date,java.text.ParseException"%>
<%@page import="org.apache.commons.lang.StringEscapeUtils"%>
<%@page import="org.oscarehr.common.model.UserProperty,org.oscarehr.casemgmt.model.*,org.oscarehr.casemgmt.service.* "%>
<%@page import="org.oscarehr.casemgmt.web.formbeans.*"%>
<%@page import="org.oscarehr.PMmodule.model.*"%>
<%@page import="org.oscarehr.common.model.*"%>
<%@page import="oscar.util.DateUtils"%>
<%@page import="oscar.dms.EDocUtil"%>
<%@page import="org.springframework.web.context.WebApplicationContext"%>
<%@page import="org.springframework.web.context.support.WebApplicationContextUtils"%>
<%@page import="org.oscarehr.casemgmt.common.Colour"%>
<%@page import="oscar.dms.EDoc"%>
<%@page import="org.springframework.web.context.support.WebApplicationContextUtils"%>
<%@page import="com.quatro.dao.security.*,com.quatro.model.security.Secrole"%>
<%@page import="org.oscarehr.util.EncounterUtil"%>
<%@page import="org.apache.cxf.common.i18n.UncheckedException"%>
<%@page import="org.oscarehr.casemgmt.web.NoteDisplay"%>
<%@page import="org.oscarehr.casemgmt.web.CaseManagementViewAction"%>
<%@page import="org.oscarehr.util.SpringUtils"%>
<%@page import="oscar.oscarRx.data.RxPrescriptionData"%>
<%@page import="org.oscarehr.casemgmt.dao.CaseManagementNoteLinkDAO"%>
<%@page import="org.oscarehr.common.dao.ProfessionalSpecialistDao"%>
<%@page import="oscar.OscarProperties"%>
<%@page import="org.oscarehr.util.MiscUtils"%>
<%@page import="oscar.util.UtilDateUtilities"%>
<%@page import="org.oscarehr.casemgmt.web.NoteDisplayNonNote"%>
<%@page import="org.oscarehr.common.dao.EncounterTemplateDao"%>
<%@page import="org.oscarehr.casemgmt.web.CheckBoxBean"%>
<%@page import="org.oscarehr.common.dao.SystemPreferencesDao" %>
<%@page import="java.util.HashMap" %>

<% java.util.Properties oscarVariables = OscarProperties.getInstance(); %>

<%
	HashMap<String, Boolean> echartPreferencesMap = new HashMap<String, Boolean>();
	SystemPreferencesDao systemPreferencesDao = SpringUtils.getBean(SystemPreferencesDao.class);
	List<SystemPreferences> schedulePreferences = systemPreferencesDao.findPreferencesByNames(SystemPreferences.ECHART_PREFERENCE_KEYS);
	for (SystemPreferences preference : schedulePreferences) {
		echartPreferencesMap.put(preference.getName(), Boolean.parseBoolean(preference.getValue()));
	}
%>

<c:set var="ctx" value="${pageContext.request.contextPath}" scope="request" />

	<div id="cppBoxes" bstyle="background-color: #FFFFFF;">
		<div id="divR1" style="width: 100%; height: 75px; margin: 0px; background-color: #FFFFFF;">
			<!-- social history -->		
			<div id="divR1I1" class="topBox" 
				style="float: left; width: 49%; margin-left: 3px; height: inherit;">
			</div>
		
			<!-- This is the Medical History cell ...mh...-->
			<div id="divR1I2" class="topBox"
				style="float: right; width: 49%; margin-right: 3px; height: inherit;">
			</div>
		</div>
	
		<div id="divR2" style="width: 100%; height: 75px; margin-top: 0px; background-color: #FFFFFF;">		
			<!--Ongoing Concerns cell -->
			<div id="divR2I1" class="topBox"
				style="clear: left; float: left; width: 49%; margin-left: 3px; height: inherit;">	
			</div>	
			<!--Reminders cell -->
			<div id="divR2I2" class="topBox"
				style="clear: right; float: right; width: 49%; margin-right: 3px; height: inherit;">		
			</div>
		</div>
	</div>
	

	<div id="notCPP" style="height: 70%; margin-left: 2px; background-color: #FFFFFF;">	
 	
	</div>
	<!--  This leaves the OCEAN toolbar accessible but not taking up prime realestate -->
	<% if (echartPreferencesMap.getOrDefault("echart_show_ocean", true)) { %>
	<div id="ocean_placeholder" >
				<span style="visibility:hidden">test</span>
	</div>
	<% } %>