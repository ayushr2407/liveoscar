<%--

    Copyright (c) 2001-2002. Department of Family Medicine, McMaster University. All Rights Reserved.
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

    This software was written for the
    Department of Family Medicine
    McMaster University
    Hamilton
    Ontario, Canada

--%>
<%@ taglib uri="/WEB-INF/security.tld" prefix="security"%>
<%@ taglib uri="/WEB-INF/struts-bean.tld" prefix="bean"%>
<%
    String roleName$ = (String)session.getAttribute("userrole") + "," + (String) session.getAttribute("user");
    String demographic$ = request.getParameter("demographic_no") ;
    boolean authed=true;
%>
<security:oscarSec roleName="<%=roleName$%>" objectName="_demographic" rights="r" reverse="<%=true%>">
	<%authed=false; %>
	<%response.sendRedirect(request.getContextPath() + "/securityError.jsp?type=_demographic");%>
</security:oscarSec>

<security:oscarSec roleName="<%=roleName$%>"
	objectName='<%="_demographic$"+demographic$%>' rights="o"
	reverse="<%=false%>">
<bean:message key="demographic.demographiceditdemographic.accessDenied"/>
<% response.sendRedirect(request.getContextPath() +  "/acctLocked.html");
authed=false;
%>
</security:oscarSec>

<%
if(!authed) {
	return;
}

%>

<!DOCTYPE html>
<%-- @ taglib uri=request.getContextPath() +  "/WEB-INF/taglibs-log.tld" prefix="log" --%>

<%@page import="java.net.*"%>
<%@page import="java.sql.*"%>
<%@page import="java.text.DateFormatSymbols"%>
<%@page import="java.text.DecimalFormat"%>
<%@page import="java.util.*"%>
<%@page import="java.util.Locale"%>
<%@page import="org.apache.commons.lang.StringEscapeUtils"%>
<%@page import="org.apache.commons.lang.StringUtils"%>
<%@page import="org.apache.commons.text.WordUtils"%>
<%@page import="org.oscarehr.PMmodule.caisi_integrator.ConformanceTestHelper"%>
<%@page import="org.oscarehr.PMmodule.dao.ProgramDao"%>
<%@page import="org.oscarehr.PMmodule.dao.ProviderDao"%>
<%@page import="org.oscarehr.PMmodule.model.Program"%>
<%@page import="org.oscarehr.PMmodule.model.ProgramProvider"%>
<%@page import="org.oscarehr.PMmodule.service.AdmissionManager"%>
<%@page import="org.oscarehr.PMmodule.service.ProgramManager"%>
<%@page import="org.oscarehr.PMmodule.web.GenericIntakeEditAction"%>
<%@page import="org.oscarehr.casemgmt.model.CaseManagementNoteLink"%>
<%@page import="org.oscarehr.casemgmt.service.CaseManagementManager"%>
<%@page import="org.oscarehr.common.Gender"%>
<%@page import="org.oscarehr.common.OtherIdManager"%>
<%@page import="org.oscarehr.common.dao.*"%>
<%@page import="org.oscarehr.common.dao.ContactSpecialtyDao"%>
<%@page import="org.oscarehr.common.dao.DemographicArchiveDao"%>
<%@page import="org.oscarehr.common.dao.DemographicCustDao"%>
<%@page import="org.oscarehr.common.dao.DemographicDao"%>
<%@page import="org.oscarehr.common.dao.DemographicExtArchiveDao"%>
<%@page import="org.oscarehr.common.dao.DemographicExtDao"%>
<%@page import="org.oscarehr.common.dao.ProfessionalSpecialistDao"%>
<%@page import="org.oscarehr.common.dao.ScheduleTemplateCodeDao"%>
<%@page import="org.oscarehr.common.dao.SpecialtyDao"%>
<%@page import="org.oscarehr.common.dao.WaitingListDao"%>
<%@page import="org.oscarehr.common.dao.WaitingListNameDao"%>
<%@page import="org.oscarehr.common.ISO36612"%>
<%@page import="org.oscarehr.common.model.*"%>
<%@page import="org.oscarehr.common.model.Consent"%>
<%@page import="org.oscarehr.common.model.ConsentType"%>
<%@page import="org.oscarehr.common.model.ContactSpecialty"%>
<%@page import="org.oscarehr.common.model.Demographic"%>
<%@page import="org.oscarehr.common.model.DemographicCust"%>
<%@page import="org.oscarehr.common.model.ProfessionalSpecialist"%>
<%@page import="org.oscarehr.common.model.Provider"%>
<%@page import="org.oscarehr.common.model.ScheduleTemplateCode"%>
<%@page import="org.oscarehr.common.model.Specialty"%>
<%@page import="org.oscarehr.common.model.WaitingListName"%>
<%@page import="org.oscarehr.common.web.ContactAction"%>
<%@page import="org.oscarehr.managers.DemographicManager"%>
<%@page import="org.oscarehr.managers.LookupListManager"%>
<%@page import="org.oscarehr.managers.PatientConsentManager"%>
<%@page import="org.oscarehr.managers.ProgramManager2"%>
<%@page import="org.oscarehr.myoscar.utils.MyOscarLoggedInInfo"%>
<%@page import="org.oscarehr.phr.util.MyOscarUtils"%>
<%@page import="org.oscarehr.sharingcenter.SharingCenterUtil"%>
<%@page import="org.oscarehr.util.LoggedInInfo"%>
<%@page import="org.oscarehr.util.SpringUtils"%>
<%@page import="org.owasp.encoder.Encode"%>
<%@page import="org.springframework.web.context.*"%>
<%@page import="org.springframework.web.context.support.*"%>
<%@page import="oscar.*"%>
<%@page import="oscar.OscarProperties"%>
<%@page import="oscar.oscarDemographic.data.*"%>
<%@page import="oscar.oscarDemographic.data.ProvinceNames"%>
<%@page import="oscar.oscarDemographic.pageUtil.Util"%>
<%@page import="oscar.oscarReport.data.DemographicSets,oscar.log.*"%>
<%@page import="oscar.oscarWaitingList.WaitingList"%>
<%@page import="oscar.util.ConversionUtils"%>
<%@page import="oscar.util.UtilMisc"%>

<%@ taglib uri="/WEB-INF/struts-html.tld" prefix="html"%>
<%@ taglib uri="/WEB-INF/phr-tag.tld" prefix="phr"%>
<%@ taglib uri="/WEB-INF/oscar-tag.tld" prefix="oscar"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>
<%@ taglib uri="http://jakarta.apache.org/struts/tags-logic" prefix="logic"%>
<%@ taglib uri="/WEB-INF/special_tag.tld" prefix="special" %>
<%@ taglib uri="http://www.caisi.ca/plugin-tag" prefix="plugin" %>

<jsp:useBean id="apptMainBean" class="oscar.AppointmentMainBean" scope="session" />
<%


    LoggedInInfo loggedInInfo=LoggedInInfo.getLoggedInInfoFromSession(request);

    WebApplicationContext ctx = WebApplicationContextUtils.getRequiredWebApplicationContext(getServletContext());
    CountryCodeDao ccDAO =  (CountryCodeDao) ctx.getBean("countryCodeDao");
    UserPropertyDAO pref = (UserPropertyDAO) ctx.getBean("UserPropertyDAO");
    List<CountryCode> countryList = ccDAO.getAllCountryCodes();

    DemographicExtDao demographicExtDao = SpringUtils.getBean(DemographicExtDao.class);
    DemographicArchiveDao demographicArchiveDao = SpringUtils.getBean(DemographicArchiveDao.class);
    DemographicExtArchiveDao demographicExtArchiveDao = SpringUtils.getBean(DemographicExtArchiveDao.class);
    ScheduleTemplateCodeDao scheduleTemplateCodeDao = SpringUtils.getBean(ScheduleTemplateCodeDao.class);
    WaitingListDao waitingListDao = SpringUtils.getBean(WaitingListDao.class);
    WaitingListNameDao waitingListNameDao = SpringUtils.getBean(WaitingListNameDao.class);

	OscarProperties oscarProps = OscarProperties.getInstance();
    String help_url = (oscarProps.getProperty("HELP_SEARCH_URL","https://oscargalaxy.org/knowledge-base/")).trim();
	String hin_check_url = (oscarProps.getProperty("HIN_CHECK_URL","https://apps.ontariomd.ca/HCValidationWeb/form.do?")).trim();
    String privateConsentEnabledProperty = oscarProps.getProperty("privateConsentEnabled");
    boolean privateConsentEnabled = (privateConsentEnabledProperty != null && privateConsentEnabledProperty.equals("true"));

	ProfessionalSpecialistDao professionalSpecialistDao = (ProfessionalSpecialistDao) SpringUtils.getBean("professionalSpecialistDao");
	DemographicCustDao demographicCustDao = (DemographicCustDao)SpringUtils.getBean("demographicCustDao");
	DemographicDao demographicDao = SpringUtils.getBean(DemographicDao.class);
	ProviderDao providerDao = SpringUtils.getBean(ProviderDao.class);
	List<Provider> providers = providerDao.getActiveProviders();
	List<Provider> doctors = providerDao.getActiveProvidersByRole("doctor");
	List<Provider> nurses = providerDao.getActiveProvidersByRole("nurse");
	List<Provider> midwifes = providerDao.getActiveProvidersByRole("midwife");

	DemographicManager demographicManager = SpringUtils.getBean(DemographicManager.class);
	ProgramManager2 programManager2 = SpringUtils.getBean(ProgramManager2.class);

	LookupList ll = null;
%>

<jsp:useBean id="providerBean" class="java.util.Properties"	scope="session" />

<c:set var="ctx" value="${ pageContext.request.contextPath }" />
<%
	if(session.getAttribute("user") == null)
	{
		response.sendRedirect(request.getContextPath() +  "/logout.jsp");
		return;
	}

	ProgramManager pm = SpringUtils.getBean(ProgramManager.class);
	ProgramDao programDao = (ProgramDao)SpringUtils.getBean("programDao");


	String curProvider_no = (String) session.getAttribute("user");
	String demographic_no = request.getParameter("demographic_no") ;
	String apptProvider = request.getParameter("apptProvider");
	String appointment = request.getParameter("appointment");
	String userfirstname = (String) session.getAttribute("userfirstname");
	String userlastname = (String) session.getAttribute("userlastname");
	String deepcolor = "#CCCCFF", weakcolor = "#EEEEFF" ;
	String str = null;
	int nStrShowLen = 20;
	String prov= (oscarProps.getProperty("billregion","")).trim().toUpperCase();

	CaseManagementManager cmm = (CaseManagementManager) SpringUtils.getBean("caseManagementManager");
	List<CaseManagementNoteLink> cml = cmm.getLinkByTableId(CaseManagementNoteLink.DEMOGRAPHIC, Long.valueOf(demographic_no));
	boolean hasImportExtra = (cml.size()>0);
	String annotation_display = CaseManagementNoteLink.DISP_DEMO;

	LogAction.addLog((String) session.getAttribute("user"), LogConst.READ, LogConst.CON_DEMOGRAPHIC,  demographic_no , request.getRemoteAddr(),demographic_no);


	Boolean isMobileOptimized = session.getAttribute("mobileOptimized") != null;
	ProvinceNames pNames = ProvinceNames.getInstance();
	Map<String,String> demoExt = demographicExtDao.getAllValuesForDemo(Integer.parseInt(demographic_no));
    SystemPreferencesDao systemPreferencesDao = SpringUtils.getBean(SystemPreferencesDao.class);
    Map<String, Boolean> generalSettingsMap = systemPreferencesDao.findByKeysAsMap(SystemPreferences.GENERAL_SETTINGS_KEYS);
    boolean replaceNameWithPreferred = generalSettingsMap.getOrDefault("replace_demographic_name_with_preferred", false);

	String usSigned = StringUtils.defaultString(apptMainBean.getString(demoExt.get("usSigned")));
    String privacyConsent = StringUtils.defaultString(apptMainBean.getString(demoExt.get("privacyConsent")), "");
	String informedConsent = StringUtils.defaultString(apptMainBean.getString(demoExt.get("informedConsent")), "");

	boolean showConsentsThisTime = false;

    GregorianCalendar now=new GregorianCalendar();
    int curYear = now.get(Calendar.YEAR);
    int curMonth = (now.get(Calendar.MONTH)+1);
    int curDay = now.get(Calendar.DAY_OF_MONTH);

	java.util.ResourceBundle oscarResources = ResourceBundle.getBundle("oscarResources", request.getLocale());
    String noteReason = oscarResources.getString("oscarEncounter.noteReason.TelProgress");

	if (oscarProps.getProperty("disableTelProgressNoteTitleInEncouterNotes") != null
			&& oscarProps.getProperty("disableTelProgressNoteTitleInEncouterNotes").equals("yes")) {
		noteReason = "";
	}

	// MARC-HI's Sharing Center
	boolean isSharingCenterEnabled = SharingCenterUtil.isEnabled();

	String currentProgram="";
	String programId = (String)session.getAttribute(org.oscarehr.util.SessionConstants.CURRENT_PROGRAM_ID);
	if(programId != null && programId.length()>0) {
		Integer prId = null;
		try {
			prId = Integer.parseInt(programId);
		} catch(NumberFormatException e) {
			//do nothing
		}
		if(prId != null) {
			ProgramManager2 programManager = SpringUtils.getBean(ProgramManager2.class);
			Program p = programManager.getProgram(loggedInInfo, prId);
			if(p != null) {
				currentProgram = p.getName();
			}
		}
	}

	// get a list of programs the patient has consented to.
	if( oscarProps.getBooleanProperty("USE_NEW_PATIENT_CONSENT_MODULE", "true") ) {
	    PatientConsentManager patientConsentManager = SpringUtils.getBean( PatientConsentManager.class );
		pageContext.setAttribute( "consentTypes", patientConsentManager.getActiveConsentTypes() );
		pageContext.setAttribute( "patientConsents", patientConsentManager.getAllConsentsByDemographic( loggedInInfo, Integer.parseInt(demographic_no) ) );
	}

	List<String> updatedFamily = (List<String>) session.getAttribute("updatedFamily");
	session.removeAttribute("updatedFamily");


    // Put 0 on the left on dates
    DecimalFormat decF = new DecimalFormat();
%>

<html:html locale="true">
<head>
<title><bean:message key="demographic.demographiceditdemographic.title" /></title>
<html:base />

<oscar:oscarPropertiesCheck property="DEMOGRAPHIC_PATIENT_HEALTH_CARE_TEAM" value="true">
	<link href="${pageContext.request.contextPath}/css/healthCareTeam.css" rel="stylesheet">
</oscar:oscarPropertiesCheck>

<!-- calendar stylesheet -->
<link href="${pageContext.request.contextPath}/share/calendar/calendar.css" title="win2k-cold-1" rel="stylesheet">

<link href="${pageContext.request.contextPath}/library/jquery/jquery-ui.structure-1.12.1.min.css" rel="stylesheet">
<link href="${pageContext.request.contextPath}/library/jquery/jquery-ui.theme-1.12.1.min.css" rel="stylesheet">
<link href="${pageContext.request.contextPath}/css/bootstrap.css" rel="stylesheet"> <!-- Bootstrap 2.3.1 -->
<link href="${pageContext.request.contextPath}/css/bootstrap-responsive.css" rel="stylesheet">
<script src="${pageContext.request.contextPath}/library/jquery/jquery-3.6.4.min.js"></script>
<script src="${pageContext.request.contextPath}/js/bootstrap.js"></script><!-- for accordion -->
<% if (oscarProps.getBooleanProperty("workflow_enhance", "true")) { %>
<script src="<%=request.getContextPath() %>/hcHandler/hcHandler.js"></script>
<script src="<%=request.getContextPath() %>/hcHandler/hcHandlerUpdateDemographic.js"></script>
<link href="<%=request.getContextPath() %>/hcHandler/hcHandler.css" rel="stylesheet">
<link href="<%=request.getContextPath() %>/demographic/demographiceditdemographic.css" rel="stylesheet">
<% } %>

<!-- calendar program -->
<script src="<%= request.getContextPath() %>/share/calendar/calendar.js"></script>
<script src="<%= request.getContextPath() %>/share/calendar/lang/<bean:message key="global.javascript.calendar"/>"></script>
<script src="<%= request.getContextPath() %>/share/calendar/calendar-setup.js"></script>

<script src="<%=request.getContextPath() %>/js/check_hin.js"></script>

<script src="${pageContext.request.contextPath}/library/jquery/jquery-ui-1.12.1.min.js"></script><!-- for History -->

<% if (isMobileOptimized) { %>
    <meta name="viewport" content="initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0, user-scalable=no, width=device-width" />
    <link href="<%= request.getContextPath() %>/mobile/editdemographicstyle.css" rel="stylesheet">
<% } else { %>
    <script src="<%= request.getContextPath() %>/js/global.js"></script>
<% } %>
<script src="<%= request.getContextPath() %>/share/javascript/Oscar.js"></script>

<!--popup menu for encounter type -->
<script src="<c:out value="${ctx}"/>/share/javascript/popupmenu.js"></script>
<script src="<c:out value="${ctx}"/>/share/javascript/menutility.js"></script>

<script src="<%=request.getContextPath() %>/demographic/demographiceditdemographic.js.jsp"></script>

<style type="text/css">
 .form-horizontal .control-group {
	margin-bottom: 0px;
 }
</style>
<style>
/* Dropdown Button */
.dropbtns {
/*  background-color: #4CAF50;
  color: white;
  padding: 16px;
  font-size: 16px;
  border: none;*/
}

/* The container <div> - needed to position the dropdown content */
.dropdowns {
  position: relative;
  display: inline-block;
}

/* Dropdown Content (Hidden by Default) */
.dropdowns-content {
  display: none;
  position: absolute;
  background-color: #f1f1f1;
  min-width: 160px;
  box-shadow: 0px 8px 16px 0px rgba(0,0,0,0.2);
  z-index: 1;
}

/* Links inside the dropdown */
.dropdowns-content a {
  color: black;
  padding: 8px 12px;
  text-decoration: none;
  display: block;
}

/* Change color of dropdown links on hover */
.dropdowns-content a:hover {background-color: #ddd;}

/* Show the dropdown menu on hover */
.dropdowns:hover .dropdowns-content {display: block;}

/* Change the background color of the dropdown button when the dropdown content is shown */
.dropdowns:hover .dropbtns {background-color: #e6e6e6;}

/* Override Bootstrap */
legend {
    margin-bottom: 4px;
}
.accordion-heading .accordion-toggle {
	padding: 2px 15px;
}

</style>
   <script>
     jQuery.noConflict();
   </script>
<script>
var preferredPhone="";

jQuery( document ).ready( function() {
  jQuery( function() {
    jQuery( ".tooltips" ).tooltip();
  } );

    <% if (updatedFamily!=null && !updatedFamily.isEmpty()){ %>
		var familyMembers = "";
    	<% for (String member : updatedFamily){%>
			familyMembers += "\n<%=Encode.forJavaScript(member)%>"
		<%}%>

        alert("<bean:message key="demographic.demographiceditdemographic.alertupdated"/> " + familyMembers+"");
    <% }%>

	var defPhTitle = "Check to set preferred contact number";
	var prefPhTitle = "Preferred contact number";
    jQuery('#cell_check').prop('title', defPhTitle);
    jQuery('#phone_check').prop('title', defPhTitle);
    jQuery('#phone2_check').prop('title', defPhTitle);

	var cellPhone = getPhoneNum(jQuery('#cell').val());
	var homePhone = getPhoneNum(jQuery('#phone').val());
	var workPhone = getPhoneNum(jQuery('#phone2').val());




  jQuery('#cell_check').on("change",function()
  {
    if(this.checked == true)
    {
	preferredPhone="C";
	jQuery('#cell_check').prop('title', prefPhTitle);
	jQuery('#phone_check').prop('title', defPhTitle);
	jQuery('#phone2_check').prop('title', defPhTitle);
	jQuery('#phone2_check').prop('checked', false);
	jQuery('#phone_check').prop('checked', false);
    }
  });
  jQuery('#phone_check').on("change",function()
  {
    if(this.checked == true)
    {
	preferredPhone="H";
	jQuery('#cell_check').prop('title', defPhTitle);
	jQuery('#phone_check').prop('title', prefPhTitle);
	jQuery('#phone2_check').prop('title', defPhTitle);
	jQuery('#phone2_check').prop('checked', false);
	jQuery('#cell_check').prop('checked', false);
    }
  });
  jQuery('#phone2_check').on("change",function()
  {
    if(this.checked == true)
    {
	preferredPhone="W";
	jQuery('#cell_check').prop('title', defPhTitle);
	jQuery('#phone_check').prop('title', defPhTitle);
	jQuery('#phone2_check').prop('title', prefPhTitle);
	jQuery('#phone_check').prop('checked', false);
	jQuery('#cell_check').prop('checked', false);
    }
  });



});

function setPhone() {
	var cellPhone = getPhoneNum(jQuery('#cell').val());
	var homePhone = getPhoneNum(jQuery('#phone').val());
	var workPhone = getPhoneNum(jQuery('#phone2').val());
	var prefPhTitle = "Preferred contact number";
    console.log("H="+homePhone+"W="+workPhone+"C="+cellPhone);

	if ( isPreferredPhone(jQuery('#cell').val()) ) {
		jQuery('#cell_check').prop('checked', true);
		jQuery('#cell').val(cellPhone);
        jQuery('#cell_check').prop('title', prefPhTitle);
    }
	else if ( isPreferredPhone(jQuery('#phone').val()) ) {
		jQuery('#phone_check').prop('checked', true);
		jQuery('#phone').val(homePhone);
        jQuery('#phone_check').prop('title', prefPhTitle);
	}
	else if ( isPreferredPhone(jQuery('#phone2').val()) ) {
		jQuery('#phone2_check').prop('checked', true);
		jQuery('#phone2').val(workPhone);
        jQuery('#phone2_check').prop('title', prefPhTitle);
	}
}

function isPreferredPhone(phone) {
	if (phone!=null && phone!="") {
		if (phone.charAt(phone.length-1)=="*") return true;
	}
	return false;
}

function getPhoneNum(phone) {
	if (isPreferredPhone(phone)) {
		phone = phone.substring(0, phone.length-1);
	}
	return phone;
}


jQuery(function(){
    jQuery('form').on( "submit",function(){
	    if (preferredPhone=="C") {jQuery("#cell").val(function(i, val) {
		    return val + "*";
	    });}
			    else if (preferredPhone=="H") {jQuery("#phone").val(function(i, val) {
		    return val + "*";
	    });}
			    else if (preferredPhone=="W"){jQuery("#phone2").val(function(i, val) {
		    return val + "*";
	    });}
    });
});

function copyHIN2Clipboard(id) {
    var range = document.createRange();
    var rNode = document.getElementById(id).childNodes[0];
    range.selectNode(rNode);
    window.getSelection().removeAllRanges(); // clear current selection
    var blank=document.getElementById(id).innerHTML.indexOf("&nbsp;");
    range.setStart(rNode, 0);
    range.setEnd(rNode, blank);
    window.getSelection().addRange(range); // to select text
    document.execCommand("copy");
	    //window.getSelection().removeAllRanges();// to deselect
}

function copyHINver2Clipboard(id) {
    var range = document.createRange();
    range.selectNode(document.getElementById(id));
    window.getSelection().removeAllRanges(); // clear current selection
    window.getSelection().addRange(range); // to select text
    document.execCommand("copy");
}
</script>
<oscar:customInterface section="master"/>

<script>

function checkTypeIn() {
  var dob = document.titlesearch.keyword; typeInOK = false;

  if (dob.value.indexOf('%b610054') == 0 && dob.value.length > 18){
     document.titlesearch.keyword.value = dob.value.substring(8,18);
     document.titlesearch.search_mode[4].checked = true;
  }

  if(document.titlesearch.search_mode[2].checked) {
    if(dob.value.length==8) {
      dob.value = dob.value.substring(0, 4)+"-"+dob.value.substring(4, 6)+"-"+dob.value.substring(6, 8);
      //alert(dob.value.length);
      typeInOK = true;
    }
    if(dob.value.length != 10) {
      alert("<bean:message key="demographic.search.msgWrongDOB"/>");
      typeInOK = false;
    }

    return typeInOK ;
  } else {
    return true;
  }
}

function checkName() {
	var typeInOK = false;
	if(document.updatedelete.last_name.value!="" && document.updatedelete.first_name.value!="" && document.updatedelete.last_name.value!=" " && document.updatedelete.first_name.value!=" ") {
	    typeInOK = true;
	} else {
		alert ("<bean:message key="demographic.demographiceditdemographic.msgNameRequired"/>");
    }
	return typeInOK;
}

function checkDate(yyyy,mm,dd,err_msg) {

	var typeInOK = false;

	if(checkTypeNum(yyyy) && checkTypeNum(mm) && checkTypeNum(dd) ){
        var check_date = new Date(yyyy,(mm-1),dd);
		var now = new Date();
		var year=now.getFullYear();
		var month=now.getMonth()+1;
		var date=now.getDate();
		//alert(yyyy + " | " + mm + " | " + dd + " " + year + " " + month + " " +date);

		var young = new Date(year,month,date);
		var old = new Date(1800,01,01);
		//alert(check_date.getTime() + " | " + young.getTime() + " | " + old.getTime());
		if (check_date.getTime() <= young.getTime() && check_date.getTime() >= old.getTime() && yyyy.length==4) {
		    typeInOK = true;
		}
		if ( yyyy == "0000"){
                    typeInOK = false;
                }
        }

	if (!isValidDate(dd,mm,yyyy) || !typeInOK){
            alert (err_msg+"\n<bean:message key="demographic.demographiceditdemographic.msgWrongDate"/>");
            typeInOK = false;
        }

	return typeInOK;
}
function checkDob() {
	var yyyy = document.updatedelete.year_of_birth.value;
	var mm = document.updatedelete.month_of_birth.value;
	var dd = document.updatedelete.date_of_birth.value;

      return checkDate(yyyy,mm,dd,"<bean:message key="demographic.search.msgWrongDOB"/>");
}

function isValidDate(day,month,year){
   month = ( month - 1 );
   dteDate=new Date(year,month,day);
   //alert(dteDate);
   return ((day==dteDate.getDate()) && (month==dteDate.getMonth()) && (year==dteDate.getFullYear()));
}

function checkHin() {
	var hin = document.updatedelete.hin.value;
	var province = document.updatedelete.hc_type.value;

	if (!isValidHin(hin, province))
	{
		alert ("<bean:message key="demographic.demographiceditdemographic.msgWrongHIN"/>");
		return(false);
	}

	return(true);
}



function rosterStatusChangedNotBlank() {
	if (rosterStatusChanged()) {

		if (document.updatedelete.roster_status.value=="") {
			alert ("<bean:message key="demographic.demographiceditdemographic.msgBlankRoster"/>");
			document.updatedelete.roster_status.focus();
			return false;
		}

		return true;
	}
	return false;
}

function rosterStatusDateAllowed() {
	if (document.updatedelete.roster_status.value=="") {
	    yyyy = document.updatedelete.roster_date_year.value.trim();
	    mm = document.updatedelete.roster_date_month.value.trim();
	    dd = document.updatedelete.roster_date_day.value.trim();

	    if (yyyy!="" || mm!="" || dd!="") {
	    	alert ("<bean:message key="demographic.search.msgForbiddenRosterDate"/>");
	    	return false;
	    }
	    return true;
	}
	return true;
}

function rosterStatusDateValid(trueIfBlank) {
//return true; //PHC disbable
    yyyy = document.updatedelete.roster_date_year.value.trim();
    mm = document.updatedelete.roster_date_month.value.trim();
    dd = document.updatedelete.roster_date_day.value.trim();
    var errMsg = "<bean:message key="demographic.search.msgWrongRosterDate"/>";

    if (trueIfBlank) {
    	errMsg += "\n<bean:message key="demographic.search.msgLeaveBlank"/>";
    	if (yyyy=="" && mm=="" && dd=="") return true;
    }
    return checkDate(yyyy,mm,dd,errMsg);
}


function rosterEnrolledToValid(trueIfBlank) {
	var val = document.updatedelete.roster_enrolled_to.value.trim();

    if (trueIfBlank) {
    	errMsg += "\n<bean:message key="demographic.search.msgLeaveBlank"/>";
    	if (val=="") return true;
    }

    var errMsg = '';

    if(val == "") {
    	errMsg += "<bean:message key="demographic.search.msgWrongRosterEnrolledTo"/>";
    }

    if(errMsg != '') {
    	 alert (errMsg);
    	 return false;
    }
    return true;
}

function rosterStatusTerminationDateFilled() {
	yyyy = document.updatedelete.roster_termination_date_year.value.trim();
    mm = document.updatedelete.roster_termination_date_month.value.trim();
    dd = document.updatedelete.roster_termination_date_day.value.trim();

    if(yyyy != '' || mm != '' || dd != '') {
    	return true;
    }
    return false;
}

function rosterStatusTerminationReasonFilled() {
	reason = document.updatedelete.roster_termination_reason.value;

	if(reason != '') {
    	return true;
    }
    return false;
}

function rosterStatusTerminationDateValid(trueIfBlank) {
    yyyy = document.updatedelete.roster_termination_date_year.value.trim();
    mm = document.updatedelete.roster_termination_date_month.value.trim();
    dd = document.updatedelete.roster_termination_date_day.value.trim();
    var errMsg = "<bean:message key="demographic.search.msgWrongRosterTerminationDate"/>";

    if (trueIfBlank) {
    	errMsg += "\n<bean:message key="demographic.search.msgLeaveBlank"/>";
    	if (yyyy=="" && mm=="" && dd=="") return true;
    }
    return checkDate(yyyy,mm,dd,errMsg);
}

function rosterStatusTerminationReasonNotBlank() {
	if (document.updatedelete.roster_termination_reason.value=="") {
		alert ("<bean:message key="demographic.demographiceditdemographic.msgNoTerminationReason"/>");
		return false;
	}
	return true;
}


function patientStatusDateValid(trueIfBlank) {
    var yyyy = document.updatedelete.patientstatus_date_year.value.trim();
    var mm = document.updatedelete.patientstatus_date_month.value.trim();
    var dd = document.updatedelete.patientstatus_date_day.value.trim();

    if (trueIfBlank) {
    	if (yyyy=="" && mm=="" && dd=="") return true;
    }
    return checkDate(yyyy,mm,dd,"<bean:message key="demographic.search.msgWrongPatientStatusDate"/>");
}




function checkONReferralNo() {
	<%
		String skip = OscarProperties.getInstance().getProperty("SKIP_REFERRAL_NO_CHECK","false");
		if(!skip.equals("true")) {
	%>
  var referralNo = document.updatedelete.r_doctor_ohip.value ;
  if (document.updatedelete.hc_type.value == 'ON' && referralNo.length > 0 && referralNo.length != 6) {
    alert("<bean:message key="demographic.demographiceditdemographic.msgWrongReferral"/>") ;
  }

  <% } %>
}


function newStatus() {
    newOpt = prompt("<bean:message key="demographic.demographiceditdemographic.msgPromptStatus"/>:", "");
    if (newOpt == null) {
    	return;
    } else if(newOpt != "") {
        document.updatedelete.patient_status.options[document.updatedelete.patient_status.length] = new Option(newOpt, newOpt);
        document.updatedelete.patient_status.options[document.updatedelete.patient_status.length-1].selected = true;
    } else {
        alert("<bean:message key="demographic.demographiceditdemographic.msgInvalidEntry"/>");
    }
}

function newStatus1() {
    newOpt = prompt("<bean:message key="demographic.demographiceditdemographic.msgPromptStatus"/>:", "");
    if (newOpt == null) {
    	return;
    } else if(newOpt != "") {
        document.updatedelete.roster_status.options[document.updatedelete.roster_status.length] = new Option(newOpt, newOpt);
        document.updatedelete.roster_status.options[document.updatedelete.roster_status.length-1].selected = true;
    } else {
        alert("<bean:message key="demographic.demographiceditdemographic.msgInvalidEntry"/>");
    }
}

</script>
<script language="JavaScript">
function showEdit(){
    document.getElementById('editDemographic').style.display = 'block';
    document.getElementById('viewDemographics2').style.display = 'none';
    document.getElementById('updateButton').style.display = 'block';
    document.getElementById('topupdateButtons').style.display = 'block';
    document.getElementById('swipeButton').style.display = 'block';
    document.getElementById('editBtn').style.display = 'none';
    document.getElementById('closeBtn').style.display = 'inline';
    //openAccordion();
}
function openAccordion() {
    document.getElementById('demographicSectionContent').style.height='auto';
    document.getElementById('contactSectionContent').style.height='auto';
    document.getElementById('insuranceSectionContent').style.height='auto';
    document.getElementById('teamSectionContent').style.height='auto';
    document.getElementById('wlSectionContent').style.height='auto';
    document.getElementById('additionalSectionContent').style.height='auto';
    var elems = document.querySelectorAll("legend");
    [].forEach.call(elems, function(el) {
        el.classList.remove("collapsed");
    });
    var elems = document.querySelectorAll(".accordion-body");
    [].forEach.call(elems, function(el) {
        el.classList.add("in");
    });
}
function closeAccordion() {
    document.getElementById('demographicSectionContent').style.height='0';
    document.getElementById('contactSectionContent').style.height='0';
    document.getElementById('insuranceSectionContent').style.height='0';
    document.getElementById('teamSectionContent').style.height='0';
    document.getElementById('wlSectionContent').style.height='0';
    document.getElementById('additionalSectionContent').style.height='0';
}

function showHideDetail(){
    showHideItem('editDemographic');
    showHideItem('viewDemographics2');
    showHideItem('updateButton');
    showHideItem('topupdateButtons');
    showHideItem('swipeButton');
    showHideItem('editWrapper');
    if(document.getElementById('editWrapper').style.display == 'block'){
        setPhone();
	}
    showHideBtn('editBtn');
    showHideBtn('closeBtn');

}

// Used to display demographic sections, where sections is an array of id's for
// div elements with class "demographicSection"
function showHideMobileSections(sections) {
    showHideItem('mobileDetailSections');
    for (var i = 0; i < sections.length; i++) {
        showHideItem(sections[i]);
    }
    // Change behaviour of cancel button
    var cancelValue = "<bean:message key="global.btnCancel" />";
    var backValue = "<bean:message key="global.btnBack" />";
    var cancelBtn = document.getElementById('cancelButton');
    if (cancelBtn.value == cancelValue) {
        cancelBtn.value = backValue;
        cancelBtn.onclick = function() { showHideMobileSections(sections); };
    } else {
        cancelBtn.value = cancelValue;
        cancelBtn.onclick = function() { self.close(); };
    }
}

function showHideItem(id){
    if(document.getElementById(id).style.display == 'inline' || document.getElementById(id).style.display == 'block')
        document.getElementById(id).style.display = 'none';
    else
        document.getElementById(id).style.display = 'block';
}

function showHideBtn(id){
    if(document.getElementById(id).style.display == 'none')
        document.getElementById(id).style.display = 'inline';
    else
        document.getElementById(id).style.display = 'none';
}


function showItem(id){
        document.getElementById(id).style.display = 'inline';
}

function hideItem(id){
        document.getElementById(id).style.display = 'none';
}

<security:oscarSec roleName="<%= roleName$ %>" objectName="_eChart" rights="r" reverse="<%= false %>" >
var numMenus = 1;
var encURL = "<c:out value="${ctx}"/>/oscarEncounter/IncomingEncounter.do?providerNo=<%=curProvider_no%>&appointmentNo=&demographicNo=<%=demographic_no%>&curProviderNo=&reason=<%=Encode.forUriComponent(noteReason)%>&encType=<%=Encode.forUriComponent("telephone encounter with client")%>&userName=<%=Encode.forUriComponent( userfirstname+" "+userlastname) %>&curDate=<%=""+curYear%>-<%=""+curMonth%>-<%=""+curDay%>&appointmentDate=&startTime=&status=";
function showMenu(menuNumber, eventObj) {
    var menuId = 'menu' + menuNumber;
    return showPopup(menuId, eventObj);
}

<%if (oscarProps.getProperty("workflow_enhance")!=null && oscarProps.getProperty("workflow_enhance").equals("true")) {%>

function showAppt (targetAppt, eventObj) {
    if(eventObj) {
	targetObjectId = 'menu' + targetAppt;
	hideCurrentPopup();
	eventObj.cancelBubble = true;
	moveObject(targetObjectId, 300, 200);
	if( changeObjectVisibility(targetObjectId, 'visible') ) {
	    window.currentlyVisiblePopup = targetObjectId;
	    return true;
	} else {
	    return false;
	}
    } else {
	return false;
    }
} // showPopup

function closeApptBox(e) {
	if (!e) var e = window.event;
	var tg = (window.event) ? e.srcElement : e.target;
	if (tg.nodeName != 'DIV') return;
	var reltg = (e.relatedTarget) ? e.relatedTarget : e.toElement;
	while (reltg != tg && reltg.nodeName != 'BODY')
		reltg= reltg.parentNode;
	if (reltg== tg) return;

	// Mouseout took place when mouse actually left layer
	// Handle event
	hideCurrentPopup();
}
<%}%>

function add2url(txt) {
    var reasonLabel = "reason=";
    var encTypeLabel = "encType=";
    var beg = encURL.indexOf(reasonLabel);
    beg+= reasonLabel.length;
    var end = encURL.indexOf("&", beg);
    var part1 = encURL.substring(0,beg);
    var part2 = encURL.substr(end);
    encURL = part1 + encodeURI(txt) + part2;
    beg = encURL.indexOf(encTypeLabel);
    beg += encTypeLabel.length;
    end = encURL.indexOf("&", beg);
    part1 = encURL.substring(0,beg);
    part2 = encURL.substr(end);
    encURL = part1 + encodeURI(txt) + part2;
    popupOscarRx(710, 1024,encURL,'E<%=demographic_no%>');
    return false;
}

function customReason() {
    var txtInput;
    var list = document.getElementById("listCustom");
    if( list.style.display == "block" )
        list.style.display = "none";
    else {
        list.style.display = "block";
        txtInput = document.getElementById("txtCustom");
        txtInput.focus();
    }

    return false;
}

function grabEnterCustomReason(event){

  var txtInput = document.getElementById("txtCustom");
  if(window.event && window.event.keyCode == 13){
      add2url(txtInput.value);
  }else if (event && event.which == 13){
      add2url(txtInput.value);
  }

  return true;
}

function addToPatientSet(demoNo, patientSet) {
    if (patientSet=="-") return;
    window.open("addDemoToPatientSet.jsp?demoNo="+demoNo+"&patientSet="+patientSet, "addpsetwin", "width=50,height=50");
}
</security:oscarSec>

var demographicNo='<%=demographic_no%>';

<%
    String patientCompliance = null;
    String frequency = null;

    // Get the demographic number (already available as demographic_no in JSP)
int demoNo = Integer.parseInt(demographic_no);

    // Ensure demoNo is valid
    if (demoNo > 0) {
        try {
            // Fetch demographic data using the DAO
DemographicDao newDemographicDao = new DemographicDao();
Demographic demographic = newDemographicDao.getDemographicByDemographicNo(demoNo);

            if (demographic != null) {
                patientCompliance = demographic.getPatientCompliance();
                frequency = demographic.getFrequency();

                // Debug: Log fetched values
                // System.out.println("Debug: Fetched patientCompliance = " + patientCompliance);
                // System.out.println("Debug: Fetched frequency = " + frequency);
            } else {
                // Log if no demographic data was found
                // System.out.println("Debug: No demographic found for demographicNo = " + demoNo);
            }
        } catch (Exception e) {
            System.err.println("Error fetching demographic data: " + e.getMessage());
            e.printStackTrace();
        }
    }

    // Handle defaults if no data is found
    // if (patientCompliance == null) patientCompliance = "unknown";
    // if (frequency == null) frequency = "daily";
%>


<%
    // Get Spring ApplicationContext
    org.springframework.context.ApplicationContext context = 
        org.springframework.web.context.support.WebApplicationContextUtils.getWebApplicationContext(application);

    // Fetch the PharmacyInfoDao bean
    PharmacyInfoDao pharmacyInfoDao = (PharmacyInfoDao) context.getBean("pharmacyInfoDao");

    // Fetch the DemographicPharmacyDao bean (Fix for Issue 1)
    DemographicPharmacyDao demographicPharmacyDao = (DemographicPharmacyDao) context.getBean("demographicPharmacyDao");

    // Fetch all pharmacies for the demographic
    List<DemographicPharmacy> pharmacies = demographicPharmacyDao.findByDemographicId(demoNo);
    
    // Filter to get the preferred pharmacy
    DemographicPharmacy preferredPharmacy = null;
    for (DemographicPharmacy pharmacy : pharmacies) {
        if (pharmacy.getPreferredOrder() == 1) {
            preferredPharmacy = pharmacy;
            break;
        }
    }

    // Use preferredPharmacy for your logic (Fix for Issue 2)
    String preferredPharmacyId = (preferredPharmacy != null) ? String.valueOf(preferredPharmacy.getPharmacyId()) : null;

    // Retrieve the list of pharmacies
    List<PharmacyInfo> pharmacyList = null;
    try {
        pharmacyList = pharmacyInfoDao.getAllPharmacies();
    } catch (Exception e) {
        e.printStackTrace(); // Log the exception
    }
%>

function checkRosterStatus2(){
	<oscar:oscarPropertiesCheck property="FORCED_ROSTER_INTEGRATOR_LOCAL_STORE" value="yes">
	var rosterSelect = document.getElementById("roster_status");
	if(rosterSelect.getValue() == "RO"){
		var primaryEmr = document.getElementById("primaryEMR");
		primaryEmr.value = "1";
		primaryEmr.disable(true);
	}
	</oscar:oscarPropertiesCheck>
	return true;
}

jQuery(document).ready(function($) {
	jQuery("a.popup").on( "click", function() {
		var $me = jQuery(this);
		var name = $me.attr("title");
		var rel = $me.attr("rel");
		var content = jQuery("#" + rel).html();
		var win = window.open(null, name, "height=250,width=600,location=no,scrollbars=yes,menubars=no,toolbars=no,resizable=yes");
		jQuery(win.document.body).html(content);
		return false;
	});

});


function showCbiReminder()
{
  alert('<bean:message key="demographic.demographiceditdemographic.updateCBIReminder"/>');
}



var addressHistory = "";
var homePhoneHistory="";
var workPhoneHistory="";
var cellPhoneHistory="";

function generateMarkup(addresses,type,header) {
    var priorAddress = "";
    var markup = '<table style="width:500px">';
    markup += '<tr><th><b><bean:message key="oscarEncounter.oscarMeasurements.displayHistory.headingDateEntered" /></b></th><th><b>'+header+'</b></th></tr>';
    for(var x=0;x<addresses.length;x++) {
        if(addresses[x].type == type ) {
            if ( addresses[x].name != priorAddress && addresses[x].name != null) {
     		    markup += '<tr><td>'+addresses[x].dateSeen+'</td><td>'+addresses[x].name+'</td></tr>';
                priorAddress = addresses[x].name;
            }
     	}
     }
     markup += "</table>";
     return markup;
}



function updatePaperArchive(paperArchiveSel) {
	var val = jQuery("#paper_chart_archived").val();
	if(val == '' || val == 'NO') {
		jQuery("#paper_chart_archived_date").val('');
		jQuery("#paper_chart_archived_program").val('');
	}
	if(val == 'YES') {
		jQuery("#paper_chart_archived_program").val('<%=currentProgram%>');
	}
}

function updatePatientStatusDate() {
    var d = new Date();
    document.updatedelete.patientstatus_date_year.value = d.getFullYear();
    var mth = "" + (d.getMonth() + 1);
    if(mth.length == 1) {
    	mth = "0" + mth;
    }
    document.updatedelete.patientstatus_date_month.value = mth;
    var day = "" + d.getDate();
    if(day.length == 1) {
    	day = "0" + day;
    }
    document.updatedelete.patientstatus_date_day.value = day;
}


jQuery(document).ready(function() {
	var addresses;

	 jQuery.getJSON("<%=request.getContextPath() %>/demographicSupport.do",
             {
                     method: "getAddressAndPhoneHistoryAsJson",
                     demographicNo: demographicNo
             },
             function(response){
                 if (response instanceof Array) {
                     addresses = response;
           	  	} else {
                     var arr = new Array();
                     arr[0] = response;
                     addresses = arr;
            	}

                addressHistory = generateMarkup(addresses,'address','<bean:message key="demographic.demographiceditdemographic.formAddr" />');
                homePhoneHistory = generateMarkup(addresses,'phone','<bean:message key="demographic.demographiceditdemographic.formPhoneH" />');
                workPhoneHistory = generateMarkup(addresses,'phone2','<bean:message key="demographic.demographiceditdemographic.formPhoneW" />');
                cellPhoneHistory = generateMarkup(addresses,'cell','<bean:message key="demographic.demographiceditdemographic.formPhoneC" />');
                jQuery( "#addressHistory" ).tooltip("option","content", addressHistory);
                jQuery( "#homePhoneHistory" ).tooltip("option","content", homePhoneHistory);
                jQuery( "#workPhoneHistory" ).tooltip("option","content", workPhoneHistory);
                jQuery( "#cellPhoneHistory" ).tooltip("option","content", cellPhoneHistory);
       });
});

function consentClearBtn(radioBtnName)
{

	if( confirm("Proceed to clear all record of this consent?") )
	{

	    //clear out opt-in/opt-out radio buttons
	    var ele = document.getElementsByName(radioBtnName);
	    var preset = document.getElementById("consentPreset_" + radioBtnName).value;

	    for(var i=0;i<ele.length;i++)
	    {
	    	ele[i].checked = false;
	    }

	    //hide consent date field from displaying
	    var consentDate = document.getElementById("consentDate_" + radioBtnName);

	    if (consentDate)
	    {
	        consentDate.style.display = "none";
	    }

	    // is the user trying to clear an old consent or are they just curious what the clear button does.
	    if(preset === "true")
	    {
		    // set the delete parameter to update the deleted status in the database entry.
		    document.getElementById("deleteConsent_" + radioBtnName).value = 1;
	    }
	}
}

<%
Demographic demographic = demographicDao.getDemographic(demographic_no);
List<DemographicArchive> archives = demographicArchiveDao.findByDemographicNo(Integer.parseInt(demographic_no));
List<DemographicExtArchive> extArchives = demographicExtArchiveDao.getDemographicExtArchiveByDemoAndKey(Integer.parseInt(demographic_no), "demo_cell");

AdmissionManager admissionManager = SpringUtils.getBean(AdmissionManager.class);
	Admission bedAdmission = admissionManager.getCurrentBedProgramAdmission(demographic.getDemographicNo());
	Admission communityAdmission = admissionManager.getCurrentCommunityProgramAdmission(demographic.getDemographicNo());
	List<Admission> serviceAdmissions = admissionManager.getCurrentServiceProgramAdmission(demographic.getDemographicNo());
	if(serviceAdmissions == null) {
		serviceAdmissions = new ArrayList<Admission>();
	}

%>


<%
if("true".equals(OscarProperties.getInstance().getProperty("iso3166.2.enabled","false"))) {
	if(Arrays.asList("BC","AB","SK","MB","ON","QC","NB","NS","NL","NS","PE","YT","NT").contains(demographic.getProvince())) {
		demographic.setProvince("CA-" + demographic.getProvince());
	}
	if(Arrays.asList("BC","AB","SK","MB","ON","QC","NB","NS","NL","NS","PE","YT","NT").contains(demographic.getResidentialProvince())) {
		demographic.setResidentialProvince("CA-" + demographic.getResidentialProvince());
	}
%>
jQuery(document).ready(function(){
	setProvince('<%=StringUtils.trimToEmpty(demographic.getProvince())%>');
	setResidentialProvince('<%=demographic.getResidentialProvince()%>');
});
<% } %>

function validateHC() {
	var hin = jQuery("#hinBox").val();
	var ver = jQuery("#verBox").val();
	var hcType = jQuery("#hcTypeBox").val();

	//if (demo.hcType!="ON" || demo.hin==null || demo.hin=="") return;
	//if (demo.ver==null) demo.ver = "";

    jQuery.ajax({
        type: "GET",
        url:  '<%=request.getContextPath() %>/ws/rs/patientDetailStatusService/validateHC?hin='+hin+'&ver='+ver,
        dataType:'json',
        contentType:'application/json',
        success: function (data) {
        	var responseCode = data.responseCode;
        	var responseDescription = data.responseDescription;
        	var responseAction = data.responseAction;
        	var fName = data.firstName;
        	var lName = data.lastName;
        	var bDate = data.birthDate;
        	var gender  = data.gender;
        	var expDate = data.expiryDate;
        	var issueDate = data.issueDate;
        	var valid = data.valid;

        	alert(Jdata.responseDescription);
        },
        error: function(data) {
        	alert('An error occured.');
        }
	});
}
</script>

<style>

#appt_table {
        background: #f1f1f1;
        border-radius: 5px;
        overflow: hidden;
}

#appt_table td {
    padding: 6px 12px;
}

