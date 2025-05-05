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
<!DOCTYPE html>

<%@ taglib uri="/WEB-INF/security.tld" prefix="security"%>
<%
    String roleName$ = (String)session.getAttribute("userrole") + "," + (String) session.getAttribute("user");
    boolean authed=true;
%>
<security:oscarSec roleName="<%=roleName$%>" objectName="_demographic" rights="w" reverse="<%=true%>">
	<%authed=false; %>
	<%response.sendRedirect(request.getContextPath() + "/securityError.jsp?type=_demographic");%>
</security:oscarSec>
<%
	if(!authed) {
		return;
	}
%>

<%
  String curUser_no = (String) session.getAttribute("user");
  String str = null;
%>
<%@page errorPage="errorpage.jsp"%>
<%@page import="java.io.InputStream"%>
<%@page import="java.sql.*"%>
<%@page import="java.text.SimpleDateFormat"%>
<%@page import="java.util.*"%>
<%@page import="java.util.Date"%>
<%@page import="org.apache.commons.io.IOUtils"%>
<%@page import="org.apache.commons.lang.StringEscapeUtils"%>
<%@page import="org.apache.commons.lang.StringUtils"%>
<%@page import="org.codehaus.jettison.json.JSONObject"%>
<%@page import="org.oscarehr.PMmodule.dao.ProgramDao"%>
<%@page import="org.oscarehr.PMmodule.dao.ProviderDao"%>
<%@page import="org.oscarehr.PMmodule.model.Program"%>
<%@page import="org.oscarehr.PMmodule.model.ProgramProvider"%>
<%@page import="org.oscarehr.PMmodule.service.ProgramManager"%>
<%@page import="org.oscarehr.PMmodule.web.GenericIntakeEditAction"%>
<%@page import="org.oscarehr.common.Gender"%>
<%@page import="org.oscarehr.common.dao.*,org.oscarehr.common.model.*"%>
<%@page import="org.oscarehr.common.dao.DemographicDao"%>
<%@page import="org.oscarehr.common.dao.EFormDao"%>
<%@page import="org.oscarehr.common.dao.ProfessionalSpecialistDao"%>
<%@page import="org.oscarehr.common.dao.WaitingListNameDao"%>
<%@page import="org.oscarehr.common.model.Demographic"%>
<%@page import="org.oscarehr.common.model.Facility"%>
<%@page import="org.oscarehr.common.model.ProfessionalSpecialist"%>
<%@page import="org.oscarehr.common.model.Provider"%>
<%@page import="org.oscarehr.common.model.WaitingListName"%>
<%@page import="org.oscarehr.managers.LookupListManager"%>
<%@page import="org.oscarehr.managers.PatientConsentManager"%>
<%@page import="org.oscarehr.managers.ProgramManager2"%>
<%@page import="org.oscarehr.util.LoggedInInfo"%>
<%@page import="org.oscarehr.util.SessionConstants"%>
<%@page import="org.oscarehr.util.SpringUtils"%>
<%@page import="org.owasp.encoder.Encode"%>
<%@page import="org.springframework.web.context.*"%>
<%@page import="org.springframework.web.context.support.*"%>
<%@page import="oscar.*"%>
<%@page import="oscar.OscarProperties"%>
<%@page import="oscar.oscarDemographic.data.ProvinceNames"%>
<%@page import="oscar.oscarDemographic.pageUtil.Util"%>
<%@page import="oscar.oscarWaitingList.WaitingList"%>
<%@ page import="org.oscarehr.common.dao.PharmacyInfoDao, org.oscarehr.common.model.PharmacyInfo, org.springframework.web.context.support.WebApplicationContextUtils" %>

<%@ taglib uri="/WEB-INF/struts-bean.tld" prefix="bean"%>
<%@ taglib uri="/WEB-INF/struts-html.tld" prefix="html"%>
<%@ taglib uri="/WEB-INF/oscar-tag.tld" prefix="oscar"%>
<%@ taglib uri="/WEB-INF/caisi-tag.tld" prefix="caisi" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>

<%-- <%
    // Get Spring ApplicationContext
    org.springframework.context.ApplicationContext context = 
        org.springframework.web.context.support.WebApplicationContextUtils.getWebApplicationContext(application);

    // Fetch the PharmacyInfoDao bean
    PharmacyInfoDao pharmacyInfoDao = (PharmacyInfoDao) context.getBean("pharmacyInfoDao");

    // Retrieve the list of pharmacies
    List<PharmacyInfo> pharmacyList = null;
    try {
        pharmacyList = pharmacyInfoDao.getAllPharmacies();
    } catch (Exception e) {
        e.printStackTrace(); // Log the exception
    }
%> --%>



<jsp:useBean id="apptMainBean" class="oscar.AppointmentMainBean" scope="session" />
<%
	ProfessionalSpecialistDao professionalSpecialistDao = (ProfessionalSpecialistDao) SpringUtils.getBean("professionalSpecialistDao");
	ProviderDao providerDao = SpringUtils.getBean(ProviderDao.class);
	ProgramManager pm = SpringUtils.getBean(ProgramManager.class);
	DemographicDao demographicDao = SpringUtils.getBean(DemographicDao.class);
	WaitingListNameDao waitingListNameDao = SpringUtils.getBean(WaitingListNameDao.class);
	EFormDao eformDao = (EFormDao)SpringUtils.getBean("EFormDao");
	ProgramDao programDao = (ProgramDao)SpringUtils.getBean("programDao");
	ProgramManager2 programManager2 = SpringUtils.getBean(ProgramManager2.class);
    String privateConsentEnabledProperty = OscarProperties.getInstance().getProperty("privateConsentEnabled");
    boolean privateConsentEnabled = privateConsentEnabledProperty != null && privateConsentEnabledProperty.equals("true");
    boolean checkP = "false".equals(OscarProperties.getInstance().getProperty("skip_postal_code_validation","false"));
    LoggedInInfo loggedInInfo=LoggedInInfo.getLoggedInInfoFromSession(request);
%>
<jsp:useBean id="providerBean" class="java.util.Properties" scope="session" />

<%@ include file="../admin/dbconnection.jsp"%>
<%
  java.util.Locale vLocale =(java.util.Locale)session.getAttribute(org.apache.struts.Globals.LOCALE_KEY);

  OscarProperties props = OscarProperties.getInstance();

  GregorianCalendar now=new GregorianCalendar();
  String curYear = Integer.toString(now.get(Calendar.YEAR));
  String curMonth = Integer.toString(now.get(Calendar.MONTH)+1);
  if (curMonth.length() < 2) curMonth = "0"+curMonth;
  String curDay = Integer.toString(now.get(Calendar.DAY_OF_MONTH));
  if (curDay.length() < 2) curDay = "0"+curDay;

  int nStrShowLen = 20;
  OscarProperties oscarProps = OscarProperties.getInstance();

  String address = session.getAttribute("address")!=null?(String)session.getAttribute("address"):"";

  ProvinceNames pNames = ProvinceNames.getInstance();
  String prov= (props.getProperty("billregion","")).trim().toUpperCase();

  String billingCentre = (props.getProperty("billcenter","")).trim().toUpperCase();
  String defaultCity = session.getAttribute("city")!=null? (String) session.getAttribute("city") : (prov.equals("ON") ? (billingCentre.equals("N") ? "Toronto" : OscarProperties.getInstance().getProperty("default_city")) : "");

  String postal = session.getAttribute("postal")!=null? (String) session.getAttribute("postal") : "";

  String phone = session.getAttribute("phone")!=null? (String) session.getAttribute("phone") : session.getAttribute("labHphone")!=null? (String) session.getAttribute("labHphone") : props.getProperty("phoneprefix", "905-");
  String phone2 = session.getAttribute("labWphone")!=null? (String) session.getAttribute("labWphone") : "";
  String dob = session.getAttribute("labDOB")!=null? (String) session.getAttribute("labDOB") : "";
  String hin = session.getAttribute("labHIN")!=null? (String) session.getAttribute("labHIN") : "";
  String ver = "";
  if (hin.length() == 12 && Character.isDigit(hin.charAt(1))) { //likely Ontario
    ver = hin.substring(10);
    hin = hin.substring(0,10);
  }
  String sex = session.getAttribute("labSex")!=null? (String) session.getAttribute("labSex") : "";

  WebApplicationContext ctx = WebApplicationContextUtils.getRequiredWebApplicationContext(getServletContext());
  CountryCodeDao ccDAO =  (CountryCodeDao) ctx.getBean("countryCodeDao");

  List<CountryCode> countryList = ccDAO.getAllCountryCodes();

  // Used to retrieve properties from user (i.e. HC_Type & default_sex)
  UserPropertyDAO userPropertyDAO = (UserPropertyDAO) ctx.getBean("UserPropertyDAO");

  UserProperty sexProp = userPropertyDAO.getProp(curUser_no,  UserProperty.DEFAULT_SEX);
    if (sexProp != null) {
        sex = sexProp.getValue();
    } else {
        // Access defaultsex system property
        sex = props.getProperty("defaultsex","");
    }

  String HCType = "";
  // Determine if curUser has selected a default HC Type
  UserProperty HCTypeProp = userPropertyDAO.getProp(curUser_no,  UserProperty.HC_TYPE);
  if (HCTypeProp != null) {
     HCType = HCTypeProp.getValue();
  } else {
     // If there is no user defined property, then determine if the hctype system property is activated
     HCType = props.getProperty("hctype","");
     if (HCType == null || HCType.equals("")) {
           // The system property is not activated, so use the billregion
           String billregion = props.getProperty("billregion", "");
           HCType = billregion;
     }
  }
  // Use this value as the default value for province, as well
  String defaultProvince = session.getAttribute("province")!=null?(String)session.getAttribute("province"):HCType;

	session.removeAttribute("address");
	session.removeAttribute("city");
	session.removeAttribute("province");
	session.removeAttribute("postal");
	session.removeAttribute("phone");
	session.removeAttribute("labLastName");
	session.removeAttribute("labFirstName");
	session.removeAttribute("labDOB");
	session.removeAttribute("labHIN");
	session.removeAttribute("labHphone");
	session.removeAttribute("labWphone");
	session.removeAttribute("labSex");

	//get a list of programs the patient has consented to.
	if( OscarProperties.getInstance().getBooleanProperty("USE_NEW_PATIENT_CONSENT_MODULE", "true") ) {
	    PatientConsentManager patientConsentManager = SpringUtils.getBean( PatientConsentManager.class );
		pageContext.setAttribute( "consentTypes", patientConsentManager.getConsentTypes() );
	}


	SimpleDateFormat fmt = new SimpleDateFormat("yyyy-MM-dd");
	String today = fmt.format(new Date());
%>
<html:html locale="true">
<head>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<link href="<%=request.getContextPath() %>/css/bootstrap.css" rel="stylesheet" type="text/css">
<link href="<%=request.getContextPath() %>/css/bootstrap-responsive.css" rel="stylesheet" type="text/css">

<style>
 .form-horizontal .control-group {
	margin-bottom: 0px;
 }
 .help-block {
	margin-top: 0px;
 }
</style>


<script src="${pageContext.request.contextPath}/js/global.js"></script>
<script src="${pageContext.request.contextPath}/js/check_hin.js"></script>
<script src="${pageContext.request.contextPath}/library/jquery/jquery-3.6.4.min.js"></script>
<script src="${pageContext.request.contextPath}/js/bootstrap.js"></script><!-- for accordion -->
<script src="${pageContext.request.contextPath}/js/jqBootstrapValidation-1.3.7.min.js"></script>
   <script>
     //jQuery.noConflict();
    //$(function () { $("input,select,textarea").not("[type=submit]").jqBootstrapValidation(); } );

     $(function () { $("input,textarea,select").jqBootstrapValidation(
                    {
                        preventSubmit: true,
                        submitError: function($form, event, errors) {
                            // Here I do nothing, but you could do something like display
                            // the error messages to the user, log, etc.
                            event.preventDefault();
                        },

                        submitSuccess: function($form, event) {
	                    if (preferredPhone=="C") {
	                                $("#cell").val(function(i, val) { return val + "*"; });
	                        }  else if (preferredPhone=="H") {
	                                $("#phone").val(function(i, val) { return val + "*"; });
	                        }  else if (preferredPhone=="W") {
	                                $("#phone2").val(function(i, val) { return val + "*"; });
	                        }
                           // aSubmit();
                        },
                        filter: function() {
                            return $(this).is(":visible");
                        },

                    }
                );

                $("a[data-toggle=\"tab\"]").on( "click", function(e) {
                    e.preventDefault();
                    $(this).tab("show");
                });

            });


   </script>
<script>
    window.onunload = refreshParent;
    function refreshParent() {
        window.opener.location.reload();
    }