#appt_table td a {
    margin: 4px 0;
    text-decoration: none;
    color: #007bff;
}

body {
    line-height:12px
}
h4{
background-color:gainsboro;
}
ul{
background-color:white;
}
legend{
background-color:gainsboro;
}


li  {
    line-height:12px;
}
.titles {
background-color: grey;
}
.info {
    font-weight:bold;
}



.custom-dropdown {
    position: relative;
    display: inline-block;
    width: 430px;
}

/* Dropdown Button */
.dropdown-toggle {
    width: 430px;
    padding: 10px;
    background-color: #ffffff;
    border: 1px solid #ccc;
    cursor: pointer;
    text-align: left;
    font-size: 14px;
    color: #333;
}

/* Dropdown Menu */
.dropdown-menu {
    display: none;
    position: absolute;
    background-color: white;
    border: 1px solid #ccc;
    width: 100%;
    max-height: 300px;
    overflow-y: auto;
    z-index: 1000;
    box-shadow: 0px 8px 16px rgba(0, 0, 0, 0.2);
}

/* Search Box */
.dropdown-search {
    width: 100%;
    padding: 8px;
    box-sizing: border-box;
    border: 1px solid #ccc;
    font-size: 14px;
    outline: none;
    margin-bottom: 8px;
}

/* Options Container */
#dropdownOptionsContainer {
    max-height: 300px;
    overflow-y: auto;
}

/* Dropdown Option */
.dropdown-option {
    padding: 5px; /* Adjusted padding to match the button */
    font-size: 14px;
    cursor: pointer;
    border-bottom: 1px solid #111111;
    white-space: normal; /* Allow multi-line text */
}

.dropdown-option:last-child {
    border-bottom: none;
}

.dropdown-option:hover {
    background-color: #f1f1f1;
}

/* Distance Styling */
.option-distance {
    font-size: 10px;
    background-color: #e5e5e5; /* Set background color */
    display: block; /* Force distance to be on a new line */
    width: 70px; /* Set fixed width */
    text-align: center; /* Center text horizontally */
}

</style>

 <link href="https://cdn.jsdelivr.net/npm/select2@4.1.0-rc.0/dist/css/select2.min.css" rel="stylesheet" />
    <script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/select2@4.1.0-rc.0/dist/js/select2.min.js"></script>

</head>
<body onLoad="setfocus(); checkONReferralNo(); formatPhoneNum(); checkRosterStatus2(); parseeff_date(); parsehc_renew_date(); parseroster_date(); parseend_date();  parseroster_termination_date(); parsepatientstatus_date(); parsedate_joined(); loaddob();"
	 id="demographiceditdemographic">

<table class="xMainTable" id="scrollNumber1">
	<tr class="xMainTableTopRow">
		<td class="xMainTableTopRowLeftColumn" style="width:150px">&nbsp;&nbsp;<i class="icon-user icon-large" title="<bean:message
			key="demographic.demographiceditdemographic.msgPatientDetailRecord" />"></i>
		</td>
		<td class="xMainTableTopRowRightColumn">
		<table class="xTopStatusBar">
			<tr>
				<td style="width: 85%;"><h3 style="margin-left: 35px;">
				<%
                           java.util.Locale vLocale =(java.util.Locale)session.getAttribute(org.apache.struts.Globals.LOCALE_KEY);
                                //----------------------------REFERRAL DOCTOR------------------------------
                                String rdohip="", rd="", fd="", family_doc = "";

                                String resident="", nurse="", alert="", notes="", midwife="";

                                DemographicCust demographicCust = demographicCustDao.find(Integer.parseInt(demographic_no));
                                if(demographicCust != null) {
                                    resident = demographicCust.getResident() == null ? "" : demographicCust.getResident();
                            		nurse = demographicCust.getNurse() == null ? "" : demographicCust.getNurse();
                            		alert = demographicCust.getAlert() == null ? "" : demographicCust.getAlert();;
                            		midwife = demographicCust.getMidwife() == null ? "" : demographicCust.getMidwife();;
                                	notes = SxmlMisc.getXmlContent(demographicCust.getNotes(),"unotes") ;
                                	resident = resident==null?"":resident;
                                	nurse = nurse==null?"":nurse;
                                	alert = alert==null?"":alert;
                                	midwife = midwife==null?"":midwife;
                                	if (null == notes || notes.isEmpty() || notes.trim().equals("null")) notes = "";
                                }

                                // Demographic demographic=demographicDao.getDemographic(demographic_no);

                                String dateString = curYear+"-"+curMonth+"-"+curDay;
                                int age=0, dob_year=0, dob_month=0, dob_date=0;
                                String birthYear="0000", birthMonth="00", birthDate="00";


                                if(demographic==null) {
                                        out.println("failed!!!");
                                } else {
                                        if (true) {
                                                //----------------------------REFERRAL DOCTOR------------------------------
                                                fd=demographic.getFamilyDoctor();
                                                if (fd==null) {
                                                        rd = "";
                                                        rdohip="";
                                                        family_doc = "";
                                                }else{
                                                        rd = SxmlMisc.getXmlContent(StringUtils.trimToEmpty(demographic.getFamilyDoctor()),"rd");
                                                        rd = rd !=null && !rd.equals("null") ? rd : "" ;
                                                        rdohip = SxmlMisc.getXmlContent(StringUtils.trimToEmpty(demographic.getFamilyDoctor()),"rdohip");
                                                        rdohip = rdohip !=null && !rdohip.equals("null") ? rdohip : "" ;
                                                        family_doc = SxmlMisc.getXmlContent(StringUtils.trimToEmpty(demographic.getFamilyDoctor()),"family_doc");
                                                        family_doc = family_doc !=null ? family_doc : "" ;
                                                }
                                                //----------------------------REFERRAL DOCTOR --------------end-----------

                                                if (oscar.util.StringUtils.filled(demographic.getYearOfBirth())) birthYear = StringUtils.trimToEmpty(demographic.getYearOfBirth());
                                                if (oscar.util.StringUtils.filled(demographic.getMonthOfBirth())) birthMonth = StringUtils.trimToEmpty(demographic.getMonthOfBirth());
                                                if (oscar.util.StringUtils.filled(demographic.getDateOfBirth())) birthDate = StringUtils.trimToEmpty(demographic.getDateOfBirth());

                                               	dob_year = Integer.parseInt(birthYear);
                                               	dob_month = Integer.parseInt(birthMonth);
                                               	dob_date = Integer.parseInt(birthDate);
                                                if(dob_year!=0) age=MyDateFormat.getAge(dob_year,dob_month,dob_date);
                        %>
						<%
						oscar.oscarDemographic.data.DemographicMerged dmDAO = new oscar.oscarDemographic.data.DemographicMerged();
                            String dboperation = "search_detail";
                            String head = dmDAO.getHead(demographic_no);
                            ArrayList records = dmDAO.getTail(head);

                                    %>
                    <a href="demographiccontrol.jsp?demographic_no=<%= head %>&displaymode=edit&dboperation=<%= dboperation %>"><%=head%></a>
    <%

		for (int i=0; i < records.size(); i++){
		    if (((String) records.get(i)).equals(demographic_no)){
			%><%=", "+demographic_no %>
				<%
		    }else{
			%>, <a
					href="demographiccontrol.jsp?demographic_no=<%= records.get(i) %>&displaymode=edit&dboperation=<%= dboperation %>"><%=records.get(i)%></a>
				<%
		    }
		}
	    %>

<%    StringBuilder patientName = new StringBuilder();
patientName.append(demographic.getLastName())
.append(", ");
if (replaceNameWithPreferred && StringUtils.isNotEmpty(demographic.getAlias())) {
patientName.append(demographic.getAlias());
} else {
patientName.append(demographic.getFirstName());
if (StringUtils.isNotEmpty(demographic.getAlias())) {
patientName.append(" (").append(demographic.getAlias()).append(")");
}
} %>
		<%=Encode.forHtml(patientName.toString())%> <%=demographic.getSex()%>
		<%=age%> <bean:message key="global.years" /> &nbsp;
		<oscar:phrverification demographicNo='<%=demographic.getDemographicNo().toString()%>' ><bean:message key="phr.verification.link"/></oscar:phrverification>

		<span style="margin-left: 20px;font-style:italic">
		<bean:message key="demographic.demographiceditdemographic.msgNextAppt"/>: <oscar:nextAppt demographicNo='<%=demographic.getDemographicNo().toString()%>' />
		</span>

		<%
		if (loggedInInfo.getCurrentFacility().isIntegratorEnabled()){%>
	<jsp:include page="../admin/IntegratorStatus.jspf"/>
	<%}%>
		</h3>
		</td>
		<td style="width:11%;text-align:right;font-size:14px;">
<i class=" icon-question-sign"></i>
<a href="<%=help_url%>master-demographic-page/" target="_blank"><bean:message key="app.top1"/></a>
<i class=" icon-info-sign" style="margin-left:10px;"></i>
<a href="javascript:void(0)"  onClick="window.open('<%=request.getContextPath()%>/oscarEncounter/About.jsp','About OSCAR','scrollbars=1,resizable=1,width=800,height=600,left=0,top=0')" ><bean:message key="global.about" /></a>
		</td>
	</tr>
</table>
</td>
</tr>
<tr>
<td class="MainTableLeftColumn" valign="top">
<table id="appt_table" style="width:100%; font-size: 12px; line-height: 18px;">
	<tr class="Header">
		<td style="font-weight: bold; background: #DCDCDC;"><bean:message key="demographic.demographiceditdemographic.msgAppt"/>&nbsp;&nbsp;</td>
	</tr>
	<tr id="appt_hx">
		<td><a
			href='demographiccontrol.jsp?demographic_no=<%=demographic.getDemographicNo()%>&last_name=<%=Encode.forUriComponent(demographic.getLastName())%>&first_name=<%=Encode.forUriComponent(demographic.getFirstName())%>&orderby=appttime&displaymode=appt_history&dboperation=appt_history&limit1=0&limit2=25'><bean:message
			key="demographic.demographiceditdemographic.btnApptHist" /></a>
		</td>
	</tr>

<%
String wLReadonly = "";
WaitingList wL = WaitingList.getInstance();
if(!wL.getFound()){
wLReadonly = "readonly";
}
if(wLReadonly.equals("")){
%>
	<tr>
		<td><a
			href="<%= request.getContextPath() %>/oscarWaitingList/SetupDisplayPatientWaitingList.do?demographic_no=<%=demographic.getDemographicNo()%>">
		<bean:message key="demographic.demographiceditdemographic.msgWaitList"/></a>
		</td>
	</tr>
	</table>
	 <table style="width:100%; font-size: 12px; line-height: 18px;">
<%}%>
<security:oscarSec roleName="<%=roleName$%>" objectName="_billing" rights="r">
	<tr class="Header">
		<td style="font-weight: bold; background: #DCDCDC;"><bean:message
			key="admin.admin.billing" /></td>
	</tr>
	<tr>
		<td>
			<%
			if ("CLINICAID".equals(prov))
			{
				%>
					<a href="<%= request.getContextPath() %>/billing.do?billRegion=CLINICAID&action=invoice_reports" target="_blank">
					<bean:message key="demographic.demographiceditdemographic.msgInvoiceList"/>
					</a>
				<%
			}
			else if("ON".equals(prov))
			{
			%>
				<a href="javascript: function myFunction() {return false; }"
					onClick="popupPage(600,1088,'<%= request.getContextPath() %>/billing/CA/ON/billinghistory.jsp?demographic_no=<%=demographic.getDemographicNo()%>&last_name=<%=Encode.forUriComponent(demographic.getLastName())%>&first_name=<%=Encode.forUriComponent(demographic.getFirstName())%>&orderby=appointment_date&displaymode=appt_history&dboperation=appt_history&limit1=0&limit2=10')">
				<bean:message key="demographic.demographiceditdemographic.msgBillHistory"/></a>
			<%
			}
			else
			{
			%>
				<a href="#"
					onclick="popupPage(600,1088,'<%= request.getContextPath() %>/billing/CA/BC/billStatus.jsp?lastName=<%=Encode.forUriComponent(demographic.getLastName())%>&firstName=<%=Encode.forUriComponent(demographic.getFirstName())%>&filterPatient=true&demographicNo=<%=demographic.getDemographicNo()%>');return false;">
				<bean:message key="demographic.demographiceditdemographic.msgInvoiceList"/></a>


				</td>
	</tr>
	<tr>
		<td>
				<a  href="javascript: void();" onclick="return !showMenu('2', event);" onmouseover="callEligibilityWebService('<%= request.getContextPath() %>/billing/CA/BC/ManageTeleplan.do','returnTeleplanMsg');"><bean:message key="demographic.demographiceditdemographic.btnCheckElig"/></a>
				<div id='menu2' class='menu' onclick='event.cancelBubble = true;' style="width:350px;">
					<span id="search_spinner" ><bean:message key="demographic.demographiceditdemographic.msgLoading"/></span>
					<span id="returnTeleplanMsg"></span>
				</div>
			<%}%>
		</td>
	</tr>
	<tr>
		<td><a
			href="javascript: function myFunction() {return false; }"
			onClick="popupPage(900, 1200, '<%= request.getContextPath() %>/billing.do?billRegion=<%=Encode.forUriComponent(prov)%>&billForm=<%=Encode.forUriComponent(oscarProps.getProperty("default_view"))%>&hotclick=&appointment_no=0&demographic_name=<%=Encode.forUriComponent(demographic.getLastName())%>%2C<%=Encode.forUriComponent(demographic.getFirstName())%>&demographic_no=<%=demographic.getDemographicNo()%>&providerview=<%=demographic.getProviderNo()%>&user_no=<%=curProvider_no%>&apptProvider_no=none&appointment_date=<%=dateString%>&start_time=00:00:00&bNewForm=1&status=t');return false;"
			title="<bean:message key="demographic.demographiceditdemographic.msgBillPatient"/>"><bean:message key="demographic.demographiceditdemographic.msgCreateInvoice"/></a></td>
	</tr>
	<%
	if("ON".equals(prov)) {
		String default_view = oscarProps.getProperty("default_view", "");

		if (!oscarProps.getProperty("clinic_no", "").startsWith("1022")) { // part 2 of quick hack to make Dr. Hunter happy
%>
		<tr>
			<td><a
				href="javascript: function myFunction() {return false; }"
				onClick="popupOscarRx(500, 720,'<%= request.getContextPath() %>/billing/CA/ON/specialtyBilling/fluBilling/addFluBilling.jsp?function=demographic&functionid=<%=demographic.getDemographicNo()%>&creator=<%=curProvider_no%>&demographic_name=<%=Encode.forUriComponent(demographic.getLastName())%>%2C<%=Encode.forUriComponent(demographic.getFirstName())%>&hin=<%=Encode.forUriComponent(demographic.getHin()!=null?demographic.getHin():"")%><%=Encode.forUriComponent(demographic.getVer()!=null?demographic.getVer():"")%>&demo_sex=<%=Encode.forUriComponent(demographic.getSex())%>&demo_hctype=<%=Encode.forUriComponent(demographic.getHcType()==null?"null":demographic.getHcType())%>&rd=<%=Encode.forUriComponent(rd==null?"null":rd)%>&rdohip=<%=Encode.forUriComponent(rdohip==null?"null":rdohip)%>&dob=<%=MyDateFormat.getStandardDate(Integer.parseInt(birthYear),Integer.parseInt(birthMonth),Integer.parseInt(birthDate))%>&mrp=<%=demographic.getProviderNo() != null ? demographic.getProviderNo() : ""%>');return false;"
				title='<bean:message key="demographic.demographiceditdemographic.msgAddFluBill"/>'><bean:message key="demographic.demographiceditdemographic.msgFluBilling"/></a></td>
		</tr>
<%          } %>
		<tr>
			<td><a
				href="javascript: function myFunction() {return false; }"
				onClick="popupOscarRx(900, 1200,'<%= request.getContextPath() %>/billing/CA/ON/billingShortcutPg1.jsp?billRegion=<%=Encode.forUriComponent(prov)%>&billForm=<%=Encode.forUriComponent(oscarProps.getProperty("hospital_view", default_view))%>&hotclick=&appointment_no=0&demographic_name=<%=Encode.forUriComponent(demographic.getLastName())%>%2C<%=Encode.forUriComponent(demographic.getFirstName())%>&demographic_no=<%=demographic.getDemographicNo()%>&providerview=<%=demographic.getProviderNo()%>&user_no=<%=curProvider_no%>&apptProvider_no=none&appointment_date=<%=dateString%>&start_time=00:00:00&bNewForm=1&status=t');return false;"
				title="<bean:message key="demographic.demographiceditdemographic.msgBillPatient"/>"><bean:message key="demographic.demographiceditdemographic.msgHospitalBilling"/></a></td>
		</tr>
		<tr>
			<td><a
				href="javascript: function myFunction() {return false; }"
				onClick="popupOscarRx(400, 600,'<%= request.getContextPath() %>/billing/CA/ON/addBatchBilling.jsp?demographic_no=<%=demographic.getDemographicNo().toString()%>&creator=<%=curProvider_no%>&demographic_name=<%=Encode.forUriComponent(demographic.getLastName())%>%2C<%=Encode.forUriComponent(demographic.getFirstName())%>&hin=<%=Encode.forUriComponent(demographic.getHin()!=null?demographic.getHin():"")%><%=Encode.forUriComponent(demographic.getVer()!=null?demographic.getVer():"")%>&dob=<%=MyDateFormat.getStandardDate(Integer.parseInt(birthYear),Integer.parseInt(birthMonth),Integer.parseInt(birthDate))%>');return false;"
				title='<bean:message key="demographic.demographiceditdemographic.msgAddBatchBilling"/>'><bean:message key="demographic.demographiceditdemographic.msgAddBatchBilling"/></a>
			</td>
		</tr>
		<tr>
			<td><a
				href="javascript: function myFunction() {return false; }"
				onClick="popupOscarRx(400, 600,'<%= request.getContextPath() %>/billing/CA/ON/inr/addINRbilling.jsp?function=demographic&functionid=<%=demographic.getDemographicNo()%>&creator=<%=curProvider_no%>&demographic_name=<%=Encode.forUriComponent(demographic.getLastName())%>%2C<%=Encode.forUriComponent(demographic.getFirstName())%>&hin=<%=Encode.forUriComponent(demographic.getHin()!=null?demographic.getHin():"")%><%=Encode.forUriComponent(demographic.getVer()!=null?demographic.getVer():"")%>&dob=<%=MyDateFormat.getStandardDate(Integer.parseInt(birthYear),Integer.parseInt(birthMonth),Integer.parseInt(birthDate))%>');return false;"
				title='<bean:message key="demographic.demographiceditdemographic.msgAddINRBilling"/>'><bean:message key="demographic.demographiceditdemographic.msgAddINR"/></a>
			</td>
		</tr>
		<tr>
			<td><a
				href="javascript: function myFunction() {return false; }"
				onClick="popupOscarRx(600, 600,'<%= request.getContextPath() %>/billing/CA/ON/inr/reportINR.jsp?provider_no=<%=curProvider_no%>');return false;"
				title='<bean:message key="demographic.demographiceditdemographic.msgINRBilling"/>'><bean:message key="demographic.demographiceditdemographic.msgINRBill"/></a>
			</td>
		</tr>
<%
	}
%>

</security:oscarSec>
	<tr class="Header">
		<td style="font-weight: bold; background: #DCDCDC;"><bean:message
			key="oscarEncounter.Index.clinicalModules" /></td>
	</tr>
	<tr>
		<td><a
			href="javascript: function myFunction() {return false; }"
			onClick="popupPage(700,960,'<%= request.getContextPath() %>/oscarEncounter/oscarConsultationRequest/DisplayDemographicConsultationRequests.jsp?de=<%=demographic.getDemographicNo()%>&proNo=<%=demographic.getProviderNo()%>')"><bean:message
			key="demographic.demographiceditdemographic.btnConsultation" /></a></td>
	</tr>

	<tr>
		<td><a
			href="javascript: function myFunction() {return false; }"
			onClick="popupOscarRx(700,1027,'<%= request.getContextPath() %>/oscarRx/choosePatient.do?providerNo=<%=curProvider_no%>&demographicNo=<%=demographic_no%>','Rx<%=demographic_no%>')"><bean:message
			key="global.prescriptions" /></a>
		</td>
	</tr>

	<security:oscarSec roleName="<%=roleName$%>" objectName="_eChart"
		rights="r" reverse="<%=false%>">
    <special:SpecialEncounterTag moduleName="eyeform" reverse="true">
    <tr><td>
			<a href="javascript: function myFunction() {return false; }" onClick="popupOscarRx(710, 1024,encURL,'E<%=demographic_no%>');return false;" title="<bean:message key="demographic.demographiceditdemographic.btnEChart"/>">
			<bean:message key="demographic.demographiceditdemographic.btnEChart" /></a>&nbsp;<a style="text-decoration: none;" href="javascript: function myFunction() {return false; }" onmouseover="return !showMenu('1', event);">+</a>
			<div id='menu1' class="menu" onclick='event.cancelBubble = true;'>
			<h4 style='text-align: center; color: black;' ><bean:message key="demographic.demographiceditdemographic.msgEncType"/></h4>

			<ul>
				<li><a href="#" style="color: #0088cc;" onclick="return add2url('<bean:message key="oscarEncounter.faceToFaceEnc.title"/>');"><bean:message key="oscarEncounter.faceToFaceEnc.title"/>
				</a><br>
				</li>
				<li><a href="#" style="color: #0088cc;"  onclick="return add2url('<bean:message key="oscarEncounter.telephoneEnc.title"/>');"><bean:message key="oscarEncounter.telephoneEnc.title"/>
				</a><br>
				</li>
				<li><a href="#" style="color: #0088cc;"  onclick="return add2url('<bean:message key="oscarEncounter.noClientEnc.title"/>');"><bean:message key="oscarEncounter.noClientEnc.title"/>
				</a><br>
				</li>
				<li><a href="#" style="color: #0088cc;"  onclick="return customReason();"><bean:message key="demographic.demographiceditdemographic.msgCustom"/></a></li>
				<li id="listCustom" style="display: none;"><input id="txtCustom" type="text" size="16" maxlength="32" onkeypress="return grabEnterCustomReason(event);"></li>
			</ul>
			</div>
    </td></tr>
    </special:SpecialEncounterTag>
    <special:SpecialEncounterTag moduleName="eyeform">
    <tr><td>
	    <a href="javascript: function myFunction() {return false; }" onClick="popupOscarRx(710, 1024,encURL,'EF<%=demographic_no%>');return false;" title="<bean:message key="demographic.demographiceditdemographic.btnEChart"/>">
	    <bean:message key="demographic.demographiceditdemographic.btnEChart"/></a>
    </td></tr>
    </special:SpecialEncounterTag>
		<tr>
			<td><a
				href="javascript: function myFunction() {return false; }"
				onClick="popupPage(700,960,'<c:out value="${ctx}"/>/oscarPrevention/index.jsp?demographic_no=<%=demographic_no%>');return false;">
			<bean:message key="oscarEncounter.LeftNavBar.Prevent" /></a></td>
		</tr>
	</security:oscarSec>
<plugin:hideWhenCompExists componentName="specialencounterComp" reverse="true">
<%session.setAttribute("encounter_oscar_baseurl",request.getContextPath());
%>
	<special:SpecialEncounterTag moduleName="eyeform" exactEqual="true">

		<tr><td>
	<a href="#" style="color: brown;" onclick="popupPage(600,800,'<%=request.getContextPath()%>/mod/specialencounterComp/PatientLog.do?method=editPatientLog&demographicNo=<%=demographic_no%>&providerNo=<%=curProvider_no%>&providerName=<%=Encode.forUriComponent( userfirstname+" "+userlastname)%>');return false;">patient log</a>
	</td>
	</tr>
	</special:SpecialEncounterTag>
	<special:SpecialEncounterTag moduleName="eyeform">
	<tr><td>
	<a href="#" style="color: brown;" onclick="popupPage(600,600,'<%=request.getContextPath()%>/mod/specialencounterComp/EyeForm.do?method=eyeFormHistory&demographicNo=<%=demographic_no%>&providerNo=<%=curProvider_no%>&providerName=<%=Encode.forUriComponent( userfirstname+" "+userlastname)%>');return false;">eyeForm Hx</a>
	</td>
	</tr>
	<tr>
	<td>
		<a href="#" style="color: brown;" onclick="popupPage(600,600,'<%=request.getContextPath()%>/mod/specialencounterComp/EyeForm.do?method=chooseField&&demographicNo=<%=demographic_no%>&providerNo=<%=curProvider_no%>&providerName=<%=Encode.forUriComponent( userfirstname+" "+userlastname)%>');return false;">Exam Hx</a>
		</td>
		</tr>
		<tr>
		<td>
		<a href="#" style="color: brown;" onclick="popupPage(600,1000,'<%=request.getContextPath()%>/mod/specialencounterComp/ConReportList.do?method=list&&dno=<%=demographic_no%>');return false;">ConReport Hx</a>

	</td></tr>
	</special:SpecialEncounterTag>
</plugin:hideWhenCompExists>
	<tr>
		<td>
<%if( org.oscarehr.common.IsPropertiesOn.isTicklerPlusEnable() ) {%>
		<a
			href="javascript: function myFunction() {return false; }"
			onClick="popupPage(700,1000,'<%= request.getContextPath() %>/Tickler.do?filter.demographic_no=<%=demographic_no%>');return false;">
		<bean:message key="global.tickler" /></a>
		<% }else { %>
		<a
			href="javascript: function myFunction() {return false; }"
			onClick="popupPage(700,1000,'<%= request.getContextPath() %>/tickler/ticklerDemoMain.jsp?demoview=<%=demographic_no%>');return false;">
		<bean:message key="global.tickler" /></a>
		<% } %>
		</td>
	</tr>
	<tr>
		<td><a
			href="javascript: function myFunction() {return false; }"
			onClick="popup(700,960,'<%= request.getContextPath() %>/oscarMessenger/SendDemoMessage.do?demographic_no=<%=demographic.getDemographicNo()%>','msg')">
		<bean:message key="demographic.demographiceditdemographic.msgSendMsg"/></a></td>
	</tr>
	<tr>
	    <td> <a href="#" onclick="popup(300,300,'demographicCohort.jsp?demographic_no=<%=demographic.getDemographicNo()%>', 'cohort'); return false;"><bean:message key="demographic.demographiceditdemographic.msgAddPatientSet"/></a>
	    </td>
	</tr>

<%
if(loggedInInfo.getCurrentFacility().isIntegratorEnabled()) {
%>
<tr>
<td> <a href="#" onclick="popup(500,500,'<%= request.getContextPath() %>/integrator/manage_linked_clients.jsp?demographicId=<%=demographic.getDemographicNo()%>', 'manage_linked_clients'); return false;">Integrator Linking</a>
</td>
</tr>
<% } %>
		<phr:indivoRegistered provider="<%=curProvider_no%>"
			demographic="<%=demographic_no%>">
		<tr class="Header">
		     <td style="font-weight: bold"><bean:message key="global.personalHealthRecord"/></td>
		</tr>
			<tr>
				<td>
					<%
						String onclickString="alert('Login to PHR First')";

						MyOscarLoggedInInfo myOscarLoggedInInfo=MyOscarLoggedInInfo.getLoggedInInfo(session);
						if (myOscarLoggedInInfo!=null && myOscarLoggedInInfo.isLoggedIn()) onclickString="popupOscarRx(600,900,request.getContextPath() +  '/phr/PhrMessage.do?method=createMessage&providerNo="+curProvider_no+"&demographicNo="+demographic_no+"')";
					%>
					<a href="javascript: function myFunction() {return false; }" ONCLICK="<%=onclickString%>"	title="myOscar">
						<bean:message key="demographic.demographiceditdemographic.msgSendMsgPHR"/>
					</a>
				</td>
			</tr>
			<tr>
				<td>
					<a href="" onclick="popup(600, 1000, '<%=request.getContextPath()%>/demographic/viewPhrRecord.do?demographic_no=<%=demographic_no%>', 'viewPatientPHR'); return false;">View PHR Record</a>
				</td>
			</tr>
			<tr>
				<td>
					<%
						if (myOscarLoggedInInfo!=null && myOscarLoggedInInfo.isLoggedIn()) onclickString="popupOscarRx(600,900,'"+request.getContextPath()+"/admin/oscar_myoscar_sync_config_redirect.jsp')";
					%>
					<a href="javascript: function myFunction() {return false; }" ONCLICK="<%=onclickString%>"	title="myOscar">
						<bean:message key="demographic.demographiceditdemographic.MyOscarDataSync"/>
					</a>
				</td>
			</tr>
		</phr:indivoRegistered>

<% if (oscarProps.getProperty("clinic_no", "").startsWith("1022")) { // quick hack to make Dr. Hunter happy
%>
	<tr>
		<td><a
			href="javascript: function myFunction() {return false; }"
			onClick="popupPage(700,1000,'<%= request.getContextPath() %>/form/forwardshortcutname.jsp?formname=AR1&demographic_no=<%=request.getParameter("demographic_no")%>');">AR1</a>
		</td>
	</tr>
	<tr>
		<td><a
			href="javascript: function myFunction() {return false; }"
			onClick="popupPage(700,1000,'<%= request.getContextPath() %>/form/forwardshortcutname.jsp?formname=AR2&demographic_no=<%=request.getParameter("demographic_no")%>');">AR2</a>
		</td>
	</tr>
<% } %>
	<tr class="Header">
		<td style="font-weight: bold; background: #DCDCDC;"><bean:message
			key="demographic.resources" /></td>
	</tr>
<special:SpecialPlugin moduleName="inboxmnger">
<tr>
<td>

	<a href="#" onClick="window.open('<%=request.getContextPath()%>/mod/docmgmtComp/DocList.do?method=list&&demographic_no=<%=demographic_no %>','_blank','resizable=yes,status=yes,scrollbars=yes');return false;">Inbox Manager</a><br>
</td>
</tr>
 </special:SpecialPlugin>
 <special:SpecialPlugin moduleName="inboxmnger" reverse="true">
	<tr><td>
		<a href="javascript: function myFunction() {return false; }"
			onClick="popupPage(710,970,'<%= request.getContextPath() %>/dms/documentReport.jsp?function=demographic&doctype=lab&functionid=<%=demographic.getDemographicNo()%>&curUser=<%=curProvider_no%>')"><bean:message
			key="demographic.demographiceditdemographic.msgDocuments" /></a></td>
	</tr>
	<%
	UserProperty upDocumentBrowserLink = pref.getProp(curProvider_no, UserProperty.EDOC_BROWSER_IN_MASTER_FILE);
	if ( upDocumentBrowserLink != null && upDocumentBrowserLink.getValue() != null && upDocumentBrowserLink.getValue().equals("yes")) {%>
	<tr><td>
		<a href="javascript: function myFunction() {return false; }"
			onClick="popupPage(710,970,'<%= request.getContextPath() %>/dms/documentBrowser.jsp?function=demographic&doctype=lab&functionid=<%=demographic.getDemographicNo()%>&categorykey=Private Documents')"><bean:message
			key="demographic.demographiceditdemographic.msgDocumentBrowser" /></a></td>
	</tr>
	<%}%>
	<tr>
		<td><a
			href="javascript: function myFunction() {return false; }"
			onClick="popupPage(710,970,'<%= request.getContextPath() %>/dms/documentReport.jsp?function=demographic&doctype=lab&functionid=<%=demographic.getDemographicNo()%>&curUser=<%=curProvider_no%>&mode=add')"><bean:message
			key="demographic.demographiceditdemographic.btnAddDocument" /></a></td>
	</tr>
</special:SpecialPlugin>
<special:SpecialEncounterTag moduleName="eyeform">
<% String iviewTag=oscarProps.getProperty("iviewTag");

if (iviewTag!=null && !"".equalsIgnoreCase(iviewTag.trim())){
%>
	<tr><td>
		<a href='<%=request.getContextPath()%>/mod/specialencounterComp/iviewServlet?method=iview&demoNo=<%=demographic.getDemographicNo()%>&<%=System.currentTimeMillis() %>'>
		<%=iviewTag %></a>
		</td></tr>
<%} %>
</special:SpecialEncounterTag>
	<tr>
		<td><a
			href="<%= request.getContextPath() %>/eform/efmpatientformlist.jsp?demographic_no=<%=demographic_no%>&apptProvider=<%=apptProvider%>&appointment=<%=appointment%>"><bean:message
			key="demographic.demographiceditdemographic.btnEForm" /></a></td>
	</tr>
	<tr>
		<td><a
			href="<%= request.getContextPath() %>/eform/efmformslistadd.jsp?demographic_no=<%=demographic_no%>&appointment=<%=appointment%>">
		<bean:message
			key="demographic.demographiceditdemographic.btnAddEForm" /> </a></td>
	</tr>
	<% if (isSharingCenterEnabled) { %>
	<!-- Sharing Center Links -->
	<tr>
	  <td><a href="<%= request.getContextPath() %>/sharingcenter/networks/sharingnetworks.jsp?demographic_no=<%=demographic_no%>"><bean:message key="sharingcenter.networks.sharingnetworks" /></a></td>
	</tr>
	<tr>
	  <td><a href="<%= request.getContextPath() %>/sharingcenter/documents/SharedDocuments.do?demographic_no=<%=demographic_no%>"><bean:message key="sharingcenter.documents.shareddocuments" /></a></td>
	</tr>
	<% } // endif isSharingCenterEnabled %>

</table>
</td>
<td class="xMainTableRightColumn" valign="top">
    <!-- A list used in the mobile version for users to pick which information they'd like to see -->
    <div id="mobileDetailSections" style="display:<%=(isMobileOptimized)?"block":"none"%>;">
	<ul class="xwideList">
	    <% if (!"".equals(alert)) { %>
	    <li><a style="color:brown" onClick="showHideMobileSections(new Array('alert'))"><bean:message
		key="demographic.demographiceditdemographic.formAlert" /></a></li>
	    <% } %>
	    <li><a onClick="showHideMobileSections(new Array('demographic'))"><bean:message
		key="demographic.demographiceditdemographic.msgDemographic"/></a></li>
	    <li><a onClick="showHideMobileSections(new Array('contactInformation'))"><bean:message
		key="demographic.demographiceditdemographic.msgContactInfo"/></a></li>
	    <li><a onClick="showHideMobileSections(new Array('otherContacts'))"><bean:message
		key="demographic.demographiceditdemographic.msgOtherContacts"/></a></li>
	    <li><a onClick="showHideMobileSections(new Array('healthInsurance'))"><bean:message
		key="demographic.demographiceditdemographic.msgHealthIns"/></a></li>
	    <li><a onClick="showHideMobileSections(new Array('patientClinicStatus','clinicStatus'))"><bean:message
		key="demographic.demographiceditdemographic.msgClinicStatus"/></a></li>
	    <li><a onClick="showHideMobileSections(new Array('notes'))"><bean:message
		key="demographic.demographiceditdemographic.formNotes" /></a></li>
	</ul>
    </div>
<table style="width:100%">
	<tr id="searchTable" >
		<td colspan="4" style="padding-left: 20px"><%-- log:info category="Demographic">Demographic [<%=demographic_no%>] is viewed by User [<%=userfirstname%> <%=userlastname %>]  </log:info --%>
		<jsp:include page="zdemographicfulltitlesearch.jsp"/>
		</td>
	</tr>
	<tr>
		<td>
		<form method="post" name="updatedelete" id="updatedelete"
			action="demographiccontrol.jsp"
			onSubmit="return checkTypeInEdit(); "><input type="hidden"
			name="demographic_no"
			value="<%=demographic.getDemographicNo()%>">
		<table style="width:100%" class="xdemographicDetail">
			<tr>
				<td class="xRowTop" style="padding-left: 32px">
	<security:oscarSec roleName="<%=roleName$%>" objectName="_demographic" rights="w">
	    <%
				    if( head.equals(demographic_no)) {
				    %>
					<a id="editBtn" href="javascript: showHideDetail();openAccordion();" class="btn btn-primary"><bean:message key="demographic.demographiceditdemographic.msgEdit"/></a>
					<a id="closeBtn" href="javascript: showHideDetail(); closeAccordion();" style="display:none;" class="btn btn-primary"><bean:message key="global.btnClose" /></a>
				   <% } %>
	      </security:oscarSec>

	    <%
	    String printEnvelope, printLbl, printAddressLbl, printChartLbl, printSexHealthLbl, printHtmlLbl, printLabLbl;
	    printEnvelope = printLbl = printAddressLbl = printChartLbl = printSexHealthLbl = printHtmlLbl = printLabLbl = null;

	    if(oscarProps.getProperty("new_label_print") != null && oscarProps.getProperty("new_label_print").equals("true")) {

		    printEnvelope = "printEnvelope.jsp?demos=";
		    printLbl = "printDemoLabel.jsp?demographic_no=";
		    printAddressLbl = "printAddressLabel.jsp?demographic_no=";
		    printChartLbl = "printDemoChartLabel.jsp?demographic_no=";
		    printSexHealthLbl = "printDemoChartLabel.jsp?labelName=SexualHealthClinicLabel&demographic_no=";
		    printHtmlLbl = "demographiclabelprintsetting.jsp?demographic_no=";
		    printLabLbl = "printClientLabLabel.jsp?demographic_no=";

	    }else{

		    printEnvelope = request.getContextPath() +  "/report/GenerateEnvelopes.do?demos=";
		    printLbl = "printDemoLabelAction.do?demographic_no=";
		    printAddressLbl = "printDemoAddressLabelAction.do?demographic_no=";
		    printChartLbl = "printDemoChartLabelAction.do?demographic_no=";
		    printSexHealthLbl = "printDemoChartLabelAction.do?labelName=SexualHealthClinicLabel&demographic_no=";
		    printHtmlLbl = "demographiclabelprintsetting.jsp?demographic_no=";
		    printLabLbl = "printClientLabLabelAction.do?demographic_no=";

	    }

	    %>
	    <div class="dropdowns">
            <button class="dropbtns btn" ><bean:message key="demographic.demographiceditdemographic.btnLabels"/> <span class="caret"></span></button>
		    <div class="dropdowns-content">
                <a href="#" onclick="popupPage(400,700,'<%=printEnvelope%><%=demographic.getDemographicNo()%>');return false;">
			    <bean:message key="demographic.demographiceditdemographic.btnCreatePDFEnvelope"/></a>
                <a href="#" onclick="popupPage(400,700,'<%=printLbl%><%=demographic.getDemographicNo()%>');return false;">
			    <bean:message key="demographic.demographiceditdemographic.btnCreatePDFLabel"/></a>
                <a href="#" onclick="popupPage(400,700,'<%=printAddressLbl%><%=demographic.getDemographicNo()%>');return false;">
			    <bean:message key="demographic.demographiceditdemographic.btnCreatePDFAddressLabel"/></a>
		        <a href="#" onclick="popupPage(400,700,'<%=printChartLbl%><%=demographic.getDemographicNo()%>');return false;">
			    <bean:message key="demographic.demographiceditdemographic.btnCreatePDFChartLabel"/></a>
		        <a href="#" onclick="popupPage(400,700,'<%=printSexHealthLbl%><%=demographic.getDemographicNo()%>');return false;">
			    <bean:message key="demographic.demographiceditdemographic.btnCreatePublicHealthLabel"/></a>
		        <a href="#" onclick="popupPage(600,800,'<%=printHtmlLbl%><%=demographic.getDemographicNo()%>');return false;">
			    <bean:message key="demographic.demographiceditdemographic.btnPrintLabel"/></a>
		        <a href="#" onclick="popupPage(400,700,'<%=printLabLbl%><%=demographic.getDemographicNo()%>');return false;">
			    <bean:message key="demographic.demographiceditdemographic.btnClientLabLabel"/></a>
            </div>
	    </div>
		<!-- PHC debug<input type="hidden" name="displaymode" value="Update Record"> -->

<%
if( demographic!=null) {
	session.setAttribute("address", demographic.getAddress());
	session.setAttribute("city", demographic.getCity());
	session.setAttribute("province", demographic.getProvince());
	session.setAttribute("postal", demographic.getPostal());
	session.setAttribute("phone", demographic.getPhone());
} %>
		<!-- PHC debug <input type="hidden" name="dboperation" value="update_record"> -->

	    <security:oscarSec roleName="<%=roleName$%>" objectName="_demographicExport" rights="r" reverse="<%=false%>">
		<input type="button" class="btn" value="<bean:message key="demographic.demographiceditdemographic.msgExport"/>"
		    onclick="window.open('demographicExport.jsp?demographicNo=<%=demographic.getDemographicNo()%>');">
	     </security:oscarSec>
	     <input type="button" name="Button" class="btn"
		    value="<bean:message key="demographic.demographiceditdemographic.btnAddFamilyMember"/>"
		    onclick="popupOscarRx(650, 1300,'demographicaddarecordhtm.jsp?search_mode=search_name&keyword=')">
<% if (oscarProps.getBooleanProperty("workflow_enhance", "true")) { %>
							<span style="position: relative; float: right; font-style: italic; background: black; color: white; padding: 4px; font-size: 12px; border-radius: 3px;">
								<span class="_hc_status_icon _hc_status_success"></span>Ready for Card Swipe
							</span>
						<% } %>
		<% if (!oscarProps.getBooleanProperty("workflow_enhance", "true")) { %>
						<span id="swipeButton" style="display: inline;">
		    <input type="button" name="Button" class="btn"
		    value="<bean:message key="demographic.demographiceditdemographic.btnSwipeCard"/>"
		    onclick="window.open('zdemographicswipe.jsp','', 'scrollbars=yes,resizable=yes,width=600,height=300, top=360, left=0')">
		</span> <!--input type="button" name="Button" value="<bean:message key="demographic.demographiceditdemographic.btnSwipeCard"/>" onclick="javascript:window.alert('Health Card Number Already Inuse');"-->
		<% } %>
	</td>
			</tr>

<%if (oscarProps.getProperty("workflow_enhance") != null && oscarProps.getProperty("workflow_enhance").equals("true")) {%>
			<tr>
	<td colspan="4">
	<table style="width:100%; background-color: #FFFFFF">
	    <tr>
		<td style="width:50%; vertical-align:top">


		</td>
		<td style="width:30%; vertical-align:top; text-align:center;">

		</td>
		<td  style="vertical-align:top; text-align:right">

		</td>
	      </tr>
	</table>
	</td>
    </tr>
			<%} %>
			
				<%
		// Step 1: Use the existing Spring ApplicationContext if not already defined
		if (context == null) {
			context = org.springframework.web.context.support.WebApplicationContextUtils.getWebApplicationContext(application);
		}

		// Step 2: Fetch the DemographicDao bean if not already defined
		if (demographicDao == null) {
			demographicDao = (DemographicDao) context.getBean("demographicDao");
		}

		// Step 3: Initialize variables for patient compliance and frequency
		String patientComplianceNew = "N/A"; // Default value
		String frequencyNew = "N/A";         // Default value

		// Step 4: Check if demographic object is in the session
			Demographic demographicNew = null;

		if (demographicNew == null) {
			// Fallback: Use the demographic_no from the request
			String demographicNoParam = request.getParameter("demographic_no");

			if (demographicNoParam != null && !demographicNoParam.isEmpty()) {
				try {
					int demographicNo = Integer.parseInt(demographicNoParam);

					// Fetch demographic data from the DAO
					Demographic demographicDataNew = demographicDao.getDemographicByDemographicNo(demographicNo);
					if (demographicDataNew != null) {
						patientComplianceNew = demographicDataNew.getPatientCompliance() != null 
							? demographicDataNew.getPatientCompliance() 
							: "N/A";
						frequencyNew = demographicDataNew.getFrequency() != null 
							? demographicDataNew.getFrequency() 
							: "N/A";

						// Optionally store the demographic object in the session for future use
						session.setAttribute("demographic", demographicDataNew);
					}
				} catch (NumberFormatException e) {
					System.out.println("Error: Invalid demographic_no parameter: " + demographicNoParam);
				}
			}
		} else {
			// If demographic object is already in the session, use it
			patientComplianceNew = demographicNew.getPatientCompliance() != null 
				? demographicNew.getPatientCompliance() 
				: "N/A";
			frequencyNew = demographicNew.getFrequency() != null 
				? demographicNew.getFrequency() 
				: "N/A";
		}
	%>

	<%
    // Step 1: Use the existing Spring ApplicationContext if not already defined
    if (context == null) {
        context = org.springframework.web.context.support.WebApplicationContextUtils.getWebApplicationContext(application);
    }

    // Step 2: Fetch DAO beans for DemographicPharmacy and PharmacyInfo with new variable names
    DemographicPharmacyDao demographicPharmacyDaoNew = (DemographicPharmacyDao) context.getBean("demographicPharmacyDao");
    PharmacyInfoDao pharmacyInfoDaoNew = (PharmacyInfoDao) context.getBean("pharmacyInfoDao");

    // Step 3: Initialize variables for pharmacy information
    String preferredPharmacyNameNew = "N/A";
    String preferredPharmacyCityNew = "N/A";
    String preferredPharmacyPhoneNew = "N/A";

    // Step 4: Get the demographic_no parameter
    String demographicNoParamNew = request.getParameter("demographic_no");
    if (demographicNoParamNew != null && !demographicNoParamNew.isEmpty()) {
        try {
            int demographicNoNew = Integer.parseInt(demographicNoParamNew);

            // Step 5: Fetch preferred pharmacy from DemographicPharmacy table
            List<DemographicPharmacy> pharmacyLinksNew = demographicPharmacyDaoNew.findByDemographicId(demographicNoNew);
            DemographicPharmacy preferredPharmacyLinkNew = pharmacyLinksNew.stream()
                .filter(dp -> dp.getPreferredOrder() == 1)
                .findFirst()
                .orElse(null);

            if (preferredPharmacyLinkNew != null) {
                // Step 6: Fetch pharmacy details from PharmacyInfo table
                PharmacyInfo preferredPharmacyNew = pharmacyInfoDaoNew.getPharmacyByRecordID(preferredPharmacyLinkNew.getPharmacyId());

                if (preferredPharmacyNew != null) {
                    preferredPharmacyNameNew = preferredPharmacyNew.getName();
                    preferredPharmacyCityNew = preferredPharmacyNew.getCity();
                    preferredPharmacyPhoneNew = preferredPharmacyNew.getPhone1();
                }
            }
        } catch (NumberFormatException e) {
            System.out.println("Error: Invalid demographic_no parameter: " + demographicNoParamNew);
        }
    }
%>

			<tr>
				<td class="xlightPurple"><!---new-->
				<div style="display: inline;" id="viewDemographics2">
				<div class=" container-fluid well span11" style="padding: 0; background-color: transparent; border: none;" >
				<div class="leftSection">
				<div class="demographicSection" id="demographic" >
				<h4>&nbsp;<bean:message key="demographic.demographiceditdemographic.msgDemographic"/>
                <i class="icon-edit" style="float: right;" title="<bean:message key="demographic.demographiceditdemographic.msgEdit"/>" onclick="showHideDetail();closeAccordion(); getElementById('demographicSectionContent').style.height='auto';"></i></h4>
				<%
					for (String key : demoExt.keySet()) {
					    if (key.endsWith("_id")) {
				%>
				<input type="hidden" name="<%=key%>" value="<%=StringEscapeUtils.escapeHtml(StringUtils.trimToEmpty(demoExt.get(key)))%>"/>
				<%
					    }
					}
				%>
				<table style="background-color: #FFFFFF; line-height: 1.2;">
				<%if (!StringUtils.isBlank(demographic.getTitle())) { // don't show title if blank %>
								<tr><td>
										<span class="labels"><bean:message key="demographic.demographiceditdemographic.msgDemoTitle"/>:</span></td>
									<td><span class="info"><%=Encode.forHtml(StringUtils.trimToEmpty(demographic.getTitle()))%></span></td></tr>
								<%}%>
					<tr><td style="white-space: nowrap;"><span class="labels"><bean:message
						      key="demographic.demographiceditdemographic.formLastName" />:</span></td>
						<td style="width:100%">
					<span class="info"><%=Encode.forHtml(WordUtils.capitalizeFully(demographic.getLastName(), new char[] {',','-','\''}))%></span>
						</td></tr>
						<%if (!StringUtils.isBlank(demographic.getMiddleNames())) { // don't show middle names if blank %>
							<tr><td style="white-space: nowrap;"><span class="labels"><bean:message
					    key="demographic.demographiceditdemographic.formMiddleNames" />:</span>
								</td><td><span class="info"><%=Encode.forHtml((WordUtils.capitalizeFully(StringUtils.trimToEmpty(demographic.getMiddleNames()))))%></span></td></tr>
					<%}%>
						<tr><td style="white-space: nowrap;"><span class="labels">
					<bean:message
							      key="demographic.demographiceditdemographic.formFirstName" />:</span></td>
							<td><span class="info"><%=Encode.forHtml(WordUtils.capitalizeFully(demographic.getFirstName(), new char[] {',','-','\''}))%></span>

							</td></tr>
					
					
				<tr><td><span class="labels"><bean:message key="demographic.demographiceditdemographic.formSex" />:</span></td>
					<td><span class="info"><%=Encode.forHtml(demographic.getSex())%></span></td>
				    </tr>
				    <tr><td><span class="labels"><bean:message key="demographic.demographiceditdemographic.msgDemoAge"/>:</span></td>
					    <td><span class="info"><%=age%>&nbsp;(<bean:message
					    key="demographic.demographiceditdemographic.formDOB" />: <%=birthYear%>-<%=birthMonth%>-<%=birthDate%>)
						    </span></td>
				    </tr>
				    <tr><td><span class="labels"><bean:message key="demographic.demographiceditdemographic.msgDemoLanguage"/>:</span></td>

				<td><span class="info"><%=StringUtils.trimToEmpty(demographic.getOfficialLanguage())%></span></td>
					    </tr>
					<% if (!StringUtils.isBlank(demographic.getCountryOfOrigin()) && !demographic.getCountryOfOrigin().equals("-1")){
						CountryCode countryCode = ccDAO.getCountryCode(demographic.getCountryOfOrigin());
						if  (countryCode != null){
					    %>
					    <tr><td><span class="labels"><bean:message key="demographic.demographiceditdemographic.msgCountryOfOrigin"/>:</span></td>
					    <td><span class="info"><%=countryCode.getCountryName() %></span></td></tr>
					<%      }
					    }
					%>
					<% if (!StringUtils.isBlank(demographic.getSpokenLanguage())) { %>
					       <tr>
						       <td><span class="labels"><bean:message key="demographic.demographiceditdemographic.msgSpokenLang"/>:</span></td>
                                                       <td><span class="info"><%=demographic.getSpokenLanguage()%></span></td>
					       </tr>
						<%}%>

						<% if (!StringUtils.isBlank(demographic.getSin())) { %>
						 <tr>
							 <td><span class="labels"><bean:message key="demographic.demographiceditdemographic.msgSIN"/>:</span></td>
                                                   	 <td><span class="info"><%=demographic.getSin()%></span><td>
						</tr>
						<%}%>
						<% String aboriginal = StringUtils.trimToEmpty(demoExt.get("aboriginal"));
						   if (aboriginal!=null && aboriginal.length()>0) { %>
						   <tr>
							   <td><span class="labels"><bean:message key="demographic.demographiceditdemographic.aboriginal"/>:</span></td>
							   <td><span class="info"><%=aboriginal%></span></td>
						   </tr>
						   <% } %>

<tr>
    <td style="white-space: nowrap;">
        <span class="labels">Patient Compliance:</span>
    </td>
    <td style="width: 100%;">
        <span class="info"><%= Encode.forHtml(patientComplianceNew.substring(0, 1).toUpperCase() + patientComplianceNew.substring(1).toLowerCase()) %></span>
    </td>
</tr>

<!-- HTML for Frequency -->
<tr>
    <td style="white-space: nowrap;">
        <span class="labels">Frequency:</span>
    </td>
    <td style="width: 100%;">
        <span class="info"><%= Encode.forHtml(frequencyNew.substring(0, 1).toUpperCase() + frequencyNew.substring(1).toLowerCase()) %></span>
    </td>
</tr>

<tr>
    <td style="white-space: nowrap;">
        <span class="labels">Preferred Pharmacy:</span>
    </td>
    <td style="width: 100%;">
        <span class="info">
            <%= Encode.forHtml(preferredPharmacyNameNew) %>,
            <%= Encode.forHtml(preferredPharmacyCityNew) %>,
            <%= Encode.forHtml(preferredPharmacyPhoneNew) %>
        </span>
    </td>
</tr>
				                </table>

						  <%-- if EXTRA_DEMO_FIELDS is set to a value in oscar.properties, additional code will be included here.
						       it will look to load a file named <parameter>.jsp, where <parameter> is the value stored in
						       EXTRA_DEMO_FIELDS --%>
						  <% if (oscarProps.getProperty("EXTRA_DEMO_FIELDS") !=null){
                                              String fieldJSP = oscarProps.getProperty("EXTRA_DEMO_FIELDS");
                                              fieldJSP+= "View.jsp";
					      %>
							<jsp:include page="<%=fieldJSP%>">
							<jsp:param name="demo" value="<%=demographic_no%>" />
							</jsp:include>
							<%}%>
						</div>


						<div class="rightSection">
					<div class="demographicSection" id="contactInformation">
					<h4>&nbsp;<bean:message key="demographic.demographiceditdemographic.msgContactInfo"/><i class="icon-edit" style="float: right;" title="<bean:message key="demographic.demographiceditdemographic.msgEdit"/>" onclick="showHideDetail();closeAccordion(); getElementById('contactSectionContent').style.height='auto';"></i></h4>
					<table style="background-color: #FFFFFF; line-height: 1.2;" >
						<tr><td style="white-space:nowrap;"><span class="labels"><bean:message
							      key="demographic.demographiceditdemographic.formPhoneH" />:</span></td>
							<td><span class="info"><%=Encode.forHtml(StringUtils.trimToEmpty(demographic.getPhone()))%>
									<% if (!StringUtils.trimToEmpty(demoExt.get("hPhoneExt")).equals("")) { %>
									x<%=StringUtils.trimToEmpty(demoExt.get("hPhoneExt"))%><%}%></span></td><td style="width:100%">
                            <span class="tooltips" id="homePhoneHistory" title="origionalTitle" style="color:#0088cc;"><bean:message
							      key="global.history" /></span>
                        </td>
						</tr>
						<% if (!StringUtils.trimToEmpty(demographic.getPhone2()).equals("")) { // don't show work phone number if blank %>
						<tr><td style="white-space:nowrap;"><span class="labels"><bean:message
							      key="demographic.demographiceditdemographic.formPhoneW" />:</span></td>
							<td style="white-space:nowrap;"><span class="info"><%=Encode.forHtml(StringUtils.trimToEmpty(demographic.getPhone2()))%>
									<% if (!StringUtils.trimToEmpty(demoExt.get("wPhoneExt")).equals("")) {%>
									x<%=StringUtils.trimToEmpty(demoExt.get("wPhoneExt"))%><%}%></span></td><td>
                            <span class="tooltips" id="workPhoneHistory" title="origionalTitle" style="color:#0088cc;"><bean:message
							      key="global.history" /></span>
                        </td>
						</tr>
						<%}%>
						<% if (!StringUtils.trimToEmpty(demoExt.get("demo_cell")).equals("")) { // don't display cell if blank %>
						<tr><td style="white-space:nowrap;"><span class="labels"><bean:message
							      key="demographic.demographiceditdemographic.formPhoneC" />:</span>


                            </td>
							<td><span class="info"><%=Encode.forHtml(StringUtils.trimToEmpty(demoExt.get("demo_cell")))%></span></td>
                            <td><span class="tooltips" id="cellPhoneHistory" title="origionalTitle" style="color:#0088cc;"><bean:message
							      key="global.history" /></span>
                            </td>
						</tr>
						<%}%>
						<% if (!StringUtils.trimToEmpty(demoExt.get("phoneComment")).equals("")) { // don't display comment if blank %>
						<tr><td><span class="labels"><bean:message
							      key="demographic.demographicaddrecordhtm.formPhoneComment" />:</span></td>
							<td><span class="info"><%=Encode.forHtml(StringUtils.trimToEmpty(demoExt.get("phoneComment")))%></span></td></tr>
						<%}%>
						<% if ((!StringUtils.trimToEmpty(demographic.getAddress()).equals(""))
							|| (!StringUtils.trimToEmpty(demographic.getCity()).equals(""))
							|| (!StringUtils.trimToEmpty(demographic.getProvince()).equals(""))) { // if there is data in any primary address field, show the header %>
							<tr><td colspan="2"><i><u><bean:message
							      key="demographic.demographiceditdemographic.formAddr" /></u></i></td></tr>
						<%}%>
						<tr><td><span class="labels"><bean:message
							      key="demographic.demographiceditdemographic.formAddr" />:</td>
							<td><span class="info"><%=Encode.forHtml(StringUtils.trimToEmpty(demographic.getAddress()))%></span></td><td>
                                <span class="tooltips" id="addressHistory" title="origionalTitle" style="color:#0088cc;"><bean:message
							      key="global.history" /></span></span>
                            </td>
							</tr>
							<tr><td><span class="labels"><bean:message
								      key="demographic.demographiceditdemographic.formCity" />:</span></td>
							<td><span class="info"><%=Encode.forHtml(StringUtils.trimToEmpty(demographic.getCity()))%></span>
							</td></tr>
							<!-- Row for Province -->
<tr>
    <td style="white-space: nowrap;">
        <span class="labels">
            <% if (oscarProps.getProperty("demographicLabelProvince") == null) { %>
                <bean:message key="demographic.demographiceditdemographic.formProcvince" />
            <% } else { 
                out.print(oscarProps.getProperty("demographicLabelProvince")); 
            } %>:
        </span>
    </td>
    <td style="width: 100%;">
        <span class="info">
            <%
                // Fetch the full string (Province, Country)
                String provinceAndCountry = ISO36612.getInstance().translateCodeToHumanReadableString(demographic.getProvince());
                if (StringUtils.isNotEmpty(provinceAndCountry)) {
                    // Extract the province
                    String province = StringUtils.substringBefore(provinceAndCountry, ",");
                    out.print(StringUtils.trimToEmpty(province)); // Print only the province
                }
            %>
        </span>
    </td>
</tr>

<!-- Row for Country -->
<tr>
    <td style="white-space: nowrap;">
        <span class="labels">Country:</span>
    </td>
    <td style="width: 100%;">
        <span class="info">
            <%
                if (StringUtils.isNotEmpty(provinceAndCountry)) {
                    // Extract the country
                    String country = StringUtils.substringAfterLast(provinceAndCountry, ",");
                    out.print(StringUtils.trimToEmpty(country)); // Print only the country
                }
            %>
        </span>
    </td>
</tr>

							<tr><td>
							<span class="labels">
							<% if(oscarProps.getProperty("demographicLabelPostal") == null) { %>
							<bean:message
								key="demographic.demographiceditdemographic.formPostal" /> <% } else {
			                                  out.print(oscarProps.getProperty("demographicLabelPostal"));
							  } %>:</span></td>
								<td><span class="info"><%=StringUtils.trimToEmpty(demographic.getPostal())%></span></td></tr>

							 <% if ((!StringUtils.isBlank(demographic.getResidentialAddress()))
                                                        || (!StringUtils.isBlank(demographic.getResidentialCity()))
                                                        || (!StringUtils.isBlank(demographic.getResidentialProvince()))) { // if there is data in any primary address field, show the header %>
							<tr><td colspan="2"<i><u><bean:message
								      key="demographic.demographiceditdemographic.formResidentialAddr" /></i></u></td></tr>
                                                <%}%>
							<%
							if(!StringUtils.isBlank(demographic.getResidentialAddress())) {  %>
							<tr><td><span class="labels"><bean:message
								      key="demographic.demographiceditdemographic.formResidentialAddr" />:</span></td>
								<td><span class="info"><%=Encode.forHtml(demographic.getResidentialAddress())%></span></td>
							</tr>
							<%}%>
							<%
							if(!StringUtils.isBlank(demographic.getResidentialCity())) { %>
							<tr><td><span class="labels"><bean:message
								      key="demographic.demographiceditdemographic.formResidentialCity" />:</span></td>
								<td><span class="info"><%=Encode.forHtml(demographic.getResidentialCity())%></span></td>
                                                        </tr>
							<%}%>
							<% if (!StringUtils.isBlank(ISO36612.getInstance().translateCodeToHumanReadableString(demographic.getResidentialProvince()))) { %>
						    <tr><td><span class="labels">
									    <bean:message key="demographic.demographiceditdemographic.formResidentialProvince" />:</span></td>
							    <td><span class="info"><%=ISO36612.getInstance().translateCodeToHumanReadableString(demographic.getResidentialProvince())%></span></td>
						        </tr>
						        <%}%>
							<% if (!StringUtils.isBlank(demographic.getResidentialPostal())) { %>
						    <tr><td><span class="labels">
							<bean:message
								  key="demographic.demographiceditdemographic.formResidentialPostal" />:</span></td>
							    <td><span class="info"><%=StringUtils.trimToEmpty(demographic.getResidentialPostal())%></span></td>
							   </tr>
							 <%}%>
							 <% if (!StringUtils.isBlank(demographic.getEmail())) { // don't show email if empty blank or null%>
							   <tr><td><span class="labels"><bean:message
									 key="demographic.demographiceditdemographic.formEmail" />:</span></td>
                                <% if (demographic.getConsentToUseEmailForCare() != null && demographic.getConsentToUseEmailForCare()){ %>
	                            	<td><span class="info"><a href="mailto:<%=Encode.forHtmlAttribute(demographic.getEmail())%>?subject=Message from your Doctors Office" target="_blank" rel="noopener noreferrer" ><%=Encode.forHtml(demographic.getEmail())%></a></span></td>
                            	<% } else { %>
                            		<td><span class="info"><%=Encode.forHtml(demographic.getEmail())%></span></td>
                            	<% }  %>
							</tr>
							<%}%>
							<%
							if (demographic.getNewsletter()!=null && !demographic.getNewsletter().equals("Unknown")) {%>
							<tr><td><span class="labels"><bean:message
								      key="demographic.demographiceditdemographic.formNewsLetter" />:</span></td>
								<td><span class="info"><%=demographic.getNewsletter()%></span></td></tr>
						<%}%>
						</table>
						</div>
						<%if (!StringUtils.isBlank(demographic.getHin())) { %>
						<div class="demographicSection" id="healthInsurance">
						<h4>&nbsp;<bean:message key="demographic.demographiceditdemographic.msgHealthIns"/>
                        <i class="icon-edit" style="float: right;" title="<bean:message key="demographic.demographiceditdemographic.msgEdit"/>" onclick="showHideDetail();closeAccordion(); getElementById('insuranceSectionContent').style.height='auto';"></i></h4>
					        <table style="background-color: #FFFFFF; line-height: 1.2;">
							<% if (!StringUtils.isBlank(demographic.getHin())) { %>
							<tr><td style="white-space: nowrap;"><span class="labels"><bean:message
								      key="demographic.demographiceditdemographic.formHin" />:</span></td>
							<td style="width:100%"><span class="info" id="hinver" onclick="copyHIN2Clipboard(this.id)" ondblclick="copyHINver2Clipboard(this.id)"><%=Encode.forHtml(demographic.getHin())%>&nbsp;<%=StringUtils.trimToEmpty(demographic.getVer())%></span>
                                <% if (!StringUtils.isBlank(demographic.getVer())) { %>
                                <a class="btn btn-link" href="<%=hin_check_url%>healthNumber=<%=Encode.forUriComponent(demographic.getHin())%>&versionCode=<%=Encode.forUriComponent(demographic.getVer())%>" target=”_blank”><bean:message key="oscarReport.manageProvider.msgCheck"/></a>
							    <%}%>
                            </td>
							</tr>
							<tr><td style="white-space: nowrap;"><span class="labels"><bean:message
								      key="demographic.demographiceditdemographic.formHCType" />:</span></td>
							<td><span class="info"><%=demographic.getHcType()==null?"":demographic.getHcType() %></span></td>
							</tr>
							<%}%>
							<% if (!MyDateFormat.getMyStandardDate(demographic.getEffDate()).equals("")) { // don't show EFF date if blank %>
							<tr><td><span class="labels"><bean:message
								      key="demographic.demographiceditdemographic.formEFFDate" />:</span></td>
								<td><span class="info"><%=MyDateFormat.getMyStandardDate(demographic.getEffDate())%></span></td>
                                                    </tr>
						    <%}%>
						    <tr><td><span class="labels"><bean:message
								  key="demographic.demographiceditdemographic.formHCRenewDate" />:</span></td>
						    <td><span class="info"><%=MyDateFormat.getMyStandardDate(demographic.getHcRenewDate())%></span></td>
                                                    </tr>
						</table>
						</div>
						<%}%>

<%-- TOGGLE NEW CONTACTS UI --%>
<%if(!oscarProps.isPropertyActive("NEW_CONTACTS_UI")) { %>

						<div class="demographicSection" id="otherContacts">
						<h4>&nbsp;<bean:message key="demographic.demographiceditdemographic.msgOtherContacts"/>
<i class="icon-edit" style="float: right;" title="<bean:message key="demographic.demographiceditdemographic.msgEdit"/>" onClick="popup(700,960,'AddAlternateContact.jsp?demo=<%=demographic.getDemographicNo()%>','AddRelation')"></i></h4>
						<ul>
							<%DemographicRelationship demoRelation = new DemographicRelationship();
                                          List relList = demoRelation.getDemographicRelationshipsWithNamePhone(loggedInInfo, demographic.getDemographicNo().toString(), loggedInInfo.getCurrentFacility().getId());
                                          for (int reCounter = 0; reCounter < relList.size(); reCounter++){
                                             HashMap relHash = (HashMap) relList.get(reCounter);
                                             String dNo = (String)relHash.get("demographicNo");
                                             String workPhone = demographicManager.getDemographicWorkPhoneAndExtension(loggedInInfo, Integer.valueOf(dNo));


                                             String formattedWorkPhone = (workPhone != null && workPhone.length()>0 && !workPhone.equals("null") )?"  W:"+workPhone:"";
                                             String sdb = relHash.get("subDecisionMaker") == null?"":((Boolean) relHash.get("subDecisionMaker")).booleanValue()?"<span title=\"SDM\" >/SDM</span>":"";
                                             String ec = relHash.get("emergencyContact") == null?"":((Boolean) relHash.get("emergencyContact")).booleanValue()?"<span title=\"Emergency Contact\">/EC</span>":"";
											 String masterLink = "<a target=\"demographic"+dNo+"\" href=\"" + request.getContextPath() + "/demographic/demographiccontrol.jsp?demographic_no="+dNo+"&displaymode=edit&dboperation=search_detail\">M</a>";
											 String encounterLink = "<a target=\"encounter"+dNo+"\" href=\"javascript: function myFunction() {return false; }\" onClick=\"popup4(710,1024,'" + request.getContextPath() + "/oscarEncounter/IncomingEncounter.do?demographicNo="+dNo+"&providerNo="+loggedInInfo.getLoggedInProviderNo()+"&appointmentNo=&curProviderNo=&reason=&appointmentDate=&startTime=&status=&userName="+Encode.forUriComponent( userfirstname+" "+userlastname)+"&curDate="+curYear+"-"+curMonth+"-"+curDay+",\"E"+demographic_no+"\");return false;\">E</a>";
                                          %>
							<li><span class="label"><%= Encode.forHtmlContent((String)relHash.get("relation"))%><%=sdb%><%=ec%>:</span>
                            	<span class="info"><%=Encode.forHtml(relHash.get("lastName")+", "+relHash.get("firstName"))%>, H:<%=relHash.get("phone")== null?"":relHash.get("phone")%><%=formattedWorkPhone%> <%=masterLink%> <%=encounterLink %></span>
                            </li>
							<%}%>

						</ul>
						</div>

						<% } else { %>
						<jsp:include page="displayOtherContacts2.jsp">
						<jsp:param name="demographicNo" value="<%= demographic_no %>" />
						</jsp:include>

						<%
							ContactDao contactDao = (ContactDao)SpringUtils.getBean("contactDao");
							DemographicContactDao dContactDao = (DemographicContactDao)SpringUtils.getBean("demographicContactDao");
							List<DemographicContact> dContacts = dContactDao.findByDemographicNo(demographic.getDemographicNo());
							dContacts = ContactAction.fillContactNames(dContacts);
							for(DemographicContact dContact:dContacts) {
								String sdm = (dContact.getSdm()!=null && dContact.getSdm().equals("true"))?"<span title=\"SDM\" >/SDM</span>":"";
								String ec = (dContact.getEc()!=null && dContact.getEc().equals("true"))?"<span title=\"Emergency Contact\" >/EC</span>":"";
								String masterLink=null;
								if(DemographicContact.CATEGORY_PERSONAL.equals(dContact.getCategory()) && DemographicContact.TYPE_DEMOGRAPHIC == dContact.getType() ) {
									 masterLink = "<a target=\"demographic"+dContact.getContactId()+"\" href=\"" + request.getContextPath() + "/demographic/demographiccontrol.jsp?demographic_no="+dContact.getContactId()+"&displaymode=edit&dboperation=search_detail\">M</a>";
                                     masterLink = masterLink + "&nbsp;<a target=\"demographic"+dContact.getContactId()+"\" href=\"" + request.getContextPath() + "/oscarEncounter/IncomingEncounter.do?appointmentNo=&demographicNo="+dContact.getContactId()+"&curProviderNo=&reason=Tel-Progress+Note&encType=&appointmentDate=&startTime=&status=&curDate=\">E</a>";
								}
								if(DemographicContact.CATEGORY_PERSONAL.equals(dContact.getCategory()) && DemographicContact.TYPE_CONTACT == dContact.getType()) {
									masterLink = "<a target=\"_blank\" href=\""+ request.getContextPath() +"/demographic/Contact.do?method=viewContact&contact.id="+ dContact.getContactId() + "\">details</a>";
                                    masterLink = masterLink + "&nbsp;<a target=\"demographic"+dContact.getContactId()+"\" href=\"" + request.getContextPath() + "/oscarEncounter/IncomingEncounter.do?appointmentNo=&demographicNo="+dContact.getContactId()+"&curProviderNo=&reason=Tel-Progress+Note&encType=&appointmentDate=&startTime=&status=&curDate=\">E</a>";
								}
%>

						<%}   %>


						<% } %>
						<div class="demographicSection" id="clinicStatus">
						<h4>&nbsp;<bean:message key="demographic.demographiceditdemographic.msgClinicStatus"/><input type="button" class="btn btn-link"  onclick="popup(1000, 650, 'EnrollmentHistory.jsp?demographicNo=<%=demographic_no%>', 'enrollmentHistory'); return false;" value="<bean:message key="demographic.demographiceditdemographic.msgEnrollmentHistory"/>"><i class="icon-edit" style="float: right;" title="<bean:message key="demographic.demographiceditdemographic.msgEdit"/>" onclick="showHideDetail();closeAccordion(); getElementById('insuranceSectionContent').style.height='auto';"></i></h4>
						<table style="background-color: #FFFFFF; line-height: 1.2;">
						<% if (!StringUtils.isBlank(demographic.getRosterStatusDisplay())) { // don't show roster status if not set %>
							<tr>
                                                    <td  style="white-space:nowrap"><span class="labels"><bean:message
							      key="demographic.demographiceditdemographic.formRosterStatus" />:</span></td>
						    <td style="width:100%"><span class="info"><%=demographic.getRosterStatusDisplay()%></span></td></tr>
						<%}%>
                                                    <%if("RO".equals(demographic.getRosterStatus()) || "TE".equals(demographic.getRosterStatus())) { %>
						    <tr><td><span class="labels"><bean:message
								  key="demographic.demographiceditdemographic.DateJoined" />:</span></td>
							    <td style="width:100%"><span class="info"><%=MyDateFormat.getMyStandardDate(demographic.getRosterDate())%></span><td>
                                                    <% } %>
                                                    <%if("RO".equals(demographic.getRosterStatus())) { %>
						    <%if(demographic.getRosterEnrolledTo()!=null) { // don't show enrolled to if it is blank %>
						    <tr><td><span class="labels"><bean:message
								  key="demographic.demographiceditdemographic.RosterEnrolledTo" />:</span></td>
							    <td style="width:100%"><span class="info">
                                                        <%
                                                        String enrolledTo = "";
                                                       	Provider enrolledToProvider = providerDao.getProvider(demographic.getRosterEnrolledTo());
                                                       	if(enrolledToProvider != null) {
                                                       		enrolledTo = enrolledToProvider.getFormattedName();
                                                       	}
                                                        %>
                                                        <%=enrolledTo %>
								    </span></td></tr>
							<%}%>
                                                    <% } %>
                                                    <%if("TE".equals(demographic.getRosterStatus())) { %>
						    <tr><td><span class="labels"><bean:message
								  key="demographic.demographiceditdemographic.RosterTerminationDate" />:</span></td>
							    <td><span class="info"><%=MyDateFormat.getMyStandardDate(demographic.getRosterTerminationDate())%></span></td></tr>
<%if (null != demographic.getRosterTerminationDate()) { %>
<tr><td><span class="labels"><bean:message
	      key="demographic.demographiceditdemographic.RosterTerminationReason" />:</span></td>
	<td><span class="info"><%=Util.rosterTermReasonProperties.getReasonByCode(demographic.getRosterTerminationReason()) %></span>
	</td></tr>
<%} }%>

<tr><td><span class="labels"><bean:message
	      key="demographic.demographiceditdemographic.formPatientStatus" />:</span></td>
	<td style="width:100%"><span class="info">
							<%
							String PatStat = demographic.getPatientStatus();
							String Dead = "DE";
							String Inactive = "IN";

							if ( Dead.equals(PatStat) ) {%>
							<b style="color: #FF0000;"><%=demographic.getPatientStatus()%></b>
							<%} else if (Inactive.equals(PatStat) ){%>
							<b style="color: #0000FF;"><%=demographic.getPatientStatus()%></b>
							<%} else {%>
                                                            <%=demographic.getPatientStatus()%>
							<%}%>
                                                        </span>
				<%
                                String tmpDate="";
                                if(demographic.getPatientStatusDate ()!= null) {
                                        tmpDate = org.apache.commons.lang.time.DateFormatUtils.ISO_DATE_FORMAT.format(demographic.getPatientStatusDate());
                                }

				if (!tmpDate.equals("")) { // don't display if no date
				%>
				<tr><td style="white-space: nowrap"><span class="labels">

<bean:message key="demographic.demographiceditdemographic.PatientStatusDate" />:</span></td>
			<td><span class="labels">
								 <span class="info">
				<%=tmpDate%></span></span></td></tr>
				<%}%>
				<% if (!StringUtils.trimToEmpty(demographic.getChartNo()).equals("")) { // don't show chart number if not set %>
						    <tr><td><span class="labels"><bean:message
								  key="demographic.demographiceditdemographic.formChartNo" />:</span></td>
							    <td><span class="info"><%=StringUtils.trimToEmpty(demographic.getChartNo())%></span></td></tr>
				<%}%>
				<%
				if(OtherIdManager.getDemoOtherId(demographic_no, "meditech_id") != ""){ %>
						    <tr><td><span class="labels">Meditech ID:</span></td>
							    <td><span class="info"><%=OtherIdManager.getDemoOtherId(demographic_no, "meditech_id")%></span></td></tr>
				<%}%>
				<%
				if(!StringUtils.trimToEmpty(demoExt.get("cytolNum")).equals("")) { // don't show cytology if blank %>
						    <tr><td><span class="labels"><bean:message
								  key="demographic.demographiceditdemographic.cytolNum" />:</span></td>
							    <td><span class="info"><%=StringUtils.trimToEmpty(demoExt.get("cytolNum"))%></span></td></tr>
				<%}%>
						    <tr><td><span class="labels"><bean:message
								  key="demographic.demographiceditdemographic.formDateJoined1" />:</span></td>
							    <td><span class="info"><%=MyDateFormat.getMyStandardDate(demographic.getDateJoined())%></span></td></tr>
						    <%if (!MyDateFormat.getMyStandardDate(demographic.getEndDate()).equals("")) { // don't show end date if blank %>
						    <tr><td><span class="labels"><bean:message
								  key="demographic.demographiceditdemographic.formEndDate" />:</span></td>
							    <td><span class="info"><%=MyDateFormat.getMyStandardDate(demographic.getEndDate())%></span></td></tr> <%}%>
							<%if(!"true".equals(OscarProperties.getInstance().getProperty("phu.hide","false"))) { %>
							<% if (!StringUtils.trimToEmpty(demoExt.get("PHU")).equals("")) { // don't show PHU if blank %>
							<tr><td><span class="labels">
										<bean:message key="demographic.demographiceditdemographic.formPHU" />:</span></td>
								<%
									String phuName = null;
									String phu = demoExt.get("PHU");

									LookupListManager lookupListManager = SpringUtils.getBean(LookupListManager.class);
									ll = lookupListManager.findLookupListByName(LoggedInInfo.getLoggedInInfoFromSession(request), "phu");
									if(ll != null) {
										LookupListItem phuItem =  lookupListManager.findLookupListItemByLookupListIdAndValue(loggedInInfo, ll.getId(), phu);

										if(phuItem != null) {
											phuName = phuItem.getLabel();
										}
									}

								%>
								<td><span class="info"><%=StringUtils.trimToEmpty(phuName)%></span></td></tr>
							<%}} %>
						</table>
						</div>
						<%if (!alert.equals("")) { // don't show alert section if no alerts %>
						<div class="demographicSection" id="alert">
						<h4>&nbsp;<bean:message
							key="demographic.demographiceditdemographic.formAlert" />
                        <i class="icon-edit" style="float: right;" title="<bean:message key="demographic.demographiceditdemographic.msgEdit"/>" onclick="showHideDetail();closeAccordion();getElementById('additionalSectionContent').style.height='auto';"></i></h4>
						<table style="background: #FFFFFF;"><tr><td style="width:100%"><b style="color: brown;"><%=Encode.forHtmlContent(alert)%></b>
									&nbsp;</td><td></td></tr></table>
						</div>
						<%}%>
			     <%
			     String warningLevel = demoExt.get("rxInteractionWarningLevel");
		      	     if(warningLevel==null) warningLevel="0";
                             String warningLevelStr = "Not Specified";
                             if(warningLevel.equals("1")) {warningLevelStr="Low";}
                             if(warningLevel.equals("2")) {warningLevelStr="Medium";}
                             if(warningLevel.equals("3")) {warningLevelStr="High";}
                             if(warningLevel.equals("4")) {warningLevelStr="None";}

			     if (!warningLevelStr.equals("Not Specified")) { // don't show interaction warning level section if not set %>
						<div class="demographicSection" id="rxInteractionWarningLevel">
						<h4>&nbsp;<bean:message
							key="demographic.demographiceditdemographic.rxInteractionWarningLevel" /></h4>
						 <span class="labels"><bean:message key="demographic.demographiceditdemographic.rxInteractionWarningLevel"/>:</span>
                                                   <span class="info"><%=warningLevelStr%></span>
						</div>
				<%}%>
						<% if (!StringUtils.trimToEmpty(demoExt.get("paper_chart_archived")).equals("")){ // don't show paper chart section if archived blank %>
						<div class="demographicSection" id="paperChartIndicator">
						<h4>&nbsp;<bean:message
							key="demographic.demographiceditdemographic.paperChartIndicator" /></h4>
							<%
								String archived = demoExt.get("paper_chart_archived");
								String archivedStr = "", archivedDate = "", archivedProgram = "";
								if("YES".equals(archived)) {
									archivedStr="Yes";
								}
								if("NO".equals(archived)) {
									archivedStr="No";
								}
                      			if(demoExt.get("paper_chart_archived_date") != null) {
                      				archivedDate = demoExt.get("paper_chart_archived_date");
                      			}
                      			if(demoExt.get("paper_chart_archived_program") != null) {
                      				archivedProgram = demoExt.get("paper_chart_archived_program");
                      			}
							%>
							<table  style="background-color: #FFFFFF" colspan="2">
								<tr><td style="white-space:nowrap;"><span class="labels"><bean:message key="demographic.demographiceditdemographic.paperChartIndicator.archived"/>:</span></td>
									<span class="info"><td style="width:100%"><%=archivedStr %></td></span>
								</tr>
								<tr><td style="white-space: nowrap;"><span class="labels"><bean:message key="demographic.demographiceditdemographic.paperChartIndicator.dateArchived"/>:</span></td>
									<td><span class="info"><%=archivedDate %></span></td>
								</tr>
								<tr><td style="white-space: nowrap;"><span class="labels"><bean:message key="demographic.demographiceditdemographic.paperChartIndicator.programArchived"/>:</span></td>
									<td><span class="info"><%=archivedProgram %></span></td>
	                          </tr>
							</table>
						</div>
						<%}%>
<%-- TOGGLE PRIVACY CONSENTS --%>
<oscar:oscarPropertiesCheck property="privateConsentEnabled" value="true">

		<div class="demographicSection" id="consent">
				<h4>&nbsp;<bean:message key="demographic.demographiceditdemographic.consent" /></h4>

					<ul>

					<%
						String[] privateConsentPrograms = oscarProps.getProperty("privateConsentPrograms","").split(",");
						ProgramProvider pp = programManager2.getCurrentProgramInDomain(loggedInInfo,loggedInInfo.getLoggedInProviderNo());

						if(pp != null) {
							for(int x=0;x<privateConsentPrograms.length;x++) {
								if(privateConsentPrograms[x].equals(pp.getProgramId().toString())) {
									showConsentsThisTime=true;
								}
							}
						}

					if(showConsentsThisTime) { %>

			  <li><span class="labels"><bean:message key="demographic.demographiceditdemographic.privacyConsent"/>:</span>
			      <span class="info"><%=privacyConsent %></span>
			  </li>
			  <li><span class="labels"><bean:message key="demographic.demographiceditdemographic.informedConsent"/>:</span>
			      <span class="info"><%=informedConsent %></span>
			  </li>
			  <li><span class="labels"><bean:message key="demographic.demographiceditdemographic.usConsent"/>:</span>
			      <span class="info"><%=usSigned %></span>
			  </li>


					<% } %>

<%-- ENABLE THE NEW PATIENT CONSENT MODULE --%>
<oscar:oscarPropertiesCheck property="USE_NEW_PATIENT_CONSENT_MODULE" value="true" >

				<c:forEach items="${ patientConsents }" var="patientConsent" >
					<c:if test="${ not empty patientConsent.optout}">
				<li>
						<c:if test="${ patientConsent.consentType.active }">
					<span class="tooltips label" title="${ patientConsent.consentType.description }" >
									<c:out value="${ patientConsent.consentType.name }" />
								</span>

					<c:choose>
									<c:when test="${ patientConsent.optout }">
										<span class="info" style="color:red;"> Opted Out:<c:out value="${ patientConsent.optoutDate }" /></span>
									</c:when>

									<c:otherwise>
										<span class="info" style="color:green;">Consented:<c:out value="${ patientConsent.consentDate }" /></span>
									</c:otherwise>
								</c:choose>

						</c:if>
				</li>
					</c:if>
				</c:forEach>
</oscar:oscarPropertiesCheck>
<%-- END ENABLE NEW PATIENT CONSENT MODULE --%>

		       </ul>
					</div>

</oscar:oscarPropertiesCheck>
<%-- END TOGGLE ALL PRIVACY CONSENTS --%>

					</div>
					
<%-- TOGGLE WORKFLOW_ENHANCE - SHOWS PATIENTS INTERNAL PROVIDERS AND RELATED SCHEDULE AVAIL --%>

<oscar:oscarPropertiesCheck value="true" property="workflow_enhance">
						<div class="demographicSection">
                        <h4>&nbsp;<bean:message key="demographic.demographiceditdemographic.msgInternalProviders"/><i class="icon-edit" style="float: right;" title="<bean:message key="demographic.demographiceditdemographic.msgEdit"/>" onclick="showHideDetail();closeAccordion(); getElementById('teamSectionContent').style.height='auto';"></i></h4>
                        <div>

			<%!	// ===== functions for quick appointment booking =====

				// convert hh:nn:ss format to elapsed minutes (from 00:00:00)
				int timeStrToMins (String timeStr) {
					String[] temp = timeStr.split(":");
					return Integer.parseInt(temp[0])*60+Integer.parseInt(temp[1]);
				}
			%>

			<%	// ===== quick appointment booking =====
				// database access object, data objects for looking things up


                DateFormatSymbols symbols = new DateFormatSymbols(Locale.getDefault());
                // OK its three letters, but its local to the current value of the default locale of this JVM
                String[] twoLetterDate = symbols.getShortWeekdays();

				//String[] twoLetterDate = {"", "Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"};

				// build templateMap, which maps template codes to their associated duration
				Map<String, String> templateMap = new HashMap<String, String>();
				for(ScheduleTemplateCode stc : scheduleTemplateCodeDao.findTemplateCodes()) {
					templateMap.put(String.valueOf(stc.getCode()),stc.getDuration());
				}


				// build list of providers associated with this patient
				Map<String, Map<String, Map<String,String>>> provMap = new HashMap<String, Map<String, Map<String,String>>>();
				if (demographic != null) {
					provMap.put("doctor", new HashMap<String, Map<String,String>>());
					provMap.get("doctor").put("prov_no", new HashMap<String, String>());
					provMap.get("doctor").get("prov_no").put("no", demographic.getProviderNo());
				}
				if (StringUtils.isNotEmpty(providerBean.getProperty(resident,""))) {
					provMap.put("prov1", new HashMap<String, Map<String,String>>());
					provMap.get("prov1").put("prov_no", new HashMap<String, String>());
					provMap.get("prov1").get("prov_no").put("no", resident);
				}
				if (StringUtils.isNotEmpty(providerBean.getProperty(midwife,""))) {
					provMap.put("prov2", new HashMap<String, Map<String,String>>());
					provMap.get("prov2").put("prov_no", new HashMap<String, String>());
					provMap.get("prov2").get("prov_no").put("no", midwife);
				}
				if (StringUtils.isNotEmpty(providerBean.getProperty(nurse,""))) {
					provMap.put("prov3", new HashMap<String, Map<String,String>>());
					provMap.get("prov3").put("prov_no", new HashMap<String, String>());
					provMap.get("prov3").get("prov_no").put("no", nurse);
				}

				// precompute all data for the providers associated with this patient
				for (String thisProv : provMap.keySet()) {

					String thisProvNo = provMap.get(thisProv).get("prov_no").get("no");

					// starting tomorrow, look for available appointment slots
					Calendar qApptCal = new GregorianCalendar();
					qApptCal.add(Calendar.DATE, 1);
					int numDays = 0;
					int maxLookahead = 90;

					while ((numDays < 5) && (maxLookahead > 0)) {
						int qApptYear = qApptCal.get(Calendar.YEAR);
						int qApptMonth = (qApptCal.get(Calendar.MONTH)+1);
						int qApptDay = qApptCal.get(Calendar.DAY_OF_MONTH);
						String qApptWkDay = twoLetterDate[qApptCal.get(Calendar.DAY_OF_WEEK)];
                        String qCurDate = qApptYear+"-"+qApptMonth+"-"+qApptDay;

						// get timecode string template associated with this day, number of minutes each slot represents
						ScheduleTemplateDao dao = SpringUtils.getBean(ScheduleTemplateDao.class);
						List<Object> timecodeResult = dao.findTimeCodeByProviderNo2(thisProvNo, ConversionUtils.fromDateString(qCurDate));

						// if theres a template on this day, continue
                        if (!timecodeResult.isEmpty()) {

                       	String timecode = StringUtils.trimToEmpty(String.valueOf(timecodeResult.get(0)));

                  	    int timecodeInterval = 1440/timecode.length();

						// build schedArr, which has 1s where template slots are
                   		int[] schedArr = new int[timecode.length()];
                   		String schedChar;
                   		for (int i=0; i<timecode.length(); i++) {
                           		schedChar = ""+timecode.charAt(i);
                           		if (!schedChar.equals("_")) {
									if (templateMap.get(""+timecode.charAt(i)) != null) {
                                     	schedArr[i] = 1;
									}
                           		}
                   		}

						// get list of appointments on this day
						int start_index, end_index;
						OscarAppointmentDao apptDao = SpringUtils.getBean(OscarAppointmentDao.class);
						// put 0s in schedArr where appointments are
						for(Appointment appt : apptDao.findByProviderAndDayandNotStatuses(thisProvNo, ConversionUtils.fromDateString(qCurDate), new String[] {"N", "C"})) {
							start_index = timeStrToMins(StringUtils.trimToEmpty(ConversionUtils.toTimeString(appt.getStartTime())))/timecodeInterval;
							end_index = timeStrToMins(StringUtils.trimToEmpty(ConversionUtils.toTimeString(appt.getEndTime())))/timecodeInterval;

							// very late appts may push us past the time range we care about
							// trying to invalidate these times will lead to a ArrayIndexOutOfBoundsException
							// fix this so we stay within the bounds of schedArr
							if (end_index > (timecode.length()-1)) {
								end_index = timecode.length()-1;
							}

							// protect against the dual case as well
							if (start_index < 0) {
								start_index = 0;
							}

							// handle appts of duration longer than template interval
							for (int i=start_index; i<=end_index; i++) {
								schedArr[i] = 0;
							}
						}

						// list slots that can act as start times for appointments of template specified length
						boolean enoughRoom;
						boolean validDay = false;
						int templateDuration, startHour, startMin;
						String startTimeStr, endTimeStr, sortDateStr;
						String timecodeChar;
						for (int i=0; i<timecode.length(); i++) {
							if (schedArr[i] == 1) {
								enoughRoom = true;
								timecodeChar = ""+timecode.charAt(i);
								templateDuration = Integer.parseInt(templateMap.get(timecodeChar));
								for (int n=0; n<templateDuration/timecodeInterval; n++) {
									if (((i+n) < (schedArr.length-1)) && (schedArr[i+n] != 1)) {
										enoughRoom=false;
									}
								}
enoughRoom=true;
								if (enoughRoom) {
									validDay = true;
									sortDateStr = qApptYear+"-"+String.format("%02d",qApptMonth)+"-"+String.format("%02d",qApptDay);
									if (!provMap.get(thisProv).containsKey(sortDateStr+","+qApptWkDay+" "+qApptMonth+"-"+qApptDay)) {
										provMap.get(thisProv).put(sortDateStr+","+qApptWkDay+" "+qApptMonth+"-"+qApptDay, new HashMap<String, String>());
									}
									startHour = i*timecodeInterval / 60;
									startMin = i*timecodeInterval % 60;
									startTimeStr = String.format("%02d",startHour)+":"+String.format("%02d",startMin);
									endTimeStr = String.format("%02d",startHour)+":"+String.format("%02d",startMin+timecodeInterval-1);

									provMap.get(thisProv).get(sortDateStr+","+qApptWkDay+" "+qApptMonth+"-"+qApptDay).put(startTimeStr+","+timecodeChar+","+templateDuration, request.getContextPath() +  "/appointment/addappointment.jsp?demographic_no="+demographic.getDemographicNo()+"&name="+Encode.forUriComponent(demographic.getLastName()+","+demographic.getFirstName())+"&provider_no="+thisProvNo+"&bFirstDisp=true&year="+qApptYear+"&month="+qApptMonth+"&day="+qApptDay+"&start_time="+startTimeStr+"&end_time="+endTimeStr+"&duration="+templateDuration+"&search=true");
								}
							}
						}

						if (validDay) {
							numDays++;
						}
						}

						// look at the next day
						qApptCal.add(Calendar.DATE, 1);
						maxLookahead--;
					}
				}
			%>
			<table>
                            <% if (demographic.getProviderNo()!=null) { %>
					<tr><td>
<% if(oscarProps.getProperty("demographicLabelDoctor") != null) { out.print(oscarProps.getProperty("demographicLabelDoctor","")); } else { %>
                            <bean:message
						key="demographic.demographiceditdemographic.formMRP" /><%}%>:</td>
<td style="width:100%"><b><%=providerBean.getProperty(demographic.getProviderNo(),"")%></b></td></tr>
                        <% // ===== quick appointment booking for doctor =====
                        if (provMap.get("doctor") != null) {
			%><tr><td colspan="2" style="text-align: center;"><%
				boolean firstBar = true;
                                ArrayList<String> sortedDays = new ArrayList(provMap.get("doctor").keySet());
                                Collections.sort(sortedDays);
                                for (String thisDate : sortedDays) {
                                        if (!thisDate.equals("prov_no")) {
                                                if (!firstBar) {%>|<%}; firstBar = false;
	                                        String[] thisDateArr = thisDate.split(",");
						String thisDispDate = thisDateArr[1];
						%>
                                                <a style="text-decoration: none;" href="#" onclick="return !showAppt('_doctor_<%=thisDateArr[0]%>', event);"><b><%=thisDispDate%></b></a>
                                                <div id='menu_doctor_<%=thisDateArr[0]%>' class='menu' onclick='event.cancelBubble = true;' >
                                                <h4 style='text-align: center; color: black;'> <bean:message
                key="schedule.scheduledatepopup.formAvailable" />&nbsp;<bean:message
                key="report.reportdaysheet.msgAppointmentTime" />&nbsp;<br>
(<%=thisDispDate%>)</h4>
						<ul>
                                                <%
                                                ArrayList<String> sortedTimes = new ArrayList(provMap.get("doctor").get(thisDate).keySet());
                                                Collections.sort(sortedTimes);
                                                for (String thisTime : sortedTimes) {
							String[] thisTimeArr = thisTime.split(",");
                                                        %><li style="color:black;">[<%=thisTimeArr[1]%>] <%=thisTimeArr[2]%> <bean:message
                key="provider.preference.min" /> <a style='color: #0088cc;' href="#" onClick="popupPage(600,843,'<%=provMap.get("doctor").get(thisDate).get(thisTime) %>');return false;"><%= thisTimeArr[0] %></a></li><%
                                                }
                                                %></ul></div><%                                        }
                                }
                        }
			%></td></tr>
                            <% } if (StringUtils.isNotEmpty(providerBean.getProperty(resident,""))) { %>
			    <tr><td>Resident:</td><td><b><%=providerBean.getProperty(resident,"")%></b></td></tr>
                        <% // ===== quick appointment booking for prov1 =====
                        if (provMap.get("prov1") != null) {
			%><tr><td colspan="2" style="text-align: center;"><%
				boolean firstBar = true;
                                ArrayList<String> sortedDays = new ArrayList(provMap.get("prov1").keySet());
                                Collections.sort(sortedDays);
                                for (String thisDate : sortedDays) {
                                        if (!thisDate.equals("prov_no")) {
                                                if (!firstBar) {%>|<%}; firstBar = false;
	                                        String[] thisDateArr = thisDate.split(",");
						String thisDispDate = thisDateArr[1];
						%>
                                                <a style="text-decoration: none;" href="#" onclick="return !showAppt('_prov1_<%=thisDateArr[0]%>', event);"><b><%=thisDispDate%></b></a>
                                                <div id='menu_prov1_<%=thisDateArr[0]%>' class='menu' onclick='event.cancelBubble = true;'>
                                                <h4 style='text-align: center; color: black;'> <bean:message
                key="schedule.scheduledatepopup.formAvailable" />&nbsp;<bean:message
                key="report.reportdaysheet.msgAppointmentTime" />&nbsp;<br>
(<%=thisDispDate%>)</h4>
                                                <ul>
                                                <%
                                                ArrayList<String> sortedTimes = new ArrayList(provMap.get("prov1").get(thisDate).keySet());
                                                Collections.sort(sortedTimes);
                                                for (String thisTime : sortedTimes) {
							String[] thisTimeArr = thisTime.split(",");
                                                        %><li style="color:black;">[<%=thisTimeArr[1]%>] <%=thisTimeArr[2]%> <bean:message
                key="provider.preference.min" />  <a style='color: #0088cc;'  href="#" onClick="popupPage(600,843,'<%=provMap.get("prov1").get(thisDate).get(thisTime) %>');return false;"><%= thisTimeArr[0] %></a></li><%
                                                }
                                                %></ul></div><%
                                        }
                                }
                        }
			%></td></tr>
                            <% } if (StringUtils.isNotEmpty(providerBean.getProperty(midwife,""))) { %>
			    <tr><td>Midwife:</td><td><b><%=providerBean.getProperty(midwife,"")%></b></td>
                        <% // ===== quick appointment booking for prov2 =====
                        if (provMap.get("prov2") != null) {
			%><tr><td colspan="2" style="text-align: center;"><%
							boolean firstBar = true;
                            	ArrayList<String> sortedDays = new ArrayList(provMap.get("prov2").keySet());
                            	Collections.sort(sortedDays);
                            	   for (String thisDate : sortedDays) {
                                        if (!thisDate.equals("prov_no")) {
                                                if (!firstBar) {%>|<%}; firstBar = false;
	                                        String[] thisDateArr = thisDate.split(",");
						String thisDispDate = thisDateArr[1];
						%>
                                                <a style="text-decoration: none;" href="#" onclick="return !showAppt('_prov2_<%=thisDateArr[0]%>', event);"><b><%=thisDispDate%></b></a>
                                                <div id='menu_prov2_<%=thisDateArr[0]%>' class='menu' onclick='event.cancelBubble = true;'>
                                                <h4 style='text-align: center; color: black;'> <bean:message
                key="schedule.scheduledatepopup.formAvailable" />&nbsp;<bean:message
                key="report.reportdaysheet.msgAppointmentTime" />&nbsp;<br>
(<%=thisDispDate%>)</h4>
                                                <ul>
                                                <%
                                                ArrayList<String> sortedTimes = new ArrayList(provMap.get("prov2").get(thisDate).keySet());
                                                Collections.sort(sortedTimes);
                                                for (String thisTime : sortedTimes) {
							String[] thisTimeArr = thisTime.split(",");
                                                        %><li style="color:black;">[<%=thisTimeArr[1]%>] <%=thisTimeArr[2]%> <bean:message
                key="provider.preference.min" /> <a style='color: #0088cc;'  href="#" onClick="popupPage(600,843,'<%=provMap.get("prov2").get(thisDate).get(thisTime) %>');return false;"><%= thisTimeArr[0] %></a></li><%
                                                }
                                                %></ul></div><%
                                        }
                                }
                        }
			%></td></tr>
                            <% } if (StringUtils.isNotEmpty(providerBean.getProperty(nurse,""))) { %>
			    <tr><td><bean:message key="demographic.demographiceditdemographic.formNurse" />:</td><td><b><%=providerBean.getProperty(nurse,"")%></b></td></tr>
                        <% // ===== quick appointment booking for prov3 =====
                        if (provMap.get("prov3") != null) {
			%><tr><td colspan="2" style="text-align: center;"><%
							boolean firstBar = true;
                                ArrayList<String> sortedDays = new ArrayList(provMap.get("prov3").keySet());
                                Collections.sort(sortedDays);
                                for (String thisDate : sortedDays) {
                                        if (!thisDate.equals("prov_no")) {
                                                if (!firstBar) {%>|<%}; firstBar = false;
	                                        String[] thisDateArr = thisDate.split(",");
						String thisDispDate = thisDateArr[1];
						%>
                                                <a style="text-decoration: none;" href="#" onclick="return !showAppt('_prov3_<%=thisDateArr[0]%>', event);"><b><%=thisDispDate%></b></a>
                                                <div id='menu_prov3_<%=thisDateArr[0]%>' class='menu' onclick='event.cancelBubble = true;'>
                                                <h4 style='text-align: center; color: black;'> <bean:message
                key="schedule.scheduledatepopup.formAvailable" />&nbsp;<bean:message
                key="report.reportdaysheet.msgAppointmentTime" />&nbsp;<br>
(<%=thisDispDate%>)</h4>
                                                <ul>
                                                <%
                                                ArrayList<String> sortedTimes = new ArrayList(provMap.get("prov3").get(thisDate).keySet());
                                                Collections.sort(sortedTimes);
                                                for (String thisTime : sortedTimes) {
							String[] thisTimeArr = thisTime.split(",");
                                                        %><li style="color:black;">[<%=thisTimeArr[1]%>] <%=thisTimeArr[2]%> <bean:message
                key="provider.preference.min" /> <a style='color: #0088cc;'  href="#" onClick="popupPage(600,843,'<%=provMap.get("prov3").get(thisDate).get(thisTime) %>');return false;"><%= thisTimeArr[0] %></a></li><%
                                                }
                                                %></ul></div><%
                                        }
                                }
                        }
			%></td></tr>
                            <% } %>
<%

// Link to providers from Contacts adapted from original code by DENNIS WARREN O/A COLCAMEX RESOURCES --
ContactSpecialtyDao specialtyDao = null;

	List<DemographicContact> demographicContacts = null;
        List<ContactSpecialty> specialty = null;
        boolean linkedHealthCareTeam = oscarProps.getProperty("NEW_CONTACTS_UI_HEALTH_CARE_TEAM_LINKED", "true").equals("true");
demographicContacts = linkedHealthCareTeam ? ContactAction.getDemographicContacts(demographic, "professional") : ContactAction.getDemographicContacts(demographic, "professional", true);
                specialtyDao = SpringUtils.getBean(ContactSpecialtyDao.class);
                specialty = specialtyDao.findAll();
        	pageContext.setAttribute("demographicContacts", demographicContacts);
        	pageContext.setAttribute("specialty", specialty);
%>
                <c:forEach items="${ demographicContacts }" var="dContact" varStatus="row">
			<tr><td>
                        <c:set value="internal" var="internal" scope="page" />
                        <c:set value="${ dContact.details.workPhone }" var="workPhone" scope="page" />
                        <c:set value="even" var="rowclass" scope="page" />
                        <c:if test="${ row.index mod 2 ne 0 }" >
                                <c:set value="odd" var="rowclass" scope="page" />
                        </c:if>
			<c:out value="${ dContact.role }" />:</td><td>
			<b><c:out value="${ dContact.contactName }" /></b></td>
                </c:forEach>
	</td></tr>
	<% if (!StringUtils.trimToEmpty(rd).equals("")) { // don't show referral doctor if blank %>
        <tr>
		<td style="white-space: nowrap;"><span class="labels">
			<bean:message key="demographic.demographiceditdemographic.formRefDoc" />:</span>
		</td>
                <td>
			<span class="info"><%=rd%></span>
		</td>
        </tr>
	<%}%>
	<% if (!StringUtils.trimToEmpty(rdohip).equals("")) { // don't show doctor number if blank %>
        <tr><td style="white-space: nowrap;"><span class="labels"><bean:message
        key="demographic.demographiceditdemographic.formRefDocNo" />:</span></td>
        <td><span class="info"><%=rdohip%></span></td>
        </tr>
	<%}%>

			 </table>
                         </div>
                         </div>

						<%--} --%>
</oscar:oscarPropertiesCheck>
<%-- END TOGGLE WORKFLOW_ENHANCE --%>



						<div class="demographicSection" id="notes">
						<h4>&nbsp;<bean:message
							key="demographic.demographiceditdemographic.formNotes" />
                        <input type="button" class="btn btn-link" onclick="popupOscarRx(800, 1000,'demographicAudit.jsp?demographic_no=<%=demographic_no %>');"
                        value="<bean:message key="admin.admin.securityLogReport" />">
                        <i class="icon-edit" style="float: right;" title="<bean:message key="demographic.demographiceditdemographic.msgEdit"/>" onclick="showHideDetail();closeAccordion(); getElementById('additionalSectionContent').style.height='auto';"></i></h4>

						<table style="background-color: #FFFFFF; line-height: 1.2;"><tr><td style="width:100%"><%=Encode.forHtmlContent(notes)%>&nbsp;
<%if (hasImportExtra) { %>
		                <a href="javascript:void(0);" title="Extra data from Import" onclick="popupOscarRx(250, 400,'<%= request.getContextPath() %>/annotation/importExtra.jsp?display=<%=annotation_display %>&amp;table_id=<%=demographic_no %>&amp;demo=<%=demographic_no %>',false);">
		                    <img src="<%= request.getContextPath() %>/images/notes.gif" align="right" alt="Extra data from Import" height="16" width="13" border="0"> </a>
				<%} %><td></td></tr></table>





						</div>

<%-- TOGGLED OFF PROGRAM ADMISSIONS --%>
<oscar:oscarPropertiesCheck property="DEMOGRAPHIC_PROGRAM_ADMISSIONS" value="true">
						<div class="demographicSection" id="programs">
						<h4>&nbsp;Programs</h4>
						<ul>
                         <li><span class="labels">Bed:</span><span class="info"><%=bedAdmission != null?bedAdmission.getProgramName():"N/A" %></span></li>
                         <%
                         for(Admission adm:serviceAdmissions) {
                        	 %>
                        		 <li><span class="labels">Service:</span><span class="info"><%=adm.getProgramName()%></span></li>

                        	 <%
                         }
                         %>
						</ul>

						</div>
</oscar:oscarPropertiesCheck>
<%-- TOGGLED OFF PROGRAM ADMISSIONS --%>


						</div>
						</div>

						<% // customized key + "Has Primary Care Physician" & "Employment Status"
						String[] propDemoExt = {};
						String hasPrimaryCarePhysician = "N/A";
						String employmentStatus = "N/A";

						final String hasPrimary = "Has Primary Care Physician";
						final String empStatus = "Employment Status";
						boolean hasDemoExt=false, hasHasPrimary=false, hasEmpStatus=false;

						String demographicExt = oscarProps.getProperty("demographicExt");
						if (demographicExt!=null && !demographicExt.trim().isEmpty()) {
							hasDemoExt = true;
							propDemoExt = demographicExt.split("\\|");
						}
						if (oscarProps.isPropertyActive("showPrimaryCarePhysicianCheck")) {
							hasHasPrimary = true;
							String key = hasPrimary.replace(" ", "");
							if (demoExt.get(key)!=null && !demoExt.get(key).trim().isEmpty())
								hasPrimaryCarePhysician = demoExt.get(key);
						}
						if (oscarProps.isPropertyActive("showEmploymentStatus")) {
							hasEmpStatus = true;
							String key = empStatus.replace(" ", "");
							if (demoExt.get(key)!=null && !demoExt.get(key).trim().isEmpty())
								employmentStatus = demoExt.get(key);
						}

						if (hasDemoExt || hasHasPrimary || hasEmpStatus) {
						%>	<div class="demographicSection" id="special">
								<h4>&nbsp;Special</h4>
						<%	for(int k=0; k<propDemoExt.length; k++) {
						%>		<%=propDemoExt[k]+": <b>" + StringUtils.trimToEmpty(demoExt.get(propDemoExt[k].replace(' ', '_'))) +"</b>"%>
								&nbsp;<%=((k+1)%4==0&&(k+1)<propDemoExt.length)?"<br>":""%>
						<%	}
							if (hasHasPrimary) {
						%>		<%=hasPrimary%>: <b><%=hasPrimaryCarePhysician%></b>
						<%	}
							if (hasEmpStatus) {
						%>		<%=empStatus%>: <b><%=employmentStatus%></b>
						<%	}
						%>
							</div>
						<%} %>
						</div>

						<!--newEnd-->


<!-- security code block -->
<span id="topupdateButtons" class="span" style="display: none;">
    <security:oscarSec roleName="<%=roleName$%>" objectName="_demographic" rights="w">
    <%
        boolean showCbiReminder=oscarProps.getBooleanProperty("CBI_REMIND_ON_UPDATE_DEMOGRAPHIC", "true");
    %>

	</security:oscarSec>
</span>
<p><p>
<!-- security code block -->



<div class="container-fluid well form-horizontal span12" id="editWrapper" style="display:none;" >
    <div  id="demographicSection" class="span11">
		 <h3><bean:message key="demographic.demographiceditdemographic.msgDemographic" /></h3>
        <div id="demographicSectionContent">
		<div class="control-group">
            <label class="control-label" for="selectTitle"><bean:message key="demographic.demographiceditdemographic.msgDemoTitle"/></label>
            <div class="controls">
              					<%
						String title = demographic.getTitle();
						if(title == null) {
							title="";
						}
					%>
								<select name="title" id="selectTitle" <%=getDisabled("title")%>>
									<option value="" <%=title.equals("")?"selected":""%> ><bean:message key="demographic.demographiceditdemographic.msgNotSet"/></option>
									<option value="DR" <%=title.equalsIgnoreCase("DR")?"selected":""%> ><bean:message key="demographic.demographicaddrecordhtm.msgDr"/></option>
								    <option value="MS" <%=title.equalsIgnoreCase("MS")?"selected":""%> ><bean:message key="demographic.demographiceditdemographic.msgMs"/></option>
								    <option value="MISS" <%=title.equalsIgnoreCase("MISS")?"selected":""%> ><bean:message key="demographic.demographiceditdemographic.msgMiss"/></option>
								    <option value="MRS" <%=title.equalsIgnoreCase("MRS")?"selected":""%> ><bean:message key="demographic.demographiceditdemographic.msgMrs"/></option>
								    <option value="MR" <%=title.equalsIgnoreCase("MR")?"selected":""%> ><bean:message key="demographic.demographiceditdemographic.msgMr"/></option>
								    <option value="MSSR" <%=title.equalsIgnoreCase("MSSR")?"selected":""%> ><bean:message key="demographic.demographiceditdemographic.msgMssr"/></option>
								    <option value="PROF" <%=title.equalsIgnoreCase("PROF")?"selected":""%> ><bean:message key="demographic.demographiceditdemographic.msgProf"/></option>
								    <option value="REEVE" <%=title.equalsIgnoreCase("REEVE")?"selected":""%> ><bean:message key="demographic.demographiceditdemographic.msgReeve"/></option>
								    <option value="REV" <%=title.equalsIgnoreCase("REV")?"selected":""%> ><bean:message key="demographic.demographiceditdemographic.msgRev"/></option>
								    <option value="RT_HON" <%=title.equalsIgnoreCase("RT_HON")?"selected":""%> ><bean:message key="demographic.demographiceditdemographic.msgRtHon"/></option>
								    <option value="SEN" <%=title.equalsIgnoreCase("SEN")?"selected":""%> ><bean:message key="demographic.demographiceditdemographic.msgSen"/></option>
								    <option value="SGT" <%=title.equalsIgnoreCase("SGT")?"selected":""%> ><bean:message key="demographic.demographiceditdemographic.msgSgt"/></option>
								    <option value="SR" <%=title.equalsIgnoreCase("SR")?"selected":""%> ><bean:message key="demographic.demographiceditdemographic.msgSr"/></option>

								    <option value="MADAM" <%=title.equalsIgnoreCase("MADAM")?"selected":""%> ><bean:message key="demographic.demographiceditdemographic.msgMadam"/></option>
								    <option value="MME" <%=title.equalsIgnoreCase("MME")?"selected":""%> ><bean:message key="demographic.demographiceditdemographic.msgMme"/></option>
								    <option value="MLLE" <%=title.equalsIgnoreCase("MLLE")?"selected":""%> ><bean:message key="demographic.demographiceditdemographic.msgMlle"/></option>
								    <option value="MAJOR" <%=title.equalsIgnoreCase("MAJOR")?"selected":""%> ><bean:message key="demographic.demographiceditdemographic.msgMajor"/></option>
								    <option value="MAYOR" <%=title.equalsIgnoreCase("MAYOR")?"selected":""%> ><bean:message key="demographic.demographiceditdemographic.msgMayor"/></option>

								    <option value="BRO" <%=title.equalsIgnoreCase("BRO")?"selected":""%> ><bean:message key="demographic.demographiceditdemographic.msgBro"/></option>
								    <option value="CAPT" <%=title.equalsIgnoreCase("CAPT")?"selected":""%> ><bean:message key="demographic.demographiceditdemographic.msgCapt"/></option>
								    <option value="CHIEF" <%=title.equalsIgnoreCase("CHIEF")?"selected":""%> ><bean:message key="demographic.demographiceditdemographic.msgChief"/></option>
								    <option value="CST" <%=title.equalsIgnoreCase("CST")?"selected":""%> ><bean:message key="demographic.demographiceditdemographic.msgCst"/></option>
								    <option value="CORP" <%=title.equalsIgnoreCase("CORP")?"selected":""%> ><bean:message key="demographic.demographiceditdemographic.msgCorp"/></option>
								    <option value="FR" <%=title.equalsIgnoreCase("FR")?"selected":""%> ><bean:message key="demographic.demographiceditdemographic.msgFr"/></option>
								    <option value="HON" <%=title.equalsIgnoreCase("HON")?"selected":""%> ><bean:message key="demographic.demographiceditdemographic.msgHon"/></option>
								    <option value="LT" <%=title.equalsIgnoreCase("LT")?"selected":""%> ><bean:message key="demographic.demographiceditdemographic.msgLt"/></option>

								</select>
            </div>
        </div>
        <div class="control-group"  title='<%=demographic.getDemographicNo()%>'>
            <label class="control-label" for="inputLN"><bean:message
                key="demographic.demographiceditdemographic.formLastName" /><span style="color:red">*</span></label>
            <div class="controls">
              <input type="text" id="inputLN" placeholder="<bean:message key="demographic.demographiceditdemographic.formLastName" />"
                    name="last_name" <%=getDisabled("last_name")%>
					value="<%=StringEscapeUtils.escapeHtml(demographic.getLastName())%>"
					onBlur="upCaseCtrl(this)">
            </div>
        </div>
		<div class="control-group">
            <label class="control-label" for="inputMN"><bean:message
					key="demographic.demographiceditdemographic.formMiddleNames" /></label>
            <div class="controls">
              <input type="text" id="inputMN" name="middleNames" placeholder="<bean:message
					key="demographic.demographiceditdemographic.formMiddleNames" />"
					value="<%=StringEscapeUtils.escapeHtml(demographic.getMiddleNames())%>"
					onBlur="upCaseCtrl(this)">
            </div>
        </div>
        <div class="control-group">
            <label class="control-label" for="inputFN"><bean:message key="demographic.demographiceditdemographic.formFirstName" /><span style="color:red">*</span></label>
            <div class="controls">
              <input type="text" id="inputFN" placeholder="<bean:message key="demographic.demographiceditdemographic.formFirstName" />"
                    name="first_name" <%=getDisabled("first_name")%>
					value="<%=StringEscapeUtils.escapeHtml(demographic.getFirstName())%>"
					onBlur="upCaseCtrl(this)">
            </div>
        </div>
      <div class="control-group">
    <label class="control-label" for="inputDOB">
        <bean:message key="demographic.demographiceditdemographic.formDOB" />
        <bean:message key="demographic.demographiceditdemographic.formDOBDetais" />
        <span style="color:red">*</span>
    </label>
    <div class="controls" style="white-space: nowrap;">
        <input 
            id="inputDOB"
            class="input input-medium" 
            type="date"
            name="inputDOB" 
            <%=getDisabled("year_of_birth")%>
            onchange="parsedob_date();" 
        />
        <input type="hidden" id="year_of_birth" name="year_of_birth" value="<%=birthYear%>">
        <input type="hidden" name="month_of_birth" id="month_of_birth" value="<%=birthMonth%>">
        <input type="hidden" name="date_of_birth" id="date_of_birth" value="<%=birthDate%>">
        <!-- Add this span to display the calculated age -->
        (<span id="ageDisplay"><%=age%></span> <bean:message key="global.years" />)
    </div>
</div>

        <div class="control-group">
            <label class="control-label" for="sex"><bean:message key="demographic.demographiceditdemographic.formSex" /><span style="color:red">*</span></label>
            <div class="controls">
                <!-- //Value are Codes F M T O U Texts are Female Male Transgender Other Undefined -->
               <select  name="sex" id="sex">
                <option value=""></option>
                <%
                String iterSex = "";
                String sexTag = "";
                for(Gender gn : Gender.values()){
                    sexTag = "global."+gn.getText();
                try{
                        iterSex = oscarResources.getString(sexTag) ;
                    } catch(Exception ex) {
                        //MiscUtils.getLogger().error("Error", ex);
                        //Fine then lets use the English default
                        iterSex = gn.getText();
                }
                %>
                <option value=<%=gn.name()%> <%=((demographic.getSex().toUpperCase().equals(gn.name())) ? " selected=\"selected\" " : "") %>><%=iterSex%></option>
			                        <% } %>
            </select>
            </div>
        </div>
        <div class="control-group">
            <label class="control-label" for="inputAlias"><bean:message
					key="demographic.demographiceditdemographic.alias" /></label>
            <div class="controls">
              <input type="text" id="inputAlias" placeholder="<bean:message
					key="demographic.demographiceditdemographic.alias" />"
                    name="alias" <%=getDisabled("alias")%>
					value="<%=StringUtils.trimToEmpty(demographic.getAlias())%>"
					onBlur="upCaseCtrl(this)">
            </div>
        </div>
        
        
        <div class="control-group">
            <label class="control-label" for="language"><bean:message key="demographic.demographiceditdemographic.msgDemoLanguage"/></label>
            <div class="controls">
              <% String lang = oscar.util.StringUtils.noNull(demographic.getOfficialLanguage()); %>
								<select name="official_lang" id="language" <%=getDisabled("official_lang")%>>
								    <option value="English" <%=lang.equals("English")?"selected":""%> ><bean:message key="demographic.demographiceditdemographic.msgEnglish"/></option>
								    <option value="French" <%=lang.equals("French")?"selected":""%> ><bean:message key="demographic.demographiceditdemographic.msgFrench"/></option>
								    <option value="Other" <%=lang.equals("Other")?"selected":""%> ><bean:message key="demographic.demographiceditdemographic.optOther"/></option>
								</select>
            </div>
        </div>

		<div class="control-group">
    <label class="control-label" for="patient_compliance">Patient Compliance</label>
    <div class="controls">
        <select name="patient_compliance" id="patient_compliance">
            <option value="yes" <%= (patientCompliance != null && patientCompliance.equalsIgnoreCase("yes")) ? "selected" : "" %>>Yes</option>
            <option value="no" <%= (patientCompliance != null && patientCompliance.equalsIgnoreCase("no")) ? "selected" : "" %>>No</option>
            <option value="unknown" <%= (patientCompliance != null && patientCompliance.equalsIgnoreCase("unknown")) ? "selected" : "" %>>Unknown</option>
        </select>
    </div>
</div>

<div class="control-group" id="frequency-group" style="display: <%= (patientCompliance != null && patientCompliance.equalsIgnoreCase("no")) ? "block" : "none" %>;">
    <label class="control-label" for="frequency">Frequency</label>
    <div class="controls">
        <label class="radio inline">
            <input type="radio" name="frequency" value="daily" <%= (frequency != null && frequency.equalsIgnoreCase("daily")) ? "checked" : "" %>> Daily
        </label>
        <label class="radio inline">
            <input type="radio" name="frequency" value="weekly" <%= (frequency != null && frequency.equalsIgnoreCase("weekly")) ? "checked" : "" %>> Weekly
        </label>
        <label class="radio inline">
            <input type="radio" name="frequency" value="bi-weekly" <%= (frequency != null && frequency.equalsIgnoreCase("bi-weekly")) ? "checked" : "" %>> Bi-Weekly
        </label>
        <label class="radio inline">
            <input type="radio" name="frequency" value="monthly" <%= (frequency != null && frequency.equalsIgnoreCase("monthly")) ? "checked" : "" %>> Monthly
        </label>
    </div>
</div>
		<br>
        </div><!-- end demographicSectionContent -->
    </div><!-- end demographicSection -->

    <div id="contactSection" class="span11">
		<h3><bean:message key="demographic.demographiceditdemographic.msgContactInfo" /></h3>
        <div id="contactSectionContent">
<!-- "postalfield" -->
        <div class="control-group">
            <label class="control-label" for="addr"><bean:message key="demographic.demographiceditdemographic.formAddr" /></label>
            <div class="controls">
              <input type="text" id="addr" placeholder="<bean:message key="demographic.demographiceditdemographic.formAddr" />" name="address" <%=getDisabled("address")%> value="<%=StringUtils.trimToEmpty(demographic.getAddress())%>">
            </div>
        </div>
        <div class="control-group">
            <label class="control-label" for="city"><bean:message key="demographic.demographiceditdemographic.formCity" /></label>
            <div class="controls">
              <input type="text" id="city" placeholder="<bean:message key="demographic.demographiceditdemographic.formCity" />" name="city" size="30" <%=getDisabled("city")%> value="<%=StringEscapeUtils.escapeHtml(StringUtils.trimToEmpty(demographic.getCity()))%>">
            </div>
        </div>
        <div class="control-group">
            <label class="control-label" for="province"><% if(oscarProps.getProperty("demographicLabelProvince") == null) { %>
								<bean:message
									key="demographic.demographiceditdemographic.formProcvince" /> <% } else {
                                  out.print(oscarProps.getProperty("demographicLabelProvince"));
                              	 } %></label>
            <div class="controls">
              <% String province = demographic.getProvince(); %>
								<%
					if("true".equals(OscarProperties.getInstance().getProperty("iso3166.2.enabled","false"))) {
				%>
					<select name="province" id="province"></select>
					<br/><br>
					Filter by Country:<br><br> <select name="country" id="country"></select>

						<% } else { %>
								<select name="province" style="width: 200px" <%=getDisabled("province")%>>
									<option value="OT"
										<%=(province==null || province.equals("OT") || province.equals("") || province.length() > 2)?" selected":""%>>Other</option>
									<% if (pNames.isDefined()) {
                                       for (ListIterator li = pNames.listIterator(); li.hasNext(); ) {
                                           String pr2 = (String) li.next(); %>
									<option value="<%=pr2%>"
										<%=pr2.equals(province)?" selected":""%>><%=li.next()%></option>
									<% }//for %>
									<% } else { %>
									<option value="AB" <%="AB".equals(province)?" selected":""%>>AB-Alberta</option>
									<option value="BC" <%="BC".equals(province)?" selected":""%>>BC-British Columbia</option>
									<option value="MB" <%="MB".equals(province)?" selected":""%>>MB-Manitoba</option>
									<option value="NB" <%="NB".equals(province)?" selected":""%>>NB-New Brunswick</option>
									<option value="NL" <%="NL".equals(province)?" selected":""%>>NL-Newfoundland Labrador</option>
									<option value="NT" <%="NT".equals(province)?" selected":""%>>NT-Northwest Territory</option>
									<option value="NS" <%="NS".equals(province)?" selected":""%>>NS-Nova Scotia</option>
									<option value="NU" <%="NU".equals(province)?" selected":""%>>NU-Nunavut</option>
									<option value="ON" <%="ON".equals(province)?" selected":""%>>ON-Ontario</option>
									<option value="PE" <%="PE".equals(province)?" selected":""%>>PE-Prince Edward Island</option>
									<option value="QC" <%="QC".equals(province)?" selected":""%>>QC-Quebec</option>
									<option value="SK" <%="SK".equals(province)?" selected":""%>>SK-Saskatchewan</option>
									<option value="YT" <%="YT".equals(province)?" selected":""%>>YT-Yukon</option>
									<option value="US" <%="US".equals(province)?" selected":""%>>US resident</option>
									<option value="US-AK" <%="US-AK".equals(province)?" selected":""%>>US-AK-Alaska</option>
									<option value="US-AL" <%="US-AL".equals(province)?" selected":""%>>US-AL-Alabama</option>
									<option value="US-AR" <%="US-AR".equals(province)?" selected":""%>>US-AR-Arkansas</option>
									<option value="US-AZ" <%="US-AZ".equals(province)?" selected":""%>>US-AZ-Arizona</option>
									<option value="US-CA" <%="US-CA".equals(province)?" selected":""%>>US-CA-California</option>
									<option value="US-CO" <%="US-CO".equals(province)?" selected":""%>>US-CO-Colorado</option>
									<option value="US-CT" <%="US-CT".equals(province)?" selected":""%>>US-CT-Connecticut</option>
									<option value="US-CZ" <%="US-CZ".equals(province)?" selected":""%>>US-CZ-Canal Zone</option>
									<option value="US-DC" <%="US-DC".equals(province)?" selected":""%>>US-DC-District Of Columbia</option>
									<option value="US-DE" <%="US-DE".equals(province)?" selected":""%>>US-DE-Delaware</option>
									<option value="US-FL" <%="US-FL".equals(province)?" selected":""%>>US-FL-Florida</option>
									<option value="US-GA" <%="US-GA".equals(province)?" selected":""%>>US-GA-Georgia</option>
									<option value="US-GU" <%="US-GU".equals(province)?" selected":""%>>US-GU-Guam</option>
									<option value="US-HI" <%="US-HI".equals(province)?" selected":""%>>US-HI-Hawaii</option>
									<option value="US-IA" <%="US-IA".equals(province)?" selected":""%>>US-IA-Iowa</option>
									<option value="US-ID" <%="US-ID".equals(province)?" selected":""%>>US-ID-Idaho</option>
									<option value="US-IL" <%="US-IL".equals(province)?" selected":""%>>US-IL-Illinois</option>
									<option value="US-IN" <%="US-IN".equals(province)?" selected":""%>>US-IN-Indiana</option>
									<option value="US-KS" <%="US-KS".equals(province)?" selected":""%>>US-KS-Kansas</option>
									<option value="US-KY" <%="US-KY".equals(province)?" selected":""%>>US-KY-Kentucky</option>
									<option value="US-LA" <%="US-LA".equals(province)?" selected":""%>>US-LA-Louisiana</option>
									<option value="US-MA" <%="US-MA".equals(province)?" selected":""%>>US-MA-Massachusetts</option>
									<option value="US-MD" <%="US-MD".equals(province)?" selected":""%>>US-MD-Maryland</option>
									<option value="US-ME" <%="US-ME".equals(province)?" selected":""%>>US-ME-Maine</option>
									<option value="US-MI" <%="US-MI".equals(province)?" selected":""%>>US-MI-Michigan</option>
									<option value="US-MN" <%="US-MN".equals(province)?" selected":""%>>US-MN-Minnesota</option>
									<option value="US-MO" <%="US-MO".equals(province)?" selected":""%>>US-MO-Missouri</option>
									<option value="US-MS" <%="US-MS".equals(province)?" selected":""%>>US-MS-Mississippi</option>
									<option value="US-MT" <%="US-MT".equals(province)?" selected":""%>>US-MT-Montana</option>
									<option value="US-NC" <%="US-NC".equals(province)?" selected":""%>>US-NC-North Carolina</option>
									<option value="US-ND" <%="US-ND".equals(province)?" selected":""%>>US-ND-North Dakota</option>
									<option value="US-NE" <%="US-NE".equals(province)?" selected":""%>>US-NE-Nebraska</option>
									<option value="US-NH" <%="US-NH".equals(province)?" selected":""%>>US-NH-New Hampshire</option>
									<option value="US-NJ" <%="US-NJ".equals(province)?" selected":""%>>US-NJ-New Jersey</option>
									<option value="US-NM" <%="US-NM".equals(province)?" selected":""%>>US-NM-New Mexico</option>
									<option value="US-NU" <%="US-NU".equals(province)?" selected":""%>>US-NU-Nunavut</option>
									<option value="US-NV" <%="US-NV".equals(province)?" selected":""%>>US-NV-Nevada</option>
									<option value="US-NY" <%="US-NY".equals(province)?" selected":""%>>US-NY-New York</option>
									<option value="US-OH" <%="US-OH".equals(province)?" selected":""%>>US-OH-Ohio</option>
									<option value="US-OK" <%="US-OK".equals(province)?" selected":""%>>US-OK-Oklahoma</option>
									<option value="US-OR" <%="US-OR".equals(province)?" selected":""%>>US-OR-Oregon</option>
									<option value="US-PA" <%="US-PA".equals(province)?" selected":""%>>US-PA-Pennsylvania</option>
									<option value="US-PR" <%="US-PR".equals(province)?" selected":""%>>US-PR-Puerto Rico</option>
									<option value="US-RI" <%="US-RI".equals(province)?" selected":""%>>US-RI-Rhode Island</option>
									<option value="US-SC" <%="US-SC".equals(province)?" selected":""%>>US-SC-South Carolina</option>
									<option value="US-SD" <%="US-SD".equals(province)?" selected":""%>>US-SD-South Dakota</option>
									<option value="US-TN" <%="US-TN".equals(province)?" selected":""%>>US-TN-Tennessee</option>
									<option value="US-TX" <%="US-TX".equals(province)?" selected":""%>>US-TX-Texas</option>
									<option value="US-UT" <%="US-UT".equals(province)?" selected":""%>>US-UT-Utah</option>
									<option value="US-VA" <%="US-VA".equals(province)?" selected":""%>>US-VA-Virginia</option>
									<option value="US-VI" <%="US-VI".equals(province)?" selected":""%>>US-VI-Virgin Islands</option>
									<option value="US-VT" <%="US-VT".equals(province)?" selected":""%>>US-VT-Vermont</option>
									<option value="US-WA" <%="US-WA".equals(province)?" selected":""%>>US-WA-Washington</option>
									<option value="US-WI" <%="US-WI".equals(province)?" selected":""%>>US-WI-Wisconsin</option>
									<option value="US-WV" <%="US-WV".equals(province)?" selected":""%>>US-WV-West Virginia</option>
									<option value="US-WY" <%="US-WY".equals(province)?" selected":""%>>US-WY-Wyoming</option>
									<% } %>
								</select>

								<% } %>
            </div>
        </div>
        <div class="control-group">
            <label class="control-label" for="postal"><% if(oscarProps.getProperty("demographicLabelPostal") == null) { %>
								<bean:message
									key="demographic.demographiceditdemographic.formPostal" /> <% } else {
                                  out.print(oscarProps.getProperty("demographicLabelPostal"));
                              	 } %></label>
            <div class="controls">
              <input type="text" id="postal" placeholder="<% if(oscarProps.getProperty("demographicLabelPostal") == null) { %>								<bean:message key="demographic.demographiceditdemographic.formPostal" /> <% } else {  out.print(oscarProps.getProperty("demographicLabelPostal")); } %>" name="postal" <%=getDisabled("postal")%>
									value="<%=StringUtils.trimToEmpty(demographic.getPostal())%>" 
									onBlur="upCaseCtrl(this)" onChange="isPostalCode()">
            </div>
        </div>
<!-- end postal -->
        <div class="control-group">
            <label class="control-label" for="inputEmail"><bean:message key="demographic.demographiceditdemographic.formEmail" /></label>
            <div class="controls">
              <input type="text" id="inputEmail" placeholder="<bean:message key="demographic.demographiceditdemographic.formEmail" />"
                    name="email" <%=getDisabled("email")%>
					value="<%=demographic.getEmail()!=null? demographic.getEmail() : ""%>">
            </div>
        </div>
        <div class="control-group">
            <label class="control-label" for="consentEmail"><bean:message key="demographic.demographiceditdemographic.consentToUseEmailForCare" /></label>
            <div class="controls" style="white-space: nowrap;">
              <bean:message key="WriteScript.msgYes"/>
            								<input type="radio" value="yes" name="consentToUseEmailForCare" id="consentEmail" <% if (demographic.getConsentToUseEmailForCare() != null && demographic.getConsentToUseEmailForCare()){ out.write("checked"); }%> />
          							 <bean:message key="WriteScript.msgNo"/>
            								<input type="radio" value="no" name="consentToUseEmailForCare"  <% if (demographic.getConsentToUseEmailForCare() != null && !demographic.getConsentToUseEmailForCare()){ out.write("checked");}%> />
									 <bean:message key="WriteScript.msgUnset"/>
            								<input type="radio" value="unset" name="consentToUseEmailForCare"  <% if (demographic.getConsentToUseEmailForCare() == null){ out.write("checked"); } %> />
            </div>
        </div>
<!-- residential -->
        <div class="control-group">
            <label class="control-label" for="residence"><bean:message key="demographic.demographiceditdemographic.formResidentialAddr" /></label>
            <div class="controls">
              <input type="text" id="residence" placeholder="<bean:message key="demographic.demographiceditdemographic.formResidentialAddr" />"
                    name="residentialAddress" <%=getDisabled("residentialAddress")%>
					value="<%=StringUtils.trimToEmpty(demographic.getResidentialAddress())%>">
            </div>
        </div>
        <div class="control-group">
            <label class="control-label" for="rCity"><bean:message key="demographic.demographiceditdemographic.formResidentialCity" /></label>
            <div class="controls">
              <input type="text" id="rCity" placeholder="<bean:message key="demographic.demographiceditdemographic.formResidentialCity" />"
                    name="residentialCity" <%=getDisabled("residentialCity")%>
					value="<%=StringEscapeUtils.escapeHtml(StringUtils.trimToEmpty(demographic.getResidentialCity()))%>">
            </div>
        </div>
        <div class="control-group">
            <label class="control-label" for="residentialProvince"><bean:message key="demographic.demographiceditdemographic.formResidentialProvince" /></label>
            <div class="controls">
              <% String residentialProvince = demographic.getResidentialProvince(); %>
				<%
					if("true".equals(OscarProperties.getInstance().getProperty("iso3166.2.enabled","false"))) {
				%>
					<select name="residentialProvince" id="residentialProvince"></select>
					<br/><br>
					Filter by Country:<br><br> <select name="residentialCountry" id="residentialCountry" ></select>

						<% } else { %>

								<select name="residentialProvince" style="width: 200px" <%=getDisabled("residentialProvince")%>>
									<option value="OT"
										<%=(residentialProvince==null || residentialProvince.equals("OT") || residentialProvince.equals("") || residentialProvince.length() > 2)?" selected":""%>>Other</option>
									<% if (pNames.isDefined()) {
                                       for (ListIterator li = pNames.listIterator(); li.hasNext(); ) {
                                           String pr2 = (String) li.next(); %>
									<option value="<%=pr2%>"
										<%=pr2.equals(residentialProvince)?" selected":""%>><%=li.next()%></option>
									<% }//for %>
									<% } else { %>
									<option value="AB" <%="AB".equals(residentialProvince)?" selected":""%>>AB-Alberta</option>
									<option value="BC" <%="BC".equals(residentialProvince)?" selected":""%>>BC-British Columbia</option>
									<option value="MB" <%="MB".equals(residentialProvince)?" selected":""%>>MB-Manitoba</option>
									<option value="NB" <%="NB".equals(residentialProvince)?" selected":""%>>NB-New Brunswick</option>
									<option value="NL" <%="NL".equals(residentialProvince)?" selected":""%>>NL-Newfoundland Labrador</option>
									<option value="NT" <%="NT".equals(residentialProvince)?" selected":""%>>NT-Northwest Territory</option>
									<option value="NS" <%="NS".equals(residentialProvince)?" selected":""%>>NS-Nova Scotia</option>
									<option value="NU" <%="NU".equals(residentialProvince)?" selected":""%>>NU-Nunavut</option>
									<option value="ON" <%="ON".equals(residentialProvince)?" selected":""%>>ON-Ontario</option>
									<option value="PE" <%="PE".equals(residentialProvince)?" selected":""%>>PE-Prince Edward Island</option>
									<option value="QC" <%="QC".equals(residentialProvince)?" selected":""%>>QC-Quebec</option>
									<option value="SK" <%="SK".equals(residentialProvince)?" selected":""%>>SK-Saskatchewan</option>
									<option value="YT" <%="YT".equals(residentialProvince)?" selected":""%>>YT-Yukon</option>
									<option value="US" <%="US".equals(residentialProvince)?" selected":""%>>US resident</option>
									<option value="US-AK" <%="US-AK".equals(residentialProvince)?" selected":""%>>US-AK-Alaska</option>
									<option value="US-AL" <%="US-AL".equals(residentialProvince)?" selected":""%>>US-AL-Alabama</option>
									<option value="US-AR" <%="US-AR".equals(residentialProvince)?" selected":""%>>US-AR-Arkansas</option>
									<option value="US-AZ" <%="US-AZ".equals(residentialProvince)?" selected":""%>>US-AZ-Arizona</option>
									<option value="US-CA" <%="US-CA".equals(residentialProvince)?" selected":""%>>US-CA-California</option>
									<option value="US-CO" <%="US-CO".equals(residentialProvince)?" selected":""%>>US-CO-Colorado</option>
									<option value="US-CT" <%="US-CT".equals(residentialProvince)?" selected":""%>>US-CT-Connecticut</option>
									<option value="US-CZ" <%="US-CZ".equals(residentialProvince)?" selected":""%>>US-CZ-Canal Zone</option>
									<option value="US-DC" <%="US-DC".equals(residentialProvince)?" selected":""%>>US-DC-District Of Columbia</option>
									<option value="US-DE" <%="US-DE".equals(residentialProvince)?" selected":""%>>US-DE-Delaware</option>
									<option value="US-FL" <%="US-FL".equals(residentialProvince)?" selected":""%>>US-FL-Florida</option>
									<option value="US-GA" <%="US-GA".equals(residentialProvince)?" selected":""%>>US-GA-Georgia</option>
									<option value="US-GU" <%="US-GU".equals(residentialProvince)?" selected":""%>>US-GU-Guam</option>
									<option value="US-HI" <%="US-HI".equals(residentialProvince)?" selected":""%>>US-HI-Hawaii</option>
									<option value="US-IA" <%="US-IA".equals(residentialProvince)?" selected":""%>>US-IA-Iowa</option>
									<option value="US-ID" <%="US-ID".equals(residentialProvince)?" selected":""%>>US-ID-Idaho</option>
									<option value="US-IL" <%="US-IL".equals(residentialProvince)?" selected":""%>>US-IL-Illinois</option>
									<option value="US-IN" <%="US-IN".equals(residentialProvince)?" selected":""%>>US-IN-Indiana</option>
									<option value="US-KS" <%="US-KS".equals(residentialProvince)?" selected":""%>>US-KS-Kansas</option>
									<option value="US-KY" <%="US-KY".equals(residentialProvince)?" selected":""%>>US-KY-Kentucky</option>
									<option value="US-LA" <%="US-LA".equals(residentialProvince)?" selected":""%>>US-LA-Louisiana</option>
									<option value="US-MA" <%="US-MA".equals(residentialProvince)?" selected":""%>>US-MA-Massachusetts</option>
									<option value="US-MD" <%="US-MD".equals(residentialProvince)?" selected":""%>>US-MD-Maryland</option>
									<option value="US-ME" <%="US-ME".equals(residentialProvince)?" selected":""%>>US-ME-Maine</option>
									<option value="US-MI" <%="US-MI".equals(residentialProvince)?" selected":""%>>US-MI-Michigan</option>
									<option value="US-MN" <%="US-MN".equals(residentialProvince)?" selected":""%>>US-MN-Minnesota</option>
									<option value="US-MO" <%="US-MO".equals(residentialProvince)?" selected":""%>>US-MO-Missouri</option>
									<option value="US-MS" <%="US-MS".equals(residentialProvince)?" selected":""%>>US-MS-Mississippi</option>
									<option value="US-MT" <%="US-MT".equals(residentialProvince)?" selected":""%>>US-MT-Montana</option>
									<option value="US-NC" <%="US-NC".equals(residentialProvince)?" selected":""%>>US-NC-North Carolina</option>
									<option value="US-ND" <%="US-ND".equals(residentialProvince)?" selected":""%>>US-ND-North Dakota</option>
									<option value="US-NE" <%="US-NE".equals(residentialProvince)?" selected":""%>>US-NE-Nebraska</option>
									<option value="US-NH" <%="US-NH".equals(residentialProvince)?" selected":""%>>US-NH-New Hampshire</option>
									<option value="US-NJ" <%="US-NJ".equals(residentialProvince)?" selected":""%>>US-NJ-New Jersey</option>
									<option value="US-NM" <%="US-NM".equals(residentialProvince)?" selected":""%>>US-NM-New Mexico</option>
									<option value="US-NU" <%="US-NU".equals(residentialProvince)?" selected":""%>>US-NU-Nunavut</option>
									<option value="US-NV" <%="US-NV".equals(residentialProvince)?" selected":""%>>US-NV-Nevada</option>
									<option value="US-NY" <%="US-NY".equals(residentialProvince)?" selected":""%>>US-NY-New York</option>
									<option value="US-OH" <%="US-OH".equals(residentialProvince)?" selected":""%>>US-OH-Ohio</option>
									<option value="US-OK" <%="US-OK".equals(residentialProvince)?" selected":""%>>US-OK-Oklahoma</option>
									<option value="US-OR" <%="US-OR".equals(residentialProvince)?" selected":""%>>US-OR-Oregon</option>
									<option value="US-PA" <%="US-PA".equals(residentialProvince)?" selected":""%>>US-PA-Pennsylvania</option>
									<option value="US-PR" <%="US-PR".equals(residentialProvince)?" selected":""%>>US-PR-Puerto Rico</option>
									<option value="US-RI" <%="US-RI".equals(residentialProvince)?" selected":""%>>US-RI-Rhode Island</option>
									<option value="US-SC" <%="US-SC".equals(residentialProvince)?" selected":""%>>US-SC-South Carolina</option>
									<option value="US-SD" <%="US-SD".equals(residentialProvince)?" selected":""%>>US-SD-South Dakota</option>
									<option value="US-TN" <%="US-TN".equals(residentialProvince)?" selected":""%>>US-TN-Tennessee</option>
									<option value="US-TX" <%="US-TX".equals(residentialProvince)?" selected":""%>>US-TX-Texas</option>
									<option value="US-UT" <%="US-UT".equals(residentialProvince)?" selected":""%>>US-UT-Utah</option>
									<option value="US-VA" <%="US-VA".equals(residentialProvince)?" selected":""%>>US-VA-Virginia</option>
									<option value="US-VI" <%="US-VI".equals(residentialProvince)?" selected":""%>>US-VI-Virgin Islands</option>
									<option value="US-VT" <%="US-VT".equals(residentialProvince)?" selected":""%>>US-VT-Vermont</option>
									<option value="US-WA" <%="US-WA".equals(residentialProvince)?" selected":""%>>US-WA-Washington</option>
									<option value="US-WI" <%="US-WI".equals(residentialProvince)?" selected":""%>>US-WI-Wisconsin</option>
									<option value="US-WV" <%="US-WV".equals(residentialProvince)?" selected":""%>>US-WV-West Virginia</option>
									<option value="US-WY" <%="US-WY".equals(residentialProvince)?" selected":""%>>US-WY-Wyoming</option>
									<% } %>
								</select>
					<% } %>
            </div>
        </div>
        <div class="control-group">
            <label class="control-label" for="rPostal"><bean:message key="demographic.demographiceditdemographic.formResidentialPostal" /></label>
            <div class="controls">
              <input type="text" id="rPostal" placeholder="<bean:message key="demographic.demographiceditdemographic.formResidentialPostal" />"
                    name="residentialPostal" <%=getDisabled("residentialPostal")%>
					value="<%=StringUtils.trimToEmpty(demographic.getResidentialPostal())%>"
					onBlur="upCaseCtrl(this)" onChange="isPostalCode2()">
            </div>
        </div>
<!-- end residential -->
        <div class="control-group" id="phone_div">
            <label class="control-label" for="phone_check"><bean:message key="demographic.demographiceditdemographic.formPhoneH" /><input type="checkbox" id="phone_check"></label>
            <div class="controls"  style="white-space:nowrap" >
              <input type="text" id="phone" placeholder="<bean:message key="demographic.demographiceditdemographic.formPhoneH" />"
                    name="phone" onblur="formatPhoneNum();" <%=getDisabled("phone")%>
					class="input-small"
					value="<%=StringUtils.trimToEmpty(StringUtils.trimToEmpty(demographic.getPhone()))%>">
            <input type="text" name="hPhoneExt" <%=getDisabled("hPhoneExt")%>
                    placeholder="<bean:message key="demographic.demographiceditdemographic.msgExt"/>"
                    class="input-small"
					value="<%=StringUtils.trimToEmpty(StringUtils.trimToEmpty(demoExt.get("hPhoneExt")))%>"/>
            <input type="hidden" name="hPhoneExtOrig"
					value="<%=StringUtils.trimToEmpty(StringUtils.trimToEmpty(demoExt.get("hPhoneExt")))%>" />
            </div>
        </div>
        <div class="control-group" id="phone2_div">
            <label class="control-label" for="phone2_check"><bean:message key="demographic.demographiceditdemographic.formPhoneW" /><input type="checkbox" id="phone2_check"></label>
            <div class="controls" style="white-space:nowrap" >
                <input type="text" id="phone2" placeholder="<bean:message key="demographic.demographiceditdemographic.formPhoneW" />"
                    name="phone2" <%=getDisabled("phone2")%>
					onblur="formatPhoneNum();"
                    class="input-small"
					value="<%=StringUtils.trimToEmpty(demographic.getPhone2())%>">
                <input type="text" name="wPhoneExt" <%=getDisabled("wPhoneExt")%>
                    placeholder="<bean:message key="demographic.demographiceditdemographic.msgExt"/>"
                    value="<%=StringUtils.trimToEmpty(StringUtils.trimToEmpty(demoExt.get("wPhoneExt")))%>"
					class="input-small" />
                <input type="hidden" name="wPhoneExtOrig"
					value="<%=StringUtils.trimToEmpty(StringUtils.trimToEmpty(demoExt.get("wPhoneExt")))%>" />
            </div>
        </div>
        <div class="control-group" id="cell_div">
            <label class="control-label" for="cell_check"><bean:message key="demographic.demographiceditdemographic.formPhoneC" /><input type="checkbox" id="cell_check"></label>
            <div class="controls">
              <input type="text" id="cell" placeholder="<bean:message key="demographic.demographiceditdemographic.formPhoneC" />"
                    name="demo_cell" onblur="formatPhoneNum();"
					<%=getDisabled("demo_cell")%>
					value="<%=StringUtils.trimToEmpty(demoExt.get("demo_cell"))%>">
				<input type="hidden" name="demo_cellOrig" value="<%=StringUtils.trimToEmpty(demoExt.get("demo_cell"))%>" />
            </div>
        </div>
        
      <%
			String entityType = OscarProperties.getInstance().getProperty("ENTITY_TYPE", "");
			boolean isPharmacy = "pharmacy".equalsIgnoreCase(entityType);
		%>

				<% if (!isPharmacy) { %>
				<div class="control-group">
					<label class="control-label" for="preferredPharmacy">Preferred Pharmacy:</label>
					<div class="custom-dropdown" id="preferredPharmacyDropdown">
						<!-- Dropdown Toggle -->
						<button class="dropdown-toggle" id="dropdownToggle" onclick="fetchAndLogAddressValues()">
							<% 
								// Determine the preselected pharmacy
								PharmacyInfo selectedPharmacy = null;
								for (PharmacyInfo pharmacy : pharmacyList) {
									if (pharmacy.getId().equals(preferredPharmacyId)) {
										selectedPharmacy = pharmacy;
										break;
									}
								}

								// Display the preselected pharmacy name or default text
								if (selectedPharmacy != null) { 
							%>
								<%= selectedPharmacy.getName() %>, <%= selectedPharmacy.getAddress() %> - <%= selectedPharmacy.getCity() %>
							<% } else { %>
								Select Pharmacy
							<% } %>
						</button>

						<!-- Dropdown Menu -->
						<div class="dropdown-menu" id="dropdownMenu">
							<input type="text" id="dropdownSearch" placeholder="Search for a pharmacy..." class="dropdown-search">
							<div id="dropdownOptionsContainer">
								<% for (PharmacyInfo pharmacy : pharmacyList) { %>
									<div class="dropdown-option" 
										data-id="<%= pharmacy.getId() %>"
										<%= (preferredPharmacyId != null && preferredPharmacyId.equals(String.valueOf(pharmacy.getId()))) ? "data-selected='true'" : "" %> >
										<span><%= pharmacy.getName() %>, <%= pharmacy.getAddress() %> - <%= pharmacy.getCity() %></span>
									</div>
								<% } %>
							</div>
						</div>
					</div>
					<input type="hidden" name="preferredPharmacy" id="preferredPharmacy" value="">
				</div>
				<% } %>
		<br>
    </div><!-- end contactSectionContent -->
    </div><!-- end contactSection -->
    <div id="insurance" class="span11">
		 <h3><bean:message key="demographic.demographiceditdemographic.msgHealthIns"/></h3>
    <div id="insuranceSectionContent">
        <div class="control-group">
            <label class="control-label" for="hcType"><bean:message key="demographic.demographiceditdemographic.formHCType" /></label>
            <div class="controls">
              <% String hctype = demographic.getHcType()==null?"":demographic.getHcType(); %>
								<select name="hc_type" id="hcType" <%=getDisabled("hc_type")%>>
									<option value="OT"
										<%=(hctype.equals("OT") || hctype.equals("") || hctype.length() > 2)?" selected":""%>><bean:message key="demographic.demographiceditdemographic.optOther"/></option>
									<% if (pNames.isDefined()) {
                                       for (ListIterator li = pNames.listIterator(); li.hasNext(); ) {
                                           province = (String) li.next(); %>
									<option value="<%=province%>"
										<%=province.equals(hctype)?" selected":""%>><%=li.next()%></option>
									<% } %>
									<% } else { %>
									<option value="AB" <%=hctype.equals("AB")?" selected":""%>>AB-Alberta</option>
									<option value="BC" <%=hctype.equals("BC")?" selected":""%>>BC-British Columbia</option>
									<option value="MB" <%=hctype.equals("MB")?" selected":""%>>MB-Manitoba</option>
									<option value="NB" <%=hctype.equals("NB")?" selected":""%>>NB-New Brunswick</option>
									<option value="NL" <%=hctype.equals("NL")?" selected":""%>>NL-Newfoundland & Labrador</option>
									<option value="NT" <%=hctype.equals("NT")?" selected":""%>>NT-Northwest Territory</option>
									<option value="NS" <%=hctype.equals("NS")?" selected":""%>>NS-Nova Scotia</option>
									<option value="NU" <%=hctype.equals("NU")?" selected":""%>>NU-Nunavut</option>
									<option value="ON" <%=hctype.equals("ON")?" selected":""%>>ON-Ontario</option>
									<option value="PE" <%=hctype.equals("PE")?" selected":""%>>PE-Prince Edward Island</option>
									<option value="QC" <%=hctype.equals("QC")?" selected":""%>>QC-Quebec</option>
									<option value="SK" <%=hctype.equals("SK")?" selected":""%>>SK-Saskatchewan</option>
									<option value="YT" <%=hctype.equals("YT")?" selected":""%>>YT-Yukon</option>
									<option value="US" <%=hctype.equals("US")?" selected":""%>>US resident</option>
									<option value="US-AK" <%=hctype.equals("US-AK")?" selected":""%>>US-AK-Alaska</option>
									<option value="US-AL" <%=hctype.equals("US-AL")?" selected":""%>>US-AL-Alabama</option>
									<option value="US-AR" <%=hctype.equals("US-AR")?" selected":""%>>US-AR-Arkansas</option>
									<option value="US-AZ" <%=hctype.equals("US-AZ")?" selected":""%>>US-AZ-Arizona</option>
									<option value="US-CA" <%=hctype.equals("US-CA")?" selected":""%>>US-CA-California</option>
									<option value="US-CO" <%=hctype.equals("US-CO")?" selected":""%>>US-CO-Colorado</option>
									<option value="US-CT" <%=hctype.equals("US-CT")?" selected":""%>>US-CT-Connecticut</option>
									<option value="US-CZ" <%=hctype.equals("US-CZ")?" selected":""%>>US-CZ-Canal Zone</option>
									<option value="US-DC" <%=hctype.equals("US-DC")?" selected":""%>>US-DC-District Of Columbia</option>
									<option value="US-DE" <%=hctype.equals("US-DE")?" selected":""%>>US-DE-Delaware</option>
									<option value="US-FL" <%=hctype.equals("US-FL")?" selected":""%>>US-FL-Florida</option>
									<option value="US-GA" <%=hctype.equals("US-GA")?" selected":""%>>US-GA-Georgia</option>
									<option value="US-GU" <%=hctype.equals("US-GU")?" selected":""%>>US-GU-Guam</option>
									<option value="US-HI" <%=hctype.equals("US-HI")?" selected":""%>>US-HI-Hawaii</option>
									<option value="US-IA" <%=hctype.equals("US-IA")?" selected":""%>>US-IA-Iowa</option>
									<option value="US-ID" <%=hctype.equals("US-ID")?" selected":""%>>US-ID-Idaho</option>
									<option value="US-IL" <%=hctype.equals("US-IL")?" selected":""%>>US-IL-Illinois</option>
									<option value="US-IN" <%=hctype.equals("US-IN")?" selected":""%>>US-IN-Indiana</option>
									<option value="US-KS" <%=hctype.equals("US-KS")?" selected":""%>>US-KS-Kansas</option>
									<option value="US-KY" <%=hctype.equals("US-KY")?" selected":""%>>US-KY-Kentucky</option>
									<option value="US-LA" <%=hctype.equals("US-LA")?" selected":""%>>US-LA-Louisiana</option>
									<option value="US-MA" <%=hctype.equals("US-MA")?" selected":""%>>US-MA-Massachusetts</option>
									<option value="US-MD" <%=hctype.equals("US-MD")?" selected":""%>>US-MD-Maryland</option>
									<option value="US-ME" <%=hctype.equals("US-ME")?" selected":""%>>US-ME-Maine</option>
									<option value="US-MI" <%=hctype.equals("US-MI")?" selected":""%>>US-MI-Michigan</option>
									<option value="US-MN" <%=hctype.equals("US-MN")?" selected":""%>>US-MN-Minnesota</option>
									<option value="US-MO" <%=hctype.equals("US-MO")?" selected":""%>>US-MO-Missouri</option>
									<option value="US-MS" <%=hctype.equals("US-MS")?" selected":""%>>US-MS-Mississippi</option>
									<option value="US-MT" <%=hctype.equals("US-MT")?" selected":""%>>US-MT-Montana</option>
									<option value="US-NC" <%=hctype.equals("US-NC")?" selected":""%>>US-NC-North Carolina</option>
									<option value="US-ND" <%=hctype.equals("US-ND")?" selected":""%>>US-ND-North Dakota</option>
									<option value="US-NE" <%=hctype.equals("US-NE")?" selected":""%>>US-NE-Nebraska</option>
									<option value="US-NH" <%=hctype.equals("US-NH")?" selected":""%>>US-NH-New Hampshire</option>
									<option value="US-NJ" <%=hctype.equals("US-NJ")?" selected":""%>>US-NJ-New Jersey</option>
									<option value="US-NM" <%=hctype.equals("US-NM")?" selected":""%>>US-NM-New Mexico</option>
									<option value="US-NU" <%=hctype.equals("US-NU")?" selected":""%>>US-NU-Nunavut</option>
									<option value="US-NV" <%=hctype.equals("US-NV")?" selected":""%>>US-NV-Nevada</option>
									<option value="US-NY" <%=hctype.equals("US-NY")?" selected":""%>>US-NY-New York</option>
									<option value="US-OH" <%=hctype.equals("US-OH")?" selected":""%>>US-OH-Ohio</option>
									<option value="US-OK" <%=hctype.equals("US-OK")?" selected":""%>>US-OK-Oklahoma</option>
									<option value="US-OR" <%=hctype.equals("US-OR")?" selected":""%>>US-OR-Oregon</option>
									<option value="US-PA" <%=hctype.equals("US-PA")?" selected":""%>>US-PA-Pennsylvania</option>
									<option value="US-PR" <%=hctype.equals("US-PR")?" selected":""%>>US-PR-Puerto Rico</option>
									<option value="US-RI" <%=hctype.equals("US-RI")?" selected":""%>>US-RI-Rhode Island</option>
									<option value="US-SC" <%=hctype.equals("US-SC")?" selected":""%>>US-SC-South Carolina</option>
									<option value="US-SD" <%=hctype.equals("US-SD")?" selected":""%>>US-SD-South Dakota</option>
									<option value="US-TN" <%=hctype.equals("US-TN")?" selected":""%>>US-TN-Tennessee</option>
									<option value="US-TX" <%=hctype.equals("US-TX")?" selected":""%>>US-TX-Texas</option>
									<option value="US-UT" <%=hctype.equals("US-UT")?" selected":""%>>US-UT-Utah</option>
									<option value="US-VA" <%=hctype.equals("US-VA")?" selected":""%>>US-VA-Virginia</option>
									<option value="US-VI" <%=hctype.equals("US-VI")?" selected":""%>>US-VI-Virgin Islands</option>
									<option value="US-VT" <%=hctype.equals("US-VT")?" selected":""%>>US-VT-Vermont</option>
									<option value="US-WA" <%=hctype.equals("US-WA")?" selected":""%>>US-WA-Washington</option>
									<option value="US-WI" <%=hctype.equals("US-WI")?" selected":""%>>US-WI-Wisconsin</option>
									<option value="US-WV" <%=hctype.equals("US-WV")?" selected":""%>>US-WV-West Virginia</option>
									<option value="US-WY" <%=hctype.equals("US-WY")?" selected":""%>>US-WY-Wyoming</option>
									<% } %>
								</select>
            </div>
        </div>
        <div class="control-group" style="white-space:nowrap">
            <label class="control-label" for="hinBox"><bean:message key="demographic.demographiceditdemographic.formHin" /></label>
            <div class="controls">
              <input type="text" placeholder="<bean:message key="demographic.demographiceditdemographic.formHin" />"
                    name="hin" id="hinBox" <%=getDisabled("hin")%>
					value="<%=StringUtils.trimToEmpty(demographic.getHin())%>" class="input-medium">
            <bean:message key="demographic.demographiceditdemographic.formVer" />
            <input type="text" placeholder="<bean:message key="demographic.demographiceditdemographic.formVer" />"
                    name="ver" <%=getDisabled("ver")%>
									value="<%=StringUtils.trimToEmpty(demographic.getVer())%>" style="width: 20px;"
									onBlur="upCaseCtrl(this)" id="verBox">
									<%if("online".equals(oscarProps.getProperty("hcv.type", "simple"))) { %>
										<input type="button" class="btn" value="Validate" onClick="validateHC()"/>
									<% } %>
            </div>
        </div>
        <div class="control-group">
            <label class="control-label" for="effDate"><bean:message key="demographic.demographiceditdemographic.formEFFDate" /></label>
            <div class="controls">

<script>
    document.addEventListener('DOMContentLoaded', function () {
        // Update the dropdown toggle button text based on preselected pharmacy
        const preselectedOption = document.querySelector('.dropdown-option[data-selected="true"]');
        if (preselectedOption) {
            const dropdownToggle = document.getElementById('dropdownToggle');
            const name = preselectedOption.querySelector('span').textContent;
            dropdownToggle.textContent = name; // Update the toggle button text
        }
    });
</script>

<script>

function loaddob(){
    console.log("DOB is "+document.getElementById('year_of_birth').value+"-"+document.getElementById('month_of_birth').value+"-"+document.getElementById('date_of_birth').value);
    document.getElementById('inputDOB').value=document.getElementById('year_of_birth').value+"-"+document.getElementById('month_of_birth').value+"-"+document.getElementById('date_of_birth').value;

}

function parsedob_date() {
    var input = document.getElementById('inputDOB').value;
    var year = "";
    var month = "";
    var day = "";
    
    if (input != "") {
        // Parse the input date (YYYY-MM-DD format)
        const myArr = input.split("-");
        year = myArr[0];
        month = myArr[1];
        day = myArr[2];

        // Update hidden fields
        document.getElementById('year_of_birth').value = year;
        document.getElementById('month_of_birth').value = month;
        document.getElementById('date_of_birth').value = day;

        // Calculate age
        const dob = new Date(year, month - 1, day); // Month is 0-indexed in JavaScript
        const today = new Date();

        let age = today.getFullYear() - dob.getFullYear();
        const monthDiff = today.getMonth() - dob.getMonth();
        const dayDiff = today.getDate() - dob.getDate();

        // Adjust age if the current date is before the birthday
        if (monthDiff < 0 || (monthDiff === 0 && dayDiff < 0)) {
            age--;
        }

        // Update the age display
        document.getElementById('ageDisplay').innerText = age;
    } else {
        // Clear the hidden fields and age display if no input is provided
        document.getElementById('year_of_birth').value = "";
        document.getElementById('month_of_birth').value = "";
        document.getElementById('date_of_birth').value = "";
        document.getElementById('ageDisplay').innerText = "";
    }
}


function parseeff_date(){
    var input=document.getElementById('eff_date').value;
    year="";
    month="";
    day="";
    if (input != "") {
        const myArr = input.split("-");
        year = myArr[0];
        month = myArr[1];
        day = myArr[2];
    }
    console.log("eff="+year+"-"+month+"-"+day);
    document.getElementById('eff_date_year').value = year;
    document.getElementById('eff_date_month').value = month;
    document.getElementById('eff_date_day').value = day;
}

function parsehc_renew_date(){
    var input=document.getElementById('hc_renew_date').value;
    year="";
    month="";
    day="";
    if (input != ""){
    const myArr = input.split("-");
        year = myArr[0];
        month = myArr[1];
        day = myArr[2];
    }
    console.log("hc_renew="+year+"-"+month+"-"+day);
        document.getElementById('hc_renew_date_year').value = year
        document.getElementById('hc_renew_date_month').value = month
        document.getElementById('hc_renew_date_day').value = day

}

function parseroster_date(){
    var input=document.getElementById('roster_date').value;
    year="";
    month="";
    day="";
    if (input != ""){
    const myArr = input.split("-");
        year = myArr[0];
        month = myArr[1];
        day = myArr[2];
    }
    console.log("rosterd="+year+"-"+month+"-"+day);
        document.getElementById('roster_date_year').value = year
        document.getElementById('roster_date_month').value = month
        document.getElementById('roster_date_day').value = day

}

function parseend_date(){
    var input=document.getElementById('end_date').value;
    year="";
    month="";
    day="";
    if (input != ""){
    const myArr = input.split("-");
        year = myArr[0];
        month = myArr[1];
        day = myArr[2];
    }
    console.log("end="+year+"-"+month+"-"+day);
        document.getElementById('end_date_year').value = year
        document.getElementById('end_date_month').value = month
        document.getElementById('end_date_day').value = day

}


function parseroster_termination_date(){
    var input=document.getElementById('roster_termination_date').value;
    year="";
    month="";
    day="";
    if (input != ""){
    const myArr = input.split("-");
        year = myArr[0];
        month = myArr[1];
        day = myArr[2];
    }
    console.log("term="+year+"-"+month+"-"+day);
        document.getElementById('roster_termination_date_year').value = year
        document.getElementById('roster_termination_date_month').value = month
        document.getElementById('roster_termination_date_day').value = day

}

function parsepatientstatus_date(){
    var input=document.getElementById('patientstatus_date').value;
    year="";
    month="";
    day="";
    if (input != ""){
    const myArr = input.split("-");
        year = myArr[0];
        month = myArr[1];
        day = myArr[2];
    }
    console.log("psdate="+year+"-"+month+"-"+day);
        document.getElementById('patientstatus_date_year').value = year
        document.getElementById('patientstatus_date_month').value = month
        document.getElementById('patientstatus_date_day').value = day

}

function parsedate_joined(){
    var input=document.getElementById('date_joined').value;
    year="";
    month="";
    day="";
    if (input != ""){
    const myArr = input.split("-");
        year = myArr[0];
        month = myArr[1];
        day = myArr[2];
    }
    console.log("joined="+year+"-"+month+"-"+day);
        document.getElementById('date_joined_year').value = year
        document.getElementById('date_joined_month').value = month
        document.getElementById('date_joined_day').value = day

}
</script>
                <input type="date" id="eff_date" name="eff_date" value="<%=MyDateFormat.getMyStandardDate(demographic.getEffDate())%>"  <%=getDisabled("eff_date_year")%> onchange="parseeff_date();">
                <input type="hidden" name="eff_date_year" id="eff_date_year">
                <input type="hidden" name="eff_date_month" id="eff_date_month">
                <input type="hidden" name="eff_date_day" id="eff_date_day">
            </div>
        </div>

        <div class="control-group">
            <label class="control-label" for="hc_renew_date"><bean:message key="demographic.demographiceditdemographic.formHCRenewDate" /></label>
            <div class="controls">
                <input type="date" id="hc_renew_date" name="hc_renew_date" value="<%=MyDateFormat.getMyStandardDate(demographic.getHcRenewDate())%>" onchange="parsehc_renew_date();" <%=getDisabled("hc_renew_date_year")%>>
                <input type="hidden" name="hc_renew_date_year" id="hc_renew_date_year">
                <input type="hidden" name="hc_renew_date_month" id="hc_renew_date_month">
                <input type="hidden" name="hc_renew_date_day" id="hc_renew_date_day">
            </div>
        </div>
        <div class="control-group">
            <label class="control-label" for="date_joined"><bean:message key="demographic.demographiceditdemographic.formDateJoined1" /></label>
            <div class="controls">
                <input type="date" id="date_joined" name="date_joined" value="<%=MyDateFormat.getMyStandardDate(demographic.getDateJoined())%>" onchange="parsedate_joined();" <%=getDisabled("date_joined_year")%>>
                <input type="hidden" name="date_joined_year" id="date_joined_year">
                <input type="hidden" name="date_joined_month" id="date_joined_month">
                <input type="hidden" name="date_joined_day" id="date_joined_day">
            </div>
        </div>

        <div class="control-group">
            <label class="control-label" for="roster_date" title="<bean:message key="demographic.demographiceditdemographic.DateJoined" />"><bean:message key="demographic.demographiceditdemographic.DateJoined" /></label>
            <div class="controls">
              <input type="date" id="roster_date" name="roster_date" value="<%=MyDateFormat.getMyStandardDate(demographic.getRosterDate())%>"  onchange="parseroster_date();" <%=getDisabled("roster_date_year")%>>
<input  type="hidden" name="roster_date_year" id="roster_date_year">
<input  type="hidden" name="roster_date_month" id="roster_date_month">
<input  type="hidden" name="roster_date_day" id="roster_date_day">
            </div>
        </div>
        <div class="control-group">
            <label class="control-label" for="end_date" ><bean:message key="demographic.demographiceditdemographic.formEndDate" /></label>
            <div class="controls">
              <input type="date" id="end_date" name="end_date" value="<%=MyDateFormat.getMyStandardDate(demographic.getEndDate())%>"  onchange="parseend_date();" <%=getDisabled("end_date_year")%>>
<input type="hidden" name="end_date_year" id="end_date_year">
<input type="hidden" name="end_date_month" id="end_date_month">
<input type="hidden" name="end_date_day" id="end_date_day">
            </div>
        </div>


<%-- TOGGLE OFF PATIENT ROSTERING - NOT USED IN ALL PROVINCES. --%>
<oscar:oscarPropertiesCheck property="DEMOGRAPHIC_PATIENT_ROSTERING" value="true">

        <div class="control-group">
            <label class="control-label" for="roster_status"><bean:message key="demographic.demographiceditdemographic.formRosterStatus" /></label>
            <div class="controls">
                <%String rosterStatus = demographic.getRosterStatus();
                     if (rosterStatus == null) {
                         rosterStatus = "";
                     }
                 %>
                <input type="hidden" name="initial_rosterstatus" value="<%=rosterStatus%>"/>
                <select id="roster_status" name="roster_status" style="width: 120px" <%=getDisabled("roster_status")%> onchange="checkRosterStatus2()">
									<option value=""></option>
									<option value="RO"
										<%="RO".equals(rosterStatus)?" selected":""%>>
									<bean:message key="demographic.demographiceditdemographic.optRostered"/></option>
									<!--
									<option value="NR"
										<%=rosterStatus.equals("NR")?" selected":""%>>
									<bean:message key="demographic.demographiceditdemographic.optNotRostered"/></option>
									-->
									<option value="TE"
										<%=rosterStatus.equals("TE")?" selected":""%>>
									<bean:message key="demographic.demographiceditdemographic.optTerminated"/></option>

									<option value="FS"
										<%=rosterStatus.equals("FS")?" selected":""%>>
									<bean:message key="demographic.demographiceditdemographic.optFeeService"/></option>
									<%
									for(String status: demographicDao.getRosterStatuses()) {
									%>
									<option
										<%=rosterStatus.equals(status)?" selected":""%>><%=status%></option>
									<% }

                                   // end while %>
                </select>
                <security:oscarSec roleName="<%=roleName$%>" objectName="_admin.demographic" rights="r" reverse="<%=false%>">
                    <sup><input type="button" class="btn btn-link" onClick="newStatus1();" value="<bean:message key="demographic.demographiceditdemographic.btnAddNew"/>"></sup>
                </security:oscarSec>
            </div>
        </div>

        <div class="control-group">
            <label class="control-label" for="enrolled_to"><bean:message key="demographic.demographiceditdemographic.RosterEnrolledTo" /></label>
            <div class="controls">
                <select name="roster_enrolled_to" <%=getDisabled("roster_enrolled_to")%>
									id="enrolled_to">
									<option value=""></option>
									<%
									for(Provider p : doctors) {
                     			   %>
									<option value="<%=p.getProviderNo()%>"
										<%=p.getProviderNo().equals(demographic.getRosterEnrolledTo())?"selected":""%>>
									<%=p.getLastName()+","+p.getFirstName()%></option>
									<% } %>
				</select>
            </div>
        </div>
        <div class="control-group">
            <label class="control-label" for="roster_termination_date"><bean:message key="demographic.demographiceditdemographic.RosterTerminationDate" /></label>
            <div class="controls">
              <input type="date" id="roster_termination_date" name="roster_termination_date" value="<%=MyDateFormat.getMyStandardDate(demographic.getRosterTerminationDate())%>" onchange="parseroster_termination_date();" <%=getDisabled("roster_termination_date_year")%>>
<input  type="hidden" name="roster_termination_date_year" id="roster_termination_date_year">
<input  type="hidden" name="roster_termination_date_month" id="roster_termination_date_month">
<input  type="hidden" name="roster_termination_date_day" id="roster_termination_date_day">
            </div>
        </div>
        <div class="control-group">
            <label class="control-label" for="roster_termination_reason"><bean:message key="demographic.demographiceditdemographic.RosterTerminationReason" /></label>
            <div class="controls">
                <select  name="roster_termination_reason" id="roster_termination_reason">
				    <option value="">N/A</option>
                <%for (String code : Util.rosterTermReasonProperties.getTermReasonCodes()) { %>
					<option value="<%=code %>" <%=code.equals(demographic.getRosterTerminationReason())?"selected":"" %> ><%=Util.rosterTermReasonProperties.getReasonByCode(code) %></option>
                <%} %>
                </select>
            </div>
        </div>

</oscar:oscarPropertiesCheck>
<%-- END TOGGLE OFF PATIENT ROSTERING --%>
        <div class="control-group">
            <label class="control-label" for="pstatus"><bean:message key="demographic.demographiceditdemographic.formPatientStatus" /></label>
            <div class="controls">
								<%
                                String patientStatus = demographic.getPatientStatus();
                                 if(patientStatus==null) patientStatus="";%>
                                <input type="hidden" name="initial_patientstatus" value="<%=patientStatus%>">
								<select name="patient_status" id="pstatus" style="width: 120" <%=getDisabled("patient_status")%> onChange="updatePatientStatusDate()">
									<option value="AC"
										<%="AC".equals(patientStatus)?" selected":""%>>
									<bean:message key="demographic.demographiceditdemographic.optActive"/></option>
									<option value="IN"
										<%="IN".equals(patientStatus)?" selected":""%>>
									<bean:message key="demographic.demographiceditdemographic.optInActive"/></option>
									<option value="DE"
										<%="DE".equals(patientStatus)?" selected":""%>>
									<bean:message key="demographic.demographiceditdemographic.optDeceased"/></option>
									<option value="MO"
										<%="MO".equals(patientStatus)?" selected":""%>>
									<bean:message key="demographic.demographiceditdemographic.optMoved"/></option>
									<option value="FI"
										<%="FI".equals(patientStatus)?" selected":""%>>
									<bean:message key="demographic.demographiceditdemographic.optFired"/></option>
									<%
									for(String status : demographicDao.search_ptstatus()) {
                                     %>
									<option
										<%=status.equals(patientStatus)?" selected":""%>><%=status%></option>
									<% }

                                   // end while %>
								</select>
                        <security:oscarSec roleName="<%=roleName$%>" objectName="_admin.demographic" rights="r" reverse="<%=false%>">
                                 <sup><input type="button" class="btn btn-link" onClick="newStatus();" value="<bean:message key="demographic.demographiceditdemographic.btnAddNew"/>"></sup>
						</security:oscarSec>
            </div>
        </div>
        <div class="control-group">
            <label class="control-label" for="patientstatus_date"><bean:message key="demographic.demographiceditdemographic.PatientStatusDate" /></label>
            <div class="controls">
                <input type="date" id="patientstatus_date" name="patientstatus_date" onchange="parsepatientstatus_date();" value="<%=MyDateFormat.getMyStandardDate(demographic.getPatientStatusDate())%>">
<input type="hidden" name="patientstatus_date_year" id="patientstatus_date_year">
<input type="hidden" name="patientstatus_date_month" id="patientstatus_date_month">
<input type="hidden" name="patientstatus_date_day" id="patientstatus_date_day">
            </div>
        </div><br>
        </div><!-- end insuranceSectionContent -->
</div><!-- end insurance -->

<%-- TOGGLE OFF PATIENT CLINIC STATUS --%>
<oscar:oscarPropertiesCheck property="DEMOGRAPHIC_PATIENT_CLINIC_STATUS" value="true">
    <div id="team" class="span11 accordion-group"><!--Care Team -->
		<fieldset class="accordion-heading" title="<bean:message key="global.btnToggle"/>">
			<legend class="accordion-toggle" data-toggle="collapse" data-parent="#editWrapper" data-target="#teamSectionContent">
			    <bean:message key="web.record.details.careTeam" />
                <i class="icon-edit" style="float: right; margin-top: 10px;" title="<bean:message key="demographic.demographiceditdemographic.msgEdit"/>"></i>
            </legend>
		</fieldset>
        <div id="teamSectionContent" class="accordion-body collapse" >
        <div class="control-group">
            <label class="control-label" for="mrp"><% if(oscarProps.getProperty("demographicLabelDoctor") != null) { out.print(oscarProps.getProperty("demographicLabelDoctor","")); } else { %>
								<bean:message key="demographic.demographiceditdemographic.formMRP" />
								<% } %></label>
            <div class="controls">
                <select name="provider_no" <%=getDisabled("provider_no")%> id="mrp">
                    <option value=""></option>
                        <%
							for(Provider p : doctors) {
                        %>
							<option value="<%=p.getProviderNo()%>"
						    <%=p.getProviderNo().equals(demographic.getProviderNo())?"selected":""%>>
						    <%=p.getLastName()+","+p.getFirstName()%></option>
						    <% } %>
			    </select>
            </div>
        </div>
        <div class="control-group">
            <label class="control-label" for="rn"><bean:message key="demographic.demographiceditdemographic.formNurse" /></label>
            <div class="controls">
              <select name="nurse" id="rn" <%=getDisabled("nurse")%>>
                <option value=""></option>
				    <%
					    for(Provider p : nurses) {
                        %>
						    <option value="<%=p.getProviderNo()%>"
							    <%=p.getProviderNo().equals(nurse)?"selected":""%>>
							    <%=p.getLastName()+","+p.getFirstName()%></option>
						    <% } %>
			    </select>
            </div>
        </div>
        <div class="control-group">
            <label class="control-label" for="mw"><bean:message key="demographic.demographiceditdemographic.formMidwife" /></label>
            <div class="controls">
              <select name="midwife" id="mw" <%=getDisabled("midwife")%>>
                <option value=""></option>
				    <%
					    for(Provider p : midwifes) {
                        %>
						<option value="<%=p.getProviderNo()%>"
						<%=p.getProviderNo().equals(midwife)?"selected":""%>>
						<%=p.getLastName()+","+p.getFirstName()%></option>
						<% } %>
			    </select>
            </div>
        </div>
        <div class="control-group">
            <label class="control-label" for="resident"><bean:message key="demographic.demographiceditdemographic.formResident" /></label>
            <div class="controls">
              <select name="resident" id="resident" <%=getDisabled("resident")%>>
                <option value=""></option>
				    <%
					    for(Provider p : doctors) {
                        %>
						<option value="<%=p.getProviderNo()%>"
						<%=p.getProviderNo().equals(resident)?"selected":""%>>
						<%=p.getLastName()+","+p.getFirstName()%></option>
						<% } %>
			    </select>
            </div>
        </div>
        <div class="control-group">
            <label class="control-label" for="r_doc"><bean:message key="demographic.demographiceditdemographic.formRefDoc" /></label>
            <div class="controls">
              <% if(!oscarProps.getProperty("isMRefDocSelectList", "").equals("false") ) {
                    // drop down list
					Properties prop = null;
					Vector vecRef = new Vector();
					List<ProfessionalSpecialist> specialists = professionalSpecialistDao.findAll();
                    for(ProfessionalSpecialist specialist : specialists) {
                         prop = new Properties();
                         if (specialist != null && specialist.getReferralNo() != null && ! specialist.getReferralNo().equals("")) {
	                          prop.setProperty("referral_no", specialist.getReferralNo());
	                          prop.setProperty("last_name", specialist.getLastName());
	                          prop.setProperty("first_name", specialist.getFirstName());
	                          vecRef.add(prop);
                         }
                     }

             %> <select name="r_doctor" <%=getDisabled("r_doctor")%>
					onChange="changeRefDoc()" id="r_doc">
					<option value=""></option>
					<% for(int k=0; k<vecRef.size(); k++) {
                         prop= (Properties) vecRef.get(k);
                    %>
					<option
						value="<%=prop.getProperty("last_name")+","+prop.getProperty("first_name")%>"
						<%=prop.getProperty("referral_no").equals(rdohip)?"selected":""%>>
					    <%=prop.getProperty("last_name")+","+prop.getProperty("first_name")%></option>
					<% } %>
                </select>
<script type="text/javascript" language="Javascript">
    <!--
        function changeRefDoc() {
            console.log(document.updatedelete.r_doctor.value);
            var refName = document.updatedelete.r_doctor.options[document.updatedelete.r_doctor.selectedIndex].value;
            var refNo = "";
              	<% for(int k=0; k<vecRef.size(); k++) {
              		prop= (Properties) vecRef.get(k);
              	%>
            if(refName=="<%=prop.getProperty("last_name")+","+prop.getProperty("first_name")%>") {
              refNo = '<%=prop.getProperty("referral_no", "")%>';
            }
            <% } %>
            document.updatedelete.r_doctor_ohip.value = refNo;
        }
    //-->
</script> <% } else {%>
                <input type="text" name="r_doctor" id="r_doctor" <%=getDisabled("r_doctor")%> value="<%=rd%>"> <% } %>
            </div>
        </div>
        <div class="control-group">
            <label class="control-label" for="r_doctor_ohip"><bean:message key="demographic.demographiceditdemographic.formRefDocNo" /></label>
            <div class="controls">
              <input type="text" name="r_doctor_ohip" id="r_doctor_ohip" <%=getDisabled("r_doctor_ohip")%>
					value="<%=rdohip%>"> <% if("ON".equals(prov)) { %>
					    <sup><a class="btn btn-link" href="javascript:referralScriptAttach2('r_doctor_ohip','r_doctor')">
                        <bean:message key="demographic.demographiceditdemographic.btnSearch"/>#</a> </sup>
                    <% } %>
            </div>
        </div><br>
    </div><!-- end teamSectionContent -->
    </div><!-- end Team -->
</oscar:oscarPropertiesCheck>
<%-- END TOGGLE OFF PATIENT CLINIC STATUS --%>
<%-- WAITING LIST MODULE --%>
        <oscar:oscarPropertiesCheck property="DEMOGRAPHIC_WAITING_LIST" value="true">
         <div id="wl" class="span11 accordion-group">
		<fieldset class="accordion-heading" title="<bean:message key="global.btnToggle"/>">
			<legend class="accordion-toggle" data-toggle="collapse" data-parent="#editWrapper" data-target="#wlSectionContent">
			    <bean:message key="demographic.demographiceditdemographic.msgWaitList"/>
                <i class="icon-edit" style="float: right; margin-top: 10px;" title="<bean:message key="demographic.demographiceditdemographic.msgEdit"/>"></i>
            </legend>
		</fieldset>
        <div id="wlSectionContent" class="accordion-body collapse" >

        <div id="wlSectionContent" class="accordion-body collapse" >
            <div class="control-group">
                <label class="control-label" for="list_id"><bean:message key="demographic.demographiceditdemographic.msgWaitList"/></label>
                <div class="controls">
                    <%

										List<org.oscarehr.common.model.WaitingList> wls = waitingListDao.search_wlstatus(Integer.parseInt(demographic_no));

 	                        String wlId="", listID="", wlnote="";
 	                        String wlReferralDate="";
                                if (wls.size()>0){
                                	org.oscarehr.common.model.WaitingList wl = wls.get(0);
                                    wlId = wl.getId().toString();
                                    listID =String.valueOf(wl.getListId());
                                    wlnote =wl.getNote();
                                    wlReferralDate =oscar.util.ConversionUtils.toDateString(wl.getOnListSince());
                                    if(wlReferralDate != null  &&  wlReferralDate.length()>10){
                                        wlReferralDate = wlReferralDate.substring(0, 11);
                                    }
                                }

                               %>
                    <input type="hidden" name="wlId"
											value="<%=wlId%>">
                    <select name="list_id" id="list_id">
											<%if("".equals(wLReadonly)){%>
											<option value="0"><bean:message key="demographic.demographiceditdemographic.optSelectWaitList"/></option>
											<%}else{%>
											<option value="0">
											<bean:message key="demographic.demographiceditdemographic.optCreateWaitList"/></option>
											<%} %>
											<%

									List<WaitingListName> wlns = waitingListNameDao.findCurrentByGroup(((org.oscarehr.common.model.ProviderPreference)session.getAttribute(org.oscarehr.util.SessionConstants.LOGGED_IN_PROVIDER_PREFERENCE)).getMyGroupNo());
                                     for(WaitingListName wln:wlns) {
                                    %>
											<option value="<%=wln.getId()%>"
												<%=wln.getId().toString().equals(listID)?" selected":""%>>
											<%=wln.getName()%></option>
											<%
                                      }

                                    %>
                    </select>
                </div>
            </div>
            <div class="control-group">
                <label class="control-label" for="wlnote"><bean:message key="demographic.demographiceditdemographic.msgWaitListNote"/></label>
                <div class="controls">
                    <input type="text" id="wlnote" placeholder="<bean:message key="demographic.demographiceditdemographic.msgWaitListNote"/>"
                        name="waiting_list_note" value="<%=wlnote%>" <%=wLReadonly%>>
                </div>
            </div>
            <div class="control-group">
                <label class="control-label" for="waiting_list_referral_date"><bean:message key="demographic.demographiceditdemographic.msgDateOfReq"/></label>
                <div class="controls">
                    <input type="date" title="<bean:message key="demographic.demographiceditdemographic.msgWaitListNote"/>"
                        name="waiting_list_referral_date"
						id="waiting_list_referral_date"
						value="<%=wlReferralDate%>" <%=wLReadonly%>>
                </div>
            </div>
    </div><!--end wlContentSection -->
    </div>
	</div><!--end wl -->
        </oscar:oscarPropertiesCheck>
<%-- END WAITING LIST MODULE --%>
    <div id="additional" class="span11 accordion-group"><!--additional -->
		<fieldset class="accordion-heading" title="<bean:message key="global.btnToggle"/>">
			<legend class="accordion-toggle" data-toggle="collapse" data-parent="#editWrapper" data-target="#additionalSectionContent">
			    <bean:message key="web.record.details.addInformation" />
                <i class="icon-edit" style="float: right; margin-top: 10px;" title="<bean:message key="demographic.demographiceditdemographic.msgEdit"/>"></i>
            </legend>
		</fieldset>
        <div id="additionalSectionContent" class="accordion-body collapse" >
        <div class="control-group">
            <label class="control-label" for="cyto"><bean:message key="demographic.demographiceditdemographic.cytolNum" /></label>
            <div class="controls">
              <input type="text" id="cyto" placeholder="<bean:message key="demographic.demographiceditdemographic.cytolNum" />"
                    name="cytolNum" <%=getDisabled("cytolNum")%>
					value="<%=StringUtils.trimToEmpty(demoExt.get("cytolNum"))%>">
			    <input type="hidden" name="cytolNumOrig"
					value="<%=StringUtils.trimToEmpty(demoExt.get("cytolNum"))%>" />
            </div>
        </div>
 <%if(!"true".equals(OscarProperties.getInstance().getProperty("phu.hide","false"))) { %>
        <div class="control-group">
            <label class="control-label" for="PHU"><bean:message key="demographic.demographiceditdemographic.formPHU" /></label>
            <div class="controls">
                <select id="PHU" name="PHU" >
					<option value="">Select Below</option>
					<%
					if(ll != null) {
							for(LookupListItem llItem : ll.getItems()) {
									String selected = "";
									if(llItem.getValue().equals(StringUtils.trimToEmpty(demoExt.get("PHU")))) {
											selected = " selected=\"selected\" ";
									}
					%>
					<option value="<%=llItem.getValue()%>" <%=selected%>><%=llItem.getLabel()%></option>
					<%
							}
					}

					%>
                </select>
            </div>
        </div>
    <% } else { %>
        <input type="hidden" name="PHU" value=""/></td>
    <% } %>
        <div class="control-group">
            <label class="control-label" for="chart_no"><bean:message key="demographic.demographiceditdemographic.formChartNo" /></label>
            <div class="controls">
                <input type="text" id="chart_no" name="chart_no" placeholder="<bean:message key="demographic.demographiceditdemographic.formChartNo" />" value="<%=StringUtils.trimToEmpty(demographic.getChartNo())%>" <%=getDisabled("chart_no")%>>
            </div>
        </div>
        <div class="control-group">
            <label class="control-label" for="paper_chart_archived"><bean:message key="web.record.details.archivedPaperChart" /></label>
            <div class="controls">
                	<%
	                            		String paperChartIndicator = StringUtils.trimToEmpty(demoExt.get("paper_chart_archived"));
	                            		String paperChartIndicatorDate = StringUtils.trimToEmpty(demoExt.get("paper_chart_archived_date"));
	                            		String paperChartIndicatorProgram = StringUtils.trimToEmpty(demoExt.get("paper_chart_archived_program"));
	                 %>
	             <select name="paper_chart_archived" id="paper_chart_archived" style="width:50px;"<%=getDisabled("paper_chart_archived")%> onChange="updatePaperArchive()">
		            <option value="" <%="".equals(paperChartIndicator)?" selected":""%>>
		                            	</option>
					<option value="NO" <%="NO".equals(paperChartIndicator)?" selected":""%>>
											<bean:message key="demographic.demographiceditdemographic.paperChartIndicator.no"/>
										</option>
					<option value="YES"	<%="YES".equals(paperChartIndicator)?" selected":""%>>
											<bean:message key="demographic.demographiceditdemographic.paperChartIndicator.yes"/>
										</option>
				</select>
                <input type="date" name="paper_chart_archived_date" class="input-medium" id="paper_chart_archived_date" value="<%=paperChartIndicatorDate%>" >
				<input type="hidden" name="paper_chart_archived_program" id="paper_chart_archived_program" value="<%=paperChartIndicatorProgram%>"/>
            </div>
        </div>
<c:forEach items="${ consentTypes }" var="consentType" varStatus="count">
					<c:set var="patientConsent" value="" />
					<c:forEach items="${ patientConsents }" var="consent" >
						<c:if test="${ consent.consentType.id eq consentType.id }">
							<c:set var="patientConsent" value="${ consent }" />
						</c:if>
					</c:forEach>

        <div class="control-group"  title="${ consentType.description }">
            <label class="control-label" for="consent_${ count.index }"><c:out value="${ consentType.name }" /></label>

							<c:if test="${ not empty patientConsent and not empty patientConsent.optout }" >
								<c:choose>
									<c:when test="${ patientConsent.optout }">
										<div id="consentDate_${consentType.type}" style="color:red;white-space:nowrap;">
											Opted Out:<c:out value="${ patientConsent.optoutDate }" />
										</div>
									</c:when>
									<c:otherwise>
										<div id="consentDate_${consentType.type}" style="color:green;white-space:nowrap;">
											Consented:<c:out value="${ patientConsent.consentDate }" />
										</div>
									</c:otherwise>
								</c:choose>
							</c:if>
            <div class="controls" style="white-space:nowrap;" >
                <input type="hidden" id="consent_${ count.index }" >
				<input type="radio"
                                   name="${ consentType.type }"
                                   id="optin_${ consentType.type }"
                                   value="0"
                                   <c:if test="${ not empty patientConsent and not empty patientConsent.optout and not patientConsent.optout }">
                                       <c:out value="checked" />
                                   </c:if>
                            />
                            <bean:message key="global.optin"/>
                            <input type="radio"
                                   name="${ consentType.type }"
                                   id="optout_${ consentType.type }"
                                   value="1"
                                   <c:if test="${ not empty patientConsent and not empty patientConsent.optout and patientConsent.optout }">
                                       <c:out value="checked" />
                                   </c:if>
                            />
                             <bean:message key="global.optout"/>
                            <input type="button" class="btn btn-link"
                                   name="clearRadio_${consentType.type}_btn"
                                   onclick="consentClearBtn('${consentType.type}')" value="<bean:message key="global.clear"/>" />

                            <%-- Was this consent set by the user? Or by the database?  --%>
                            <input type="hidden" name="consentPreset_${consentType.type}" id="consentPreset_${consentType.type}"
                            	value="${ not empty patientConsent }" />

                            <%-- This consent will be labeled for delete when the clear button is clicked. --%>
                            <input type="hidden" name="deleteConsent_${consentType.type}" id="deleteConsent_${consentType.type}" value="0" />
            </div>
        </div>

				</c:forEach>
        <div class="control-group">
            <label class="control-label" for="meditech_id">Meditech ID</label>
            <div class="controls">
                <input type="text" id="meditech_id" placeholder="Meditech ID"
                    name="meditech_id"
					value="<%=OtherIdManager.getDemoOtherId(demographic_no, "meditech_id")%>">
                <input type="hidden" name="meditech_idOrig"
					value="<%=OtherIdManager.getDemoOtherId(
					demographic_no, "meditech_id")%>">
            </div>
        </div>
        <div class="control-group">
            <label class="control-label" for="rxInteractionWarningLevel"><bean:message key="demographic.demographiceditdemographic.rxInteractionWarningLevel" /></label>
            <div class="controls">
                <input type="hidden" name="rxInteractionWarningLevelOrig"
							value="<%=StringUtils.trimToEmpty(demoExt.get("rxInteractionWarningLevel"))%>" />
			<select id="rxInteractionWarningLevel" name="rxInteractionWarningLevel">
				<option value="0" <%=(warningLevel.equals("0")?"selected=\"selected\"":"") %>>Not Specified</option>
				<option value="1" <%=(warningLevel.equals("1")?"selected=\"selected\"":"") %>>Low</option>
				<option value="2" <%=(warningLevel.equals("2")?"selected=\"selected\"":"") %>>Medium</option>
				<option value="3" <%=(warningLevel.equals("3")?"selected=\"selected\"":"") %>>High</option>
				<option value="4" <%=(warningLevel.equals("4")?"selected=\"selected\"":"") %>>None</option>
			</select>
            </div>
        </div>