function closeAccordion() {
    document.getElementById('demographicSectionContent').style.height='0';
    document.getElementById('contactSectionContent').style.height='0';
    document.getElementById('insuranceSectionContent').style.height='0';
    document.getElementById('teamSectionContent').style.height='0';
    document.getElementById('wlSectionContent').style.height='0';
    document.getElementById('additionalSectionContent').style.height='0';
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
</script>

   <script>
        function aSubmit(){

            if(document.getElementById("eform_iframe")!=null)document.getElementById("eform_iframe").contentWindow.document.forms[0].submit();

            if(!checkFormTypeIn()) return false;

            if( !ignoreDuplicates() ) return false;


  			var rosterStatus = document.adddemographic.roster_status.value;
  			if(rosterStatus == 'RO') {
  				var rosterEnrolledTo = document.adddemographic.roster_enrolled_to.value;
  				var rosterDateYear = document.adddemographic.roster_date_year.value;
  	  			var rosterDateMonth = document.adddemographic.roster_date_month.value;
  	  			var rosterDateDate = document.adddemographic.roster_date_date.value;

  	  			if(rosterEnrolledTo == '') {
  	  				//alert('<bean:message key="demographic.demographiceditdemographic.alertenrollto" />');
                    //document.adddemographic.roster_enrolled_to.focus();
  	  				return false;
  	  			}

  	  			if(rosterDateYear == '' || rosterDateMonth == '' || rosterDateDate == '') {
	  				//alert('<bean:message key="demographic.demographiceditdemographic.alertrosterdate" />');
                    //document.adddemographic.roster_date.focus();
	  				return false;
	  			}

  			}

            return true;
        }

   </script>


<oscar:customInterface section="masterCreate"/>

<title><bean:message
	key="demographic.demographicaddrecordhtm.title" /></title>

<% if (OscarProperties.getInstance().getBooleanProperty("indivica_hc_read_enabled", "true")) { %>
	<script language="javascript" src="<%=request.getContextPath() %>/hcHandler/hcHandler.js"></script>
	<script language="javascript" src="<%=request.getContextPath() %>/hcHandler/hcHandlerNewDemographic.js"></script>
	<link rel="stylesheet" href="<%=request.getContextPath() %>/hcHandler/hcHandler.css" type="text/css" />
<% } %>


<script language="JavaScript">
function upCaseCtrl(ctrl) {
	ctrl.value = ctrl.value.toUpperCase();
}


function checkTypeIn() {
  var dob = document.titlesearch.keyword; typeInOK = false;

  if (dob.value.indexOf('%b610054') == 0 && dob.value.length > 18){
     document.titlesearch.keyword.value = dob.value.substring(8,18);
     document.titlesearch.search_mode[4].checked = true;
  }

  if(document.titlesearch.search_mode[2].checked) {
    if(dob.value.length==8) {
      dob.value = dob.value.substring(0, 4)+"-"+dob.value.substring(4, 6)+"-"+dob.value.substring(6, 8);
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

function checkTypeInAdd() {
	var typeInOK = false;
	if(document.adddemographic.last_name.value!="" && document.adddemographic.first_name.value!="" && document.adddemographic.sex.value!="") {
      if(checkTypeNum(document.adddemographic.year_of_birth.value) && checkTypeNum(document.adddemographic.month_of_birth.value) && checkTypeNum(document.adddemographic.date_of_birth.value) ){
	    typeInOK = true;
	  }
	}
	if(!typeInOK) alert ("<bean:message key="demographic.demographicaddrecordhtm.msgMissingFields"/>");
	return typeInOK;
}

function newStatus() {
    newOpt = prompt("Please enter the new status:", "");
    if (newOpt != "") {
        document.adddemographic.patient_status.options[document.adddemographic.patient_status.length] = new Option(newOpt, newOpt);
        document.adddemographic.patient_status.options[document.adddemographic.patient_status.length-1].selected = true;
    } else {
        alert("<bean:message	key="global.alertinvalid" />");
    }
}
function newStatus1() {
    newOpt = prompt("Please enter the new status:", "");
    if (newOpt != "") {
        document.adddemographic.roster_status.options[document.adddemographic.roster_status.length] = new Option(newOpt, newOpt);
        document.adddemographic.roster_status.options[document.adddemographic.roster_status.length-1].selected = true;
    } else {
        alert("<bean:message	key="global.alertinvalid" />");
    }
}

function formatPhone(obj) {
    // formats to North American xxx-xxx-xxxx standard numbers that are exactly 10 digits long
    var x=obj.value;
    //strip the formatting to get the numbers
    var matches = x.match(/\d+/g);
    if (!matches || x.substring(0,1) == "+"){
        // don't do anything if non numberic and or international format
        return;
    }
    var num = '';
    for (var i=0; i< matches.length; i++) {
        console.log(matches[i]);
        num = num + matches[i];
    }
    if (num.length == 10){
        obj.value = num.substring(0,3)+"-"+num.substring(3,6) + "-"+ num.substring(6);
    } else {
        if (num.length == 11 && x.substring(0,1) == "1"){
            obj.value = num.substring(0,1)+"-"+num.substring(1,4) + "-"+ num.substring(4,7)+ "-"+ num.substring(7);
        }
    }
}

function rs(n,u,w,h,x) {
  args="width="+w+",height="+h+",resizable=yes,scrollbars=yes,status=0,top=60,left=30";
  remote=window.open(u,n,args);
}
function referralScriptAttach2(elementName, name2) {
     var d = elementName;
     t0 = escape("document.forms[1].elements[\'"+d+"\'].value");
     t1 = escape("document.forms[1].elements[\'"+name2+"\'].value");
     rs('att',('<%=request.getContextPath() %>/billing/CA/ON/searchRefDoc.jsp?param='+t0+'&param2='+t1),600,600,1);
}

function checkName() {
	var typeInOK = false;
	if(document.adddemographic.last_name.value!="" && document.adddemographic.first_name.value!="" && document.adddemographic.last_name.value!=" " && document.adddemographic.first_name.value!=" ") {
	    typeInOK = true;
	} else {
		//alert ("You must type in the following fields: Last Name, First Name.");
        last_name.focus();
    }
	return typeInOK;
}

function checkDob() {
	var typeInOK = false;
	var yyyy = document.adddemographic.year_of_birth.value;
	//var selectBox = document.adddemographic.month_of_birth;
	var mm = document.adddemographic.month_of_birth.value
	//selectBox = document.adddemographic.date_of_birth;
	var dd = document.adddemographic.date_of_birth.value

	if(checkTypeNum(yyyy) && checkTypeNum(mm) && checkTypeNum(dd) ){

        var check_date = new Date(yyyy,(mm-1),dd);
		var now = new Date();
		var year=now.getFullYear();
		var month=now.getMonth()+1;
		var date=now.getDate();

		var young = new Date(year,month,date);
		var old = new Date(1800,01,01);

		if (check_date.getTime() <= young.getTime() && check_date.getTime() >= old.getTime() && yyyy.length==4) {
		    typeInOK = true;
		}
		if ( yyyy == "0000"){
        typeInOK = false;
      }
	}

	if (!typeInOK){
        //alert ("You must type in the right DOB.");
        //inputDOB.focus();
   }

   if (!isValidDate(dd,mm,yyyy)){
        //alert ("DOB Date is an incorrect date");
        //inputDOB.focus();
        typeInOK = false;
   }

	return typeInOK;
}


function isValidDate(day,month,year){
   month = ( month - 1 );
   dteDate=new Date(year,month,day);
   return ((day==dteDate.getDate()) && (month==dteDate.getMonth()) && (year==dteDate.getFullYear()));
}

function checkHin() {
	var hin = document.adddemographic.hin.value;
    if($("#hc_type").val()==""||$("#hc_type").val()=== null){ return false; }
	var province = document.adddemographic.hc_type.value;

	if (!isValidHin(hin, province))
	{
		alert ("You must type in the right HIN.");
        hin.focus();
		return(false);
	}

	return(true);
}


function checkSex() {
	var sex = document.adddemographic.sex.value;

	if(sex.length == 0)
	{
		//alert ("You must select a Gender.");
        //document.adddemographic.sex.focus();
		return(false);
	}

	return(true);
}


function checkResidentStatus(){
    var rs = document.adddemographic.rsid.value;
    if(rs!="")return true;
    else{
        alert("<bean:message	key="demographic.demographiceditdemographic.alertresstat" />");
        document.adddemographic.rsid.focus();
     return false;}
}

function checkAllDate() {
	var typeInOK = false;
	typeInOK = checkDateYMD( document.adddemographic.date_joined_year.value , document.adddemographic.date_joined_month.value , document.adddemographic.date_joined_day.value , document.adddemographic.date_joined );
	if (!typeInOK) { return false; }

	typeInOK = checkDateYMD( document.adddemographic.end_date_year.value , document.adddemographic.end_date_month.value , document.adddemographic.end_date_day.value , document.adddemographic.end_date );
	if (!typeInOK) { return false; }

	typeInOK = checkDateYMD( document.adddemographic.hc_renew_date_year.value , document.adddemographic.hc_renew_date_month.value , document.adddemographic.hc_renew_date_day.value , document.adddemographic.hc_renew_date );
	if (!typeInOK) { return false; }

	typeInOK = checkDateYMD( document.adddemographic.eff_date_year.value , document.adddemographic.eff_date_month.value , document.adddemographic.eff_date_day.value , document.adddemographic.eff_date );
	if (!typeInOK) { return false; }

	return typeInOK;
}
	function checkDateYMD(yy, mm, dd, fieldName) {
		var typeInOK = false;
		if((yy.length==0) && (mm.length==0) && (dd.length==0) ){
			typeInOK = true;
		} else if(checkTypeNum(yy) && checkTypeNum(mm) && checkTypeNum(dd) ){
			if (checkDateYear(yy) && checkDateMonth(mm) && checkDateDate(dd)) {
				typeInOK = true;
			}
		}
		//if (!typeInOK) { alert ("Invalid Entry.  Please verify and retry."); return false; }
        //fieldName.focus();
		return typeInOK;
	}

	function checkDateYear(y) {
		if (y>1900 && y<2045) return true;
		return false;
	}
	function checkDateMonth(y) {
		if (y>=1 && y<=12) return true;
		return false;
	}
	function checkDateDate(y) {
		if (y>=1 && y<=31) return true;
		return false;
	}

function checkFormTypeIn() {
	if(document.getElementById("eform_iframe")!=null)document.getElementById("eform_iframe").contentWindow.document.forms[0].submit();
	if ( !checkName() ) return false;
	if ( !checkDob() ) return false;
	if ( !checkHin() ) return false;
	if ( !checkSex() ) return false;
	if ( !checkResidentStatus() ) return false;
	if ( !checkAllDate() ) return false;
	return true;
}

function checkTitleSex(ttl) {
   // if (ttl=="MS" || ttl=="MISS" || ttl=="MRS" || ttl=="SR") document.adddemographic.sex.selectedIndex=1;
	//else if (ttl=="MR" || ttl=="MSSR") document.adddemographic.sex.selectedIndex=0;
}

function removeAccents(s){
        var r=s.toLowerCase();
        r = r.replace(new RegExp("\\s", 'g'),"");
        r = r.replace(new RegExp("[\ufffd\ufffd\ufffd\ufffd\ufffd\ufffd]", 'g'),"a");
        r = r.replace(new RegExp("\ufffd", 'g'),"c");
        r = r.replace(new RegExp("[\ufffd\ufffd\ufffd\ufffd]", 'g'),"e");
        r = r.replace(new RegExp("[\ufffd\ufffd\ufffd\ufffd]", 'g'),"i");
        r = r.replace(new RegExp("\ufffd", 'g'),"n");
        r = r.replace(new RegExp("[\ufffd\ufffd\ufffd\ufffd\ufffd]", 'g'),"o");
        r = r.replace(new RegExp("[\ufffd\ufffd\ufffd\ufffd]", 'g'),"u");
        r = r.replace(new RegExp("[\ufffd\ufffd]", 'g'),"y");
        r = r.replace(new RegExp("\\W", 'g'),"");
        return r;
}

function autoFillHin(){
   var hcType = document.getElementById('hc_type').value;
   var hin = document.getElementById('hin').value;
   if(	hcType == 'QC' && hin == ''){
   	  var last = document.getElementById('last_name').value;
   	  var first = document.getElementById('first_name').value;
      var yob = document.getElementById('year_of_birth').value;
      var mob = document.getElementById('month_of_birth').value;
      var dob = document.getElementById('date_of_birth').value;

   	  last = removeAccents(last.substring(0,3)).toUpperCase();
   	  first = removeAccents(first.substring(0,1)).toUpperCase();
   	  yob = yob.substring(2,4);

   	  var sex = document.getElementById('sex').value;
   	  if(sex == 'F'){
   		  mob = parseInt(mob) + 50;
   	  }

      document.getElementById('hin').value = last + first + yob + mob + dob;

   }
}


function ignoreDuplicates() {
		//do the check
		var lastName = $("#last_name").val();
		var firstName = $("#first_name").val();
		var yearOfBirth = $("#year_of_birth").val();
		var monthOfBirth = $("#month_of_birth").val();
		var dayOfBirth = $("#date_of_birth").val();
		var ret = false;
	$.ajax({
			url:"<%=request.getContextPath() %>/demographicSupport.do?method=checkForDuplicates&lastName="+lastName+"&firstName="+firstName+"&yearOfBirth="+yearOfBirth+"&monthOfBirth="+monthOfBirth+"&dayOfBirth="+dayOfBirth,
			success:function(data){
				if(data.hasDuplicates != null) {
					if(data.hasDuplicates) {

						if(confirm('<bean:message key="demographic.demographiceditdemographic.alertduplicate"/>')) {
							//submit the form
							ret = true;
						}
					} else {

						//submit the form
						ret = true;
					}
				} else {

					//submit the form
					ret = true;
				}
			},
			dataType:'json',
			async: false
	});


	return ret;
}


function isCanadian(){

    if($("#province").val()==""||$("#province").val() === null){ return false; }
    if($("#country").val()=="CA"){ return true; }
    var province = $("#province").val();
    if ( province.indexOf("CA")>-1 ) { return true; }
    return false;
}

function consentClearBtn(radioBtnName)
{

	if( confirm("<bean:message key="demographic.demographiceditdemographic.alertclearconsent"/>") )
	{

	    //clear out opt-in/opt-out radio buttons
	    var ele = document.getElementsByName(radioBtnName);
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

	}
}


var preferredPhone="";

$( document ).ready( function() {

    console.log( "ready!" );
    parsedob_date();
    formatPhone(document.getElementById("phone"));
    formatPhone(document.getElementById("phoneW"));

	var defPhTitle = "Check to set preferred contact number";
	var prefPhTitle = "Preferred contact number";

  $('#cell_check').on("change",function()
  {
    if(this.checked == true)
    {
	preferredPhone="C";
	$('#cell_check').prop('title', prefPhTitle);
	$('#phone_check').prop('title', defPhTitle);
	$('#phone2_check').prop('title', defPhTitle);
	$('#phone2_check').prop('checked', false);
	$('#phone_check').prop('checked', false);
    }
  });
  $('#phone_check').on("change",function()
  {
    if(this.checked == true)
    {
	preferredPhone="H";
	$('#cell_check').prop('title', defPhTitle);
	$('#phone_check').prop('title', prefPhTitle);
	$('#phone2_check').prop('title', defPhTitle);
	$('#phone2_check').prop('checked', false);
	$('#cell_check').prop('checked', false);
    }
  });
  $('#phone2_check').on("change",function()
  {
    if(this.checked == true)
    {
	preferredPhone="W";
	$('#cell_check').prop('title', defPhTitle);
	$('#phone_check').prop('title', defPhTitle);
	$('#phone2_check').prop('title', prefPhTitle);
	$('#phone_check').prop('checked', false);
	$('#cell_check').prop('checked', false);
    }
  });

    $('#cell_check').prop('title', defPhTitle);
    $('#phone_check').prop('title', defPhTitle);
    $('#phone2_check').prop('title', defPhTitle);


});





<%
if("true".equals(OscarProperties.getInstance().getProperty("iso3166.2.enabled","false"))) {
%>


$(document).ready(function(){

	$("#country").on('change',function(){
		updateProvinces('');
	});

	$("#residentialCountry").on('change',function(){
		updateResidentialProvinces('');
	});

    $.ajax({
        type: "POST",
        url:  '<%=request.getContextPath() %>/demographicSupport.do',
        data: 'method=getCountryAndProvinceCodes',
        dataType: 'json',
        success: function (data) {
        	$('#country').append($('<option>').text('').attr('value', ''));
        	$.each(data, function(i, value) {
                 $('#country').append($('<option>').text(value.label).attr('value', value.value));
             });

        	var defaultProvince = '<%=OscarProperties.getInstance().getProperty("demographic.default_province","")%>';
        	var defaultCountry = '';

        	if(defaultProvince == '' && defaultCountry == '') {
        		defaultProvince = 'CA-BC';
        	}
        	defaultCountry = defaultProvince.substring(0,defaultProvince.indexOf('-'));

        	$("#country").val(defaultCountry);

        	updateProvinces(defaultProvince);

        }
	});

    $.ajax({
        type: "POST",
        url:  '<%=request.getContextPath() %>/demographicSupport.do',
        data: 'method=getCountryAndProvinceCodes',
        dataType: 'json',
        success: function (data) {
        	$('#residentialCountry').append($('<option>').text('').attr('value', ''));
        	$.each(data, function(i, value) {
                 $('#residentialCountry').append($('<option>').text(value.label).attr('value', value.value));
             });

        	var defaultProvince = '<%=OscarProperties.getInstance().getProperty("demographic.default_province","")%>';
        	var defaultCountry = '';

        	if(defaultProvince == '' && defaultCountry == '') {
        		defaultProvince = 'CA-BC';
        	}
        	defaultCountry = defaultProvince.substring(0,defaultProvince.indexOf('-'));

        	$("#residentialCountry").val(defaultCountry);

        	updateResidentialProvinces(defaultProvince);

        }
	});



});


function updateProvinces(province) {
	var country = $("#country").val();

	console.log('country=' + country);

	$.ajax({
        type: "POST",
        url:  '<%=request.getContextPath() %>/demographicSupport.do',
        data: 'method=getCountryAndProvinceCodes&country=' + country,
        dataType: 'json',
        success: function (data) {
        	$('#province').empty();

        	$.each(data, function(i, value) {
                 $('#province').append($('<option>').text(value.label).attr('value', value.value));
             });


        	if(province != null) {
        		$("#province").val(province);
        	}


        }
	});
}


function updateResidentialProvinces(province) {
	var country = $("#residentialCountry").val();


	$.ajax({
        type: "POST",
        url:  '<%=request.getContextPath() %>/demographicSupport.do',
        data: 'method=getCountryAndProvinceCodes&country=' + country,
        dataType: 'json',
        success: function (data) {
        	$('#residentialProvince').empty();

        	$.each(data, function(i, value) {
                 $('#residentialProvince').append($('<option>').text(value.label).attr('value', value.value));
             });


        	if(province != null) {
        		$("#residentialProvince").val(province);
        	}


        }
	});
}
<% }  %>

</script>
<style>

input[type="text"], input[type="date"], input[type="email"] {
    height: 22px;
    line-height: 22px;
}
/* Override Bootstrap */
legend {
    margin-bottom: 4px;
    background-color:gainsboro;
}
.accordion-heading .accordion-toggle {
	padding: 2px 15px;
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

<!-- Select2 CSS -->
<link href="https://cdn.jsdelivr.net/npm/select2@4.1.0-rc.0/dist/css/select2.min.css" rel="stylesheet" />
<!-- jQuery -->
<script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
<!-- Select2 JavaScript -->
<script src="https://cdn.jsdelivr.net/npm/select2@4.1.0-rc.0/dist/js/select2.min.js"></script>

<script>
    /**
     * Synchronize the value of one input field with another
     * @param {string} sourceId - The ID of the source field
     * @param {string} targetId - The ID of the target field
     */
    function syncFields(sourceId, targetId) {
        // Get the source and target fields
        const sourceField = document.getElementById(sourceId);
        const targetField = document.getElementById(targetId);

        // Synchronize the value
        if (sourceField && targetField) {
            targetField.value = sourceField.value;
        }
    }
</script>


</head>
<!-- Databases have alias for today. It is not necessary give the current date -->

<body style="padding: 20px;">
<table style="width:100%">
	<tr >
    <th class="subject" style="
    text-align: left;
    font-size: 20px;
">ADD A DEMOGRAPHIC RECORD</th>
		<%-- <th class="subject"><bean:message
			key="demographic.demographicaddrecordhtm.msgMainLabel" /></th> --%>
	</tr>
</table>

<%-- <%@ include file="zdemographicfulltitlesearch.jsp"%> --%>
<form method="post" id="adddemographic" name="adddemographic" action="demographicaddarecord.jsp" novalidate onsubmit="return aSubmit()">
<input type="hidden" name="fromAppt" value="<%=Encode.forHtmlAttribute(request.getParameter("fromAppt"))%>">
<input type="hidden" name="originalPage" value="<%=Encode.forHtmlAttribute(request.getParameter("originalPage"))%>">
<input type="hidden" name="bFirstDisp" value="<%=Encode.forHtmlAttribute(request.getParameter("bFirstDisp"))%>">
<input type="hidden" name="provider_no" value="<%=Encode.forHtmlAttribute(request.getParameter("provider_no"))%>">
<input type="hidden" name="start_time" value="<%=Encode.forHtmlAttribute(request.getParameter("start_time"))%>">
<input type="hidden" name="end_time" value="<%=Encode.forHtmlAttribute(request.getParameter("end_time"))%>">
<input type="hidden" name="duration" value="<%=Encode.forHtmlAttribute(request.getParameter("duration"))%>">
<input type="hidden" name="year" value="<%=Encode.forHtmlAttribute(request.getParameter("year"))%>">
<input type="hidden" name="month" value="<%=Encode.forHtmlAttribute(request.getParameter("month"))%>">
<input type="hidden" name="day" value="<%=Encode.forHtmlAttribute(request.getParameter("day"))%>">
<input type="hidden" name="appointment_date" value="<%=Encode.forHtmlAttribute(request.getParameter("appointment_date"))%>">
<input type="hidden" name="notes" value="<%=Encode.forHtmlAttribute(request.getParameter("notes"))%>">
<input type="hidden" name="reason" value="<%=Encode.forHtmlAttribute(request.getParameter("reason"))%>">
<input type="hidden" name="location" value="<%=Encode.forHtmlAttribute(request.getParameter("location"))%>">
<input type="hidden" name="resources" value="<%=Encode.forHtmlAttribute(request.getParameter("resources"))%>">
<input type="hidden" name="type" value="<%=Encode.forHtmlAttribute(request.getParameter("type"))%>">
<input type="hidden" name="style" value="<%=Encode.forHtmlAttribute(request.getParameter("style"))%>">
<input type="hidden" name="billing" value="<%=Encode.forHtmlAttribute(request.getParameter("billing"))%>">
<input type="hidden" name="status" value="<%=Encode.forHtmlAttribute(request.getParameter("status"))%>">
<input type="hidden" name="createdatetime" value="<%=Encode.forHtmlAttribute(request.getParameter("createdatetime"))%>">
<input type="hidden" name="creator" value="<%=Encode.forHtmlAttribute(request.getParameter("creator"))%>">
<input type="hidden" name="remarks" value="<%=Encode.forHtmlAttribute(request.getParameter("remarks"))%>">

<table style="width:100%">
<%-- <tr><td class="RowTop"> --%>
    <%-- <b><bean:message key="demographic.record"/></b> --%>
    <%-- <% if (OscarProperties.getInstance().getBooleanProperty("indivica_hc_read_enabled", "true")) { %> --%>
		<%-- <span style="position: relative; float: right; font-style: italic; background: black; color: white; padding: 4px; font-size: 12px; border-radius: 3px;"> --%>
			<%-- <span class="_hc_status_icon _hc_status_success"></span>Ready for Card Swipe --%>
		<%-- </span> --%>
	<%-- <% } %> --%>
<%-- </td></tr> --%>
<tr><td>



<table id="addDemographicTbl" style="width:100%" >


    <%if (OscarProperties.getInstance().getProperty("workflow_enhance")!=null && OscarProperties.getInstance().getProperty("workflow_enhance").equals("true")) { %>
   		 <tr>
				<td>
          <input type="hidden" name="displaymode" value="Add Record">
				<!-- <div align="center"><input type="hidden" name="dboperation"
					value="add_record">
				<input type="submit" name="submit" class="btn btn-primary"
					value="<bean:message key="demographic.demographicaddrecordhtm.btnAddRecord"/>">
					<input type="submit" name="submit" class="btn" value="<bean:message key="demographic.demographiceditdemographic.btnSaveAddFamilyMember"/>">
				<input type="button" name="Button" class="btn"
					value="<bean:message key="demographic.demographicaddrecordhtm.btnSwipeCard"/>"
					onclick="window.open('zadddemographicswipe.htm','', 'scrollbars=yes,resizable=yes,width=600,height=300')";>
				&nbsp; <input type="button" name="Button" class="btn btn-link"
					value="<bean:message key="demographic.demographicaddrecordhtm.btnCancel"/>"
					onclick=self.close();></div> -->
				</td>
			</tr>
    <%}
   String searchMode = request.getParameter("search_mode") != null ? request.getParameter("search_mode") : "search_name";
   String keyWord = request.getParameter("keyword") != null ? request.getParameter("keyword") : "";

   String lastNameVal = "";
   String firstNameVal = "";
   String chartNoVal = "";

   if (searchMode != null) {
      if (searchMode.equals("search_name")) {
        int commaIdx = keyWord.indexOf(",");
        if (commaIdx == -1)
	   lastNameVal = keyWord.trim();
        else if (commaIdx == (keyWord.length()-1))
           lastNameVal = keyWord.substring(0,keyWord.length()-1).trim();
        else {
           lastNameVal = keyWord.substring(0,commaIdx).trim();
  	   firstNameVal = keyWord.substring(commaIdx+1).trim();
        }
   } else if (searchMode.equals("search_chart_no")) {
	chartNoVal = keyWord;
   }
  }
%>

   		 <tr>
				<td>
<div class="container-fluid well form-horizontal span12 accordion" id="editWrapper" style="
    padding: 0;
    margin: 0;
    width: 600px;
" data-select2-id="select2-data-editWrapper">
    <div id="demographicSection" class="span11 accordion-group" style="width: 600px; margin-left: 0;">

		<%-- <fieldset class="accordion-heading" title="<bean:message key="global.btnToggle"/>" id="demotoggle">
			<legend class="accordion-toggle" data-toggle="collapse" data-parent="#editWrapper" data-target="#demographicSectionContent">
                <bean:message key="demographic.demographiceditdemographic.msgDemographic" /><span style="color:red;">*</span>
                <i id="toggleD" class="icon-edit" style="float: right; margin-top: 10px;" title="<bean:message key="demographic.demographiceditdemographic.msgEdit"/>"></i>
            </legend>
		</fieldset> --%>
            <%-- <div id="demographicSectionContent" class="accordion-body in collapse" > --%>
        <%-- <h3><bean:message key="demographic.demographiceditdemographic.msgDemographic" /></h3> --%>
        <div style="padding-left: 10px;">
    <h3>
        <bean:message key="demographic.demographiceditdemographic.msgDemographic" />
    </h3>
</div>

        
        <div id="demographicSectionContent">

<div class="control-group" style="white-space:nowrap">
    <label class="control-label" for="hinTop"><bean:message key="demographic.demographiceditdemographic.formHin" /></label>
    <div class="controls">
        <input type="text" placeholder="<bean:message key="demographic.demographiceditdemographic.formHin" />"
            name="hinTop" id="hinTop"
            class="input-medium"
            oninput="syncFields('hinTop', 'hin')">
        <bean:message key="demographic.demographiceditdemographic.formVer" />
        <input type="text" placeholder="<bean:message key="demographic.demographiceditdemographic.formVer" />"
            name="verTop" id="verTop"
            style="width: 40px;"
            onBlur="upCaseCtrl(this)"
            oninput="syncFields('verTop', 'ver')">
    </div>
</div>

    <div class="control-group">
            <label class="control-label" for="selectTitle"><bean:message key="demographic.demographiceditdemographic.msgDemoTitle"/></label>
            <div class="controls">
								<select name="title" id="selectTitle" >
									<option value="" label="<bean:message key="demographic.demographiceditdemographic.msgNotSet"/>"><bean:message key="demographic.demographiceditdemographic.msgNotSet"/></option>
									<option value="DR"  ><bean:message key="demographic.demographicaddrecordhtm.msgDr"/></option>
								    <option value="MS"  ><bean:message key="demographic.demographiceditdemographic.msgMs"/></option>
								    <option value="MISS" ><bean:message key="demographic.demographiceditdemographic.msgMiss"/></option>
								    <option value="MRS" ><bean:message key="demographic.demographiceditdemographic.msgMrs"/></option>
								    <option value="MR" ><bean:message key="demographic.demographiceditdemographic.msgMr"/></option>
								    <option value="MSSR" ><bean:message key="demographic.demographiceditdemographic.msgMssr"/></option>
								    <option value="PROF" ><bean:message key="demographic.demographiceditdemographic.msgProf"/></option>
								    <option value="REEVE"><bean:message key="demographic.demographiceditdemographic.msgReeve"/></option>
								    <option value="REV" ><bean:message key="demographic.demographiceditdemographic.msgRev"/></option>
								    <option value="RT_HON" ><bean:message key="demographic.demographiceditdemographic.msgRtHon"/></option>
								    <option value="SEN" ><bean:message key="demographic.demographiceditdemographic.msgSen"/></option>
								    <option value="SGT" ><bean:message key="demographic.demographiceditdemographic.msgSgt"/></option>
								    <option value="SR"  ><bean:message key="demographic.demographiceditdemographic.msgSr"/></option>
								    <option value="MADAM" ><bean:message key="demographic.demographiceditdemographic.msgMadam"/></option>
								    <option value="MME" ><bean:message key="demographic.demographiceditdemographic.msgMme"/></option>
								    <option value="MLLE"  ><bean:message key="demographic.demographiceditdemographic.msgMlle"/></option>
								    <option value="MAJOR" ><bean:message key="demographic.demographiceditdemographic.msgMajor"/></option>
								    <option value="MAYOR" ><bean:message key="demographic.demographiceditdemographic.msgMayor"/></option>

								    <option value="BRO" ><bean:message key="demographic.demographiceditdemographic.msgBro"/></option>
								    <option value="CAPT" ><bean:message key="demographic.demographiceditdemographic.msgCapt"/></option>
								    <option value="CHIEF" ><bean:message key="demographic.demographiceditdemographic.msgChief"/></option>
								    <option value="CST" ><bean:message key="demographic.demographiceditdemographic.msgCst"/></option>
								    <option value="CORP"  ><bean:message key="demographic.demographiceditdemographic.msgCorp"/></option>
								    <option value="FR" ><bean:message key="demographic.demographiceditdemographic.msgFr"/></option>
								    <option value="HON"  ><bean:message key="demographic.demographiceditdemographic.msgHon"/></option>
								    <option value="LT"  ><bean:message key="demographic.demographiceditdemographic.msgLt"/></option>

								</select>
            </div>
        </div>

        <div class="control-group"  >
            <label class="control-label" for="last_name"><bean:message
                key="demographic.demographiceditdemographic.formLastName" /><span style="color:red">*</span></label>
            <div class="controls">
              <input type="text"  placeholder="<bean:message key="demographic.demographiceditdemographic.formLastName" />"
                    name="last_name" id="last_name" required ="required" data-validation-required-message="<bean:message key="global.missing" />" onBlur="upCaseCtrl(this)" value="<%=Encode.forHtmlAttribute(lastNameVal)%>">
                 <p class="help-block text-danger"></p>
            </div>
        </div>
         <div class="control-group">
            <label class="control-label" for="inputMN"><bean:message
					key="demographic.demographiceditdemographic.formMiddleNames" /></label>
            <div class="controls">
              <input type="text" id="inputMN" name="middleNames" placeholder="<bean:message
					key="demographic.demographiceditdemographic.formMiddleNames" />"
					onBlur="upCaseCtrl(this)">
            </div>
        </div>

        <div class="control-group">
            <label class="control-label" for="first_name"><bean:message key="demographic.demographiceditdemographic.formFirstName" /><span style="color:red">*</span></label>
            <div class="controls">
              <input type="text" placeholder="<bean:message key="demographic.demographiceditdemographic.formFirstName" />"
                    name="first_name" id="first_name" required="required" data-validation-required-message="<bean:message key="global.missing" />" onBlur="upCaseCtrl(this)"  value="<%=Encode.forHtmlAttribute(firstNameVal)%>">
<p class="help-block text-danger"></p>
            </div>
        </div>
        <div class="control-group">
            <label class="control-label" for="inputDOB"><bean:message key="demographic.demographiceditdemographic.formDOB" /> <bean:message key="demographic.demographiceditdemographic.formDOBDetais" /><span style="color:red">*</span></label>
            <div class="controls" style="white-space: nowrap;">
                <input type="date" id="inputDOB"
                    class="input input-medium" required="required" data-validation-required-message="<bean:message key="global.missing" />"
                    name="inputDOB"
                    max="<%=new java.text.SimpleDateFormat("yyyy-MM-dd").format(new java.util.Date())%>"
                    value="<%=Encode.forHtmlAttribute(dob)%>"
					onchange="parsedob_date();">
                <input type="hidden" id="year_of_birth" name="year_of_birth">
                <input type="hidden" name="month_of_birth" id="month_of_birth">
				<input type="hidden" name="date_of_birth" id="date_of_birth">
            </div>
        </div>
        <div class="control-group">
            <label class="control-label" for="sex"><bean:message key="demographic.demographiceditdemographic.formSex" /><span style="color:red">*</span></label>
            <div class="controls">
            <!-- Value are Codes F M T O U Texts are Female Male Transgender Other Undefined -->
            <select  name="sex" id="sex" required data-validation-required-message="<bean:message key="global.warning" />">
                <option value="" label="<bean:message key="demographic.demographiceditdemographic.msgNotSet"/>"></option>
                <%
            	java.util.ResourceBundle oscarResources = ResourceBundle.getBundle("oscarResources", request.getLocale());
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
                <option value=<%=gn.name()%> <%=((sex.equals(gn.name())) ? " selected=\"selected\" " : "") %>><%=iterSex%></option>
			                        <% } %>
            </select>
            </div>
        </div>
     
              <div class="control-group">
            <label class="control-label" for="official_lang"><bean:message key="demographic.demographiceditdemographic.msgDemoLanguage"/></label>
            <div class="controls">
								<select name="official_lang" id="official_lang" >
								    <option value="English" ><bean:message key="demographic.demographiceditdemographic.msgEnglish"/></option>
								    <option value="French" ><bean:message key="demographic.demographiceditdemographic.msgFrench"/></option>
								    <option value="Other" ><bean:message key="demographic.demographiceditdemographic.optOther"/></option>
								</select>
            </div>
        </div>

        <div class="control-group">
            <label class="control-label" for="inputAlias"><bean:message
					key="demographic.demographiceditdemographic.alias" /></label>
            <div class="controls">
              <input type="text" id="inputAlias" placeholder="<bean:message
					key="demographic.demographiceditdemographic.alias" />"
                    name="alias"
					onBlur="upCaseCtrl(this)">
            </div>
        </div>

<!-- New Patient Compliance -->
<div class="control-group">
    <label class="control-label" for="patientCompliance">Patient Compliance</label>
    <div class="controls">
        <select id="patientCompliance" name="patientCompliance" class="span3" onchange="toggleFrequencyOptions()">
            <option value="yes">Yes</option>
            <option value="no">No</option>
            <option value="unknown">Unknown</option>
        </select>
    </div>
</div>

<!-- New Field : Frequency(Conditional Display) -->
<div class="control-group" id="frequencyGroup" style="display: none;">
    <label class="control-label" for="frequency">Frequency</label>
    <div class="controls">
        <label class="radio inline">
            <input type="radio" id="daily" name="frequency" value="daily"> Daily
        </label>
        <label class="radio inline">
            <input type="radio" id="weekly" name="frequency" value="weekly"> Weekly
        </label>
        <label class="radio inline">
            <input type="radio" id="bi-weekly" name="frequency" value="bi-weekly"> Bi-Weekly
        </label>
        <label class="radio inline">
            <input type="radio" id="monthly" name="frequency" value="monthly"> Monthly
        </label>
    </div>
</div>

<%-- <form name="addDemographicForm" method="post" action="saveDemographic.do">
    <label for="patientCompliance">Patient Compliance:</label>
      <select id="patientCompliance" name="patientCompliance">
        <option value="yes">Yes</option>
        <option value="no">No</option>
        <option value="unknown">Unknown</option>
    </select>

    <div id="frequencyOptions" style="display: none;">
        <label for="frequency">Frequency:</label>
        <input type="radio" name="client.frequency" value="daily" id="frequencyDaily"> Daily
        <input type="radio" name="client.frequency" value="weekly" id="frequencyWeekly"> Weekly
        <input type="radio" name="client.frequency" value="bi-weekly" id="frequencyBiWeekly"> Bi-Weekly
        <input type="radio" name="client.frequency" value="monthly" id="frequencyMonthly"> Monthly
    </div>
    <button type="submit">Save</button>
</form> --%>



        <%-- <div class="control-group">
            <label class="control-label" for="inputMN"><bean:message
					key="demographic.demographiceditdemographic.formMiddleNames" /></label>
            <div class="controls">
              <input type="text" id="inputMN" name="middleNames" placeholder="<bean:message
					key="demographic.demographiceditdemographic.formMiddleNames" />"
					onBlur="upCaseCtrl(this)">
            </div>
        </div> --%>
        <%-- <div class="control-group">
            <label class="control-label" for="selectTitle"><bean:message key="demographic.demographiceditdemographic.msgDemoTitle"/></label>
            <div class="controls">
								<select name="title" id="selectTitle" >
									<option value="" label="<bean:message key="demographic.demographiceditdemographic.msgNotSet"/>"><bean:message key="demographic.demographiceditdemographic.msgNotSet"/></option>
									<option value="DR"  ><bean:message key="demographic.demographicaddrecordhtm.msgDr"/></option>
								    <option value="MS"  ><bean:message key="demographic.demographiceditdemographic.msgMs"/></option>
								    <option value="MISS" ><bean:message key="demographic.demographiceditdemographic.msgMiss"/></option>
								    <option value="MRS" ><bean:message key="demographic.demographiceditdemographic.msgMrs"/></option>
								    <option value="MR" ><bean:message key="demographic.demographiceditdemographic.msgMr"/></option>
								    <option value="MSSR" ><bean:message key="demographic.demographiceditdemographic.msgMssr"/></option>
								    <option value="PROF" ><bean:message key="demographic.demographiceditdemographic.msgProf"/></option>
								    <option value="REEVE"><bean:message key="demographic.demographiceditdemographic.msgReeve"/></option>
								    <option value="REV" ><bean:message key="demographic.demographiceditdemographic.msgRev"/></option>
								    <option value="RT_HON" ><bean:message key="demographic.demographiceditdemographic.msgRtHon"/></option>
								    <option value="SEN" ><bean:message key="demographic.demographiceditdemographic.msgSen"/></option>
								    <option value="SGT" ><bean:message key="demographic.demographiceditdemographic.msgSgt"/></option>
								    <option value="SR"  ><bean:message key="demographic.demographiceditdemographic.msgSr"/></option>
								    <option value="MADAM" ><bean:message key="demographic.demographiceditdemographic.msgMadam"/></option>
								    <option value="MME" ><bean:message key="demographic.demographiceditdemographic.msgMme"/></option>
								    <option value="MLLE"  ><bean:message key="demographic.demographiceditdemographic.msgMlle"/></option>
								    <option value="MAJOR" ><bean:message key="demographic.demographiceditdemographic.msgMajor"/></option>
								    <option value="MAYOR" ><bean:message key="demographic.demographiceditdemographic.msgMayor"/></option>

								    <option value="BRO" ><bean:message key="demographic.demographiceditdemographic.msgBro"/></option>
								    <option value="CAPT" ><bean:message key="demographic.demographiceditdemographic.msgCapt"/></option>
								    <option value="CHIEF" ><bean:message key="demographic.demographiceditdemographic.msgChief"/></option>
								    <option value="CST" ><bean:message key="demographic.demographiceditdemographic.msgCst"/></option>
								    <option value="CORP"  ><bean:message key="demographic.demographiceditdemographic.msgCorp"/></option>
								    <option value="FR" ><bean:message key="demographic.demographiceditdemographic.msgFr"/></option>
								    <option value="HON"  ><bean:message key="demographic.demographiceditdemographic.msgHon"/></option>
								    <option value="LT"  ><bean:message key="demographic.demographiceditdemographic.msgLt"/></option>

								</select>
            </div>
        </div> --%>
        <%-- <div class="control-group">
            <label class="control-label" for="official_lang"><bean:message key="demographic.demographiceditdemographic.msgDemoLanguage"/></label>
            <div class="controls">
								<select name="official_lang" id="official_lang" >
								    <option value="English" ><bean:message key="demographic.demographiceditdemographic.msgEnglish"/></option>
								    <option value="French" ><bean:message key="demographic.demographiceditdemographic.msgFrench"/></option>
								    <option value="Other" ><bean:message key="demographic.demographiceditdemographic.optOther"/></option>
								</select>
            </div>
        </div> --%>
        <%-- <div class="control-group">
            <label class="control-label" for="spoken"><bean:message key="demographic.demographiceditdemographic.msgSpoken"/></label>
            <div class="controls">
			    <select name="spoken_lang" id="spoken" >
                    <option value="" label="<bean:message key="demographic.demographiceditdemographic.msgNotSet"/>"></option>
                   <%for (String splang : Util.spokenLangProperties.getLangSorted()) { %>
                    <option value="<%=splang %>" ><%=splang %></option>
                     <%} %>
				</select>
            </div>
        </div>
        <div class="control-group">
            <label class="control-label" for="firstNation"><bean:message key="demographic.demographiceditdemographic.aboriginal" /></label>
            <div class="controls">
                <select name="aboriginal" id="firstNation" >
									<option value="" ><bean:message key="demographic.demographiceditdemographic.msgNotSet" /></option>
									<option value="No" ><bean:message key="global.no" /></option>
									<option value="Yes" ><bean:message key="global.yes" /></option>
				</select>
                <input type="hidden" name="aboriginalOrig"  />
            </div>
        </div>
        <div class="control-group">
            <label class="control-label" for="countryOfOrigin"><bean:message key="demographic.demographiceditdemographic.msgCountryOfOrigin"/></label>
            <div class="controls">
                <select id="countryOfOrigin" name="countryOfOrigin" >
									<option value="-1"><bean:message key="demographic.demographiceditdemographic.msgNotSet"/></option>
									<%for(CountryCode cc : countryList){ %>
									<option value="<%=cc.getCountryId()%>"
										><%=cc.getCountryName() %></option>
									<%}%>
                </select>
            </div>
        </div>
        <div class="control-group">
            <label class="control-label" for="sin"><bean:message key="web.record.details.sin" /></label>
            <div class="controls">
              <input type="text" id="sin" placeholder="<bean:message key="web.record.details.sin" />" name="sin">
            </div>
        </div> --%>
        </div><!-- end demographicSectionContent -->
    </div><!-- end demographicSection -->

    <div id="contactSection" class="span11 accordion-group" style="width: 600px; margin-left: 0;">
		<%-- <fieldset class="accordion-heading" title="<bean:message key="global.btnToggle"/>">
			<legend class="accordion-toggle" data-toggle="collapse" data-parent="#editWrapper" data-target="#contactSectionContent">
			    <bean:message key="demographic.demographiceditdemographic.msgContactInfo" />
                <i class="icon-edit" style="float: right; margin-top: 10px;" title="<bean:message key="demographic.demographiceditdemographic.msgEdit"/>"></i>
            </legend>
		</fieldset>
        
        <div id="contactSectionContent" class="accordion-body collapse" > --%>
        <div style="padding-left: 10px;">
         <h3><bean:message key="demographic.demographiceditdemographic.msgContactInfo" /></h3>
         </div>
        <div id="contactSectionContent">
        <!-- "postalfield" -->
        <div class="control-group">
            <label class="control-label" for="address"><bean:message key="demographic.demographiceditdemographic.formAddr" /></label>
            <div class="controls">
              <input type="text" placeholder="<bean:message key="demographic.demographiceditdemographic.formAddr" />"  id="address" name="address" value="<%=Encode.forHtmlAttribute(address)%>" />
            </div>
        </div>
        <div class="control-group">
            <label class="control-label" for="city"><bean:message key="demographic.demographiceditdemographic.formCity" /></label>
            <div class="controls">
              <input type="text" id="city" placeholder="<bean:message key="demographic.demographiceditdemographic.formCity" />" name="city"
					value="<%=StringUtils.trimToEmpty(defaultCity)%>"/>
            </div>
        </div>
        <div class="control-group">
            <label class="control-label" for="province"><% if(oscarProps.getProperty("demographicLabelProvince") == null) { %>
								<bean:message
									key="demographic.demographiceditdemographic.formProcvince" /> <% } else {
                                  out.print(oscarProps.getProperty("demographicLabelProvince"));
                              	 } %></label>
            <div class="controls">
<%
					if("true".equals(OscarProperties.getInstance().getProperty("iso3166.2.enabled","false"))) {
				%>
					<select name="province" id="province"></select>
					<br/>
					<bean:message
					    key="demographic.demographiceditdemographic.filterByCountry" /> : <select name="country" id="country" ></select>

				<% } else  {  %>
				<select id="province" name="province">
					<option value="BC"
						<%=defaultProvince.equals("")||defaultProvince.equals("BC")?" selected":""%>>Other</option>
					<%-- <option value="">None Selected</option> --%>
					<% if (pNames.isDefined()) {
                   for (ListIterator li = pNames.listIterator(); li.hasNext(); ) {
                       String province = (String) li.next(); %>
					<option value="<%=province%>"
						<%=province.equals(defaultProvince)?" selected":""%>><%=li.next()%></option>
					<% } %>
					<% } else { %>
					<option value="AB" <%=defaultProvince.equals("AB")?" selected":""%>>AB-Alberta</option>
					<option value="BC" <%=defaultProvince.equals("BC")?" selected":""%>>BC-British Columbia</option>
					<option value="MB" <%=defaultProvince.equals("MB")?" selected":""%>>MB-Manitoba</option>
					<option value="NB" <%=defaultProvince.equals("NB")?" selected":""%>>NB-New Brunswick</option>
					<option value="NL" <%=defaultProvince.equals("NL")?" selected":""%>>NL-Newfoundland & Labrador</option>
					<option value="NT" <%=defaultProvince.equals("NT")?" selected":""%>>NT-Northwest Territory</option>
					<option value="NS" <%=defaultProvince.equals("NS")?" selected":""%>>NS-Nova Scotia</option>
					<option value="NU" <%=defaultProvince.equals("NU")?" selected":""%>>NU-Nunavut</option>
					<option value="ON" <%=defaultProvince.equals("ON")?" selected":""%>>ON-Ontario</option>
					<option value="PE" <%=defaultProvince.equals("PE")?" selected":""%>>PE-Prince Edward Island</option>
					<option value="QC" <%=defaultProvince.equals("QC")?" selected":""%>>QC-Quebec</option>
					<option value="SK" <%=defaultProvince.equals("SK")?" selected":""%>>SK-Saskatchewan</option>
					<option value="YT" <%=defaultProvince.equals("YT")?" selected":""%>>YT-Yukon</option>
					<option value="US" <%=defaultProvince.equals("US")?" selected":""%>>US resident</option>
					<option value="US-AK" <%=defaultProvince.equals("US-AK")?" selected":""%>>US-AK-Alaska</option>
					<option value="US-AL" <%=defaultProvince.equals("US-AL")?" selected":""%>>US-AL-Alabama</option>
					<option value="US-AR" <%=defaultProvince.equals("US-AR")?" selected":""%>>US-AR-Arkansas</option>
					<option value="US-AZ" <%=defaultProvince.equals("US-AZ")?" selected":""%>>US-AZ-Arizona</option>
					<option value="US-CA" <%=defaultProvince.equals("US-CA")?" selected":""%>>US-CA-California</option>
					<option value="US-CO" <%=defaultProvince.equals("US-CO")?" selected":""%>>US-CO-Colorado</option>
					<option value="US-CT" <%=defaultProvince.equals("US-CT")?" selected":""%>>US-CT-Connecticut</option>
					<option value="US-CZ" <%=defaultProvince.equals("US-CZ")?" selected":""%>>US-CZ-Canal Zone</option>
					<option value="US-DC" <%=defaultProvince.equals("US-DC")?" selected":""%>>US-DC-District Of Columbia</option>
					<option value="US-DE" <%=defaultProvince.equals("US-DE")?" selected":""%>>US-DE-Delaware</option>
					<option value="US-FL" <%=defaultProvince.equals("US-FL")?" selected":""%>>US-FL-Florida</option>
					<option value="US-GA" <%=defaultProvince.equals("US-GA")?" selected":""%>>US-GA-Georgia</option>
					<option value="US-GU" <%=defaultProvince.equals("US-GU")?" selected":""%>>US-GU-Guam</option>
					<option value="US-HI" <%=defaultProvince.equals("US-HI")?" selected":""%>>US-HI-Hawaii</option>
					<option value="US-IA" <%=defaultProvince.equals("US-IA")?" selected":""%>>US-IA-Iowa</option>
					<option value="US-ID" <%=defaultProvince.equals("US-ID")?" selected":""%>>US-ID-Idaho</option>
					<option value="US-IL" <%=defaultProvince.equals("US-IL")?" selected":""%>>US-IL-Illinois</option>
					<option value="US-IN" <%=defaultProvince.equals("US-IN")?" selected":""%>>US-IN-Indiana</option>
					<option value="US-KS" <%=defaultProvince.equals("US-KS")?" selected":""%>>US-KS-Kansas</option>
					<option value="US-KY" <%=defaultProvince.equals("US-KY")?" selected":""%>>US-KY-Kentucky</option>
					<option value="US-LA" <%=defaultProvince.equals("US-LA")?" selected":""%>>US-LA-Louisiana</option>
					<option value="US-MA" <%=defaultProvince.equals("US-MA")?" selected":""%>>US-MA-Massachusetts</option>
					<option value="US-MD" <%=defaultProvince.equals("US-MD")?" selected":""%>>US-MD-Maryland</option>
					<option value="US-ME" <%=defaultProvince.equals("US-ME")?" selected":""%>>US-ME-Maine</option>
					<option value="US-MI" <%=defaultProvince.equals("US-MI")?" selected":""%>>US-MI-Michigan</option>
					<option value="US-MN" <%=defaultProvince.equals("US-MN")?" selected":""%>>US-MN-Minnesota</option>
					<option value="US-MO" <%=defaultProvince.equals("US-MO")?" selected":""%>>US-MO-Missouri</option>
					<option value="US-MS" <%=defaultProvince.equals("US-MS")?" selected":""%>>US-MS-Mississippi</option>
					<option value="US-MT" <%=defaultProvince.equals("US-MT")?" selected":""%>>US-MT-Montana</option>
					<option value="US-NC" <%=defaultProvince.equals("US-NC")?" selected":""%>>US-NC-North Carolina</option>
					<option value="US-ND" <%=defaultProvince.equals("US-ND")?" selected":""%>>US-ND-North Dakota</option>
					<option value="US-NE" <%=defaultProvince.equals("US-NE")?" selected":""%>>US-NE-Nebraska</option>
					<option value="US-NH" <%=defaultProvince.equals("US-NH")?" selected":""%>>US-NH-New Hampshire</option>
					<option value="US-NJ" <%=defaultProvince.equals("US-NJ")?" selected":""%>>US-NJ-New Jersey</option>
					<option value="US-NM" <%=defaultProvince.equals("US-NM")?" selected":""%>>US-NM-New Mexico</option>
					<option value="US-NU" <%=defaultProvince.equals("US-NU")?" selected":""%>>US-NU-Nunavut</option>
					<option value="US-NV" <%=defaultProvince.equals("US-NV")?" selected":""%>>US-NV-Nevada</option>
					<option value="US-NY" <%=defaultProvince.equals("US-NY")?" selected":""%>>US-NY-New York</option>
					<option value="US-OH" <%=defaultProvince.equals("US-OH")?" selected":""%>>US-OH-Ohio</option>
					<option value="US-OK" <%=defaultProvince.equals("US-OK")?" selected":""%>>US-OK-Oklahoma</option>
					<option value="US-OR" <%=defaultProvince.equals("US-OR")?" selected":""%>>US-OR-Oregon</option>
					<option value="US-PA" <%=defaultProvince.equals("US-PA")?" selected":""%>>US-PA-Pennsylvania</option>
					<option value="US-PR" <%=defaultProvince.equals("US-PR")?" selected":""%>>US-PR-Puerto Rico</option>
					<option value="US-RI" <%=defaultProvince.equals("US-RI")?" selected":""%>>US-RI-Rhode Island</option>
					<option value="US-SC" <%=defaultProvince.equals("US-SC")?" selected":""%>>US-SC-South Carolina</option>
					<option value="US-SD" <%=defaultProvince.equals("US-SD")?" selected":""%>>US-SD-South Dakota</option>
					<option value="US-TN" <%=defaultProvince.equals("US-TN")?" selected":""%>>US-TN-Tennessee</option>
					<option value="US-TX" <%=defaultProvince.equals("US-TX")?" selected":""%>>US-TX-Texas</option>
					<option value="US-UT" <%=defaultProvince.equals("US-UT")?" selected":""%>>US-UT-Utah</option>
					<option value="US-VA" <%=defaultProvince.equals("US-VA")?" selected":""%>>US-VA-Virginia</option>
					<option value="US-VI" <%=defaultProvince.equals("US-VI")?" selected":""%>>US-VI-Virgin Islands</option>
					<option value="US-VT" <%=defaultProvince.equals("US-VT")?" selected":""%>>US-VT-Vermont</option>
					<option value="US-WA" <%=defaultProvince.equals("US-WA")?" selected":""%>>US-WA-Washington</option>
					<option value="US-WI" <%=defaultProvince.equals("US-WI")?" selected":""%>>US-WI-Wisconsin</option>
					<option value="US-WV" <%=defaultProvince.equals("US-WV")?" selected":""%>>US-WV-West Virginia</option>
					<option value="US-WY" <%=defaultProvince.equals("US-WY")?" selected":""%>>US-WY-Wyoming</option>
					<% } %>
				</select>
				<% } %>
            </div>
        </div>
        <div class="control-group">
            <label class="control-label" for="postal"><% if(oscarProps.getProperty("demographicLabelPostal") == null) { %>
								<bean:message key="demographic.demographiceditdemographic.formPostal" /> <% } else {
                                  out.print(oscarProps.getProperty("demographicLabelPostal"));
                              	 } %></label>
            <div class="controls">
                <input type="text" id="postal" placeholder="<bean:message key="demographic.demographiceditdemographic.formPostal" /> "
                    name="postal" value="<%=StringUtils.trimToEmpty(postal)%>" onBlur="upCaseCtrl(this)" maxlength=10
<% if (checkP) { %>
pattern="[ABCEGHJ-NPRSTVXY]\d[ABCEGHJ-NPRSTVXYWZ]\s\d[ABCEGHJ-NPRSTVXYWZ]\d"
required
data-validation-pattern-message="<bean:message key="demographic.demographiceditdemographic.alertpostal" />"
<% } %>
					>
        <p class="help-block text-danger"></p>
            </div>
        </div>
<!-- end postal -->
        <div class="control-group">
            <label class="control-label" for="inputEmail"><bean:message key="demographic.demographiceditdemographic.formEmail" /></label>
            <div class="controls">
              <input type="email" id="inputEmail" placeholder="<bean:message key="demographic.demographiceditdemographic.formEmail" />"
                    name="email" >
            </div>
        </div>
        <div class="control-group">
            <label class="control-label" for="consentEmail"><bean:message key="demographic.demographiceditdemographic.consentToUseEmailForCare" /></label>
            <div class="controls" style="white-space: nowrap;">
              <bean:message key="WriteScript.msgYes"/>
            								<input type="radio" value="yes" name="consentToUseEmailForCare" id="consentEmail">
          							 <bean:message key="WriteScript.msgNo"/>
            								<input type="radio" value="no" name="consentToUseEmailForCare" >
									 <%-- <bean:message key="WriteScript.msgUnset"/>
            								<input type="radio" value="unset" name="consentToUseEmailForCare" checked > --%>
            </div>
        </div>
<!-- residential -->
<script>
function loadResidence(){
    $('#residence_div').show();
    $('#raddress_div').show();
    $('#rcity_div').show();
    $('#rprovince_div').show();
    $('#rpostal_div').show();
    $('#rPostal').val($('#postal').val());
    $('#rCity').val($('#city').val());
    $('#residence').val($('#address').val());
    $('#residentialCountry')
         .val($('#country').val())
         .trigger('change');
    updateResidentialProvinces($('#province').val());
}

function clearResidence(){
    $('#residence_div').hide();
    $('#raddress_div').hide();
    $('#rcity_div').hide();
    $('#rprovince_div').hide();
    $('#rpostal_div').hide();
}
</script>

        <div class="control-group">
            <label class="control-label" for="residential"><bean:message key="demographic.demographiceditdemographic.sameresidence" /></label>
            <div class="controls" style="white-space: nowrap;">
              <%-- <bean:message key="WriteScript.msgYes"/>
            		<input type="radio" value="yes" name="residential" onclick="loadResidence();" id="residential"> --%>
                    <bean:message key="WriteScript.msgUnset"/>
            		<input type="radio" value="unset" name="residential" onclick="clearResidence();" checked >
          		<bean:message key="WriteScript.msgNo"/>
            		<input type="radio" value="no" name="residential" onclick="loadResidence();" >
				
            </div>
        </div>
        <div class="control-group" id="residence_div">
            <label class="control-label" for="residence"><bean:message key="demographic.demographiceditdemographic.formResidentialAddr" /></label>
            <div class="controls">
              <input type="text" id="residence" placeholder="<bean:message key="demographic.demographiceditdemographic.formResidentialAddr" />"
                    name="residentialAddress"
					>
            </div>
        </div>
        <div class="control-group" id="rcity_div">
            <label class="control-label" for="rCity"><bean:message key="demographic.demographiceditdemographic.formResidentialCity" /></label>
            <div class="controls">
              <input type="text" id="rCity" placeholder="<bean:message key="demographic.demographiceditdemographic.formResidentialCity" />"
                    name="residentialCity">
            </div>
        </div>
        <div class="control-group" id="rprovince_div">
            <label class="control-label" for="residentialProvince"><bean:message key="demographic.demographiceditdemographic.formResidentialProvince" /></label>
            <div class="controls">

				<%
					if("true".equals(OscarProperties.getInstance().getProperty("iso3166.2.enabled","false"))) {
				%>
					<select name="residentialProvince" id="residentialProvince"></select>
					<br/>
					<bean:message
					    key="demographic.demographiceditdemographic.filterByCountry" />: <select name="residentialCountry" id="residentialCountry" ></select>

				<% } else { %>
				<select id="residentialProvince" name="residentialProvince">
					<option value="OT"
						<%=defaultProvince.equals("")||defaultProvince.equals("OT")?" selected":""%>>Other</option>
					<%-- <option value="">None Selected</option> --%>
					<% if (pNames.isDefined()) {
                   for (ListIterator li = pNames.listIterator(); li.hasNext(); ) {
                       String province = (String) li.next(); %>
					<option value="<%=province%>"
						<%=province.equals(defaultProvince)?" selected":""%>><%=li.next()%></option>
					<% } %>
					<% } else { %>
					<option value="AB" <%=defaultProvince.equals("AB")?" selected":""%>>AB-Alberta</option>
					<option value="BC" <%=defaultProvince.equals("BC")?" selected":""%>>BC-British Columbia</option>
					<option value="MB" <%=defaultProvince.equals("MB")?" selected":""%>>MB-Manitoba</option>
					<option value="NB" <%=defaultProvince.equals("NB")?" selected":""%>>NB-New Brunswick</option>
					<option value="NL" <%=defaultProvince.equals("NL")?" selected":""%>>NL-Newfoundland & Labrador</option>
					<option value="NT" <%=defaultProvince.equals("NT")?" selected":""%>>NT-Northwest Territory</option>
					<option value="NS" <%=defaultProvince.equals("NS")?" selected":""%>>NS-Nova Scotia</option>
					<option value="NU" <%=defaultProvince.equals("NU")?" selected":""%>>NU-Nunavut</option>
					<option value="ON" <%=defaultProvince.equals("ON")?" selected":""%>>ON-Ontario</option>
					<option value="PE" <%=defaultProvince.equals("PE")?" selected":""%>>PE-Prince Edward Island</option>
					<option value="QC" <%=defaultProvince.equals("QC")?" selected":""%>>QC-Quebec</option>
					<option value="SK" <%=defaultProvince.equals("SK")?" selected":""%>>SK-Saskatchewan</option>
					<option value="YT" <%=defaultProvince.equals("YT")?" selected":""%>>YT-Yukon</option>
					<option value="US" <%=defaultProvince.equals("US")?" selected":""%>>US resident</option>
					<option value="US-AK" <%=defaultProvince.equals("US-AK")?" selected":""%>>US-AK-Alaska</option>
					<option value="US-AL" <%=defaultProvince.equals("US-AL")?" selected":""%>>US-AL-Alabama</option>
					<option value="US-AR" <%=defaultProvince.equals("US-AR")?" selected":""%>>US-AR-Arkansas</option>
					<option value="US-AZ" <%=defaultProvince.equals("US-AZ")?" selected":""%>>US-AZ-Arizona</option>
					<option value="US-CA" <%=defaultProvince.equals("US-CA")?" selected":""%>>US-CA-California</option>
					<option value="US-CO" <%=defaultProvince.equals("US-CO")?" selected":""%>>US-CO-Colorado</option>
					<option value="US-CT" <%=defaultProvince.equals("US-CT")?" selected":""%>>US-CT-Connecticut</option>
					<option value="US-CZ" <%=defaultProvince.equals("US-CZ")?" selected":""%>>US-CZ-Canal Zone</option>
					<option value="US-DC" <%=defaultProvince.equals("US-DC")?" selected":""%>>US-DC-District Of Columbia</option>
					<option value="US-DE" <%=defaultProvince.equals("US-DE")?" selected":""%>>US-DE-Delaware</option>
					<option value="US-FL" <%=defaultProvince.equals("US-FL")?" selected":""%>>US-FL-Florida</option>
					<option value="US-GA" <%=defaultProvince.equals("US-GA")?" selected":""%>>US-GA-Georgia</option>
					<option value="US-GU" <%=defaultProvince.equals("US-GU")?" selected":""%>>US-GU-Guam</option>
					<option value="US-HI" <%=defaultProvince.equals("US-HI")?" selected":""%>>US-HI-Hawaii</option>
					<option value="US-IA" <%=defaultProvince.equals("US-IA")?" selected":""%>>US-IA-Iowa</option>
					<option value="US-ID" <%=defaultProvince.equals("US-ID")?" selected":""%>>US-ID-Idaho</option>
					<option value="US-IL" <%=defaultProvince.equals("US-IL")?" selected":""%>>US-IL-Illinois</option>
					<option value="US-IN" <%=defaultProvince.equals("US-IN")?" selected":""%>>US-IN-Indiana</option>
					<option value="US-KS" <%=defaultProvince.equals("US-KS")?" selected":""%>>US-KS-Kansas</option>
					<option value="US-KY" <%=defaultProvince.equals("US-KY")?" selected":""%>>US-KY-Kentucky</option>
					<option value="US-LA" <%=defaultProvince.equals("US-LA")?" selected":""%>>US-LA-Louisiana</option>
					<option value="US-MA" <%=defaultProvince.equals("US-MA")?" selected":""%>>US-MA-Massachusetts</option>
					<option value="US-MD" <%=defaultProvince.equals("US-MD")?" selected":""%>>US-MD-Maryland</option>
					<option value="US-ME" <%=defaultProvince.equals("US-ME")?" selected":""%>>US-ME-Maine</option>
					<option value="US-MI" <%=defaultProvince.equals("US-MI")?" selected":""%>>US-MI-Michigan</option>
					<option value="US-MN" <%=defaultProvince.equals("US-MN")?" selected":""%>>US-MN-Minnesota</option>
					<option value="US-MO" <%=defaultProvince.equals("US-MO")?" selected":""%>>US-MO-Missouri</option>
					<option value="US-MS" <%=defaultProvince.equals("US-MS")?" selected":""%>>US-MS-Mississippi</option>
					<option value="US-MT" <%=defaultProvince.equals("US-MT")?" selected":""%>>US-MT-Montana</option>
					<option value="US-NC" <%=defaultProvince.equals("US-NC")?" selected":""%>>US-NC-North Carolina</option>
					<option value="US-ND" <%=defaultProvince.equals("US-ND")?" selected":""%>>US-ND-North Dakota</option>
					<option value="US-NE" <%=defaultProvince.equals("US-NE")?" selected":""%>>US-NE-Nebraska</option>
					<option value="US-NH" <%=defaultProvince.equals("US-NH")?" selected":""%>>US-NH-New Hampshire</option>
					<option value="US-NJ" <%=defaultProvince.equals("US-NJ")?" selected":""%>>US-NJ-New Jersey</option>
					<option value="US-NM" <%=defaultProvince.equals("US-NM")?" selected":""%>>US-NM-New Mexico</option>
					<option value="US-NU" <%=defaultProvince.equals("US-NU")?" selected":""%>>US-NU-Nunavut</option>
					<option value="US-NV" <%=defaultProvince.equals("US-NV")?" selected":""%>>US-NV-Nevada</option>
					<option value="US-NY" <%=defaultProvince.equals("US-NY")?" selected":""%>>US-NY-New York</option>
					<option value="US-OH" <%=defaultProvince.equals("US-OH")?" selected":""%>>US-OH-Ohio</option>
					<option value="US-OK" <%=defaultProvince.equals("US-OK")?" selected":""%>>US-OK-Oklahoma</option>
					<option value="US-OR" <%=defaultProvince.equals("US-OR")?" selected":""%>>US-OR-Oregon</option>
					<option value="US-PA" <%=defaultProvince.equals("US-PA")?" selected":""%>>US-PA-Pennsylvania</option>
					<option value="US-PR" <%=defaultProvince.equals("US-PR")?" selected":""%>>US-PR-Puerto Rico</option>
					<option value="US-RI" <%=defaultProvince.equals("US-RI")?" selected":""%>>US-RI-Rhode Island</option>
					<option value="US-SC" <%=defaultProvince.equals("US-SC")?" selected":""%>>US-SC-South Carolina</option>
					<option value="US-SD" <%=defaultProvince.equals("US-SD")?" selected":""%>>US-SD-South Dakota</option>
					<option value="US-TN" <%=defaultProvince.equals("US-TN")?" selected":""%>>US-TN-Tennessee</option>
					<option value="US-TX" <%=defaultProvince.equals("US-TX")?" selected":""%>>US-TX-Texas</option>
					<option value="US-UT" <%=defaultProvince.equals("US-UT")?" selected":""%>>US-UT-Utah</option>
					<option value="US-VA" <%=defaultProvince.equals("US-VA")?" selected":""%>>US-VA-Virginia</option>
					<option value="US-VI" <%=defaultProvince.equals("US-VI")?" selected":""%>>US-VI-Virgin Islands</option>
					<option value="US-VT" <%=defaultProvince.equals("US-VT")?" selected":""%>>US-VT-Vermont</option>
					<option value="US-WA" <%=defaultProvince.equals("US-WA")?" selected":""%>>US-WA-Washington</option>
					<option value="US-WI" <%=defaultProvince.equals("US-WI")?" selected":""%>>US-WI-Wisconsin</option>
					<option value="US-WV" <%=defaultProvince.equals("US-WV")?" selected":""%>>US-WV-West Virginia</option>
					<option value="US-WY" <%=defaultProvince.equals("US-WY")?" selected":""%>>US-WY-Wyoming</option>
					<% } %>
				</select>
				<% } %>
            </div>
        </div>
        <div class="control-group" id="rpostal_div">
            <label class="control-label" for="rPostal"><bean:message key="demographic.demographiceditdemographic.formResidentialPostal" />
            <%
                if (checkP) { %>
 					<span style="color:red">*</span>
 				 <% } %>
                </label>
            <div class="controls">
              <input type="text" id="rPostal" placeholder="<bean:message key="demographic.demographiceditdemographic.formResidentialPostal" />"
                    name="residentialPostal"
<% if (checkP) { %>
pattern="[ABCEGHJ-NPRSTVXY]\d[ABCEGHJ-NPRSTVXYWZ]\s\d[ABCEGHJ-NPRSTVXYWZ]\d"
data-validation-pattern-message="<bean:message key="demographic.demographiceditdemographic.alertpostal" />"
<% } %>
					onBlur="upCaseCtrl(this)" >
            </div>
        </div>
<!-- end residential -->
        <div class="control-group">
            <label class="control-label" for="phone_check"><bean:message key="demographic.demographiceditdemographic.formPhoneH" /><input type="checkbox" id="phone_check"></label>
            <div class="controls"  style="white-space:nowrap" >
              <input type="text" placeholder="<bean:message key="demographic.demographiceditdemographic.formPhoneH" />"
                    id="phone" name="phone"
					onBlur="formatPhone(this)"
					value="<%=Encode.forHtmlAttribute(phone)%>"
					class="input-medium"
					>
            <input type="text" name="hPhoneExt"
                    placeholder="<bean:message key="demographic.demographiceditdemographic.msgExt"/>"
                    class="input-mini"
					/>
            <input type="hidden" name="hPhoneExtOrig"
					 />
            </div>
        </div>
        <div class="control-group">
            <label class="control-label" for="phone2_check"><bean:message key="demographic.demographiceditdemographic.formPhoneW" /><input type="checkbox" id="phone2_check"></label>
            <div class="controls" style="white-space:nowrap" >
                <input type="text" id="phoneW" placeholder="<bean:message key="demographic.demographiceditdemographic.formPhoneW" />"
                    name="phone2"
                    value="<%=Encode.forHtmlAttribute(phone2)%>"
					onblur="formatPhone(this);"
                    class="input-medium"
					>
                <input type="text" name="wPhoneExt"
                    placeholder="<bean:message key="demographic.demographiceditdemographic.msgExt"/>"
                    class="input-mini" />
                <input type="hidden" name="wPhoneExtOrig"
					 />
            </div>
        </div>
        <div class="control-group">
            <label class="control-label" for="cell_check"><bean:message key="demographic.demographiceditdemographic.formPhoneC" /><input type="checkbox" id="cell_check"></label>
            <div class="controls">
              <input type="text" id="cell" placeholder="<bean:message key="demographic.demographiceditdemographic.formPhoneC" />"
                    name="demo_cell" onblur="formatPhone(this);"
					>
				<input type="hidden" name="demo_cellOrig"  />
            </div>
        </div>
        <div class="control-group">
            <label class="control-label" for="commentP"><bean:message key="demographic.demographicaddrecordhtm.formPhoneComment" /></label>
            <div class="controls">
              <input type="text" id="commentP" placeholder="<bean:message key="demographic.demographicaddrecordhtm.formPhoneComment" />"
                    name="phoneComment"
                    >
               <input type="hidden" name="phoneCommentOrig"
					 />
            </div>
        </div>

        <%
            String entityType = OscarProperties.getInstance().getProperty("ENTITY_TYPE", "");
            String preferredPharmacyId = OscarProperties.getInstance().getProperty("PREFERRED_PHARMACY", "");
            boolean isPharmacy = "pharmacy".equalsIgnoreCase(entityType);
        %>

<% if (!isPharmacy) { %>
<div class="control-group">
    <label class="control-label" for="preferredPharmacy">Preferred Pharmacy:</label>

    <div class="custom-dropdown" id="preferredPharmacyDropdown">
        <button class="dropdown-toggle" id="dropdownToggle" onclick="fetchAndLogAddressValues(); fetchPharmaciesSortedByDistance(0, 0);">
            Select Pharmacy
        </button>
        <div class="dropdown-menu" id="dropdownMenu">
            <input type="text" id="dropdownSearch" placeholder="Search for a pharmacy..." class="dropdown-search">
            <div id="dropdownOptionsContainer"></div>
        </div>
    </div>

    <input type="hidden" name="preferredPharmacy" id="preferredPharmacy" value="">
</div>
<% } else { %>
    <!-- Hidden field only for pharmacy (no label, no UI shown) -->
    <input type="hidden" name="preferredPharmacy" id="preferredPharmacy" value="<%= preferredPharmacyId + "|active" %>">
<% } %>


        <%-- <div class="control-group">
    <label class="control-label" for="preferredPharmacy">Preferred Pharmacy:</label>
    <div class="controls">
        <select id="preferredPharmacy" name="preferredPharmacy" class="form-control">
            <option value="">Select Pharmacy</option>
        </select>
    </div>
</div> --%>

        <%-- <div class="control-group">
            <label class="control-label" for="news"><bean:message key="demographic.demographiceditdemographic.formNewsLetter" /></label>
            <div class="controls">
              <% String newsletter =  "Unknown";

								  %>
                <select name="newsletter" id="news" >
								    <option value="Unknown" ><bean:message
								        key="demographic.demographicaddrecordhtm.formNewsLetter.optUnknown" /></option>
								    <option value="No" ><bean:message
								        key="demographic.demographicaddrecordhtm.formNewsLetter.optNo" /></option>
								    <option value="Paper" ><bean:message
								        key="demographic.demographicaddrecordhtm.formNewsLetter.optPaper" /></option>
								    <option value="Electronic"
								        ><bean:message
								        key="demographic.demographicaddrecordhtm.formNewsLetter.optElectronic" /></option>
                </select>
            </div>
        </div>
        <div class="control-group">
            <label class="control-label" for="phr"><bean:message key="demographic.demographiceditdemographic.formPHRUserName" /></label>
            <div class="controls">
              <input type="text" id="phr" placeholder="<bean:message key="demographic.demographiceditdemographic.formPHRUserName" />"
                    name="myOscarUserName"
									>


            </div>
        </div> --%>
        </div><!-- end contactSectionContent -->
    </div><!-- end contactSection -->

    <div id="insurance" class="span11 accordion-group" style="width: 600px; margin-left: 0;">
		<%-- <fieldset class="accordion-heading" title="<bean:message key="global.btnToggle"/>">
			<legend class="accordion-toggle" data-toggle="collapse" data-parent="#editWrapper" data-target="#insuranceSectionContent">
			    <bean:message key="demographic.demographiceditdemographic.msgHealthIns"/>
                <i class="icon-edit" style="float: right; margin-top: 10px;" title="<bean:message key="demographic.demographiceditdemographic.msgEdit"/>"></i>
            </legend>
		</fieldset>
        <div id="insuranceSectionContent" class="accordion-body collapse" > --%>
        <div style="padding-left: 10px;">
        <h3><bean:message key="demographic.demographiceditdemographic.msgHealthIns"/></h3>
        </div>
        <div id="insuranceSectionContent">
        <div class="control-group">
            <label class="control-label" for="hc_type"><bean:message key="demographic.demographiceditdemographic.formHCType" /></label>
            <div class="controls">

				<select name="hc_type" id="hc_type" onchange="autoFillHin();">
					<option value="OT"
						<%=HCType.equals("")||HCType.equals("OT")?" selected":""%>>Other</option>
					<% if (pNames.isDefined()) {
                   for (ListIterator li = pNames.listIterator(); li.hasNext(); ) {
                       String province = (String) li.next(); %>
                       <option value="<%=province%>"<%=province.equals(HCType)?" selected":""%>><%=li.next()%></option>
                   <% } %>
            <% } else { %>
		<option value="AB"<%=HCType.equals("AB")?" selected":""%>>AB-Alberta</option>
		<option value="BC"<%=HCType.equals("BC")?" selected":""%>>BC-British Columbia</option>
		<option value="MB"<%=HCType.equals("MB")?" selected":""%>>MB-Manitoba</option>
		<option value="NB"<%=HCType.equals("NB")?" selected":""%>>NB-New Brunswick</option>
		<option value="NL"<%=HCType.equals("NL")?" selected":""%>>NL-Newfoundland & Labrador</option>
		<option value="NT"<%=HCType.equals("NT")?" selected":""%>>NT-Northwest Territory</option>
		<option value="NS"<%=HCType.equals("NS")?" selected":""%>>NS-Nova Scotia</option>
		<option value="NU"<%=HCType.equals("NU")?" selected":""%>>NU-Nunavut</option>
		<option value="ON"<%=HCType.equals("ON")?" selected":""%>>ON-Ontario</option>
		<option value="PE"<%=HCType.equals("PE")?" selected":""%>>PE-Prince Edward Island</option>
		<option value="QC"<%=HCType.equals("QC")?" selected":""%>>QC-Quebec</option>
		<option value="SK"<%=HCType.equals("SK")?" selected":""%>>SK-Saskatchewan</option>
		<option value="YT"<%=HCType.equals("YT")?" selected":""%>>YT-Yukon</option>
		<option value="US"<%=HCType.equals("US")?" selected":""%>>US resident</option>
		<option value="US-AK" <%=HCType.equals("US-AK")?" selected":""%>>US-AK-Alaska</option>
		<option value="US-AL" <%=HCType.equals("US-AL")?" selected":""%>>US-AL-Alabama</option>
		<option value="US-AR" <%=HCType.equals("US-AR")?" selected":""%>>US-AR-Arkansas</option>
		<option value="US-AZ" <%=HCType.equals("US-AZ")?" selected":""%>>US-AZ-Arizona</option>
		<option value="US-CA" <%=HCType.equals("US-CA")?" selected":""%>>US-CA-California</option>
		<option value="US-CO" <%=HCType.equals("US-CO")?" selected":""%>>US-CO-Colorado</option>
		<option value="US-CT" <%=HCType.equals("US-CT")?" selected":""%>>US-CT-Connecticut</option>
		<option value="US-CZ" <%=HCType.equals("US-CZ")?" selected":""%>>US-CZ-Canal Zone</option>
		<option value="US-DC" <%=HCType.equals("US-DC")?" selected":""%>>US-DC-District Of Columbia</option>
		<option value="US-DE" <%=HCType.equals("US-DE")?" selected":""%>>US-DE-Delaware</option>
		<option value="US-FL" <%=HCType.equals("US-FL")?" selected":""%>>US-FL-Florida</option>
		<option value="US-GA" <%=HCType.equals("US-GA")?" selected":""%>>US-GA-Georgia</option>
		<option value="US-GU" <%=HCType.equals("US-GU")?" selected":""%>>US-GU-Guam</option>
		<option value="US-HI" <%=HCType.equals("US-HI")?" selected":""%>>US-HI-Hawaii</option>
		<option value="US-IA" <%=HCType.equals("US-IA")?" selected":""%>>US-IA-Iowa</option>
		<option value="US-ID" <%=HCType.equals("US-ID")?" selected":""%>>US-ID-Idaho</option>
		<option value="US-IL" <%=HCType.equals("US-IL")?" selected":""%>>US-IL-Illinois</option>
		<option value="US-IN" <%=HCType.equals("US-IN")?" selected":""%>>US-IN-Indiana</option>
		<option value="US-KS" <%=HCType.equals("US-KS")?" selected":""%>>US-KS-Kansas</option>
		<option value="US-KY" <%=HCType.equals("US-KY")?" selected":""%>>US-KY-Kentucky</option>
		<option value="US-LA" <%=HCType.equals("US-LA")?" selected":""%>>US-LA-Louisiana</option>
		<option value="US-MA" <%=HCType.equals("US-MA")?" selected":""%>>US-MA-Massachusetts</option>
		<option value="US-MD" <%=HCType.equals("US-MD")?" selected":""%>>US-MD-Maryland</option>
		<option value="US-ME" <%=HCType.equals("US-ME")?" selected":""%>>US-ME-Maine</option>
		<option value="US-MI" <%=HCType.equals("US-MI")?" selected":""%>>US-MI-Michigan</option>
		<option value="US-MN" <%=HCType.equals("US-MN")?" selected":""%>>US-MN-Minnesota</option>
		<option value="US-MO" <%=HCType.equals("US-MO")?" selected":""%>>US-MO-Missouri</option>
		<option value="US-MS" <%=HCType.equals("US-MS")?" selected":""%>>US-MS-Mississippi</option>
		<option value="US-MT" <%=HCType.equals("US-MT")?" selected":""%>>US-MT-Montana</option>
		<option value="US-NC" <%=HCType.equals("US-NC")?" selected":""%>>US-NC-North Carolina</option>
		<option value="US-ND" <%=HCType.equals("US-ND")?" selected":""%>>US-ND-North Dakota</option>
		<option value="US-NE" <%=HCType.equals("US-NE")?" selected":""%>>US-NE-Nebraska</option>
		<option value="US-NH" <%=HCType.equals("US-NH")?" selected":""%>>US-NH-New Hampshire</option>
		<option value="US-NJ" <%=HCType.equals("US-NJ")?" selected":""%>>US-NJ-New Jersey</option>
		<option value="US-NM" <%=HCType.equals("US-NM")?" selected":""%>>US-NM-New Mexico</option>
		<option value="US-NU" <%=HCType.equals("US-NU")?" selected":""%>>US-NU-Nunavut</option>
		<option value="US-NV" <%=HCType.equals("US-NV")?" selected":""%>>US-NV-Nevada</option>
		<option value="US-NY" <%=HCType.equals("US-NY")?" selected":""%>>US-NY-New York</option>
		<option value="US-OH" <%=HCType.equals("US-OH")?" selected":""%>>US-OH-Ohio</option>
		<option value="US-OK" <%=HCType.equals("US-OK")?" selected":""%>>US-OK-Oklahoma</option>
		<option value="US-OR" <%=HCType.equals("US-OR")?" selected":""%>>US-OR-Oregon</option>
		<option value="US-PA" <%=HCType.equals("US-PA")?" selected":""%>>US-PA-Pennsylvania</option>
		<option value="US-PR" <%=HCType.equals("US-PR")?" selected":""%>>US-PR-Puerto Rico</option>
		<option value="US-RI" <%=HCType.equals("US-RI")?" selected":""%>>US-RI-Rhode Island</option>
		<option value="US-SC" <%=HCType.equals("US-SC")?" selected":""%>>US-SC-South Carolina</option>
		<option value="US-SD" <%=HCType.equals("US-SD")?" selected":""%>>US-SD-South Dakota</option>
		<option value="US-TN" <%=HCType.equals("US-TN")?" selected":""%>>US-TN-Tennessee</option>
		<option value="US-TX" <%=HCType.equals("US-TX")?" selected":""%>>US-TX-Texas</option>
		<option value="US-UT" <%=HCType.equals("US-UT")?" selected":""%>>US-UT-Utah</option>
		<option value="US-VA" <%=HCType.equals("US-VA")?" selected":""%>>US-VA-Virginia</option>
		<option value="US-VI" <%=HCType.equals("US-VI")?" selected":""%>>US-VI-Virgin Islands</option>
		<option value="US-VT" <%=HCType.equals("US-VT")?" selected":""%>>US-VT-Vermont</option>
		<option value="US-WA" <%=HCType.equals("US-WA")?" selected":""%>>US-WA-Washington</option>
		<option value="US-WI" <%=HCType.equals("US-WI")?" selected":""%>>US-WI-Wisconsin</option>
		<option value="US-WV" <%=HCType.equals("US-WV")?" selected":""%>>US-WV-West Virginia</option>
		<option value="US-WY" <%=HCType.equals("US-WY")?" selected":""%>>US-WY-Wyoming</option>
          <% } %>
          </select>
            </div>
        </div>
        <div class="control-group" style="white-space:nowrap">
            <label class="control-label" for="hin"><bean:message key="demographic.demographiceditdemographic.formHin" /></label>
            <div class="controls">
              <input type="text" placeholder="<bean:message key="demographic.demographiceditdemographic.formHin" />"
                    name="hin" id="hin"
                    value="<%=Encode.forHtmlAttribute(hin)%>"
					class="input-medium" >
            <bean:message key="demographic.demographiceditdemographic.formVer" />
            <input type="text" placeholder="<bean:message key="demographic.demographiceditdemographic.formVer" />"
                    name="ver" style="width: 40px;"
                    value="<%=Encode.forHtmlAttribute(ver)%>"
					onBlur="upCaseCtrl(this)" id="verBox">
					<%if("online".equals(oscarProps.getProperty("hcv.type", "simple"))) { %>
					  <input type="button" class="btn" value="Validate" onClick="validateHC()"/>
					<% } %>
            </div>
        </div>
        <div class="control-group">
            <label class="control-label" for="eff_date"><bean:message key="demographic.demographiceditdemographic.formEFFDate" /></label>
            <div class="controls">
<script>
function loaddob(){
console.log("DOB is "+document.getElementById('year_of_birth').value+"-"+document.getElementById('month_of_birth').value+"-"+document.getElementById('date_of_birth').value);
    document.getElementById('inputDOB').value=document.getElementById('year_of_birth').value+"-"+document.getElementById('month_of_birth').value+"-"+document.getElementById('date_of_birth').value;

}
function parsedob_date(){
    var input=document.getElementById('inputDOB').value;
    year="";
    month="";
    day="";
    if (input != ""){
        const myArr = input.split("-");
        year = myArr[0];
        month = myArr[1];
        day = myArr[2];
    }
        document.getElementById('year_of_birth').value = year
        document.getElementById('month_of_birth').value = month
        document.getElementById('date_of_birth').value = day
}

function parseeff_date(){
    var input=document.getElementById('eff_date').value;
    year="";
    month="";
    day="";
    if (input != ""){
        const myArr = input.split("-");
        year = myArr[0];
        month = myArr[1];
        day = myArr[2];
    }
console.log(year+"-"+month+"-"+day);
        document.getElementById('eff_date_year').value = year
        document.getElementById('eff_date_month').value = month
        document.getElementById('eff_date_day').value = day
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
console.log(year+"-"+month+"-"+day);
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
console.log(year+"-"+month+"-"+day);
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
console.log(year+"-"+month+"-"+day);
        document.getElementById('end_date_year').value = year
        document.getElementById('end_date_month').value = month
        document.getElementById('end_date_day').value = day

}



function parsepatient_status_date(){
    var input=document.getElementById('patient_status_date').value;
    year="";
    month="";
    day="";
    if (input != ""){
        const myArr = input.split("-");
        year = myArr[0];
        month = myArr[1];
        day = myArr[2];
    }
console.log(year+"-"+month+"-"+day);
        document.getElementById('patient_status_date_year').value = year
        document.getElementById('patient_status_date_month').value = month
        document.getElementById('patient_status_date_day').value = day
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
console.log(year+"-"+month+"-"+day);
        document.getElementById('date_joined_year').value = year
        document.getElementById('date_joined_month').value = month
        document.getElementById('date_joined_day').value = day
}
</script>
                <input type="date" id="eff_date" name="eff_date"  onchange="parseeff_date();">
                <input type="hidden" name="eff_date_year" id="eff_date_year">
                <input type="hidden" name="eff_date_month" id="eff_date_month">
                <input type="hidden" name="eff_date_day" id="eff_date_day">
            </div>
        </div>

        <div class="control-group">
            <label class="control-label" for="hc_renew_date"><bean:message key="demographic.demographiceditdemographic.formHCRenewDate" /></label>
            <div class="controls">
                <input type="date" id="hc_renew_date" name="hc_renew_date" onchange="parsehc_renew_date();" >
                <input type="hidden" name="hc_renew_date_year" id="hc_renew_date_year">
                <input type="hidden" name="hc_renew_date_month" id="hc_renew_date_month">
                <input type="hidden" name="hc_renew_date_day" id="hc_renew_date_day">
            </div>
        </div>
        <div class="control-group">
            <label class="control-label" for="date_joined"><bean:message key="demographic.demographiceditdemographic.formDateJoined1" /></label>
            <div class="controls">
                <input type="date" id="date_joined" name="date_joined" onchange="parsedate_joined();" >
                <input type="hidden" name="date_joined_year" id="date_joined_year">
                <input type="hidden" name="date_joined_month" id="date_joined_month">
                <input type="hidden" name="date_joined_day" id="date_joined_day">
            </div>
        </div>

        <div class="control-group">
            <label class="control-label" for="end_date" ><bean:message key="demographic.demographiceditdemographic.formEndDate" /></label>
            <div class="controls">
              <input type="date" id="end_date" name="end_date" onchange="parseend_date();" >
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
                <%String rosterStatus = "";%>
                <input type="hidden" name="initial_rosterstatus" />
                <select id="roster_status" name="roster_status" style="width: 120px;"
                onchange="if (this.value=='RO'){$('#roster_to_div').show();$('#roster_date_div').show(); } else {$('#roster_to_div').hide();$('#roster_date_div').hide();}"
                >
									<option value="" label="<bean:message key="demographic.demographiceditdemographic.msgNotSet"/>"></option>
									<option value="RO"
										>
									<bean:message key="demographic.demographiceditdemographic.optRostered"/></option>
									<!--
									<option value="NR"
										>
									<bean:message key="demographic.demographiceditdemographic.optNotRostered"/></option>
									-->
									<option value="TE"
										>
									<bean:message key="demographic.demographiceditdemographic.optTerminated"/></option>

									<option value="FS"
										>
									<bean:message key="demographic.demographiceditdemographic.optFeeService"/></option>
									<%
									for(String status: demographicDao.getRosterStatuses()) {
									%>
									<option
										><%=status%></option>
									<% }

                                   // end while %>
                </select>
                <security:oscarSec roleName="<%=roleName$%>" objectName="_admin.demographic" rights="r" reverse="<%=false%>">
                    <sup><input type="button" class="btn btn-link" onClick="newStatus1();" value="<bean:message key="demographic.demographiceditdemographic.btnAddNew"/>"></sup>
                </security:oscarSec>
            </div>
        </div>
        <div class="control-group" id="roster_date_div" >
            <label class="control-label" for="roster_date" title="<bean:message key="demographic.demographiceditdemographic.DateJoined" />"><bean:message key="demographic.demographiceditdemographic.DateJoined" /></label>
            <div class="controls">
              <input type="date" id="roster_date" name="roster_date" onchange="parseroster_date();" data-validation-required-message="<bean:message key="demographic.demographiceditdemographic.alertrosterdate" />">
<input  type="hidden" name="roster_date_year" id="roster_date_year">
<input  type="hidden" name="roster_date_month" id="roster_date_month">
<input  type="hidden" name="roster_date_day" id="roster_date_day">
            </div>
        </div>
        <div class="control-group" id="roster_to_div" >
            <label class="control-label" for="roster_enrolled_to"><bean:message key="demographic.demographiceditdemographic.RosterEnrolledTo" /></label>
            <div class="controls">
                <select id="roster_enrolled_to"  name="roster_enrolled_to" style="width: 160px;" data-validation-required-message="<bean:message key="demographic.demographiceditdemographic.alertenrollto" />" >
					<option value="" label="<bean:message key="demographic.demographiceditdemographic.msgNotSet"/>"></option>
					<%
						for (Provider p : providerDao.getActiveProvidersByRole("doctor")) {
								String docProviderNo = p.getProviderNo();
					%>
					<option id="<%=docProviderNo%>" value="<%=docProviderNo%>"><%=p.getFormattedName()%></option>
					<%
						}
					%>
				</select>
                <p class="help-block text-danger"></p>
            </div>
        </div>


</oscar:oscarPropertiesCheck>
<%-- END TOGGLE OFF PATIENT ROSTERING --%>
        <div class="control-group">
            <label class="control-label" for="pstatus"><bean:message key="demographic.demographiceditdemographic.formPatientStatus" /></label>
            <div class="controls">
								<%
                                String patientStatus = "";%>
                                <input type="hidden" name="initial_patientstatus" value="<%=patientStatus%>">
								<select name="patient_status" id="pstatus" style="width: 120px" onChange="updatePatientStatusDate()">
									<option value="AC"
										>
									<bean:message key="demographic.demographiceditdemographic.optActive"/></option>
									<option value="IN"
										>
									<bean:message key="demographic.demographiceditdemographic.optInActive"/></option>
									<option value="DE"
										>
									<bean:message key="demographic.demographiceditdemographic.optDeceased"/></option>
									<option value="MO"
										>
									<bean:message key="demographic.demographiceditdemographic.optMoved"/></option>
									<option value="FI"
										>
									<bean:message key="demographic.demographiceditdemographic.optFired"/></option>
									<%
									for(String status : demographicDao.search_ptstatus()) {
                                     %>
									<option
										><%=status%></option>
									<% }

                                   // end while %>
								</select>
                        <security:oscarSec roleName="<%=roleName$%>" objectName="_admin.demographic" rights="r" reverse="<%=false%>">
                                 <sup><input type="button" class="btn btn-link" onClick="newStatus();" value="<bean:message key="demographic.demographiceditdemographic.btnAddNew"/>"></sup>
						</security:oscarSec>
            </div>
        </div>

        <div class="control-group">
            <label class="control-label" for="patient_status_date"><bean:message key="demographic.demographiceditdemographic.PatientStatusDate" /></label>
            <div class="controls">
                <input type="date" id="patient_status_date" name="patient_status_date" onchange="parsepatient_status_date();" >
<input type="hidden" name="patient_status_date_year" id="patient_status_date_year">
<input type="hidden" name="patient_status_date_month" id="patient_status_date_month">
<input type="hidden" name="patient_status_date_day" id="patient_status_date_day">
            </div>
</div>
        </div><!-- end insuranceSectionContent -->
    </div><!-- end insurance -->

<%-- TOGGLE OFF PATIENT CLINIC STATUS --%>
<oscar:oscarPropertiesCheck property="DEMOGRAPHIC_PATIENT_CLINIC_STATUS" value="true">
    <div id="team" class="span11 accordion-group" style="width: 600px; margin-left: 0;"><!--Care Team -->
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
                <select name="staff" id="mrp">
					<option value="" label="<bean:message key="demographic.demographiceditdemographic.msgNotSet"/>"></option>
					<%
						for (Provider p : providerDao.getActiveProvidersByRole("doctor")) {
								String docProviderNo = p.getProviderNo();
					%>
					<option id="doc<%=docProviderNo%>" value="<%=docProviderNo%>"><%=Misc.getShortStr((p.getFormattedName()), "", 12)%></option>
					<%
						}
					%>
					<option value="" label="<bean:message key="demographic.demographiceditdemographic.msgNotSet"/>"></option>
				</select>
            </div>
        </div>
        <div class="control-group">
            <label class="control-label" for="cust1"><bean:message key="demographic.demographiceditdemographic.formNurse" /></label>
            <div class="controls">
              <select name="cust1" id="cust1">
					<option value="" label="<bean:message key="demographic.demographiceditdemographic.msgNotSet"/>" ></option>
					<%
					for(Provider p: providerDao.getActiveProvidersByRole("nurse")) {
%>
					<option value="<%=p.getProviderNo()%>"><%=Encode.forHtmlContent(Misc.getShortStr( (p.getFormattedName()),"",12))%></option>
					<%
  }

%>
				</select>
            </div>
        </div>
        <div class="control-group">
            <label class="control-label" for="cust4"><bean:message key="demographic.demographiceditdemographic.formMidwife" /></label>
            <div class="controls">
              <select name="cust4" id="cust4">
					<option value="" label="<bean:message key="demographic.demographiceditdemographic.msgNotSet"/>"></option>
					<%
					for(Provider p: providerDao.getActiveProvidersByRole("midwife")) {
%>
					<option value="<%=p.getProviderNo()%>">
					<%=Encode.forHtmlContent(Misc.getShortStr( (p.getFormattedName()),"",12))%></option>
					<%
  }

%>
				</select>
            </div>
        </div>
        <div class="control-group">
            <label class="control-label" for="cust2"><bean:message key="demographic.demographiceditdemographic.formResident" /></label>
            <div class="controls">
              <select name="cust2"  id="cust2">
					<option value="" label="<bean:message key="demographic.demographiceditdemographic.msgNotSet"/>"></option>
					<%
					for(Provider p: providerDao.getActiveProvidersByRole("doctor")) {
%>
					<option value="<%=p.getProviderNo()%>">
					<%=Encode.forHtmlContent(Misc.getShortStr( (p.getFormattedName()),"",12))%></option>
					<%
  }

%>
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

             %> <select name="r_doctor"
					onChange="changeRefDoc()" id="r_doc">
					<option value="" label="<bean:message key="demographic.demographiceditdemographic.msgNotSet"/>"></option>
					<% for(int k=0; k<vecRef.size(); k++) {
                         prop= (Properties) vecRef.get(k);
                    %>
					<option
						value="<%=prop.getProperty("last_name")+","+prop.getProperty("first_name")%>"
						>
					    <%=prop.getProperty("last_name")+","+prop.getProperty("first_name")%></option>
					<% } %>
                </select>
<script language="Javascript">
<!--
function changeRefDoc() {

var refName = document.forms[1].r_doctor.options[document.forms[1].r_doctor.selectedIndex].value;
var refNo = "";
  	<% for(int k=0; k<vecRef.size(); k++) {
  		prop= (Properties) vecRef.get(k);
  	%>
if(refName.indexOf("<%=prop.getProperty("last_name")+","+prop.getProperty("first_name")%>")>=0) {
  refNo = '<%=prop.getProperty("referral_no", "")%>';
}
<% } %>
document.forms[1].r_doctor_ohip.value = refNo;
}
//-->
</script> <% } else {%>
                <input type="text" name="r_doctor" id="r_doctor"  <% } %>
            </div>
        </div>
        <div class="control-group">
            <label class="control-label" for="r_doctor_ohip"><bean:message key="demographic.demographiceditdemographic.formRefDocNo" /></label>
            <div class="controls">
              <input type="text" name="r_doctor_ohip" id="r_doctor_ohip"
					> <% if("ON".equals(prov)) { %>
					    <sup><a class="btn btn-link" href="javascript:referralScriptAttach2('r_doctor_ohip','r_doctor')">
                        <bean:message key="demographic.demographiceditdemographic.btnSearch"/>#</a> </sup>
                    <% } %>
            </div>
        </div>
    </div><!-- end teamSectionContent -->
    </div><!-- end Team -->
</oscar:oscarPropertiesCheck>
<%-- END TOGGLE OFF PATIENT CLINIC STATUS --%>
<%-- WAITING LIST MODULE --%>
        <oscar:oscarPropertiesCheck property="DEMOGRAPHIC_WAITING_LIST" value="true">
    <div id="wl" class="span11 accordion-group" style="width: 600px; margin-left: 0;">
		<fieldset class="accordion-heading" title="<bean:message key="global.btnToggle"/>">
			<legend class="accordion-toggle" data-toggle="collapse" data-parent="#editWrapper" data-target="#wlSectionContent">
			    <bean:message key="demographic.demographiceditdemographic.msgWaitList"/>
                <i class="icon-edit" style="float: right; margin-top: 10px;" title="<bean:message key="demographic.demographiceditdemographic.msgEdit"/>"></i>
            </legend>
		</fieldset>
        <div id="wlSectionContent" class="accordion-body collapse" >
            <div class="control-group">
                <label class="control-label" for="name_list_id"><a href="<%=request.getContextPath() %>/oscarWaitingList/WLEditWaitingListNameAction.do?waitingListId=&edit=Y" target="_blank"><bean:message key="demographic.demographiceditdemographic.msgWaitList"/></a></label>
                <div class="controls">

<%

        String wLReadonly = "";
        WaitingList wL = WaitingList.getInstance();
        if(!wL.getFound()){
            wLReadonly = "readonly";
            }
    %>
			        <select id="name_list_id" name="list_id">
							<% if(wLReadonly.equals("")){ %>
							<option value="0"><bean:message key="demographic.demographiceditdemographic.msgNotSet"/></option>
							<%}else{ %>
							<option value="0"><bean:message key="demographic.demographicaddarecordhtm.optCreateWaitList"/>
							</option>
							<%} %>
							<%
							for(WaitingListName wln : waitingListNameDao.findCurrentByGroup(((ProviderPreference)session.getAttribute(SessionConstants.LOGGED_IN_PROVIDER_PREFERENCE)).getMyGroupNo())) {

                                    %>
							<option value="<%=wln.getId()%>"><%=wln.getName()%></option>
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
                        name="waiting_list_note" >
                </div>
            </div>
            <div class="control-group">
                <label class="control-label" for="wldate"><bean:message key="demographic.demographiceditdemographic.msgDateOfReq"/></label>
                <div class="controls">
                    <input type="date" id="wldate" name="waiting_list_referral_date">
                </div>
            </div>
    </div><!--end wlContentSection -->
    </div><!--end wl -->
        </oscar:oscarPropertiesCheck>
<%-- END WAITING LIST MODULE --%>
    <div id="additional" class="span11 accordion-group" style="width: 600px; margin-left: 0;"><!--additional -->
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
                    name="cytolNum"
					>
			    <input type="hidden" name="cytolNumOrig"
					>
            </div>
        </div>
 <%if(!"true".equals(OscarProperties.getInstance().getProperty("phu.hide","false"))) { %>
        <div class="control-group">
            <label class="control-label" for="PHU"><bean:message key="demographic.demographiceditdemographic.formPHU" /></label>
            <div class="controls">
                	<select id="PHU" name="PHU" >
					<option value="" label="<bean:message key="demographic.demographiceditdemographic.msgNotSet"/>">Select Below</option>
					<%
						String defaultPhu = OscarProperties.getInstance().getProperty("default_phu");

						LookupListManager lookupListManager = SpringUtils.getBean(LookupListManager.class);
						LookupList ll = lookupListManager.findLookupListByName(LoggedInInfo.getLoggedInInfoFromSession(request), "phu");
						if(ll != null) {
							for(LookupListItem llItem : ll.getItems()) {
								String selected = "";
								if (llItem.getValue().equals("")) {
    selected = " selected=\"selected\" "; // Default to "Not Set"
} else if (llItem.getValue().equals(defaultPhu)) {
    selected = ""; // Do not select "default_phu"
}

								%>
									<option value="<%=llItem.getValue()%>" <%=selected%>><%=llItem.getLabel()%></option>
								<%
							}
						} else {
							%>
							<option value="" label="<bean:message key="demographic.demographiceditdemographic.msgNotSet"/>">None Available</option>
						<%
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
                <input type="text" id="chart_no" name="chart_no" placeholder="<bean:message key="demographic.demographiceditdemographic.formChartNo" />"  >
            </div>
        </div>
        <div class="control-group">
            <label class="control-label" for="paper_chart_archived"><bean:message key="web.record.details.archivedPaperChart" /></label>
            <div class="controls">

	             <select name="paper_chart_archived" id="paper_chart_archived" style="width:50px;" onChange="updatePaperArchive()">
		            <option value="" label="<bean:message key="demographic.demographiceditdemographic.msgNotSet"/>" >
		                            	</option>
					<option value="NO" >
											<bean:message key="demographic.demographiceditdemographic.paperChartIndicator.no"/>
										</option>
					<option value="YES"	>
											<bean:message key="demographic.demographiceditdemographic.paperChartIndicator.yes"/>
										</option>
				</select>
                <input type="date" name="paper_chart_archived_date" class="input-medium" id="paper_chart_archived_date"  >
				<input type="hidden" name="paper_chart_archived_program" id="paper_chart_archived_program" >
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
            <label class="control-label" ><c:out value="${ consentType.name }" /></label>

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
                    name="meditech_id">
                <input type="hidden" name="meditech_idOrig"
					>
            </div>
        </div>
        <div class="control-group">
            <label class="control-label" for="rxInteractionWarningLevel"><bean:message key="demographic.demographiceditdemographic.rxInteractionWarningLevel" /></label>
            <div class="controls">
                <input type="hidden" name="rxInteractionWarningLevelOrig"
							>
			<select id="rxInteractionWarningLevel" name="rxInteractionWarningLevel">
				<option value="0" >Not Specified</option>
				<option value="1" >Low</option>
				<option value="2" >Medium</option>
				<option value="3" >High</option>
				<option value="4" >None</option>
			</select>
            </div>
        </div>

<%--  PROGRAM ADMISSIONS --%>

                <div class="control-group">
                    <label class="control-label" for="rsid"><bean:message key="demographic.demographiceditdemographic.programAdmissions" /></label>
                    <div class="controls">
                        <select id="rsid" name="rps">
                                    <%
                                        GenericIntakeEditAction gieat = new GenericIntakeEditAction();
                                        gieat.setProgramManager(pm);

                                        String _pvid = loggedInInfo.getLoggedInProviderNo();
                                        Set<Program> pset = gieat.getActiveProviderProgramsInFacility(loggedInInfo,_pvid,loggedInInfo.getCurrentFacility().getId());
                                        List<Program> bedP = gieat.getBedPrograms(pset,_pvid);
                                        List<Program> commP = gieat.getCommunityPrograms();

                                        for(Program _p:bedP){
                                    %>
                                        <option value="<%=_p.getId()%>" <%=("OSCAR".equals(_p.getName())?" selected=\"selected\" ":"")%> ><%=_p.getName()%></option>
                                    <%
                                        }
                                     %>
                        </select>
                    </div>
                </div>
                <div class="control-group">
                    <label class="control-label" ><bean:message key="demographic.demographiceditdemographic.servicePrograms" /></label>
                    <div class="controls">
<%
			                        List<Program> servP = gieat.getServicePrograms(pset,_pvid);
			                        for(Program _p:servP){
			                    %>
			                        <input type="checkbox" name="sp" value="<%=_p.getId()%>"/><%=_p.getName()%><br/>
			                    <%}%>

                    </div>
                </div>

<%-- END PROGRAM ADMISSIONS --%>

        <oscar:oscarPropertiesCheck property="INTEGRATOR_LOCAL_STORE" value="yes">
                <div class="control-group">
                    <label class="control-label" for="primaryEMR"><bean:message key="demographic.demographiceditdemographic.primaryEMR" /></label>
                    <div class="controls">
                        <input type="hidden" name="rxInteractionWarningLevelOrig"
							        />
		            <%
		               	String primaryEMR ="0";
		            %>
			        <input type="hidden" name="primaryEMROrig"  />
			        <select id="primaryEMR" name="primaryEMR">
				        <option value="0" <%=(primaryEMR.equals("0")?"selected=\"selected\"":"") %>>No</option>
				        <option value="1" <%=(primaryEMR.equals("1")?"selected=\"selected\"":"") %>>Yes</option>
			        </select>
                    </div>
                </div>

		</oscar:oscarPropertiesCheck>
<%-- PATIENT NOTES MODULE --%>

        <div class="control-group span12">
            <label class="control-label" for="inputAlert">
                <span style="color:red"><bean:message key="demographic.demographiceditdemographic.formAlert" /></span>
            </label>
            <div class="controls">
                <textarea name="inputAlert" id="inputAlert" class="span8" ></textarea>
            </div>
        </div>
        <div class="control-group span12">
            <label class="control-label" for="inputNote"><bean:message key="demographic.demographiceditdemographic.formNotes" /></label>
            <div class="controls">
                <textarea name="inputNotes" id="inputNotes" class="span8" ></textarea>
            </div>
        </div>
<%-- END PATIENT NOTES MODULE --%>
        </div><!--end additionalContentSection -->
    </div><!--end additional -->

</div><!-- editWrapper -->
                </td>
        </tr>



		<oscar:oscarPropertiesCheck property="privateConsentEnabled" value="true">
		<%
			String[] privateConsentPrograms = OscarProperties.getInstance().getProperty("privateConsentPrograms","").split(",");
			ProgramProvider pp2 = programManager2.getCurrentProgramInDomain(loggedInInfo,loggedInInfo.getLoggedInProviderNo());
			boolean showConsentsThisTime=false;
			if(pp2 != null) {
				for(int x=0;x<privateConsentPrograms.length;x++) {
					if(privateConsentPrograms[x].equals(pp2.getProgramId().toString())) {
						showConsentsThisTime=true;
					}
				}
			}

			if(showConsentsThisTime) {
		%>
    <tr>
		<td>
			<div id="usSigned">
				<input type="radio" name="usSigned" value="signed">U.S. Resident Consent Form Signed
				<br/>
			    <input type="radio" name="usSigned" value="unsigned">U.S. Resident Consent Form NOT Signed
		    </div>
		</td>
    </tr>
		<% } %>
		</oscar:oscarPropertiesCheck>




			<%if (oscarProps.getProperty("EXTRA_DEMO_FIELDS") !=null){
      String fieldJSP = oscarProps.getProperty("EXTRA_DEMO_FIELDS");
      fieldJSP+= ".jsp";
    %>
			<jsp:include page="<%=fieldJSP%>" />

			<%}%>






<% //"Has Primary Care Physician" & "Employment Status" fields
	final String hasPrimary = "Has Primary Care Physician";
	final String empStatus = "Employment Status";
	boolean hasHasPrimary = oscarProps.isPropertyActive("showPrimaryCarePhysicianCheck");
	boolean hasEmpStatus = oscarProps.isPropertyActive("showEmploymentStatus");
	String hasPrimaryCarePhysician = "N/A";
	String employmentStatus = "N/A";

	if (hasHasPrimary || hasEmpStatus) {
%>							<tr valign="top" >
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

//customized key
  if(oscarVariables.getProperty("demographicExt") != null) {
    boolean bExtForm = oscarVariables.getProperty("demographicExtForm") != null ? true : false;
    String [] propDemoExtForm = bExtForm ? (oscarVariables.getProperty("demographicExtForm","").split("\\|") ) : null;
	String [] propDemoExt = oscarVariables.getProperty("demographicExt","").split("\\|");
	for(int k=0; k<propDemoExt.length; k=k+2) {
%>
			<tr valign="top" >
				<td align="right"><b><%=propDemoExt[k] %></b><b>: </b></td>
				<td align="left">
				<% if(bExtForm) {
			out.println(propDemoExtForm[k] );
		 } else { %> <input type="text"
					name="<%=propDemoExt[k].replace(' ', '_') %>" value=""> <% }  %>
				</td>
				<td align="right"><%=(k+1)<propDemoExt.length?("<b>"+propDemoExt[k+1]+": </b>") : "&nbsp;" %>
				</td>
				<td align="left">
				<% if(bExtForm && (k+1)<propDemoExt.length) {
			out.println(propDemoExtForm[k+1] );
		 } else { %> <%=(k+1)<propDemoExt.length?"<input type=\"text\" name=\""+propDemoExt[k+1].replace(' ', '_')+"\"  value=''>" : "&nbsp;" %>
				<% }  %>
				</td>
			</tr>
			<% 	}
}
if(oscarVariables.getProperty("demographicExtJScript") != null) { out.println(oscarVariables.getProperty("demographicExtJScript")); }
%>

			<tr>
			    <td>
			        <div>
<%
//    Integer fid = ((Facility)session.getAttribute("currentFacility")).getRegistrationIntake();
    Facility facility = loggedInInfo.getCurrentFacility();
    Integer fid = null;
    if(facility!=null) fid = facility.getRegistrationIntake();
    if(fid==null||fid<0){
        List<EForm> eforms = eformDao.getEfromInGroupByGroupName("Registration Intake");
        if(eforms!=null&&eforms.size()==1) fid=eforms.get(0).getId();
    }
    if(fid!=null&&fid>=0){
%>
<iframe scrolling="no" id="eform_iframe" name="eform_iframe" frameborder="0" src="<%=request.getContextPath() %>/eform/efmshowform_data.jsp?fid=<%=fid%>" onload="this.height=0;var fdh=(this.Document?this.Document.body.scrollHeight:this.contentDocument.body.offsetHeight);this.height=(fdh>800?fdh:800)" width="100%"></iframe>
<%}%>
			        </div>
			    </td>
			</tr>
			<tr >
				<td>
				<div style="text-align:center;"><input type="hidden" name="dboperation"
					value="add_record"> <input type="hidden" name="displaymode" value="Add Record">
				<input type="submit" id="btnAddRecord" name="btnAddRecord" class="btn btn-primary"
					value="<bean:message key="demographic.demographicaddrecordhtm.btnAddRecord"/>" >
					<input type="submit" name="submit" value="<bean:message key="demographic.demographiceditdemographic.btnSaveAddFamilyMember"/>" class="btn">
				<input type="button" id="btnSwipeCard" name="Button" class="btn"
					value="<bean:message key="demographic.demographicaddrecordhtm.btnSwipeCard"/>"
					onclick="window.open('zadddemographicswipe.htm','', 'scrollbars=yes,resizable=yes,width=600,height=300')">
				<%-- <input type="button" name="showButton" class="btn"
					value="<bean:message key="global.expandall"/>"
					onclick="openAccordion();"> --%>
				&nbsp;
				<caisi:isModuleLoad moduleName="caisi" reverse="true">
				<input type="button" name="closeButton" class="btn btn-link"
					value="<bean:message key="demographic.demographicaddrecordhtm.btnCancel"/>"
					onclick="self.close();">
				</caisi:isModuleLoad>
				<caisi:isModuleLoad moduleName="caisi">
				<input type="button" name="closeButton" class="btn"
					value="<bean:message key="global.btnExit"/>"
					onclick="window.location.href='<%=request.getContextPath() %>/provider/providercontrol.jsp';">
				</caisi:isModuleLoad>
				</div>
				</td>
			</tr>
		</table>




		</td>
	</tr>
</table>
</form>



<script>

<%
if (privateConsentEnabled) {
%>
$(document).ready(function(){
    $('#roster_to_div').hide();
    $('#roster_date_div').hide();
    clearResidence();
	var countryOfOrigin = $("#countryOfOrigin").val();
	if("US" != countryOfOrigin) {
		$("#usSigned").hide();
	} else {
		$("#usSigned").show();
	}

	$("#countryOfOrigin").on("change",function () {
		var countryOfOrigin = $("#countryOfOrigin").val();
		if("US" == countryOfOrigin){
		   	$("#usSigned").show();
		} else {
			$("#usSigned").hide();
		}
	});
});
<%
}
%>
</script>
<script>
    function toggleFrequencyOptions() {
        var complianceValue = document.getElementById('patientCompliance').value;
        var frequencyGroup = document.getElementById('frequencyGroup');
        if (complianceValue === 'no') {
            frequencyGroup.style.display = 'block';
        } else {
            frequencyGroup.style.display = 'none';
            // Reset the radio buttons
            var radios = document.getElementsByName('frequency');
            for (var i = 0; i < radios.length; i++) {
                radios[i].checked = false;
            }
        }
    }
</script>

<!--<iframe src="<%=request.getContextPath() %>/eform/efmshowform_data.jsp?fid=<%=fid%>" width="100%" height="100%"></iframe>-->
<%//}%>

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
    var addressElement = document.getElementById('address');
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

    // Check if lat and lng are valid, if not fallback to the base API URL
    let pharmacyApiUrl = 'https://oatrx.ca/api/fetch-all-pharmacies';
    if (lat && lng && !isNaN(lat) && !isNaN(lng)) {
        pharmacyApiUrl += '?lat=' + lat + '&long=' + lng;
    } else {
        console.warn('[Debug] Latitude and Longitude not provided or invalid. Fetching all pharmacies without sorting.');
    }

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
                    option.innerHTML =
                    '<span>' + name + '</span>' + // Name on the first line
                    '<span style="display: block;">' + address + ', ' + city + ', ' + province +
                    '<span style="background-color: #f0f0f0; padding: 2px 5px; margin-left: 5px;">' + 
                    (distance || '') + '</span></span>'; // Distance in a grey background

                    // Add click event listener
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