<%-- TOGGLED OFF PROGRAM ADMISSIONS --%>
        <oscar:oscarPropertiesCheck property="DEMOGRAPHIC_PROGRAM_ADMISSIONS" value="true">
                <div class="control-group">
                    <label class="control-label" for="rsid"><bean:message key="demographic.demographiceditdemographic.programAdmissions" /></label>
                    <div class="controls">
                        <select id="rsid" name="rps">
                            <option value=""></option>
                                <%
                                GenericIntakeEditAction gieat = new GenericIntakeEditAction();
                                gieat.setProgramManager(pm);
                                String _pvid =loggedInInfo.getLoggedInProviderNo();
                                Set<Program> pset = gieat.getActiveProviderProgramsInFacility(loggedInInfo,_pvid,loggedInInfo.getCurrentFacility().getId());
                                List<Program> bedP = gieat.getBedPrograms(pset,_pvid);
                                List<Program> commP = gieat.getCommunityPrograms();
                              	Program oscarp = programDao.getProgramByName("OSCAR");
                                for(Program _p:bedP){
                                %>
                            <option value="<%=_p.getId()%>" <%=isProgramSelected(bedAdmission, _p.getId()) %>><%=_p.getName()%></option>
                                <%
                                    }
                                %>
                        </select>
                    </div>
                </div>
                <div class="control-group">
                    <label class="control-label" for="sp"><bean:message key="demographic.demographiceditdemographic.servicePrograms" /></label>
                    <div class="controls">
			                    <%
			                    	ProgramManager programManager = SpringUtils.getBean(ProgramManager.class);
			                    	List<Program> servP = programManager.getServicePrograms();

			                        for(Program _p:servP){
			                        	boolean readOnly=false;
			                        	if(!pset.contains(_p)) {
			                        		readOnly=true;
			                        	}
			                        	String selected = isProgramSelected(serviceAdmissions, _p.getId());

			                        	if(readOnly && selected.length() == 0) {
			                        		continue;
			                        	}

			                    %>
			                        <input type="checkbox" name="sp" value="<%=_p.getId()%>" <%=selected %> <%=(readOnly)?" disabled=\"disabled\" ":"" %> />
			                        <%=_p.getName()%>
			                    <%}%>
                    </div>
                </div>
        </oscar:oscarPropertiesCheck>
<%-- END TOGGLE OFF PROGRAM ADMISSIONS --%>

        <oscar:oscarPropertiesCheck property="INTEGRATOR_LOCAL_STORE" value="yes">
                <div class="control-group">
                    <label class="control-label" for="primaryEMR"><bean:message key="demographic.demographiceditdemographic.primaryEMR" /></label>
                    <div class="controls">
                        <input type="hidden" name="rxInteractionWarningLevelOrig"
							        value="<%=StringUtils.trimToEmpty(demoExt.get("rxInteractionWarningLevel"))%>" />
		            <%
		               	String primaryEMR = demoExt.get("primaryEMR");
		               	if(primaryEMR==null) primaryEMR="0";
		            %>
			        <input type="hidden" name="primaryEMROrig" value="<%=StringUtils.trimToEmpty(demoExt.get("primaryEMR"))%>" />
			        <select id="primaryEMR" name="primaryEMR">
				        <option value="0" <%=(primaryEMR.equals("0")?"selected=\"selected\"":"") %>>No</option>
				        <option value="1" <%=(primaryEMR.equals("1")?"selected=\"selected\"":"") %>>Yes</option>
			        </select>
                    </div>
                </div>

		</oscar:oscarPropertiesCheck>
<%-- PATIENT NOTES MODULE --%>

        <div class="control-group span10">
            <label class="control-label" for="inputAlert">
                <span style="color:red"><bean:message key="demographic.demographiceditdemographic.formAlert" /></span>
            </label>
            <div class="controls">
                <textarea name="alert" id="inputAlert" class="span7" ><%=alert%></textarea>
            </div>
        </div>
        <div class="control-group span10">
            <label class="control-label" for="inputNote"><bean:message key="demographic.demographiceditdemographic.formNotes" /></label>
            <div class="controls">
                <textarea name="notes" id="inputNote" class="span7" ><%=Encode.forHtmlContent(notes) %></textarea>
            </div>
        </div>
<%-- END PATIENT NOTES MODULE --%>
        </div><!--end additionalContentSection -->
    </div><!--end additional -->

</div><!--end editWrapper -->

<table id="editDemographic" style="width:100%; display: none;">

<%
								java.text.SimpleDateFormat sdf = new java.text.SimpleDateFormat("yyyy-MM-dd");
								String effDate=null;
								if(demographic.getEffDate() != null) {
									effDate=StringUtils.trimToNull(sdf.format(demographic.getEffDate()));
								}

%>



<%-- TOGGLE PATIENT PRIVACY CONSENT --%>


<%-- END TOGGLE OFF PATIENT PRIVACY CONSENT --%>

<%-- TOGGLE MEDITECH MODULE --%>
<% if (oscarProps.isPropertyActive("meditech_id")) { %>

												<%
													}
												%>
<%-- END TOGGLE OFF MEDITECH MODULE --%>

<%-- TOGGLE OFF EXTRA DEMO FIELDS (NATIVE HEALTH) --%>
<%
								if (oscarProps.getProperty("EXTRA_DEMO_FIELDS") != null) {
												String fieldJSP = oscarProps
														.getProperty("EXTRA_DEMO_FIELDS");
												fieldJSP += ".jsp";
							%>
	<jsp:include page="<%=fieldJSP%>">
		<jsp:param name="demo" value="<%=demographic_no%>" />
	</jsp:include>
<%}%>

<%-- END TOGGLE OFF EXTRA DEMO FIELDS (NATIVE HEALTH) --%>

<%-- AUTHOR DENNIS WARREN O/A COLCAMEX RESOURCES --%>
<oscar:oscarPropertiesCheck property="DEMOGRAPHIC_PATIENT_HEALTH_CARE_TEAM" value="true">
	<tr><td colspan="4" >
		<jsp:include page="manageHealthCareTeam.jsp">
			<jsp:param name="demographicNo" value="<%= demographic_no %>" />
		</jsp:include>
	</td></tr>
</oscar:oscarPropertiesCheck>
<%-- END AUTHOR DENNIS WARREN O/A COLCAMEX RESOURCES --%>



<% // customized key + "Has Primary Care Physician" & "Employment Status"
	if (hasHasPrimary || hasEmpStatus) {
%>							<tr valign="top" bgcolor="#CCCCFF">
<%		if (hasHasPrimary) {
%>								<td><b><%=hasPrimary.replace(" ", "&nbsp;")%>:</b></td>
								<td>
									<select name="<%=hasPrimary.replace(" ", "")%>">
										<option value="N/A" <%="N/A".equals(hasPrimaryCarePhysician)?"selected":""%>>N/A</option>
										<option value="Yes" <%="Yes".equals(hasPrimaryCarePhysician)?"selected":""%>>Yes</option>
										<option value="No" <%="No".equals(hasPrimaryCarePhysician)?"selected":""%>>No</option>
									</select>
								</td>
<%		}
		if (hasEmpStatus) {
%>								<td><b><%=empStatus.replace(" ", "&nbsp;")%>:</b></td>
								<td>
									<select name="<%=empStatus.replace(" ", "")%>">
										<option value="N/A" <%="N/A".equals(employmentStatus)?"selected":""%>>N/A</option>
										<option value="FULL TIME" <%="FULL TIME".equals(employmentStatus)?"selected":""%>>FULL TIME</option>
										<option value="ODSP" <%="ODSP".equals(employmentStatus)?"selected":""%>>ODSP</option>
										<option value="OW" <%="OW".equals(employmentStatus)?"selected":""%>>OW</option>
										<option value="PART TIME" <%="PART TIME".equals(employmentStatus)?"selected":""%>>PART TIME</option>
										<option value="UNEMPLOYED" <%="UNEMPLOYED".equals(employmentStatus)?"selected":""%>>UNEMPLOYED</option>
									</select>
								</td>
							</tr>
<%		}
	}
if (hasDemoExt) {
    boolean bExtForm = oscarProps.getProperty("demographicExtForm") != null ? true : false;
    String [] propDemoExtForm = bExtForm ? (oscarProps.getProperty("demographicExtForm","").split("\\|") ) : null;
	for(int k=0; k<propDemoExt.length; k=k+2) {
%>
							<tr valign="top">
								<td align="right" nowrap><b><%=propDemoExt[k]%>: </b></td>
								<td align="left">
								<% if(bExtForm) {
                                  	if(propDemoExtForm[k].indexOf("<select")>=0) {
                                		out.println(propDemoExtForm[k].replaceAll("value=\""+StringUtils.trimToEmpty(demoExt.get(propDemoExt[k].replace(' ', '_')))+"\"" , "value=\""+StringUtils.trimToEmpty(demoExt.get(propDemoExt[k].replace(' ', '_')))+"\"" + " selected") );
                                  	} else {
                              			out.println(propDemoExtForm[k].replaceAll("value=\"\"", "value=\""+StringUtils.trimToEmpty(demoExt.get(propDemoExt[k].replace(' ', '_')))+"\"" ) );
                                  	}
                              	 } else { %> <input type="text"
									name="<%=propDemoExt[k].replace(' ', '_')%>"
									value="<%=StringUtils.trimToEmpty(demoExt.get(propDemoExt[k].replace(' ', '_')))%>" />
								<% }  %> <input type="hidden"
									name="<%=propDemoExt[k].replace(' ', '_')%>Orig"
									value="<%=StringUtils.trimToEmpty(demoExt.get(propDemoExt[k].replace(' ', '_')))%>" />
								</td>
								<% if((k+1)<propDemoExt.length) { %>
								<td align="right" nowrap><b>
								<%out.println(propDemoExt[k+1]+":");%> </b></td>
								<td align="left">
								<% if(bExtForm) {
                                  	if(propDemoExtForm[k+1].indexOf("<select")>=0) {
                                		out.println(propDemoExtForm[k+1].replaceAll("value=\""+StringUtils.trimToEmpty(demoExt.get(propDemoExt[k+1].replace(' ', '_')))+"\"" , "value=\""+StringUtils.trimToEmpty(demoExt.get(propDemoExt[k+1].replace(' ', '_')))+"\"" + " selected") );
                                  	} else {
                              			out.println(propDemoExtForm[k+1].replaceAll("value=\"\"", "value=\""+StringUtils.trimToEmpty(demoExt.get(propDemoExt[k+1].replace(' ', '_')))+"\"" ) );
                                  	}
                              	 } else { %> <input type="text"
									name="<%=propDemoExt[k+1].replace(' ', '_')%>"
									value="<%=StringUtils.trimToEmpty(demoExt.get(propDemoExt[k+1].replace(' ', '_')))%>" />
								<% }  %> <input type="hidden"
									name="<%=propDemoExt[k+1].replace(' ', '_')%>Orig"
									value="<%=StringUtils.trimToEmpty(demoExt.get(propDemoExt[k+1].replace(' ', '_')))%>" />
								</td>
								<% } else {%>
								<td>&nbsp;</td>
								<td>&nbsp;</td>
								<% }  %>
							</tr>
							<% 	}
}
if(oscarProps.getProperty("demographicExtJScript") != null) { out.println(oscarProps.getProperty("demographicExtJScript")); }
%>




<%-- BOTTOM TOOLBAR  --%>
					<tr class="xdarkPurple">
						<td colspan="1" style="white-space:nowrap; padding-left:20px;">


								<input type="hidden" name="dboperation" value="update_record">
								<input type="hidden" name="displaymode" value="Update Record">
								<!-- security code block --> <span id="updateButton"
									style="display: none;"> <security:oscarSec
									roleName="<%=roleName$%>" objectName="_demographic" rights="w">
									<%
										boolean showCbiReminder=oscarProps.getBooleanProperty("CBI_REMIND_ON_UPDATE_DEMOGRAPHIC", "true");
									%>
									<input type="submit" <%=(showCbiReminder?"onclick='showCbiReminder()'":"")%> class="btn btn-primary"
										id="updaterecord2" value="<bean:message key="demographic.demographiceditdemographic.btnUpdate"/>">
										<input type="submit" name="submit" <%=(showCbiReminder?"onclick='showCbiReminder()'":"")%> class="btn"
											   value="<bean:message key="demographic.demographiceditdemographic.btnSaveUpdateFamilyMember"/>">
								</security:oscarSec> </span> <!-- security code block -->


</td><td>
    <div class="dropdowns">
        <button class="dropbtns btn" ><bean:message key="demographic.demographiceditdemographic.btnLabels"/> <span class="caret"></span></button>
		    <div class="dropdowns-content">
                <a href="#" onclick="popupPage(400,700,'<%=printEnvelope%><%=demographic.getDemographicNo()%>');return false;">
			    <bean:message key="demographic.demographiceditdemographic.btnCreatePDFEnvelope"/></a>
                <a href="#" onclick="popupPage(400,700,'<%=printLbl%><%=demographic.getDemographicNo()%>');return false;">
			    <bean:message key="demographic.demographiceditdemographic.btnCreatePDFLabel"/></a>
                <a href="#" onclick="popupPage(400,700,'<%=printAddressLbl%><%=demographic.getDemographicNo()%>');return false;">
			    <bean:message key="demographic.demographiceditdemographic.btnCreatePDFAddressLabel"/></a>
		        <a href="#" onclick="popupPage(400,700,'<%=printChartLbl%><%=demographic.getDemographicNo()%>');return false;">
			    <bean:message key="demographic.demographiceditdemographic.btnCreatePDFChartLabel"/></a>
		        <a href="#" onclick="popupPage(400,700,'<%=printSexHealthLbl%><%=demographic.getDemographicNo()%>');return false;">
			    <bean:message key="demographic.demographiceditdemographic.btnCreatePublicHealthLabel"/></a>
		        <a href="#" onclick="popupPage(600,800,'<%=printHtmlLbl%><%=demographic.getDemographicNo()%>');return false;">
			    <bean:message key="demographic.demographiceditdemographic.btnPrintLabel"/></a>
		        <a href="#" onclick="popupPage(400,700,'<%=printLabLbl%><%=demographic.getDemographicNo()%>');return false;">
			    <bean:message key="demographic.demographiceditdemographic.btnClientLabLabel"/></a>
            </div>
    </div>

								 <security:oscarSec roleName="<%=roleName$%>" objectName="_demographicExport" rights="r" reverse="<%=false%>">
								<input type="button" class="btn" value="<bean:message key="demographic.demographiceditdemographic.msgExport"/>"
									onclick="window.open('demographicExport.jsp?demographicNo=<%=demographic.getDemographicNo()%>');">
								</security:oscarSec>
</td><td>
                                <span
									id="swipeButton" style="display: none;white-space:nowrap;"> <input
									type="button" name="Button" class="btn"
									value="<bean:message key="demographic.demographiceditdemographic.btnSwipeCard"/>"
									onclick="window.open('zdemographicswipe.jsp','', 'scrollbars=yes,resizable=yes,width=600,height=300, top=360, left=0')">
								</span> <!--input type="button" name="Button" value="<bean:message key="demographic.demographiceditdemographic.btnSwipeCard"/>" onclick="javascript:window.alert('Health Card Number Already Inuse');"-->

									    <%
											if(oscarProps.getProperty("showSexualHealthLabel", "false").equals("true")) {
										%>
									<input type="button" size="110" name="Button" class="btn"
									    value="<bean:message key="demographic.demographiceditdemographic.btnCreatePublicHealthLabel"/>"
									    onclick="popupPage(400,700,'<%=printSexHealthLbl%><%=demographic.getDemographicNo()%>');return false;">
									    <% } %>
</td><td>								<input
									type="button" name="Button" id="cancelButton" class="btn btn-link"
									value="<bean:message key="global.btnExit" />"	onclick="self.close();">


<%-- END BOTTOM TOOLBAR  --%>

						<%
							if (ConformanceTestHelper.enableConformanceOnlyTestFeatures)
							{
								String styleBut = "";
								if(ConformanceTestHelper.hasDifferentRemoteDemographics(loggedInInfo, Integer.parseInt(demographic$))){
                                                                       styleBut = " style=\"background-color:yellow\" ";
                                                                }%>
									<input type="button" class="btn" value="Compare with Integrator" <%=styleBut%>  onclick="popup(425, 600, 'DiffRemoteDemographics.jsp?demographicId=<%=demographic$%>', 'RemoteDemoWindow')" />
									<input type="button" class="btn" value="Update latest integrated demographics information" onclick="document.location='<%=request.getContextPath()%>/demographic/copyLinkedDemographicInfoAction.jsp?demographicId=<%=demographic$%>&<%=request.getQueryString()%>'" />
									<input type="button" class="btn" value="Send note to integrated provider" onclick="document.location='<%=request.getContextPath()%>/demographic/followUpSelection.jsp?demographicId=<%=demographic$%>'" />
								<%
							}
						%>
						</td>
					</tr>
				</table>

                                </form>
				<%
                    }
                  }
                %>

		</table>
		</td>
	</tr>
	<tr>
		<td class="MainTableBottomRowLeftColumn"></td>
		<td class="MainTableBottomRowRightColumn"></td>
	</tr>
</table>



<script type="text/javascript">

function callEligibilityWebService(url,id){

       var ran_number=Math.round(Math.random()*1000000);
       var params = "demographic=<%=demographic_no%>&method=checkElig&rand="+ran_number;  //hack to get around ie caching the page
       var response;
       fetch(url+"?"+params, {method:"get"})
       .then(function (response){ return response.text();
       }).then(function(data) {
           document.getElementById(id).innerHTML=data;
           document.getElementById('search_spinner').innerHTML="";
       });

 }

<%
if (privateConsentEnabled) {
%>
jQuery(document).ready(function(){
	var countryOfOrigin = jQuery("#countryOfOrigin").val();
	if("US" != countryOfOrigin) {
		jQuery("#usSigned").hide();
	} else {
		jQuery("#usSigned").show();
	}

	jQuery("#countryOfOrigin").on("change",function () {
		var countryOfOrigin = jQuery("#countryOfOrigin").val();
		if("US" == countryOfOrigin){
		   	jQuery("#usSigned").show();
		} else {
			jQuery("#usSigned").hide();
		}
	});
});
<%
}
%>

jQuery(document).ready(function(){
	//Check if PHR is active and if patient has consented
	/*
	PHR inactive                    FALSE      INACTIVE
	PHR active & Consent Needed     TRUE       NEED_CONSENT
	PHR Active & Consent exists.    TRUE       CONSENTED
	*/
	jQuery.ajax({
		url: "<%=request.getContextPath() %>/ws/rs/app/PHRActive/consentGiven/<%=demographic_no%>",
		dataType: 'json',
		success: function (data) {
			console.log("PHR CONSENT",data);
			if(data.success && data.message === "NEED_CONSENT"){
				jQuery("#phrConsent").show();
			}else{
				jQuery("#phrConsent").hide();
			}
		}
	});

	jQuery.ajax({
		url: "<%=request.getContextPath() %>/ws/rs/app/PHRActive/",
		dataType: 'json',
		success: function (data) {
			console.log("PHR Active",data);
			if(!data.success){
				jQuery("#emailInvite").hide();
			}
		}
	});

	jQuery("#phrConsent").on( "click", function() {
  		jQuery.ajax({
  			type: "POST",
	        url: "<%=request.getContextPath() %>/ws/rs/app/PHRActive/consentGiven/<%=demographic_no%>",
	        dataType: 'json',
	        success: function (data) {
	       		console.log("PHR CONSENT POST",data);
	       		if(data.success && data.message === "NEED_CONSENT"){
	       			jQuery("#phrConsent").show();
	       		}else{
	       			alert("<bean:message key="indivio.successMsg"/>");
	       			jQuery("#phrConsent").hide();
	       		}
	    		}
		});
	});

});



</script>

<script>
    function toggleFrequency() {
        // Get the compliance field and frequency group
        const complianceField = document.getElementById("patient_compliance");
        const frequencyGroup = document.getElementById("frequency-group");
        const frequencyInputs = document.querySelectorAll("input[name='frequency']");

        if (!complianceField || !frequencyGroup) {
            // console.error("Missing elements: Ensure #patient_compliance and #frequency-group exist.");
            return;
        }

        const compliance = complianceField.value;
        // console.log("Compliance value:", compliance); // Debugging log

        // Show or hide frequency group based on compliance value
        if (compliance === "no") {
            frequencyGroup.style.display = "block";
            // console.log("Frequency group shown."); // Debugging log
        } else {
            frequencyGroup.style.display = "none";
            // console.log("Frequency group hidden. Clearing frequency selection."); // Debugging log

            // Clear selected frequency value when hidden
            frequencyInputs.forEach(input => {
                input.checked = false;
            });
        }
    }

    // Ensure the function runs once the page is fully loaded
    document.addEventListener("DOMContentLoaded", function () {
        // Initial toggleFrequency call to set visibility correctly
        toggleFrequency();

        // Attach event listener to the compliance dropdown
        const complianceField = document.getElementById("patient_compliance");
        if (complianceField) {
            complianceField.addEventListener("change", toggleFrequency);
            // console.log("Event listener attached to compliance dropdown."); // Debugging log
        } else {
            // console.error("Compliance dropdown not found."); // Debugging log
        }

        // Add MutationObserver for dynamic visibility of compliance field
        const observer = new MutationObserver(function (mutationsList, observer) {
            const complianceField = document.getElementById("patient_compliance");
            if (complianceField && complianceField.offsetParent !== null) {
                // console.log("Compliance field detected. Attaching event listener.");
                complianceField.addEventListener("change", toggleFrequency);
                toggleFrequency();
                observer.disconnect(); // Stop observing after processing
            }
        });

        // Observe the document body for changes
        observer.observe(document.body, { childList: true, subtree: true });
    });
</script>

<script>
    // Toggle the dropdown menu
document.getElementById('dropdownToggle').addEventListener('click', function (event) {
    event.preventDefault();
    const dropdownMenu = document.getElementById('dropdownMenu');
    dropdownMenu.style.display = dropdownMenu.style.display === 'block' ? 'none' : 'block';

    // Focus on the search box when the dropdown opens
    const searchBox = document.getElementById('dropdownSearch');
    if (searchBox && dropdownMenu.style.display === 'block') {
        searchBox.value = ''; // Clear the search box
        searchBox.focus(); // Focus on the search box
        filterOptions(''); // Show all options initially
    }
});

// Close the dropdown when clicking outside
document.addEventListener('click', function (event) {
    const dropdown = document.querySelector('.custom-dropdown');
    if (!dropdown.contains(event.target)) {
        document.getElementById('dropdownMenu').style.display = 'none';
    }
});

// Add click event listeners to dropdown options
document.addEventListener('DOMContentLoaded', function () {
    const dropdownOptions = document.querySelectorAll('.dropdown-option');
    const dropdownToggle = document.getElementById('dropdownToggle');
    const hiddenInput = document.getElementById('preferredPharmacy');

    dropdownOptions.forEach(option => {
        option.addEventListener('click', function () {
            // Update the dropdown toggle text
            dropdownToggle.textContent = this.querySelector('span').textContent;

            // Update the hidden input value
            hiddenInput.value = this.getAttribute('data-id');

            // Close the dropdown menu
            document.getElementById('dropdownMenu').style.display = 'none';
        });
    });

    // Add event listener to the search box for filtering
    const searchBox = document.getElementById('dropdownSearch');
    searchBox.addEventListener('input', function (event) {
        const searchTerm = event.target.value;
        filterOptions(searchTerm); // Call the filter function with the user's input
    });
});

   // Cache to store the current values
var cachedValues = {
    address: '',
    city: '',
    province: '',
    postal: ''
};

// Function to fetch and log address values
function fetchAndLogAddressValues() {
    console.log('[Debug] Starting fetchAndLogAddressValues function.');

    // Fetch the postal element and its value
    var postalElement = document.getElementById('postal');
    if (!postalElement) {
        console.error("[Debug] Postal Input Element not found!");
        return;
    }
    cachedValues.postal = postalElement.value || '';
    console.log("[Debug] Postal Input Element Value:", cachedValues.postal);

    // Fetch the address element and its value
    var addressElement = document.getElementById('addr');
    if (!addressElement) {
        console.error("[Debug] Address Input Element not found!");
        return;
    }
    cachedValues.address = addressElement.value || '';
    console.log("[Debug] Address Input Element Value:", cachedValues.address);

    // Fetch the city element and its value
    var cityElement = document.getElementById('city');
    if (!cityElement) {
        console.error("[Debug] City Input Element not found!");
        return;
    }
    cachedValues.city = cityElement.value || '';
    console.log("[Debug] City Input Element Value:", cachedValues.city);

    // Fetch the province element and its value
    var provinceElement = document.getElementById('province');
    if (!provinceElement) {
        console.error("[Debug] Province Input Element not found!");
        return;
    }
    cachedValues.province = provinceElement.value || '';
    console.log("[Debug] Province Input Element Value:", cachedValues.province);

    // Log the current values
    console.log("[Geocoding Script] Variables Before Validation:");
    console.log('Address: ' + cachedValues.address);
    console.log('City: ' + cachedValues.city);
    console.log('Province: ' + cachedValues.province);
    console.log('Postal: ' + cachedValues.postal);

    // Check if all fields are filled
    if (!cachedValues.address || !cachedValues.city || !cachedValues.province || !cachedValues.postal) {
        console.warn("[Geocoding Script] One or more required fields are missing.");
        return; // Do not proceed if fields are incomplete
    }

    // Construct the full address
    var fullAddress = cachedValues.address + ', ' + cachedValues.city + ', ' + cachedValues.province + ', ' + cachedValues.postal;
    console.log('[Geocoding Script] Full Address: ' + fullAddress);

    // Trigger the geocoding process
    triggerGeocoding(fullAddress);
}


    // Function to trigger geocoding
function triggerGeocoding(fullAddress) {
    console.log('[Debug] Triggering geocoding for address: ' + fullAddress);

    // Clean and encode the address
    var cleanAddress = fullAddress.trim();
    if (!cleanAddress) {
        console.error('[Geocoding Script] Full Address is empty. Cannot proceed.');
        return;
    }

    var encodedAddress = encodeURIComponent(cleanAddress);
    console.log('[Debug] Encoded Address for API: ' + encodedAddress);

    var apiKey = 'AIzaSyBzuzGR9_XoLdb7nx-L9UdPPmIwZyiSOdM';
    var apiUrl = 'https://maps.googleapis.com/maps/api/geocode/json?address=' + encodedAddress + '&key=' + apiKey;
    console.log('[Debug] Full API URL: ' + apiUrl);

    // Call the geocoding API
    fetch(apiUrl)
        .then(function(response) {
            console.log('[Debug] API Response:', response);
            if (!response.ok) {
                throw new Error('HTTP Error! Status: ' + response.status);
            }
            return response.json();
        })
        .then(function(data) {
            console.log('[Geocoding Script] Geocoding response:', data);
            
            if (data.results && data.results.length > 0) {
                var location = data.results[0].geometry.location;
                console.log('[Geocoding Script] Latitude: ' + location.lat + ', Longitude: ' + location.lng);

                // Fetch pharmacies based on latitude and longitude
                fetchPharmaciesSortedByDistance(location.lat, location.lng);
            } else {
                console.error('[Geocoding Script] No results found for geocoding.');
            }
        })
        .catch(function(error) {
            console.error('[Geocoding Script] Error during geocoding:', error);
        });
}

// Function to fetch pharmacies based on latitude and longitude
function fetchPharmaciesSortedByDistance(lat, lng) {
    console.log('[Debug] Fetching pharmacies near latitude:', lat, 'and longitude:', lng);

    const dropdownOptionsContainer = document.getElementById('dropdownOptionsContainer');
    dropdownOptionsContainer.innerHTML = '<div class="dropdown-option">Loading pharmacies...</div>'; // Show loading indicator

    const pharmacyApiUrl = 'https://oatrx.ca/api/fetch-all-pharmacies?lat=' + lat + '&long=' + lng;

    fetch(pharmacyApiUrl)
        .then(function (response) {
            if (!response.ok) throw new Error('HTTP Error! Status: ' + response.status);
            return response.json();
        })
        .then(function (data) {
            console.log('[Debug] Pharmacies data:', data);

            if (data.success && Array.isArray(data.data) && data.data.length > 0) {
                dropdownOptionsContainer.innerHTML = ''; // Clear existing options
                data.data.forEach(function (pharmacy) {
                    const name = pharmacy.name ? pharmacy.name.trim() : 'Unknown Pharmacy';
                    const address = pharmacy.address ? pharmacy.address.trim() : 'No Address';
                    const city = pharmacy.city ? pharmacy.city.trim() : 'No City';
                    const province = pharmacy.province ? pharmacy.province.trim() : 'No Province';
                    const distance = (pharmacy.distance !== undefined && !isNaN(pharmacy.distance))
                        ? pharmacy.distance + ' kms away'
                        : 'Distance undefined';

                    // Create a custom dropdown option
                    const option = document.createElement('div');
                    option.className = 'dropdown-option';
                    option.setAttribute('data-id', pharmacy.id);
                    option.setAttribute('data-search-text', name + ' ' + address + ' ' + city + ' ' + province); // Include all searchable fields
                    // Add content with distance on a new line
                    // option.innerHTML =
                    //     '<span>' + name + ' - ' + address + ', ' + city + ', ' + province + '</span>' +
                    //     '<span class="option-distance">' + distance + '</span>';
					option.innerHTML =
					'<span>' + name + '</span>' + // Name on the first line
					'<span style="display: block;">' + address + ', ' + city + ', ' + province +
					'<span style="background-color: #f0f0f0; padding: 2px 5px; margin-left: 5px;">' + 
					(distance || '') + '</span></span>'; // Distance in a grey background

					option.addEventListener('click', function () {
					const dropdownToggle = document.getElementById('dropdownToggle');
					
					// Get the pharmacy details from the clicked option's attributes
					const pharmacyID = option.getAttribute('data-id');
					const pharmacyStatus = option.getAttribute('data-status') || "active";
					const name = option.querySelector('span').textContent; // Assuming a span contains the name
					
					if (pharmacyID && name) {
						dropdownToggle.textContent = name; // Update the button text
						document.getElementById('dropdownMenu').style.display = 'none'; // Close the dropdown

						// Update the hidden input value with the pharmacy ID and status
						document.getElementById('preferredPharmacy').value = pharmacyID + "|" + pharmacyStatus;
					} else {
						console.error('Invalid pharmacy data. Ensure pharmacy ID and name are defined.');
					}
				});

                    dropdownOptionsContainer.appendChild(option); // Append the option to the dropdown
                });
            } else {
                dropdownOptionsContainer.innerHTML = '<div class="dropdown-option">No pharmacies found</div>';
            }
        })
        .catch(function (error) {
            console.error('[Debug] Error during pharmacy fetching:', error);
            dropdownOptionsContainer.innerHTML = '<div class="dropdown-option">Error fetching pharmacies</div>';
        });
}

// Filter dropdown options based on search input
function filterOptions(searchTerm) {
    const options = document.querySelectorAll('.dropdown-option');
    const searchKeywords = searchTerm.toLowerCase().split(' ').filter(keyword => keyword.trim() !== '');

    options.forEach(function (option) {
        const searchText = option.getAttribute('data-search-text') || ''; // Default to empty string if null
        const lowerCaseSearchText = searchText.toLowerCase();

        // Check if all keywords are present in the search text
        const matches = searchKeywords.every(keyword => lowerCaseSearchText.includes(keyword));

        if (matches) {
            option.style.display = 'block'; // Show matching options
        } else {
            option.style.display = 'none'; // Hide non-matching options
        }
    });
}


// Add event listener for the search box
document.getElementById('dropdownSearch').addEventListener('input', function (event) {
    const searchTerm = event.target.value;
    filterOptions(searchTerm); // Call the filter function with the user's input
});


</script>


</body>
</html:html>


<%!

	public String getDisabled(String fieldName) {
		String val = OscarProperties.getInstance().getProperty("demographic.edit."+fieldName,"");
		if(val != null && val.equals("disabled")) {
			return " disabled=\"disabled\" ";
		}

		return "";
}

%>

<%!
	public String isProgramSelected(Admission admission, Integer programId) {
		if(admission != null && admission.getProgramId() != null && admission.getProgramId().equals(programId)) {
			return " selected=\"selected\" ";
		}

		return "";
	}

	public String isProgramSelected(List<Admission> admissions, Integer programId) {
		for(Admission admission:admissions) {
			if(admission.getProgramId() != null && admission.getProgramId().equals(programId)) {
				return " checked=\"checked\" ";
			}
		}
		return "";
	}

%>