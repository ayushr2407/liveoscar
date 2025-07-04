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
<%@taglib uri="/WEB-INF/oscar-tag.tld" prefix="oscar" %>
<%@page import="org.apache.commons.lang.StringEscapeUtils" %>
<%@page import="org.oscarehr.util.WebUtilsOld" %>
<%@page import="org.oscarehr.myoscar.utils.MyOscarLoggedInInfo" %>
<%@page import="org.oscarehr.common.dao.DrugDao" %>
<%@page import="org.oscarehr.common.model.Drug" %>
<%@page import="org.oscarehr.common.model.PharmacyInfo" %>
<%@page import="org.oscarehr.util.WebUtils" %>
<%@page import="org.oscarehr.phr.util.MyOscarUtils" %>
<%@page import="org.oscarehr.util.LocaleUtils" %>
<%@taglib uri="/WEB-INF/struts-bean.tld" prefix="bean" %>
<%@taglib uri="/WEB-INF/struts-html.tld" prefix="html" %>
<%@taglib uri="/WEB-INF/struts-logic.tld" prefix="logic" %>
<%@taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@taglib uri="/WEB-INF/security.tld" prefix="security" %>
<%@taglib uri="/WEB-INF/indivo-tag.tld" prefix="indivo" %>
<%@page import="oscar.oscarRx.data.*,oscar.oscarProvider.data.ProviderMyOscarIdData,oscar.oscarDemographic.data.DemographicData,oscar.OscarProperties,oscar.log.*" %>
<%@page import="org.oscarehr.casemgmt.service.CaseManagementManager" %>
<%@page import="java.text.SimpleDateFormat" %>
<%@page import="java.util.*" %>
<%@page import="java.util.Enumeration" %>
<%@page import="org.oscarehr.util.SpringUtils" %>
<%@page import="org.oscarehr.util.SessionConstants" %>
<%@page import="java.util.List" %>
<%@page import="org.oscarehr.casemgmt.web.PrescriptDrug" %>
<%@page import="org.oscarehr.PMmodule.caisi_integrator.CaisiIntegratorManager" %>
<%@page import="org.oscarehr.util.LoggedInInfo" %>
<%@page import="java.util.ArrayList,oscar.oscarRx.data.RxPrescriptionData" %>
<%@page import="org.oscarehr.common.model.ProviderPreference" %>
<%@page import="org.oscarehr.web.admin.ProviderPreferencesUIBean" %>
<%@page import="org.oscarehr.study.StudyFactory, org.oscarehr.study.Study, org.oscarehr.study.types.MyMedsStudy" %>
<bean:define id="patient" type="oscar.oscarRx.data.RxPatientData.Patient" name="Patient"/>
<%@page import="org.oscarehr.casemgmt.service.CaseManagementManager" %>
<%@page import="org.oscarehr.casemgmt.model.CaseManagementNote" %>
<%@page import="org.oscarehr.casemgmt.model.Issue" %>
<%@page import="org.oscarehr.common.dao.UserPropertyDAO" %>
<%@page import="org.oscarehr.common.model.UserProperty" %>
<%@ page import="org.oscarehr.common.dao.DemographicDao, org.oscarehr.common.model.Demographic" %>
<%-- <%@ page import="org.hibernate.SessionFactory, org.hibernate.Session, org.hibernate.Query" %>
<%@ page import="org.hibernate.cfg.Configuration" %>
<%@ page import="org.oscarehr.common.model.Demographic" %> --%>

<%
    String rx_enhance = OscarProperties.getInstance().getProperty("rx_enhance");
%>
<%
    if (rx_enhance != null && rx_enhance.equals("true")) {
        if (request.getParameter("ID") != null) { %>
<script>
    window.opener.location = window.opener.location;
    window.close();
</script>
<%
        }
    }
    com.quatro.service.security.SecurityManager securityManager = new com.quatro.service.security.SecurityManager();
%>
<%@ taglib uri="/WEB-INF/security.tld" prefix="security" %>
<%
    String roleName2$ = (String) session.getAttribute("userrole") + "," + (String) session.getAttribute("user");
    boolean authed = true;
%>
<security:oscarSec roleName="<%=roleName2$%>" objectName="_rx" rights="r" reverse="<%=true%>">
    <%authed = false; %>
    <%response.sendRedirect("../securityError.jsp?type=_rx");%>
</security:oscarSec>
<%
    if (!authed) {
        return;
    }
%>
<logic:notPresent name="RxSessionBean" scope="session">
    <logic:redirect href="error.html"/>
</logic:notPresent>
<logic:present name="RxSessionBean" scope="session">
    <bean:define id="bean" type="oscar.oscarRx.pageUtil.RxSessionBean"
                 name="RxSessionBean" scope="session"/>
    <logic:equal name="bean" property="valid" value="false">
        <logic:redirect href="error.html"/>
    </logic:equal>
</logic:present>
<c:set var="ctx" value="${pageContext.request.contextPath}"/>
<%
    oscar.oscarRx.pageUtil.RxSessionBean bean = (oscar.oscarRx.pageUtil.RxSessionBean) pageContext.findAttribute("bean");

    String usefav = request.getParameter("usefav");
    String favid = request.getParameter("favid");
    int demoNo = bean.getDemographicNo();
%>

<%
    String patientCompliance = null;
    String frequency = null;

    // Ensure demoNo is valid
    if (demoNo > 0) {
        try {
            // Fetch demographic data using the simplified JDBC-based DAO method
            DemographicDao demographicDao = new DemographicDao();
            Demographic demographic = demographicDao.getDemographicByDemographicNo(demoNo);

            if (demographic != null) {
                patientCompliance = demographic.getPatientCompliance();
                frequency = demographic.getFrequency();
                
                // Debug: Log fetched values
                // System.out.println("Debug: Fetched patientCompliance = " + patientCompliance);
                // System.out.println("Debug: Fetched frequency = " + frequency);
            } else {
                // Log if no demographic data was found
                System.out.println("Debug: No demographic found for demographicNo = " + demoNo);
            }
        } catch (Exception e) {
            System.err.println("Error fetching demographic data: " + e.getMessage());
            e.printStackTrace();
        }
    }
%>

<security:oscarSec roleName="<%=roleName2$%>"
                   objectName='<%="_rx$"+demoNo%>' rights="o"
                   reverse="<%=false%>">
    <bean:message key="demographic.demographiceditdemographic.accessDenied"/>
    <% response.sendRedirect("../acctLocked.html"); %>
</security:oscarSec>

<%
    LoggedInInfo loggedInInfo = LoggedInInfo.getLoggedInInfoFromSession(request);
    String providerNo = bean.getProviderNo();
    UserPropertyDAO userPropertyDao = SpringUtils.getBean(UserPropertyDAO.class);
    UserProperty rxViewProp = userPropertyDao.getProp(providerNo, UserProperty.RX_PROFILE_VIEW);
    //String reRxDrugId=request.getParameter("reRxDrugId");
    //HashMap hm=(HashMap)session.getAttribute("profileViewSpec");
    String defaultView = "show_current";

    if (rxViewProp != null) {
        defaultView = rxViewProp.getValue().trim();
    }
    boolean show_current = true;
    boolean show_all = true;
    boolean active = true;
    boolean inactive = true;
    //boolean all=true;
    boolean longterm_acute = true;
    boolean longterm_acute_inactive_external = true;

    RxPharmacyData pharmacyData = new RxPharmacyData();
    List<PharmacyInfo> pharmacyList;
    pharmacyList = pharmacyData.getPharmacyFromDemographic(Integer.toString(demoNo));

    String drugref_route = OscarProperties.getInstance().getProperty("drugref_route");
    if (drugref_route == null) {
        drugref_route = "";
    }
    String[] d_route = ("Oral," + drugref_route).split(",");
    String annotation_display = org.oscarehr.casemgmt.model.CaseManagementNoteLink.DISP_PRESCRIP;

    oscar.oscarRx.data.RxPrescriptionData.Prescription[] prescribedDrugs;
    prescribedDrugs = patient.getPrescribedDrugScripts(); //this function only returns drugs which have an entry in prescription and drugs table
    String script_no = "";

    //This checks if the provider has the ExternalPresriber feature enabled, if so then a link appear for the provider to access the ExternalPrescriber
    ProviderPreference providerPreference = ProviderPreferencesUIBean.getProviderPreference(loggedInInfo.getLoggedInProviderNo());

    boolean eRxEnabled = false;
    String eRx_SSO_URL = null;
    String eRxUsername = null;
    String eRxPassword = null;
    String eRxFacility = null;
    String eRxTrainingMode = "0"; //not in training mode

    if (providerPreference != null) {
        eRxEnabled = providerPreference.isERxEnabled();
        eRx_SSO_URL = providerPreference.getERx_SSO_URL();
        eRxUsername = providerPreference.getERxUsername();
        eRxPassword = providerPreference.getERxPassword();
        eRxFacility = providerPreference.getERxFacility();

        boolean eRxTrainingModeTemp = providerPreference.isERxTrainingMode();
        if (eRxTrainingModeTemp) eRxTrainingMode = "1";
    }

    CaseManagementManager cmgmtMgr = SpringUtils.getBean(CaseManagementManager.class);
    List<Issue> issues = cmgmtMgr.getIssueInfoByCode(loggedInInfo.getLoggedInProviderNo(), "OMeds");
    String[] issueIds = new String[issues.size()];
    int idx = 0;
    for (Issue issue : issues) {
        issueIds[idx] = String.valueOf(issue.getId());
    }
    List<CaseManagementNote> notes = cmgmtMgr.getNotes(bean.getDemographicNo() + "", issueIds);
    String url_get_rxcui = OscarProperties.getInstance().getProperty("URL_GET_RXCUI") != null ? OscarProperties.getInstance().getProperty("URL_GET_RXCUI") : "https://rxnav.nlm.nih.gov/REST/rxcui.json?name=";
    String url_get_interaction = OscarProperties.getInstance().getProperty("URL_GET_INTERACTION") != null ? OscarProperties.getInstance().getProperty("URL_GET_INTERACTION") : "https://rxnav.nlm.nih.gov/REST/interaction/list?rxcuis=";
%>
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"
"http://www.w3.org/TR/html4/loose.dtd">
<html:html locale="true">
    <head>
        <title>Rx -
            <jsp:getProperty name="patient" property="surname"/>
            ,
            <jsp:getProperty name="patient" property="firstName"/>
        </title>
        <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.2/css/all.min.css">
        <link rel="stylesheet" type="text/css" href="styles.css">
        <html:base/>

        <script type="text/javascript">
            var ctx = '${ ctx }';
        </script>

        <script src="${ ctx }/library/jquery/jquery-3.6.4.min.js"></script>
        <script src="${ ctx }/library/jquery/jquery-migrate-3.4.0.js"></script>
        <script src="${ ctx }/library/jquery/jquery-ui-1.12.1.min.js"></script>

        <script>
            jQuery.noConflict();
        </script>
        <script>
        async function getRxcui(names) {
            // we have to get RxCUI
            let responses = "";
            for (let name of names){
                const response = await fetch('<%=url_get_rxcui%>'+name);
                const json = await response.json();
                console.log(name+json.idGroup.rxnormId);
                if (json.hasOwnProperty('idGroup')){
                    if (json.idGroup.hasOwnProperty('rxnormId')){
                        responses += json.idGroup.rxnormId ;
                        responses += "+";
                    }
                }
            }
            console.log("Rxcui found:"+responses);
            return responses;
        }

        function assembleRxDrugs() {
            //iterate through the generic names and assemble the array
            var druglist = []
            var atag = document.getElementsByTagName('a');
            for (var i = 0; i < atag.length; i++) {
                if (atag[i].outerHTML.indexOf("window.open") > -1) {
                    y = atag[i].innerText
                    y = y.split("/")
                    for (j = 0; j < y.length; j++) {
                        y[j] = y[j].trim()
                        //take the first word or the first word in each word/word combo
                        newwordA = y[j].match(/(?:^|(?:\.\s))(\w+)/);
                        if (newwordA){
                            console.log(newwordA[0])
                            druglist.push(newwordA[0])
                        }
                    }
                }
            }
            console.log("Searching the following drugs for interactions:"+druglist)
            return druglist;
        }

       
    
function assembleCurrentDrugs() {
            //iterate through the current names and assemble the array
            var druglist = []
            var ctag = document.getElementsByClassName('currentDrug');
            for (var i = 0; i < ctag.length; i++) {
                    if (ctag[i].id.slice(0,9)=='prescrip_'){
                        y = ctag[i].getAttribute("title");
                        if (y && y != "null"){
                            y = y.split("/")
                            for (j = 0; j < y.length; j++) {
                                y[j] = y[j].trim()
                                //take the first word or the first word in each word/word combo
                                newword = y[j].match(/(?:^|(?:\.\s))(\w+)/);
                                if (newword){
                                    console.log(newword[0])
                                    druglist.push(newword[0])
                                }
                            }
                        }
                    }
            }
            console.log("Searching the following current drugs for interactions:"+druglist)
            return druglist;
        }



        function getInteractions(drugs) {
            let drugsStr = drugs.toString().replace(/,/gi,', ');
            let alertlist = "<strong>"+ drugsStr +" <br> the interactions service has been discontinued by RxNorm. </strong>";
            //document.getElementById('interactionsRxMyD').innerHTML += alertlist;
            document.getElementById('interactionsRxMyD').innerHTML ='<div style="background-color:silver;margin-right:100px;margin-left:20px;margin-top:10px;padding-left:10px;padding-top:10px;padding-bottom:5px;border-bottom: 2px solid gray;border-right: 2px solid #999;border-top: 1px solid #CCC;border-left: 1px solid #CCC;width:300px;">' + alertlist + ' Use a publically available alternative <a href="https://go.drugbank.com/drug-interaction-checker" target="blank_">Drugbank Interaction checker</a></div>';

        }

        async function getInteractionsDEFUNCT(drugs) {
            if (drugs.length < 1) {
                alert("You must have existing current drugs or some Rx set to perscribe prior to checking");
                return;
            }
            let drugsStr = drugs.toString().replace(/,/gi,', ');
            let alertlist= "<strong>"+ drugsStr +" interactions are:</strong><br>";
            getRxcui(drugs).then(
                async function(rxcuis) {
                const response = await fetch('<%=url_get_interaction%>'+rxcuis);
                const str = await response.text();
                parser = new DOMParser();
                xmlDoc = parser.parseFromString(str, 'text/xml');
                y = xmlDoc.getElementsByTagName("description").length
                for (x = 0; x < y; x++) {
                    z = (xmlDoc.getElementsByTagName("description")[x].childNodes[0].nodeValue);
                    alertlist = alertlist + "<p>" + z
                }
                if (y <1 ) { alertlist="No interactions found with " + drugsStr +"<p>Use this service with discretion!  This product uses publicly available data from the U.S. National Library of Medicine (NLM), National Institutes of Health, Department of Health and Human Services; NLM is not responsible for the product and does not endorse or recommend this or any other product"; }

                //append
                document.getElementById('interactionsRxMyD').innerHTML += '<div style="background-color:silver;margin-right:100px;margin-left:20px;margin-top:10px;padding-left:10px;padding-top:10px;padding-bottom:5px;border-bottom: 2px solid gray;border-right: 2px solid #999;border-top: 1px solid #CCC;border-left: 1px solid #CCC;width:300px;">' +
alertlist +'<p>source: <a href="https://lhncbc.nlm.nih.gov/RxNav/" target="blank_">RxNav</a> and <a href="https://go.drugbank.com/drug-interaction-checker" target="blank_">Drugbank</a> <span style="font-size:9px;">CC BY-NC 4.0</span></div>'

                }
            )
        }

        function checkRxInteract() {
            let drugs = assembleRxDrugs();
            getInteractions(drugs);

        }

        function checkCurrentDrugs() {
            let drugs = assembleCurrentDrugs();
            getInteractions(drugs);

        }
        function checkAllDrugs() {
            let currentdrugs = assembleCurrentDrugs();
            let alldrugs = currentdrugs.concat(assembleRxDrugs());
            console.log("All drugs:"+alldrugs);
            getInteractions(alldrugs);

        }
        </script>
        <link rel="stylesheet" href="<c:out value="${ctx}/share/lightwindow/css/lightwindow.css"/>" type="text/css"
              media="screen"/>
        <link rel="stylesheet" type="text/css" media="all" href="../share/css/extractedFromPages.css"/>
        <!--link rel="stylesheet" type="text/css" href="modaldbox.css"  /-->

        <script type="text/javascript" src="${ctx}/js/global.js"></script>
        <script type="text/javascript" src="<c:out value="${ctx}/share/javascript/prototype.js"/>"></script>
        <script type="text/javascript" src="<c:out value="${ctx}/share/javascript/screen.js"/>"></script>
        <script type="text/javascript" src="<c:out value="${ctx}/share/javascript/rx.js"/>"></script>
        <script type="text/javascript" src="<c:out value="${ctx}/share/javascript/scriptaculous.js"/>"></script>
        <script type="text/javascript" src="<c:out value="${ctx}/share/javascript/effects.js"/>"></script>
        <script type="text/javascript" src="<c:out value="${ctx}/share/javascript/controls.js"/>"></script>
        <script type="text/javascript" src="<c:out value="${ctx}/share/javascript/Oscar.js"/>"></script>
        <script type="text/javascript" src="<c:out value="${ctx}/share/javascript/dragiframe.js"/>"></script>
        <script type="text/javascript" src="<c:out value="${ctx}/share/lightwindow/javascript/lightwindow.js"/>"></script>
        <!--script type="text/javascript" src="<%--c:out value="modaldbox.js"/--%>"></script-->
        <script type="text/javascript" src="<c:out value="${ctx}/js/checkDate.js"/>"></script>
        <!-- <link href="<%=request.getContextPath() %>/css/bootstrap.css" rel="stylesheet" type="text/css">-->
        <link rel="stylesheet" href="<%=request.getContextPath() %>/css/font-awesome.min.css">
        <link rel="stylesheet" type="text/css" href="<c:out value="${ctx}/share/yui/css/fonts-min.css"/>">
        <link rel="stylesheet" type="text/css" href="<c:out value="${ctx}/share/yui/css/autocomplete.css"/>">
        <script type="text/javascript" src="<c:out value="${ctx}/share/yui/js/yahoo-dom-event.js"/>"></script>
        <script type="text/javascript" src="<c:out value="${ctx}/share/yui/js/connection-min.js"/>"></script>
        <script type="text/javascript" src="<c:out value="${ctx}/share/yui/js/animation-min.js"/>"></script>
        <script type="text/javascript" src="<c:out value="${ctx}/share/yui/js/datasource-min.js"/>"></script>
        <script type="text/javascript" src="<c:out value="${ctx}/share/yui/js/autocomplete-min.js"/>"></script>
        <script type="text/javascript" src="<c:out value="${ctx}/js/checkDate.js"/>"></script>

        <script type="text/javascript">
            function saveLinks(randNumber) {
                $('method_' + randNumber).onblur();
                $('route_' + randNumber).onblur();
                $('frequency_' + randNumber).onblur();
                $('minimum_' + randNumber).onblur();
                $('maximum_' + randNumber).onblur();
                $('duration_' + randNumber).onblur();
                $('durationUnit_' + randNumber).onblur();
            }
           // Function to handle compliance change and toggle frequency visibility




            function handleEnter(inField, ev) {
                var charCode;
                if (ev && ev.which) {
                    charCode = ev.which;
                } else if (window.event) {
                    ev = window.event;
                    charCode = ev.keyCode;
                }
                var id = inField.id.split("_")[1];
                if (charCode == 13) {
                    showHideSpecInst('siAutoComplete_' + id);
                }
            }

            //has to be in here, not prescribe.jsp for it to work in IE 6/7 and probably 8.
            function showHideSpecInst(elementId) {
                if ($(elementId).getStyle('display') == 'none') {
                    Effect.BlindDown(elementId);
                } else {
                    Effect.BlindUp(elementId);
                }
            }

            function resetReRxDrugList() {
                var rand = Math.floor(Math.random() * 10001);
                var url = "<c:out value="${ctx}"/>" + "/oscarRx/deleteRx.do?parameterValue=clearReRxDrugList";
                var data = "rand=" + rand;
                new Ajax.Request(url, {
                    method: 'post', parameters: data, onSuccess: function (transport) {
                        updateCurrentInteractions();
                    }
                });
            }

            function onPrint(cfgPage) {
                var docF = $('printFormDD');
                docF.action = "../form/createpdf?__title=Rx&__cfgfile=" + cfgPage + "&__template=a6blank";
                docF.target = "_blank";
                docF.submit();
                return true;
            }

            function buildRoute() {
                pickRoute = "";
            }

            function popupRxSearchWindow() {
                var winX = (document.all) ? window.screenLeft : window.screenX;
                var winY = (document.all) ? window.screenTop : window.screenY;
                var top = winY + 70;
                var left = winX + 110;
                var url = "searchDrug.do?rx2=true&searchString=" + $('searchString').value;
                popup2(600, 800, top, left, url, 'windowNameRxSearch<%=demoNo%>');
            }

            function popupRxReasonWindow(demographic, id) {
                var winX = (document.all) ? window.screenLeft : window.screenX;
                var winY = (document.all) ? window.screenTop : window.screenY;
                var top = winY + 70;
                var left = winX + 110;
                var url = "SelectReason.jsp?demographicNo=" + demographic + "&drugId=" + id;
                popup2(575, 650, top, left, url, 'windowNameRxReason<%=demoNo%>');

            }

            var highlightMatch = function (full, snippet, matchindex) {
                return "<a title='" + full + "'>" + full.substring(0, matchindex) +
                    "<span class=match>" + full.substr(matchindex, snippet.length) + "</span>" + full.substring(matchindex + snippet.length) + "</a>";
            };

            var highlightMatchInactiveMatchWord = function (full, snippet, matchindex) {
                //oscarLog(full+"--"+snippet+"--"+matchindex);
                return "<a title='" + full + "'>" + "<span class=matchInactive>" + full.substring(0, matchindex) +
                    "<span class=match>" + full.substr(matchindex, snippet.length) + "</span>" + full.substring(matchindex + snippet.length) + "</span>" + "</a>";
            };

            var highlightMatchInactive = function (full, snippet, matchindex) {
                /* oscarLog(full+"--"+snippet+"--"+matchindex);
                oscarLog(" aa "+full.substring(0, matchindex) );
                oscarLog(" bb "+full.substr(matchindex, snippet.length) );
                oscarLog(" cc "+ full.substring(matchindex + snippet.length));*/
                /*return "<a title='"+full+"'>"+"<span class=matchInactive>"+full.substring(0, matchindex) +
                full.substr(matchindex, snippet.length) +full.substring(matchindex + snippet.length)+"</span>"+"</a>";*/
                return "<a title='" + full + "'>" + "<span class=matchInactive>" + full + "</span>" + "</a>";
            };

            var resultFormatter = function (oResultData, sQuery, sResultMatch) {
                //oscarLog("oResultData, sQuery, sResultMatch="+oResultData+"--"+sQuery+"--"+sResultMatch);
                //oscarLog("oResultData[0]="+oResultData[0]);
                //oscarLog("oResultData.name="+oResultData.name);
                //oscarLog("oResultData.name="+oResultData.id);
                var query = sQuery.toUpperCase();
                var drugName = oResultData[0];
                var mIndex = drugName.toUpperCase().indexOf(query);
                var display = '';

                if (mIndex > -1) {
                    display = highlightMatch(drugName, query, mIndex);
                } else {
                    display = drugName;
                }
                return display;
            };


           var resultFormatter2 = function (oResultData, sQuery, sResultMatch) {
    var query = sQuery.toUpperCase();
    var drugName = oResultData.name;
    var isInactive = oResultData.isInactive;
    var mIndex = drugName.toUpperCase().indexOf(query);
    var display = '';

    // Skip inactive drugs by returning null or an empty string
    if (isInactive == 'true' || isInactive === true) {
        return null; // or you can use 'return "";' to return an empty string
    }

    if (mIndex > -1) { // match found and active
        display = highlightMatch(drugName, query, mIndex);
    } else { // no match found but active
        display = drugName;
    }

var unescapedName = oResultData.name.replace(/&amp;/g, '&')
                                    .replace(/&lt;/g, '<')
                                    .replace(/&gt;/g, '>')
                                    .replace(/&quot;/g, '"')
                                    .replace(/&#039;/g, "'");
return '<div style=" white-space: normal; max-width: 600px; overflow-wrap: break-word;" class="dropdown-item">' + 
       '<span style="display: block; font-weight: bold; font-size: 14px; text-transform: uppercase;">' + unescapedName + '</span>' + 
       '</div>';
};



            <% if (Boolean.valueOf(request.getParameter("autoSaveOpenerOnOpen"))) { %>
            self.opener.autoSave(true);
            <% } %>
        </script>

        <script type="text/javascript">
            addEvent(window, "load", sortables_init);
            var SORT_COLUMN_INDEX;
            function sortables_init() {
                // Find all tables with class sortable and make them sortable
                if (!document.getElementsByTagName) return;
                tbls = document.getElementsByTagName("table");

                for (ti = 0; ti < tbls.length; ti++) {
                    thisTbl = tbls[ti];
                    if (((' ' + thisTbl.className + ' ').indexOf("sortable") != -1) && (thisTbl.id)) {
                        //initTable(thisTbl.id);
                        ts_makeSortable(thisTbl);
                    }
                }
            }

            function ts_makeSortable(table) {
                console.log('making ' + table.id + ' sortable');
                if (table.rows && table.rows.length > 0) {
                    var firstRow = table.rows[0];
                }
                if (!firstRow) return;
                oscarLog('Gets past here');

                // We have a first row: assume it's the header, and make its contents clickable links
                for (var i = 0; i < firstRow.cells.length; i++) {
                    var cell = firstRow.cells[i];
                    var txt = ts_getInnerText(cell);
                    cell.innerHTML = '<a href="#"  class="sortheader" ' +
                        'onclick="ts_resortTable(this, ' + i + ');return false;">' +
                        txt + '<span class="sortarrow"></span></a>';
                }
            }

            function ts_getInnerText(el) {
                if (typeof el == "string") return el;
                if (typeof el == "undefined") {
                    return el
                }
                ;
                if (el.innerText) return el.innerText;	//Not needed but it is faster
                var str = "";
                var cs = el.childNodes;
                var l = cs.length;
                for (var i = 0; i < l; i++) {
                    switch (cs[i].nodeType) {
                        case 1: //ELEMENT_NODE
                            str += ts_getInnerText(cs[i]);
                            break;
                        case 3:	//TEXT_NODE
                            str += cs[i].nodeValue;
                            break;
                    }
                }
                return str;
            }

            function ts_resortTable(lnk, clid) {
                // get the span
                var span;
                for (var ci = 0; ci < lnk.childNodes.length; ci++) {
                    if (lnk.childNodes[ci].tagName && lnk.childNodes[ci].tagName.toLowerCase() == 'span') span = lnk.childNodes[ci];
                }

                var spantext = ts_getInnerText(span);
                var td = lnk.parentNode;
                var column = clid;
                var table = getParent(td, 'TABLE');

                // Work out a type for the column
                if (table.rows.length <= 1) return;

                var itm = ts_getInnerText(table.rows[1].cells[column]).trim();
                sortfn = ts_sort_caseinsensitive;
                if (itm.match(/^\d\d[\/-]\d\d[\/-]\d\d\d\d$/)) sortfn = ts_sort_date;
                if (itm.match(/^\d\d[\/-]\d\d[\/-]\d\d$/)) sortfn = ts_sort_date;
                if (itm.match(/^[\Uffffffff$]/)) sortfn = ts_sort_currency;
                if (itm.match(/^[\d\.]+$/)) sortfn = ts_sort_numeric;
                SORT_COLUMN_INDEX = column;
                var firstRow = new Array();
                var newRows = new Array();

                for (i = 0; i < table.rows[0].length; i++) {
                    firstRow[i] = table.rows[0][i];
                }
                for (j = 1; j < table.rows.length; j++) {
                    newRows[j - 1] = table.rows[j];
                }

                newRows.sort(sortfn);

                if (span.getAttribute("sortdir") == 'down') {
                    ARROW = '&nbsp;&nbsp;&uarr;';
                    newRows.reverse();
                    span.setAttribute('sortdir', 'up');
                } else {
                    ARROW = '&nbsp;&nbsp;&darr;';
                    span.setAttribute('sortdir', 'down');
                }

                // We appendChild rows that already exist to the tbody, so it moves them rather than creating new ones
                // don't do sortbottom rows
                for (i = 0; i < newRows.length; i++) {
                    if (!newRows[i].className || (newRows[i].className && (newRows[i].className.indexOf('sortbottom') == -1))) table.tBodies[0].appendChild(newRows[i]);
                }

                // do sortbottom rows only
                for (i = 0; i < newRows.length; i++) {
                    if (newRows[i].className && (newRows[i].className.indexOf('sortbottom') != -1)) table.tBodies[0].appendChild(newRows[i]);
                }

                // Delete any other arrows there may be showing
                var allspans = document.getElementsByTagName("span");
                for (var ci = 0; ci < allspans.length; ci++) {
                    if (allspans[ci].className == 'sortarrow') {
                        if (getParent(allspans[ci], "table") == getParent(lnk, "table")) { // in the same table as us?
                            allspans[ci].innerHTML = '';
                        }
                    }
                }
               span.innerHTML = ARROW;
            }

            function getParent(el, pTagName) {
                if (el == null) return null;
                else if (el.nodeType == 1 && el.tagName.toLowerCase() == pTagName.toLowerCase())	// Gecko bug, supposed to be uppercase
                    return el;
                else
                    return getParent(el.parentNode, pTagName);
            }

            function ts_sort_date(a, b) {
                // y2k notes: two digit years less than 50 are treated as 20XX, greater than 50 are treated as 19XX
                aa = ts_getInnerText(a.cells[SORT_COLUMN_INDEX]);
                bb = ts_getInnerText(b.cells[SORT_COLUMN_INDEX]);
                if (aa.length == 10) {
                    dt1 = aa.substr(6, 4) + aa.substr(3, 2) + aa.substr(0, 2);
                } else {
                    yr = aa.substr(6, 2);
                    if (parseInt(yr) < 50) {
                        yr = '20' + yr;
                    } else {
                        yr = '19' + yr;
                    }
                    dt1 = yr + aa.substr(3, 2) + aa.substr(0, 2);
                }
                if (bb.length == 10) {
                    dt2 = bb.substr(6, 4) + bb.substr(3, 2) + bb.substr(0, 2);
                } else {
                    yr = bb.substr(6, 2);
                    if (parseInt(yr) < 50) {
                        yr = '20' + yr;
                    } else {
                        yr = '19' + yr;
                    }
                    dt2 = yr + bb.substr(3, 2) + bb.substr(0, 2);
                }
                if (dt1 == dt2) return 0;
                if (dt1 < dt2) return -1;
                return 1;
            }

            function ts_sort_currency(a, b) {
                aa = ts_getInnerText(a.cells[SORT_COLUMN_INDEX]).replace(/[^0-9.]/g, '');
                bb = ts_getInnerText(b.cells[SORT_COLUMN_INDEX]).replace(/[^0-9.]/g, '');
                return parseFloat(aa) - parseFloat(bb);
            }

            function ts_sort_numeric(a, b) {
                aa = parseFloat(ts_getInnerText(a.cells[SORT_COLUMN_INDEX]));
                if (isNaN(aa)) aa = 0;
                bb = parseFloat(ts_getInnerText(b.cells[SORT_COLUMN_INDEX]));
                if (isNaN(bb)) bb = 0;
                return aa - bb;
            }

            function ts_sort_caseinsensitive(a, b) {
                aa = ts_getInnerText(a.cells[SORT_COLUMN_INDEX]).toLowerCase();
                bb = ts_getInnerText(b.cells[SORT_COLUMN_INDEX]).toLowerCase();
                if (aa == bb) return 0;
                if (aa < bb) return -1;
                return 1;
            }

            function ts_sort_default(a, b) {
                aa = ts_getInnerText(a.cells[SORT_COLUMN_INDEX]);
                bb = ts_getInnerText(b.cells[SORT_COLUMN_INDEX]);
                if (aa == bb) return 0;
                if (aa < bb) return -1;
                return 1;
            }

            function addEvent(elm, evType, fn, useCapture)
// addEvent and removeEvent
// cross-browser event handling for IE5+,  NS6 and Mozilla
// By Scott Andrew
            {
                if (elm.addEventListener) {
                    elm.addEventListener(evType, fn, useCapture);
                    return true;
                } else if (elm.attachEvent) {
                    var r = elm.attachEvent("on" + evType, fn);
                    return r;
                } else {
                    alert("Handler could not be removed");
                }
            }

            function checkFav() {
                var usefav = '<%=usefav%>';
                var favid = '<%=favid%>';
                if (usefav == "true" && favid != null && favid != 'null') {
                    //oscarLog("****** favid "+favid);
                    useFav2(favid);
                } else {
                }
            }

            function moveDrugDown(drugId, swapDrugId, demographicNo) {
                new Ajax.Request('<c:out value="${ctx}"/>/oscarRx/reorderDrug.do?method=update&direction=down&drugId=' + drugId + '&swapDrugId=' + swapDrugId + '&demographicNo=' + demographicNo + "&rand=" + Math.floor(Math.random() * 10001), {
                    method: 'get',
                    onSuccess: function (transport) {
                        callReplacementWebService("ListDrugs.jsp", 'drugProfile');
                        resetReRxDrugList();
                        resetStash();
                    }
                });
            }

            function moveDrugUp(drugId, swapDrugId, demographicNo) {
                new Ajax.Request('<c:out value="${ctx}"/>/oscarRx/reorderDrug.do?method=update&direction=up&drugId=' + drugId + '&swapDrugId=' + swapDrugId + '&demographicNo=' + demographicNo + "&rand=" + Math.floor(Math.random() * 10001), {
                    method: 'get',
                    onSuccess: function (transport) {
                        callReplacementWebService("ListDrugs.jsp", 'drugProfile');
                        resetReRxDrugList();
                        resetStash();
                    }
                });
            }

            function showPreviousPrints(scriptNo) {
                popupWindow(720, 700, 'ShowPreviousPrints.jsp?scriptNo=' + scriptNo, 'ShowPreviousPrints')
            }

            /*<![CDATA[*/
            var Lst;

            function CngClass(obj) {
                document.getElementById("show_current").removeAttribute("style");
                if (Lst) Lst.className = '';
                obj.className = 'selected';
                Lst = obj;
            }

            /*]]>*/

            function toggleStartDate(rand) {
                var cb = document.getElementById('startDate_' + rand);
                var txt = document.getElementById('rxDate_' + rand);
                if (cb.checked) {
                    <%
    			java.text.SimpleDateFormat formatter = new java.text.SimpleDateFormat("yyyy-MM-dd");
    			String today = formatter.format(new java.util.Date());
    		%>
                    txt.disabled = true;
                    txt.value = '<%=today%>';
                } else {
                    txt.disabled = false;
                }
            }

            //this is a SJHH specific feature
            function completeMedRec() {
                var ok = confirm("Are you sure you would like to mark the Med Rec as complete?");
                if (ok) {
                    var url = "<c:out value="${ctx}"/>" + "/oscarRx/completeMedRec.jsp?demographicNo=<%=bean.getDemographicNo()%>";
                    var data;
                    new Ajax.Request(url, {
                        method: 'get', parameters: data, onSuccess: function (transport) {
                            alert('Completed.')
                        }
                    });
                }
            }

            function printDrugProfile() {
                var ids = [];

                jQuery("input[type='checkbox'][id ^= 'reRxCheckBox']").each(function () {
                    if (jQuery(this).is(":checked")) {
                        var name = jQuery(this).attr('name').substring(9);
                        ids.push(name);
                    }
                });

                if (ids.length > 0) {
                    popupWindow(720, 700, 'PrintDrugProfile2.jsp?ids=' + ids.join(','), 'PrintDrugProfile');
                } else {
                    popupWindow(720, 700, 'PrintDrugProfile2.jsp', 'PrintDrugProfile');
                }
            }

        </script>
        <style type="text/css" media="print">
            noprint {
                display: none;
            }

            justforprint {
                float: left;
            }
        </style>
        <style type="text/css">
            <!--
            .selected {
                font: Arial, Verdana;
                color: #000000;
                text-decoration: none;
            }

            -->

            a {
                color: #0088CC;
                text-decoration: none;
            }

            a:hover {
                text-decoration: underline;
            }

            #verificationLink {
                color: white;
            }

            table.legend {
                font-size: 12px;
                padding-left: 20px;

            }

            table.legend_items td {
                font-size: 12px;
                text-align: left;
                height: 30px;
                padding-right: 10px;
            }

            .highlight {
                background-color: #99FFCC;
                border: 1px solid #008000;
                color: #fff !important;
            }

            .rxStr a:hover {
                color: blue;
                text-decoration: underline;
            }

            .rxStr a {
                color: black;
                text-decoration: none;
            }

            .match {
                font-weight: bold;
            }

            .matchInactive {
                background-color: #C0C0C0;
            }


            #myAutoComplete {
                width: 25em; /* set width here or else widget will expand to fit its container */
                padding-bottom: 2em;
            }

            body {
                margin: 0;
                padding: 0;
            }

            /*THEMES

     .currentDrug{
        color:red;
     }
     .archivedDrug{
        text-decoration: line-through;
     }
     .expireInReference{
         color:orange;
         font-weight:bold;
     }
     .expiredDrug{
     font-size:13px;

     }

     .longTermMed{

     }

     .discontinued{

     }

THEME 2*/

            .currentDrug {
                font-weight: bold;
                font-size: 13px;
            }

            .archivedDrug {
                text-decoration: line-through;
            }

            .expireInReference {
                color: orange;
                font-weight: bold;
                font-size: 13px;
            }

            .expiredDrug {
                color: gray;
                font-size: 13px;
            }

            .longTermMed {
                font-style: italic;
            }

            .discontinued {
                text-decoration: line-through;

            }

            .deleted {
                text-decoration: line-through;

            }

            .external {
                color: purple;
            }

            .sortheader {
                text-decoration: none;
                color: black;
            }

            #addDrugButton {
    margin-left: 10px !important;
    padding: 6px 12px !important;
    font-size: 12px !important;
    background-color: #0b5ed7 !important;
    border-radius: 5px !important;
    color: #fff !important;
    box-shadow: none !important;
}

/* Ensure the 'Add New Drug' button doesn't get affected by external styles */
#addDrugButton, #saveButton {
    all: unset;
    display: inline-block;
}

            
            /* Force the h2 element to use consistent styles */
h2 {
    font-weight: bold !important;
    line-height: normal !important;
}


#searchString {
    width: 278px !important;
    position: static !important;
    box-shadow: none !important;
    font-size: 14px !important;
    background-color: white !important;
    border: 1px solid #ccc !important;
    padding: 5px !important;
}

/* Ensure the 'Create Rx' button doesn't shift styles */
    #saveButton {
        margin-left: 10px !important;
        padding: 6px 12px !important;
        font-size: 12px !important;
        background-color: #0b5ed7 !important;
        border-radius: 5px !important;
        color: #fff !important;
        box-shadow: none !important;
    }

    /* Remove any additional styles applied by Bootstrap or other libraries */
    #searchString, #saveButton {
        all: unset;
        display: inline-block;
    }

    li {
    border-bottom: 1px solid #e1e1e1;
    }

    .ingredient {
        font-size: 10px;
        font-weight: normal !important;
        color: #a8a8a8;
        display: block;
    }

    /* Define hover effect on the li */
    li:hover .ingredient {
        color: white;
    }

    /* Define hover effect on li */
    li:hover {
        background-color: #426FD9;
        color: white;
    }

    #searchLoader {
    position: absolute;
    top: 15%;
    right: 10px;
    transform: translateY(-50%);
    width: 16px;
    height: 16px;
    border: 3px solid #f3f3f3;
    border-top: 3px solid #3498db;
    border-radius: 50%;
    animation: spin 1s linear infinite;
    display: none;
}

@keyframes spin {
    0% { transform: rotate(0deg); }
    100% { transform: rotate(360deg); }
}

/* loader overlay for ReRx */
#rerxLoaderOverlay {
    position: fixed;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    background-color: rgba(255, 255, 255, 0.3);
    z-index: 9999;
    display: flex;
    justify-content: center;
    align-items: center;
    visibility: hidden;
}

/* Loader Spinner */
.loaderSpinner {
    border: 6px solid rgba(255, 255, 255, 0.3);
    border-top: 6px solid #3498db;
    border-radius: 50%;
    width: 50px;
    height: 50px;
    animation: spin 1s linear infinite;
    z-index: 10000;
}

@keyframes spin {
    0% { transform: rotate(0deg); }
    100% { transform: rotate(360deg); }
}

        </style>
        <!--[if IE]>
        <style type="text/css">
            table.legend {
                margin-left: 20px;
            }
        </style>
        <![endif]-->
    </head>
    <%
        boolean showall = false;
        if (request.getParameter("show") != null) if (request.getParameter("show").equals("all")) showall = true;
    %>
    <script language="JavaScript">
        top.window.resizeTo(1440, 900);  //width,height for 19" LCD allowing for most Rx to be in two rows

    </script>
    <body vlink="#0000FF"
          onload="setplaceholder();checkFav();iterateStash();rxPageSizeSelect();checkReRxLongTerm();load()"
          class="yui-skin-sam">
    <script>
        function setplaceholder() {
            $('searchString').placeholder = "<bean:message key="SearchDrug.EnterDrugName"/>";
        }
    </script>
    <%=WebUtilsOld.popErrorAndInfoMessagesAsHtml(session)%>
    <table border="0" cellpadding="0" cellspacing="0" style="border-collapse: collapse" bordercolor="#111111"
           width="100%" id="AutoNumber1" height="100%">
        <%@ include file="TopLinks2.jspf" %><!-- Row One included here-->
        <tr>
            <td width="10%" height="100%" valign="top">
                <%@ include file="SideLinksEditFavorites2.jsp" %>
            </td>
                <%-- <td></td>Side Bar File --%>
            <td height="100%" valign="top" width="100%"><!--Column Two Row Two-->
                <table cellpadding="0" cellspacing="0"
                       style="border-left:1px solid black; border-right:1px solid black; border-bottom:1px solid black; border-collapse: collapse">
                    <tr><!--put this left-->
                        <td valign="top" align="left" style="background: #e5f1ff; border-bottom: 1px solid rgb(0, 96, 148)">
                            <%if (securityManager.hasWriteAccess("_rx", roleName2$, true)) {%>
                            <html:form action="/oscarRx/searchDrug" onsubmit="return checkEnterSendRx();"
                                       style="display: inline; margin-bottom:0;" styleId="drugForm">
                                <div id="interactingDrugErrorMsg" style="display:none"></div>
                                <div id="rxText"></div>
                                <br style="clear:left;">
                                <input type="hidden" id="deleteOnCloseRxBox" value="false">
                                <input type="hidden" id="rxPharmacyId" name="rxPharmacyId" value=""/>
                                <html:hidden property="demographicNo"
                                             value="<%=new Integer(patient.getDemographicNo()).toString()%>"/>
                                <h2 id="writeNewPrescription" style="padding: 0; margin: 0 0 5px 10px; font-size: 14px;">Write New Prescription</h2>
                                <table border="0" style="border-collapse:collapse;">

                                    <tr width="100%" valign="top">
                                        <!-- Search Bar Container -->
                                            <td style="padding-left:10px;">
                                                   <!-- Search Bar Container with Loader -->
                                                    <div style="position: relative; display: inline-block;">
                                                        <html:text styleId="searchString" property="searchString"
                                                            onfocus="changeContainerHeight();"
                                                            onblur="changeContainerHeight();"
                                                            onclick="changeContainerHeight();"
                                                            onkeydown="changeContainerHeight();"
                                                            style="width:278px;position:static !important;\ padding-right: 35px;\" autocomplete=\"off"/>
                                                        <div id="searchLoader" class="spinner" style="display: none;"></div>
                                                    </div>

                                                    <!-- Autocomplete Dropdown -->
                                                    <div id="autocomplete_choices" class="drugchoices" style="color:black;overflow:auto;width:600px"></div>
                                                    <span id="indicator1" style="display: none">  <!--img src="/images/spinner.gif" alt="Working..." --></span>
                                                <!-- "Add New Drug" Button (Initially Hidden) -->
                                            <button id="addDrugButton" type="button"
                                                    class="ControlPushButton btn btn-primary"
                                                    onclick="showSearchBar();"
                                                    style="display: none;">
                                                Add New Drug
                                            </button>

                                            </td>
                                        <td>
                                           

                                            <%if (OscarProperties.getInstance().hasProperty("ONTARIO_MD_INCOMINGREQUESTOR")) {%>
                                            <a href="javascript:goOMD();"
                                               title="<bean:message key="SearchDrug.help.OMD"/>"><bean:message
                                                    key="SearchDrug.msgOMDLookup"/></a>
                                            <% } %>
                                            &nbsp;
                                            <!-- Save and Print Button initially hidden -->
<security:oscarSec roleName="<%=roleName2$%>" objectName="_rx" rights="x">
    <input id="saveButton" type="button"
           class="ControlPushButton btn btn-primary"
           onclick="updateSaveAllDrugsPrint();"
           value="Generate Prescription"
           title="<bean:message key='SearchDrug.help.SaveAndPrint'/>"
           style="display: none;"/>  <!-- Initially hidden -->
</security:oscarSec>

                                            <%
                                                if (OscarProperties.getInstance().getProperty("oscarrx.medrec", "false").equals("true")) {
                                            %>
                                            <input id="completeMedRecButton" class="ControlPushButton btn" type="button"
                                                   onclick="completeMedRec();" value="Complete Med Rec"/>
                                            <% } %>

                                            <% if (eRxEnabled) { %>
                                            <a href="<%=eRx_SSO_URL%>User=<%=eRxUsername%>&Password=<%=eRxPassword%>&Clinic=<%=eRxFacility%>&PatientIdPMIS=<%=patient.getDemographicNo()%>&IsTraining=<%=eRxTrainingMode%>"><bean:message
                                                    key="SearchDrug.eRx.msgExternalPrescriber"/></a>
                                            <% } %>
                                        </td>
                                    </tr>
                                    <tr>
                                        <td colspan="3">
                                                <%-- input type="button" class="ControlPushButton btn" onclick="customWarning();" value="<bean:message key="SearchDrug.msgCustomDrug"/>" / --%>
                                        </td>
                                    </tr>
                                </table>
                            </html:form>
                            <br>
                            <div id="previewForm" style="display:none;"></div>
                            <% } %>
                        </td>
                    </tr>
                    <tr><!--put this left-->
                        <td align="left" valign="top">
                            <div>
                                <table width="100%"><!--drug profile, view and listdrugs.jsp-->
                                    
                                    <tr>
                                        <td>
                                                <%-- Start List Drugs Prescribed --%>
                                            <div style="height: 100px; overflow: auto; background-color: #DCDCDC; border: thin solid green; display: none;"
                                                 id="reprint">
                                                <%
                                                    for (int i = 0; i < prescribedDrugs.length; i++) {
                                                        oscar.oscarRx.data.RxPrescriptionData.Prescription drug = prescribedDrugs[i];
                                                        if (drug.getScript_no() != null && script_no.equals(drug.getScript_no())) {
                                                %>
                                                <br>
                                                <div style="float: left; width: 24%; padding-left: 40px;">&nbsp;</div>
                                                <a style="float: left;" href="javascript:void(0);"
                                                   onclick="reprint2('<%=drug.getScript_no()%>')"><%=drug.getRxDisplay()%>
                                                </a>
                                                <%
                                                } else {
                                                %>
                                                <%=i > 0 ? "<br style='clear:both;'><br style='clear:both;'>" : ""%>
                                                <div style="float: left; width: 12%; padding-left: 20px;"><%=drug.getRxDate()%>
                                                </div>
                                                <div style="float: left; width: 12%; padding-left: 20px;">
                                                    <a href="#"
                                                       onclick="showPreviousPrints(<%=drug.getScript_no() %>);return false;">
                                                                <%=drug.getNumPrints()%>&nbsp;Prints</div>
                                                </a>
                                                <a style="float: left;" href="javascript:void(0);"
                                                   onclick="reprint2('<%=drug.getScript_no()%>')"><%=drug.getRxDisplay()%>
                                                </a>
                                                <%
                                                        }
                                                        script_no = drug.getScript_no() == null ? "" : drug.getScript_no();
                                                    }
                                                %>
                                            </div>
                                        </td>
                                    </tr>
                                    <tr><!--move this left-->
                                        <td>
                                            <table border="0" style="width:100%">
                                                <tr>
                                                    <td>
                                                        <table width="100%" cellspacing="0" cellpadding="0"
                                                               class="legend">
                                                            <tr>
                                                                <td width="100">
                                                                    <a href="javascript:void(0);"
                                                                       title="View drug profile legend"
                                                                       onclick="ThemeViewer();"
                                                                       style="font-style:normal;color:#000000">
                                                                        <bean:message
                                                                                key="SearchDrug.msgProfileLegend"/>:
                                                                    </a>
                                                                    <a href="#"
                                                                       title="<bean:message key="provider.rxChangeProfileViewMessage"/>"
                                                                       onclick="popupPage(230,860,'../setProviderStaleDate.do?method=viewRxProfileView');"
                                                                       style="color:red;text-decoration:none">
                                                                        <bean:message
                                                                                key="provider.rxChangeProfileView"/>
                                                                    </a>
                                                                </td>
                                                                <td align="left">
                                                                    <table class="legend_items" align="left">
                                                                        <tr>
                                                                            <%
                                                                                if (show_all) {
                                                                            %>
                                                                            <td>
                                                                                <a href="javascript:void(0);"
                                                                                   id="show_all"
                                                                                   onclick="callReplacementWebService('ListDrugs.jsp?show=all','drugProfile');CngClass(this);"
                                                                                   Title="<bean:message key='SearchDrug.msgShowAllDesc'/>">
                                                                                    <bean:message
                                                                                            key="SearchDrug.msgShowAll"/>
                                                                                </a>
                                                                            </td>
                                                                            <%
                                                                                }
                                                                                if (active) {
                                                                            %>
                                                                            <td>
                                                                                <a href="javascript:void(0);"
                                                                                   id="active"
                                                                                   onclick="callReplacementWebService('ListDrugs.jsp?status=active','drugProfile');CngClass(this);"
                                                                                   TITLE="<bean:message key='SearchDrug.msgActiveDesc'/>">
                                                                                    <bean:message
                                                                                            key="SearchDrug.msgActive"/>
                                                                                </a>
                                                                            </td>
                                                                            <%
                                                                                }
                                                                                if (inactive) {
                                                                            %>
                                                                            <td>
                                                                                <a href="javascript:void(0);"
                                                                                   id="inactive"
                                                                                   onclick="callReplacementWebService('ListDrugs.jsp?status=inactive','drugProfile');CngClass(this);"
                                                                                   TITLE="<bean:message key='SearchDrug.msgInactiveDesc'/>">
                                                                                    <bean:message
                                                                                            key="SearchDrug.msgInactive"/>
                                                                                </a>
                                                                            </td>
                                                                            <%
                                                                                }
                                                                                if (!OscarProperties.getInstance().getProperty("rx.profile_legend.hide", "false").equals("true")) {

                                                                                    if (longterm_acute) {
                                                                            %>
                                                                            <td>
                                                                                <a href="javascript:void(0);"
                                                                                   id="longterm_acute"
                                                                                   onclick="callReplacementWebService('ListDrugs.jsp?longTermOnly=true&heading=Long Term Meds','drugProfile');"
                                                                                   TITLE="<bean:message key='SearchDrug.msgLongTermAcuteDesc'/>">
                                                                                    <bean:message
                                                                                            key="SearchDrug.msgLongTermAcute"/>
                                                                                </a>
                                                                            </td>
                                                                            
                                                                            <%
                                                                                    }
                                                                                }
                                                                            %>
                                                                        </tr>
                                                                    </table>
                                                                </td>
                                                            </tr>
                                                        </table>
                                                        <div id="drugProfile"></div>
                                                        <html:form action="/oscarRx/rePrescribe">
                                                            <html:hidden property="drugList"/>
                                                            <input type="hidden" name="method">
                                                        </html:form> <br>
                                                        <html:form action="/oscarRx/deleteRx">
                                                            <html:hidden property="drugList"/>
                                                        </html:form></td>
                                                </tr>
                                            </table>
                                        </td>
                                    </tr>
                                </table>
                            </div>
                        </td>
                    </tr>
                </table>
                    <%-- End List Drugs Prescribed --%>
            </td>
            <td width="300px" valign="top">
                <div id="interactionsRxMyD" style="float:right;"></div>
            </td>
        </tr>
        <tr>
            <td></td>
            <td align="center"><a href="javascript:window.scrollTo(0,0);"><bean:message key="oscarRx.BackToTop"/></a>
            </td>
        </tr>
        <tr>
            <td height="0%" style="border:none;" colspan="3">
        </tr>
        <tr>
            <td width="100%" height="0%" colspan="3">&nbsp;
            </td>
        </tr>
        <tr>
            <td width="100%" height="0%" style="padding: 5" bgcolor="#DCDCDC" colspan="3">
            </td>
        </tr>
    </table>
    <div id="treatmentsMyD"
         style="position: absolute; left: 1px; top: 1px; width: 800px; height: 600px; display:none; z-index: 1">
        <a href="javascript: function myFunction() {return false; }" onclick="$('treatmentsMyD').toggle();"
           style="text-decoration: none;">X</a>
    </div>
    <div id="dragifm" style="top:0px;left:0px;"></div>
    <div id="discontinueUI"
         style="position: absolute;display:none;width:500px;height:200px;background-color:white;padding:20px;border:1px solid grey">
        <h3>Discontinue :<span id="disDrug"></span></h3>
        <input type="hidden" name="disDrugId" id="disDrugId"/>
        <bean:message key="oscarRx.discontinuedReason.msgReason"/>
        <select name="disReason" id="disReason">
            <option value="adverseReaction"><bean:message key="oscarRx.discontinuedReason.AdverseReaction"/></option>
            <option value="allergy"><bean:message key="oscarRx.discontinuedReason.Allergy"/></option>
            <option value="cost"><bean:message key="oscarRx.discontinuedReason.Cost"/></option>
            <option value="discontinuedByAnotherPhysician"><bean:message
                    key="oscarRx.discontinuedReason.DiscontinuedByAnotherPhysician"/></option>
            <option value="doseChange"><bean:message key="oscarRx.discontinuedReason.DoseChange"/></option>
            <option value="drugInteraction"><bean:message key="oscarRx.discontinuedReason.DrugInteraction"/></option>
            <option value="increasedRiskBenefitRatio"><bean:message
                    key="oscarRx.discontinuedReason.IncreasedRiskBenefitRatio"/></option>
            <option value="ineffectiveTreatment"><bean:message
                    key="oscarRx.discontinuedReason.IneffectiveTreatment"/></option>
            <option value="newScientificEvidence"><bean:message
                    key="oscarRx.discontinuedReason.NewScientificEvidence"/></option>
            <option value="noLongerNecessary"><bean:message
                    key="oscarRx.discontinuedReason.NoLongerNecessary"/></option>
            <option value="enteredInError"><bean:message key="oscarRx.discontinuedReason.EnteredInError"/></option>
            <option value="patientRequest"><bean:message key="oscarRx.discontinuedReason.PatientRequest"/></option>
            <option value="prescribingError"><bean:message key="oscarRx.discontinuedReason.PrescribingError"/></option>
            <option value="simplifyingTreatment"><bean:message
                    key="oscarRx.discontinuedReason.SimplifyingTreatment"/></option>
            <option value="unknown"><bean:message key="oscarRx.discontinuedReason.Unknown"/></option>
            <option value="other"><bean:message key="oscarRx.discontinuedReason.Other"/></option>
        </select>
        <br/>
        <bean:message key="oscarRx.discontinuedReason.msgComment"/><br/>
        <textarea id="disComment" rows="3" cols="45"></textarea><br/>
        <input type="button" onclick="$('discontinueUI').hide();" value="Cancel"/>
        <input type="button"
               onclick="Discontinue2($('disDrugId').value,$('disReason').value,$('disComment').value,$('disDrug').innerHTML);"
               value="Discontinue"/>
    </div>
    <div id="themeLegend"
         style="position: absolute;display:none; width:500px;height:200px;background-color:white;padding:20px;border:1px solid grey">
        <a href="javascript:void(0);" class="currentDrug">Drug that is current</a><br/>
        <%if (!OscarProperties.getInstance().getProperty("rx.delete_drug.hide", "false").equals("true")) {%>
        <a href="javascript:void(0);" class="archivedDrug">Drug that is archived</a><br/>
        <% } %>
        <a href="javascript:void(0);" class="expireInReference">Drug that is current but will expire within the
            reference range</a><br/>
        <a href="javascript:void(0);" class="expiredDrug">Drug that is expired</a><br/>
        <a href="javascript:void(0);" class="longTermMed">Long Term Med Drug</a><br/>
        <a href="javascript:void(0);" class="discontinued">Discontinued Drug</a><br/>
        <a href="javascript:void(0);" class="external">Prescribed by an outside provider</a><br/><br/><br/><br/>
        <a href="javascript:void(0);" onclick="$('themeLegend').hide()">Close</a>
    </div>
    <%
        if (pharmacyList != null) {
    %>
    <div id="Layer1"
         style="position: absolute; left: 1px; top: 1px; width: 350px; height: 311px; visibility: hidden; z-index: 1; background-color: white;">
        <!--  This should be changed to automagically fill if this changes often -->
        <table border="0" cellspacing="1" cellpadding="1" align="center" class="hiddenLayer">
            <tr class="LightBG">
                <td class="wcblayerTitle">&nbsp;</td>
                <td class="wcblayerTitle">&nbsp;</td>
                <td class="wcblayerTitle" align="right"><a href="javascript: function myFunction() {return false; }"
                                                           onclick="hidepic('Layer1');"
                                                           style="text-decoration: none;">X</a></td>
            </tr>
            <tr class="LightBG">
                <td class="wcblayerTitle"><bean:message key="SearchDrug.pharmacy.msgName"/></td>
                <td class="wcblayerItem">&nbsp;</td>
                <td id="pharmacyName"></td>
            </tr>
            <tr class="LightBG">
                <td class="wcblayerTitle"><bean:message key="SearchDrug.pharmacy.msgAddress"/></td>
                <td class="wcblayerItem">&nbsp;</td>
                <td id="pharmacyAddress"></td>
            </tr>
            <tr class="LightBG">
                <td class="wcblayerTitle"><bean:message key="SearchDrug.pharmacy.msgCity"/></td>
                <td class="wcblayerItem">&nbsp;</td>
                <td id="pharmacyCity"></td>
            </tr>
            <tr class="LightBG">
                <td class="wcblayerTitle"><bean:message key="SearchDrug.pharmacy.msgProvince"/></td>
                <td class="wcblayerItem">&nbsp;</td>
                <td id="pharmacyProvince"></td>
            </tr>
            <tr class="LightBG">
                <td class="wcblayerTitle"><bean:message key="SearchDrug.pharmacy.msgPostalCode"/> :</td>
                <td class="wcblayerItem">&nbsp;</td>
                <td id="pharmacyPostalCode"></td>
            </tr>
            <tr class="LightBG">
                <td class="wcblayerTitle"><bean:message key="SearchDrug.pharmacy.msgPhone1"/> :</td>
                <td class="wcblayerItem">&nbsp;</td>
                <td id="pharmacyPhone1"></td>
            </tr>
            <tr class="LightBG">
                <td class="wcblayerTitle"><bean:message key="SearchDrug.pharmacy.msgPhone2"/> :</td>
                <td class="wcblayerItem">&nbsp;</td>
                <td id="pharmacyPhone2"></td>
            </tr>
            <tr class="LightBG">
                <td class="wcblayerTitle"><bean:message key="SearchDrug.pharmacy.msgFax"/> :</td>
                <td class="wcblayerItem">&nbsp;</td>
                <td id="pharmacyFax"></td>
            </tr>
            <tr class="LightBG">
                <td class="wcblayerTitle"><bean:message key="SearchDrug.pharmacy.msgEmail"/> :</td>
                <td class="wcblayerItem">&nbsp;</td>
                <td id="pharmacyEmail"></td>
            </tr>
            <tr class="LightBG">
                <td colspan="3" class="wcblayerTitle"><bean:message key="SearchDrug.pharmacy.msgNotes"/> :</td>
            </tr>
            <tr class="LightBG">
                <td id="pharmacyNotes" colspan="3"></td>
            </tr>
        </table>
    </div>
    <% } %>
    <script type="text/javascript">
        function changeLt(drugId, isLongTerm) {
            if (confirm(isLongTerm ? '<bean:message key = "oscarRx.Prescription.changeDrugShortTermConfirm" />' : '<bean:message key = "oscarRx.Prescription.changeDrugLongTermConfirm" />') == true) {
                let data = "ltDrugId=" + drugId + "&rand=" + Math.floor(Math.random() * 10001);
                let url = "<c:out value = '${ctx}'/>" + "/oscarRx/WriteScript.do?parameterValue=changeLongTerm";

                new Ajax.Request(url, {
                    method: 'post', parameters: data, onSuccess: function (transport) {
                        let json = transport.responseText.evalJSON();
                        if (json != null && (json.success == 'true' || json.success == true)) {
                            let elementName = isLongTerm ? "longTermDrug_" : "notLongTermDrug_";
                            $(elementName + drugId).innerHTML = isLongTerm ? "<bean:message key = "global.no" />" : "<bean:message key = "global.yes" />";
                            $(elementName + drugId).setAttribute("onclick", "changeLt('" + drugId + "', " + !isLongTerm + ");");
                            isLongTerm ? $(elementName + drugId).setAttribute("id", "notLongTermDrug_" + drugId) : $(elementName + drugId).setAttribute("id", "longTermDrug_" + drugId);
                        }
                    }
                });
            }
        }

        function checkReRxLongTerm() {
            var url = window.location.href;
            var match = url.indexOf('ltm=true');
            if (match > -1) {
                RePrescribeLongTerm();
            }
        }

        function changeContainerHeight(ele) {
            var ss = $('searchString').value;
            ss = trim(ss);
            if (ss.length == 0)
                $('autocomplete_choices').setStyle({height: '0%'});
            else
                $('autocomplete_choices').setStyle({height: '80%'});
        }

        function addInstruction(content, randomId) {
            $('instructions_' + randomId).value = content;
            parseIntr($('instructions_' + randomId));
        }

        function addSpecialInstruction(content, randomId) {
            if ($('siAutoComplete_' + randomId).getStyle('display') == 'none') {
                Effect.BlindDown('siAutoComplete_' + randomId);
            } else {
            }
            $('siInput_' + randomId).value = content;
            $('siInput_' + randomId).setStyle({color: 'black'});
        }

        function hideMedHistory() {
            mb.hide();
        }

        var modalBox = function () {
            this.show = function (randomId, displaySRC, H) {
                if (!document.getElementById("xmaskframe")) {
                    var divFram = document.createElement('iframe');
                    divFram.setAttribute("id", "xmaskframe");
                    divFram.setAttribute("name", "xmaskframe");
                    //divFram.setAttribute("src","displayMedHistory.jsp?randomId="+randomId);
                    divFram.setAttribute("allowtransparency", "false");
                    document.body.appendChild(divFram);
                    var divSty = document.getElementById("xmaskframe").style;
                    divSty.position = "fixed";
                    divSty.top = "0px";
                    divSty.right = "0px";
                    divSty.width = "390px"
                    //divSty.border="solid";
                    divSty.backgroundColor = "#F5F5F5";
                    divSty.zIndex = "45";
                    //divSty.cursor="move";
                }
                this.waitifrm = document.getElementById("xmaskframe");
                this.waitifrm.setAttribute("src", displaySRC + ".jsp?randomId=" + randomId);
                this.waitifrm.style.display = "block";
                this.waitifrm.style.height = H;
                $("dragifm").appendChild(this.waitifrm);
                Effect.Appear('xmaskframe');
            };
            this.hide = function () {
                Effect.Fade('xmaskframe');
            };
        }

        var mb = new modalBox();

        function displayMedHistory(randomId) {
            var data = "randomId=" + randomId;
            new Ajax.Request("<c:out value='${ctx}'/>" + "/oscarRx/WriteScript.do?parameterValue=listPreviousInstructions",
                {
                    method: 'post', parameters: data, asynchronous: false, onSuccess: function (transport) {
                        mb.show(randomId, 'displayMedHistory', '200px');
                    }
                });
        }

        function displayInstructions(randomId) {
            var data = "randomId=" + randomId;
            mb.show(randomId, 'displayInstructions', '600px');
        }

        function updateProperty(elementId) {
            var randomId = elementId.split("_")[1];
            if (randomId != null) {
                var url = "<c:out value="${ctx}"/>" + "/oscarRx/WriteScript.do?parameterValue=updateProperty";
                var data = "";
                if (elementId.match("prnVal_") != null)
                    data = "elementId=" + elementId + "&propertyValue=" + $(elementId).value;
                else if (elementId.match("repeats_") != null)
                    data = "elementId=" + elementId + "&propertyValue=" + $(elementId).value;
                else
                    data = "elementId=" + elementId + "&propertyValue=" + $(elementId).innerHTML;
                data = data + "&rand=" + Math.floor(Math.random() * 10001);
                new Ajax.Request(url, {method: 'post', parameters: data});
            }
        }

        function lookNonEdittable(elementId) {
            $(elementId).className = '';
        }

        function lookEdittable(elementId) {
            $(elementId).className = 'highlight';
        }

        function setPrn(randomId) {
            var prnStr = $('prn_' + randomId).innerHTML;
            prnStr = prnStr.strip();
            var prnStyle = $('prn_' + randomId).getStyle('textDecoration');
            if (prnStr == 'prn' || prnStr == 'PRN' || prnStr == 'Prn') {
                if (prnStyle.match("line-through") != null) {
                    $('prn_' + randomId).setStyle({textDecoration: 'none'});
                    $('prnVal_' + randomId).value = true;
                } else {
                    $('prn_' + randomId).setStyle({textDecoration: 'line-through'});
                    $('prnVal_' + randomId).value = false;
                }
            }
        }

        function focusTo(elementId) {
            $(elementId).contentEditable = 'true';
            $(elementId).focus();
            //IE 6/7 bug..will this call onfocus twice?? may need to do browser check.
            document.getElementById(elementId).onfocus();
        }

        function updateSpecialInstruction(elementId) {
            var randomId = elementId.split("_")[1];
            var url = "<c:out value="${ctx}"/>" + "/oscarRx/WriteScript.do?parameterValue=updateSpecialInstruction";
            var data = "randomId=" + randomId + "&specialInstruction=" + $(elementId).value;
            data = data + "&rand=" + Math.floor(Math.random() * 10001);
            new Ajax.Request(url, {method: 'post', parameters: data});
        }

        function changeText(elementId) {
            if ($(elementId).value == 'Enter Special Instruction') {
                $(elementId).value = "";
                $(elementId).setStyle({color: 'black'});
            } else if ($(elementId).value == '') {
                $(elementId).value = 'Enter Special Instruction';
                $(elementId).setStyle({color: 'gray'});
            }
        }

        function updateMoreLess(elementId) {
            if ($(elementId).innerHTML == 'more')
                $(elementId).innerHTML = 'less';
            else
                $(elementId).innerHTML = 'more';
        }

        function changeDrugName(randomId, origDrugName) {
            if (confirm('If you change the drug name and write your own drug, you will lose the following functionality:'
                + '\n  *  Known Dosage Forms / Routes'
                + '\n  *  Drug Allergy Information'
                + '\n  *  Drug-Drug Interaction Information'
                + '\n  *  Drug Information'
                + '\n\nAre you sure you wish to use this feature?') == true) {

                //call another function to bring up prescribe.jsp
                var url = "<c:out value="${ctx}"/>" + "/oscarRx/WriteScript.do?parameterValue=normalDrugSetCustom";
                var customDrugName = $("drugName_" + randomId).getValue();
                var data = "randomId=" + randomId + "&customDrugName=" + customDrugName;
                new Ajax.Updater('rxText', url, {
                    method: 'get',
                    parameters: data,
                    asynchronous: true,
                    insertion: Insertion.Bottom,
                    onSuccess: function (transport) {
                        $('set_' + randomId).remove();

                    }
                });
                <oscar:oscarPropertiesCheck property="MYDRUGREF_DS" value="yes">
                callReplacementWebService("GetmyDrugrefInfo.do?method=view", 'interactionsRxMyD');
                </oscar:oscarPropertiesCheck>
            } else {
                $("drugName_" + randomId).value = origDrugName;
            }
        }

        function resetStash() {
            var url = "<c:out value="${ctx}"/>" + "/oscarRx/deleteRx.do?parameterValue=clearStash";
            var data = "rand=" + Math.floor(Math.random() * 10001);
            new Ajax.Request(url, {
                method: 'post', parameters: data, onSuccess: function (transport) {
                    updateCurrentInteractions();
                }
            });
            $('rxText').innerHTML = "";//make pending prescriptions disappear.
            $("searchString").focus();
        }

        function iterateStash() {
            var url = "<c:out value="${ctx}"/>" + "/oscarRx/WriteScript.do?parameterValue=iterateStash";
            var data = "rand=" + Math.floor(Math.random() * 10001);
            new Ajax.Updater('rxText', url, {
                method: 'get', parameters: data, asynchronous: true, evalScripts: true,
                insertion: Insertion.Bottom, onSuccess: function (transport) {
                    updateCurrentInteractions();
                }
            });

        }

        function rxPageSizeSelect() {
            var ran_number = Math.round(Math.random() * 1000000);
            var url = "GetRxPageSizeInfo.do?method=view";
            var params = "demographicNo=<%=demoNo%>&rand=" + ran_number;  //hack to get around ie caching the page
            new Ajax.Request(url, {method: 'post', parameters: params});
        }

        function reprint2(scriptNo) {
            var data = "scriptNo=" + scriptNo + "&rand=" + Math.floor(Math.random() * 10001);
            var url = "<c:out value="${ctx}"/>" + "/oscarRx/rePrescribe2.do?method=reprint2";
            new Ajax.Request(url,
                {
                    method: 'post', postBody: data,
                    onSuccess: function (transport) {
                        popForm2(scriptNo);
                    }
                });
            return false;
        }

        function deletePrescribe(randomId) {
            var data = "randomId=" + randomId;
            var url = "<c:out value="${ctx}"/>" + "/oscarRx/rxStashDelete.do?parameterValue=deletePrescribe";
            new Ajax.Request(url, {
                method: 'get', parameters: data, onSuccess: function (transport) {
                    updateCurrentInteractions();
                    if ($('deleteOnCloseRxBox').value == 'true') {
                        deleteRxOnCloseRxBox(randomId);
                    }
                }
            });
        }

        function deleteRxOnCloseRxBox(randomId) {
            var data = "randomId=" + randomId;
            var url = "<c:out value="${ctx}"/>" + "/oscarRx/deleteRx.do?parameterValue=DeleteRxOnCloseRxBox";
            new Ajax.Request(url, {
                method: 'get', parameters: data, onSuccess: function (transport) {
                    var json = transport.responseText.evalJSON();
                    if (json != null) {
                        var id = json.drugId;
                        var rxDate = "rxDate_" + id;
                        var reRx = "reRx_" + id;
                        var del = "del_" + id;
                        var discont = "discont_" + id;
                        var prescrip = "prescrip_" + id;
                        $(rxDate).style.textDecoration = 'line-through';
                        $(reRx).style.textDecoration = 'line-through';
                        $(del).style.textDecoration = 'line-through';
                        $(discont).style.textDecoration = 'line-through';
                        $(prescrip).style.textDecoration = 'line-through';
                        updateCurrentInteractions();
                    }
                }
            });
        }

        function ThemeViewer() {
            var xy = Position.page($('drugProfile'));
            var x = (xy[0] + 200) + 'px';
            var y = xy[1] + 'px';
            var wid = ($('drugProfile').getWidth() - 300) + 'px';
            var styleStr = {left: x, top: y, width: wid};

            $('themeLegend').setStyle(styleStr);
            $('themeLegend').show();
        }

        var skipParseInstr = false;

        function useFav2(favoriteId) {
            var randomId = Math.round(Math.random() * 1000000);
            var data = "favoriteId=" + favoriteId + "&randomId=" + randomId;
            var url = "<c:out value="${ctx}"/>" + "/oscarRx/useFavorite.do?parameterValue=useFav2";
            new Ajax.Updater('rxText', url, {
                method: 'get',
                parameters: data,
                asynchronous: true,
                evalScripts: true,
                insertion: Insertion.Bottom
            });

            skipParseInstr = true;
        }

        function calculateRxData(randomId) {
            if (skipParseInstr) {
                return false;
            }
            var dummie = parseIntr($('instructions_' + randomId));
            if (dummie)
                updateQty($('quantity_' + randomId));
        }

        function Delete2(element) {
            if (confirm('Are you sure you wish to delete the selected prescriptions?') == true) {
                var id_str = (element.id).split("_");
                var id = id_str[1];
                //var id=element.id;
                var rxDate = "rxDate_" + id;
                var reRx = "reRx_" + id;
                var del = "del_" + id;
                var discont = "discont_" + id;
                var prescrip = "prescrip_" + id;

                var url = "<c:out value="${ctx}"/>" + "/oscarRx/deleteRx.do?parameterValue=Delete2";
                var data = "deleteRxId=" + element.id + "&rand=" + Math.floor(Math.random() * 10001);
                new Ajax.Request(url, {
                    method: 'post', postBody: data, onSuccess: function (transport) {
                        $(rxDate).style.textDecoration = 'line-through';
                        $(reRx).style.textDecoration = 'line-through';
                        $(del).style.textDecoration = 'line-through';
                        $(discont).style.textDecoration = 'line-through';
                        $(prescrip).style.textDecoration = 'line-through';
                        updateCurrentInteractions();
                    }
                });
            }
            return false;
        }

        function checkAllergy(id, atcCode) {
            var url = "<c:out value="${ctx}"/>" + "/oscarRx/getAllergyData.jsp";
            var data = "atcCode=" + atcCode + "&id=" + id + "&rand=" + Math.floor(Math.random() * 10001);
            new Ajax.Request(url, {
                method: 'post', postBody: data, onSuccess: function (transport) {
                    var response = JSON.parse(transport.responseText);
                    var items = response.items;
                    var output = "";

                    if (items != null && items.length > 0) {
                        for (var x = 0; x < items.length; x++) {
                            if (items[x].warning != null && items[x].warning == true) {
                                var str = "<font color='red'>Warning: Allergy \"" + items[x].description + "\" with reaction  \"" + items[x].reaction + "\" and " + items[x].severity + " severity Found.</font><br/>";
                                output += str;
                            }
                            if (items[x].missing != null && items[x].missing == true) {
                                var str = "<font color='red'>Warning Allergy: \"" + items[x].description + "\" not Found in drug database. Please update this Allergy.</font><br/>";
                                output += str;
                            }
                        }
                        $('alleg_' + response.id).innerHTML = output;
                        document.getElementById('alleg_tbl_' + response.id).style.display = 'table';
                    }
                }
            });
        }

        function checkIfInactive(id, dinNumber) {
            var url = "<c:out value="${ctx}"/>" + "/oscarRx/getInactiveDate.jsp";
            var data = "din=" + dinNumber + "&id=" + id + "&rand=" + Math.floor(Math.random() * 10001);
            new Ajax.Request(url, {
                method: 'post', postBody: data, onSuccess: function (transport) {
                    var json = transport.responseText.evalJSON();
                    if (json != null) {
                        var str = "Inactive Drug Since: " + new Date(json.vec[0].time).toDateString();
                        $('inactive_' + json.id).innerHTML = str;
                    }
                }
            });
        }

        function Discontinue(event, element) {
            var id_str = (element.id).split("_");
            var id = id_str[1];
            var widVal = ($('drugProfile').getWidth() - 300);
            var widStr = widVal + 'px';
            var heightDrugProfile = $('discontinueUI').getHeight();
            var posx = 0, posy = 0;
            if (event.pageX || event.pageY) {
                posx = event.pageX;
                posx = posx - widVal;
                posy = event.pageY - heightDrugProfile / 2;
                posx = posx + 'px';
                posy = posy + 'px';
            } else if (event.clientX || event.clientY) {
                posx = event.clientX + document.body.scrollLeft
                    + document.documentElement.scrollLeft;
                posx = posx - widVal;
                posy = event.clientY + document.body.scrollTop
                    + document.documentElement.scrollTop - heightDrugProfile / 2;
                posx = posx + 'px';
                posy = posy + 'px';
            } else {
                var xy = Position.page($('drugProfile'));
                posx = (xy[0] + 200) + 'px';
                if (xy[1] >= 0)
                    posy = xy[1] + 'px';
                else
                    posy = 0 + 'px';
            }
            var styleStr = {left: posx, top: posy, width: widStr};
            var drugName = $('prescrip_' + id).innerHTML;
            $('discontinueUI').setStyle(styleStr);
            $('disDrug').innerHTML = drugName;
            $('discontinueUI').show();
            $('disDrugId').value = id;
        }

        function Discontinue2(id, reason, comment, drugSpecial) {
            var url = "<c:out value="${ctx}"/>" + "/oscarRx/deleteRx.do?parameterValue=Discontinue";
            var demoNo = '<%=patient.getDemographicNo()%>';
            var data = "drugId=" + id + "&reason=" + reason + "&comment=" + comment + "&demoNo=" + demoNo + "&drugSpecial=" + drugSpecial + "&rand=" + Math.floor(Math.random() * 10001);
            new Ajax.Request(url, {
                method: 'post', postBody: data, onSuccess: function (transport) {
                    var json = transport.responseText.evalJSON();
                    $('discontinueUI').hide();
                    $('rxDate_' + json.id).style.textDecoration = 'line-through';
                    $('reRx_' + json.id).style.textDecoration = 'line-through';
                    $('del_' + json.id).style.textDecoration = 'line-through';
                    $('discont_' + json.id).innerHTML = json.reason;
                    $('prescrip_' + json.id).style.textDecoration = 'line-through';
                    updateCurrentInteractions();
                }
            });
        }

        function updateCurrentInteractions() {
            new Ajax.Request("GetmyDrugrefInfo.do?method=findInteractingDrugList&rand=" + Math.floor(Math.random() * 10001), {
                method: 'get', onSuccess: function (transport) {
                    new Ajax.Request("UpdateInteractingDrugs.jsp?rand=" + Math.floor(Math.random() * 10001), {
                        method: 'get', onSuccess: function (transport) {
                            var str = transport.responseText;
                            str = str.replace('<script type="text/javascript">', '');
                            str = str.replace(/<\/script>/, '');
                            eval(str);
                            <oscar:oscarPropertiesCheck property="MYDRUGREF_DS" value="yes">
                            callReplacementWebService("GetmyDrugrefInfo.do?method=view&rand=" + Math.floor(Math.random() * 10001), 'interactionsRxMyD');
                            </oscar:oscarPropertiesCheck>
                        }
                    });
                }
            });
        }

        //represcribe long term meds
        function RePrescribeLongTerm() {
            var demoNo = '<%=patient.getDemographicNo()%>';
            var data = "demoNo=" + demoNo + "&showall=<%=showall%>&rand=" + Math.floor(Math.random() * 10001);
            var url = "<c:out value="${ctx}"/>" + "/oscarRx/rePrescribe2.do?method=repcbAllLongTerm";
            new Ajax.Updater('rxText', url, {
                method: 'get',
                parameters: data,
                asynchronous: true,
                insertion: Insertion.Bottom,
                onSuccess: function (transport) {
                    updateCurrentInteractions();
                }
            });
            return false;
        }

        function customNoteWarning() {
            if (confirm('This feature will allow you to manually enter a prescription.'
                + '\nWarning: you will lose the following functionality:'
                + '\n  *  Quantity and Repeats'
                + '\n  *  Known Dosage Forms / Routes'
                + '\n  *  Drug Allergy Information'
                + '\n  *  Drug-Drug Interaction Information'
                + '\n  *  Drug Information'
                + '\n\nAre you sure you wish to use this feature?') == true) {
                var randomId = Math.round(Math.random() * 1000000);
                var url = "<c:out value="${ctx}"/>" + "/oscarRx/WriteScript.do?parameterValue=newCustomNote";
                var data = "randomId=" + randomId;
                new Ajax.Updater('rxText', url, {
                    method: 'get',
                    parameters: data,
                    asynchronous: true,
                    evalScripts: true,
                    insertion: Insertion.Bottom
                });
            }
        }

        function customWarning2() {
            if (confirm('This feature will allow you to manually enter a drug.'
                + '\nWarning: Only use this feature if absolutely necessary, as you will lose the following functionality:'
                + '\n  *  Known Dosage Forms / Routes'
                + '\n  *  Drug Allergy Information'
                + '\n  *  Drug-Drug Interaction Information'
                + '\n  *  Drug Information'
                + '\n\nAre you sure you wish to use this feature?') == true) {
                //call another function to bring up prescribe.jsp
                var randomId = Math.round(Math.random() * 1000000);
                var searchString = $("searchString").value;
                var url = "<c:out value="${ctx}"/>" + "/oscarRx/WriteScript.do?parameterValue=newCustomDrug&name=" + searchString;
                var data = "randomId=" + randomId;
                new Ajax.Updater('rxText', url, {
                    method: 'get', parameters: data, asynchronous: true, evalScripts: true,
                    insertion: Insertion.Bottom, onComplete: function (transport) {
                        updateQty($('quantity_' + randomId));
                    }
                });
            }
        }

        function saveCustomName(element) {
            var elemId = element.id;
            var ar = elemId.split("_");
            var rand = ar[1];
            var url = "<c:out value="${ctx}"/>" + "/oscarRx/WriteScript.do?parameterValue=saveCustomName";
            var data = "customName=" + encodeURIComponent(element.value) + "&randomId=" + rand;
            var instruction = "instructions_" + rand;
            var quantity = "quantity_" + rand;
            var repeat = "repeats_" + rand;
            new Ajax.Request(url, {
                method: 'get', parameters: data, onSuccess: function (transport) {
                }
            });
        }

        function updateDeleteOnCloseRxBox() {
            $('deleteOnCloseRxBox').value = 'true';
        }

        function popForm2(scriptId, prescriptionBatchId) {
            try {
                //oscarLog("popForm2 called");
                var url1 = "<c:out value="${ctx}"/>" + "/oscarRx/WriteScript.do?parameterValue=checkNoStashItem&rand=" + Math.floor(Math.random() * 10001);
                var data = "";
                var h = 900;
                new Ajax.Request(url1, {
                    method: 'get', parameters: data, onSuccess: function (transport) {
                        //output default instructions
                        var json = transport.responseText.evalJSON();
                        var n = json.NoStashItem;
                        if (n > 4) {
                            h = h + (n - 4) * 100;
                        }
                        //oscarLog("h="+h+"--n="+n);
                        var url;
                        var json = jQuery("#Calcs").val();
                        //oscarLog(json);
                        if (json != null && json != "") {
                            var pharmacy = JSON.parse(json);
                            if (pharmacy != null) {
                                url = "<c:out value="${ctx}"/>" + "/oscarRx/ViewScript2.jsp?scriptId=" + scriptId + "&pharmacyId=" + pharmacy.id+ "&prescriptionBatchId=" + prescriptionBatchId;
                            } else {
                                url = "<c:out value="${ctx}"/>" + "/oscarRx/ViewScript2.jsp?scriptId=" + scriptId+ "&prescriptionBatchId=" + prescriptionBatchId;
                            }
                        } else {
                            url = "<c:out value="${ctx}"/>" + "/oscarRx/ViewScript2.jsp?scriptId=" + scriptId+ "&prescriptionBatchId=" + prescriptionBatchId;
                        }
                        //oscarLog( "preview2 done");
                        myLightWindow.activateWindow({
                            href: url,
                            width: 1000,
                            height: h
                        });
                        var editRxMsg = '<bean:message key="oscarRx.Preview.EditRx"/>';
                        $('lightwindow_title_bar_close_link').update(editRxMsg);
                        $('lightwindow_title_bar_close_link').onclick = updateDeleteOnCloseRxBox;
                    }
                });
            } catch (er) {
                oscarLog(er);
            }
            //oscarLog("bottom of popForm");
        }

        function callTreatments(textId, id) {
            var ele = $(textId);
            var url = "TreatmentMyD.jsp"
            var ran_number = Math.round(Math.random() * 1000000);
            var params = "demographicNo=<%=demoNo%>&cond=" + ele.value + "&rand=" + ran_number;  //hack to get around ie caching the page
            new Ajax.Updater(id, url, {method: 'get', parameters: params, asynchronous: true});
            $('treatmentsMyD').toggle();
        }

        function callAdditionWebService(url, id) {
            var ran_number = Math.round(Math.random() * 1000000);
            var params = "demographicNo=<%=demoNo%>&rand=" + ran_number;  //hack to get around ie caching the page
            var updater = new Ajax.Updater(id, url, {
                method: 'get',
                parameters: params,
                insertion: Insertion.Bottom,
                evalScripts: true
            });
        }

        function callReplacementWebService(url, id) {
            var ran_number = Math.round(Math.random() * 1000000);
            var params = "demographicNo=<%=demoNo%>&rand=" + ran_number;  //hack to get around ie caching the page
            var updater = new Ajax.Updater(id, url, {method: 'get', parameters: params, evalScripts: true});
        }

        //callReplacementWebService("InteractionDisplay.jsp",'interactionsRx');
        <oscar:oscarPropertiesCheck property="MYDRUGREF_DS" value="yes">
        callReplacementWebService("GetmyDrugrefInfo.do?method=view", 'interactionsRxMyD');
        </oscar:oscarPropertiesCheck>
        callReplacementWebService("ListDrugs.jsp", 'drugProfile');

        YAHOO.example.FnMultipleFields = function () {
            var url = "<c:out value="${ctx}"/>" + "/oscarRx/searchDrug.do?method=jsonSearch";
            var oDS = new YAHOO.util.XHRDataSource(url, {connMethodPost: true, connXhrMode: 'ignoreStaleResponses'});
oDS.responseType = YAHOO.util.XHRDataSource.TYPE_JSON;
oDS.responseSchema = {
    resultsList: "results",
    fields: ["name", "id", "dosage_value", "dosage_unit", "isInactive", "din"]
};

// Filter out inactive drugs
oDS.doBeforeParseData = function (oRequest, oFullResponse) {
    if (oFullResponse && oFullResponse.results) {
        oFullResponse.results = oFullResponse.results.filter(function (result) {
            return !result.isInactive; // Only include drugs where isInactive is false or undefined
        });
    }
    return oFullResponse; // Return the modified response
};

var oAC = new YAHOO.widget.AutoComplete("searchString", "autocomplete_choices", oDS);
oAC.useShadow = true;
oAC.resultTypeList = false;
oAC.queryMatchSubset = false;
oAC.minQueryLength = 3;
oAC.maxResultsDisplayed = 1000;
oAC.formatResult = resultFormatter2;
oAC.allowHtml = true;

oAC.dataRequestEvent.subscribe(function() {
    var searchLoader = document.getElementById('searchLoader');

    if (searchLoader) {
        searchLoader.style.display = 'block'; // Show loader inside search bar
    }
});

oAC.dataReturnEvent.subscribe(function() {
    var searchLoader = document.getElementById('searchLoader');

    if (searchLoader) {
        searchLoader.style.display = 'none'; // Hide loader when results arrive
    }
});

oAC.dataErrorEvent.subscribe(function() {
    var searchLoader = document.getElementById('searchLoader');

    if (searchLoader) {
        searchLoader.style.display = 'none'; // Hide loader on error
    }
    console.error("Failed to fetch drug data.");
});


// Footer for more results
// oAC.doBeforeExpandContainer = function (sQuery, oResponse) {
//     if (oAC._nDisplayedItems < oAC.maxResultsDisplayed) {
//         oAC.setFooter("");
//     } else {
//         oAC.setFooter("<a href='javascript:void(0)' onClick='popupRxSearchWindow();oAC.collapseContainer();'>See more results...</a>");
//     }
//     return true;
// }


// Selection handler function to process the selected item
var myHandler = function (type, args) {
    var arr = args[2]; // Get the selected item
    var url = "<c:out value='${ctx}'/>" + "/oscarRx/WriteScript.do?parameterValue=createNewRx"; //"prescribe.jsp";
    var ran_number = Math.round(Math.random() * 1000000);
    var name = encodeURIComponent(arr.name);
    var din = arr.din;
    var params = "demographicNo=<%=demoNo%>&drugId=" + arr.id + "&text=" + name + "&randomId=" + ran_number + "&din=" + din;

    // Send selected item data via Ajax
    new Ajax.Updater('rxText', url, {
        method: 'get', parameters: params, evalScripts: true,
        insertion: Insertion.Bottom, onSuccess: function (transport) {
            updateCurrentInteractions();
        }
    });

    // Clear search input field after selection
    document.getElementById('searchString').value = "";
};

            oAC.itemSelectEvent.subscribe(myHandler);
            var collapseFn = function () {
                $('autocomplete_choices').hide();
            }
            oAC.containerCollapseEvent.subscribe(collapseFn);
            var expandFn = function () {
                $('autocomplete_choices').show();
            }
            oAC.dataRequestEvent.subscribe(expandFn);
            return {
                oDS: oDS,
                oAC: oAC
            };
        }();

        function addFav(randomId, brandName) {
            var favoriteName = window.prompt('Please enter a name for the Favorite:', brandName);
            if (favoriteName == null) {
                return;
            }
            favoriteName = encodeURIComponent(favoriteName);
            if (favoriteName.length > 0) {
                var url = "<c:out value="${ctx}"/>" + "/oscarRx/addFavorite2.do?parameterValue=addFav2";
                var data = "randomId=" + randomId + "&favoriteName=" + favoriteName;
                new Ajax.Request(url, {
                    method: 'get', parameters: data, onSuccess: function (transport) {
                        window.location.href = "SearchDrug3.jsp";
                    }
                })
            }
        }

        var showOrHide = 0;

        function showOrHideRes(hiddenRes) {
            hiddenRes = hiddenRes.replace(/\{/g, "");
            hiddenRes = hiddenRes.replace(/\}/g, "");
            hiddenRes = hiddenRes.replace(/\s/g, "");
            var arr = hiddenRes.split(",");
            var numberOfHiddenResources = 0;
            if (showOrHide == 0) {
                numberOfHiddenResources = 0;
                for (var i = 0; i < arr.length; i++) {
                    var element = arr[i];
                    element = element.replace("mydrugref", "");
                    var elementArr = element.split("=");
                    var resId = elementArr[0];
                    var resUpdated = elementArr[1];
                    var id = resId + "." + resUpdated;
                    $(id).show();
                    $('show_' + id).hide();
                    $('showHideWord').update('hide');
                    showOrHide = 1;
                    numberOfHiddenResources++;
                }
            } else {
                numberOfHiddenResources = 0
                for (var i = 0; i < arr.length; i++) {
                    var element = arr[i];
                    element = element.replace("mydrugref", "");
                    var elementArr = element.split("=");
                    var resId = elementArr[0];
                    var resUpdated = elementArr[1];
                    var id = resId + "." + resUpdated;
                    oscarLog("id=" + id);
                    $(id).hide();
                    $('show_' + id).show();
                    $('showHideWord').update('show');
                    showOrHide = 0;
                    numberOfHiddenResources++;
                }
            }
            $('showHideNumber').update(numberOfHiddenResources);
        }

        // var totalHiddenResources=0;
        var addTextView = 0;

        function showAddText(randId) {
            var addTextId = "addText_" + randId;
            var addTextWordId = "addTextWord_" + randId;
            if (addTextView == 0) {
                $(addTextId).show();
                addTextView = 1;
                $(addTextWordId).update("less")
            } else {
                $(addTextId).hide();
                addTextView = 0;
                $(addTextWordId).update("more")
            }
        }

        function ShowW(id, resourceId, updated) {
            var params = "resId=" + resourceId + "&updatedat=" + updated
            var url = 'GetmyDrugrefInfo.do?method=setWarningToShow&rand=' + Math.floor(Math.random() * 10001);
            new Ajax.Updater('showHideTotal', url, {
                method: 'get',
                parameters: params,
                asynchronous: true,
                evalScripts: true,
                onSuccess: function (transport) {
                    $(id).show();
                    $('show_' + id).hide();
                }
            });
        }

        function HideW(id, resourceId, updated) {
            var url = 'GetmyDrugrefInfo.do?method=setWarningToHide';
            var ran_number = Math.round(Math.random() * 1000000);
            var params = "resId=" + resourceId + "&updatedat=" + updated + "&rand=" + ran_number;  //hack to get around ie caching the page
            //totalHiddenResources++;
            new Ajax.Updater('showHideTotal', url, {
                method: 'get',
                parameters: params,
                asynchronous: true,
                evalScripts: true,
                onSuccess: function (transport) {
                    $(id).hide();
                    $("show_" + id).show();
                }
            });
        }

        function setSearchedDrug(drugId, name) {
            var url = "<c:out value="${ctx}"/>" + "/oscarRx/WriteScript.do?parameterValue=createNewRx";
            var ran_number = Math.round(Math.random() * 1000000);
            name = encodeURIComponent(name);
            var params = "demographicNo=<%=demoNo%>&drugId=" + drugId + "&text=" + name + "&randomId=" + ran_number;
            new Ajax.Updater('rxText', url, {
                method: 'get',
                parameters: params,
                asynchronous: true,
                evalScripts: true,
                insertion: Insertion.Bottom,
                onSuccess: function (transport) {
                    updateCurrentInteractions();
                }
            });
            $('searchString').value = "";
        }

        var counterRx = 0;

        function updateReRxDrugId(elementId) {
            var ar = elementId.split("_");
            var drugId = ar[1];
            if (drugId != null && $(elementId).checked == true) {
                var data = "reRxDrugId=" + drugId + "&action=addToReRxDrugIdList&rand=" + Math.floor(Math.random() * 10001);
                var url = "<c:out value="${ctx}"/>" + "/oscarRx/WriteScript.do?parameterValue=updateReRxDrug";
                new Ajax.Request(url, {method: 'get', parameters: data});
            } else if (drugId != null) {
                var data = "reRxDrugId=" + drugId + "&action=removeFromReRxDrugIdList&rand=" + Math.floor(Math.random() * 10001);
                var url = "<c:out value="${ctx}"/>" + "/oscarRx/WriteScript.do?parameterValue=updateReRxDrug";
                new Ajax.Request(url, {method: 'get', parameters: data});
            }
        }

        function removeReRxDrugId(drugId) {
            if (drugId != null) {
                var data = "reRxDrugId=" + drugId + "&action=removeFromReRxDrugIdList&rand=" + Math.floor(Math.random() * 10001);
                var url = "<c:out value="${ctx}"/>" + "/oscarRx/WriteScript.do?parameterValue=updateReRxDrug";
                new Ajax.Request(url, {method: 'get', parameters: data});
            }
        }

        //represcribe a drug
        function represcribe(element, toArchive) {
    var elemId = element.id;
    var drugId = elemId.split("_")[1];
    var drugNameElement = document.getElementById("drugName_" + drugId);
    var loaderOverlay = document.getElementById("rerxLoaderOverlay");

    if (drugNameElement) {
        var drugName = drugNameElement.textContent.trim();
        var url = "<c:out value='${ctx}'/>/oscarRx/searchDrug.do?method=jsonSearch";

        // Clearly show loader overlay before AJAX call
        loaderOverlay.style.visibility = "visible";

        new Ajax.Request(url, {
            method: "post",
            parameters: { query: drugName },
            requestHeaders: {
                "Accept": "application/json",
                "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8"
            },
            onSuccess: function(transport) {
                var responseText = transport.responseText;
                if (!responseText) {
                    loaderOverlay.style.visibility = "hidden";
                    alert("Empty response from server.");
                    return;
                }
                
                let jsonData;
                try {
                    jsonData = JSON.parse(responseText);
                } catch (e) {
                    loaderOverlay.style.visibility = "hidden";
                    console.error("JSON Parsing Error:", e);
                    alert("Failed to parse drug data.");
                    return;
                }

                if (jsonData && jsonData.results && jsonData.results.length > 0) {
                    var selectedDrug = jsonData.results[0];
                    selectedDrug.name = decodeHtmlEntities(selectedDrug.name);
                    
                    var createRxUrl = "<c:out value='${ctx}'/>/oscarRx/WriteScript.do?parameterValue=createNewRx";
                    var ran_number = Math.round(Math.random() * 1000000);
                    var name = encodeURIComponent(selectedDrug.name);
                    var din = selectedDrug.din;
                    var params = "demographicNo=<%=demoNo%>&drugId=" + selectedDrug.id + "&text=" + name + "&randomId=" + ran_number + "&din=" + din;

                    new Ajax.Updater('rxText', createRxUrl, {
                        method: 'get',
                        parameters: params,
                        evalScripts: true,
                        insertion: Insertion.Bottom,
                        onSuccess: function (transport) {
                            updateCurrentInteractions();
                            // Hide loader after successful prescription load
                            loaderOverlay.style.visibility = "hidden";
                        },
                        onFailure: function() {
                            loaderOverlay.style.visibility = "hidden";
                            alert("Failed to load prescription.");
                        }
                    });

                } else {
                    loaderOverlay.style.visibility = "hidden";
                    alert("No matching drug found for: " + drugName);
                }
            },
            onFailure: function() {
                loaderOverlay.style.visibility = "hidden";
                alert("Failed to fetch drug data from server.");
            }
        });
    } else {
        alert("Drug name not found. Please select manually.");
    }
}

// Helper clearly defined
function decodeHtmlEntities(text) {
    var temp = document.createElement("textarea");
    temp.innerHTML = text;
    return temp.value;
}


        function updateQty(element) {
            var elemId = element.id;
            var ar = elemId.split("_");
            var rand = ar[1];
            var data = "randomId=" + rand + "&action=updateQty&quantity=" + element.value;
            var url = "<c:out value="${ctx}"/>" + "/oscarRx/WriteScript.do?parameterValue=updateDrug";
            var rxMethod = "rxMethod_" + rand;
            var rxRoute = "rxRoute_" + rand;
            var rxFreq = "rxFreq_" + rand;
            var rxDrugForm = "rxDrugForm_" + rand;
            var rxDuration = "rxDuration_" + rand;
            var rxDurationUnit = "rxDurationUnit_" + rand;
            var rxAmt = "rxAmount_" + rand;
            var str;
            // var rxString="rxString_"+rand;
            var methodStr = "method_" + rand;
            var routeStr = "route_" + rand;
            var frequencyStr = "frequency_" + rand;
            var minimumStr = "minimum_" + rand;
            var maximumStr = "maximum_" + rand;
            var durationStr = "duration_" + rand;
            var durationUnitStr = "durationUnit_" + rand;
            var quantityStr = "quantityStr_" + rand;
            var unitNameStr = "unitName_" + rand;
            var prnStr = "prn_" + rand;
            var prnVal = "prnVal_" + rand;
            new Ajax.Request(url, {
                method: 'get', parameters: data, onSuccess: function (transport) {
                    var json = transport.responseText.evalJSON();
                    $(methodStr).innerHTML = json.method;
                    $(routeStr).innerHTML = json.route;
                    $(frequencyStr).innerHTML = json.frequency;
                    $(minimumStr).innerHTML = json.takeMin;
                    $(maximumStr).innerHTML = json.takeMax;
                    if (json.duration == null || json.duration == "null") {
                        $(durationStr).innerHTML = '';
                    } else {
                        $(durationStr).innerHTML = json.duration;
                    }
                    $(durationUnitStr).innerHTML = json.durationUnit;
                    $(quantityStr).innerHTML = json.calQuantity;
                    if (json.unitName != null && json.unitName != "null" && json.unitName != "NULL" && json.unitName != "Null") {
                        $(unitNameStr).innerHTML = json.unitName;
                    } else {
                        $(unitNameStr).innerHTML = '';
                    }
                    if (json.prn) {
                        $(prnStr).innerHTML = "prn";
                        $(prnVal).value = true;
                    } else {
                        $(prnStr).innerHTML = "";
                        $(prnVal).value = false;
                    }

                }
            });
            return true;
        }

        function parseIntr(element) {
            var elemId = element.id;
            var ar = elemId.split("_");
            var rand = ar[1];
            var instruction = "instruction=" + element.value + "&action=parseInstructions&randomId=" + rand;
            var url = "<c:out value="${ctx}"/>" + "/oscarRx/UpdateScript.do?parameterValue=updateDrug";
            var quantity = "quantity_" + rand;
            var str;
            var methodStr = "method_" + rand;
            var routeStr = "route_" + rand;
            var frequencyStr = "frequency_" + rand;
            var minimumStr = "minimum_" + rand;
            var maximumStr = "maximum_" + rand;
            var durationStr = "duration_" + rand;
            var durationUnitStr = "durationUnit_" + rand;
            var quantityStr = "quantityStr_" + rand;
            var unitNameStr = "unitName_" + rand;
            var prnStr = "prn_" + rand;
            var prnVal = "prnVal_" + rand;
            new Ajax.Request(url, {
                method: 'get', parameters: instruction, asynchronous: false, onSuccess: function (transport) {
                    var json = transport.responseText.evalJSON();
                    if (json.policyViolations != null && json.policyViolations.length > 0) {
                        for (var x = 0; x < json.policyViolations.length; x++) {
                            alert(json.policyViolations[x]);
                        }
                        $("saveButton").disabled = true;
                        $("saveOnlyButton").disabled = true;
                    } else {
                        $("saveButton").disabled = false;
                        $("saveOnlyButton").disabled = false;
                    }

                    $(methodStr).innerHTML = json.method;
                    $(routeStr).innerHTML = json.route;
                    $(frequencyStr).innerHTML = json.frequency;
                    $(minimumStr).innerHTML = json.takeMin;
                    $(maximumStr).innerHTML = json.takeMax;
                    if (json.duration == null || json.duration == "null") {
                        $(durationStr).innerHTML = '';
                    } else {
                        $(durationStr).innerHTML = json.duration;
                    }
                    $(durationUnitStr).innerHTML = json.durationUnit;
                    if (json.calQuantity != "0") {
                        $(quantityStr).innerHTML = json.calQuantity;
                    }
                    if (json.unitName != null && json.unitName != "null" && json.unitName != "NULL" && json.unitName != "Null") {
                        $(unitNameStr).innerHTML = json.unitName;
                    } else {
                        $(unitNameStr).innerHTML = '';
                    }
                    if (json.prn) {
                        $(prnStr).innerHTML = "prn";
                        $(prnVal).value = true;
                    } else {
                        $(prnStr).innerHTML = "";
                        $(prnVal).value = false;
                    }
                    if ($(unitNameStr).innerHTML != '')
                        $(quantity).value = $(quantityStr).innerHTML + " " + $(unitNameStr).innerHTML;
                    else
                        $(quantity).value = $(quantityStr).innerHTML;
                }
            });
            return true;
        }

        function addLuCode(eleId, luCode) {
            $(eleId).value = $(eleId).value + " LU Code: " + luCode;
        }

        function getRenalDosingInformation(divId, atcCode) {
            var url = "RenalDosing.jsp";
            var ran_number = Math.round(Math.random() * 1000000);
            var params = "demographicNo=<%=demoNo%>&atcCode=" + atcCode + "&divId=" + divId + "&rand=" + ran_number;
            new Ajax.Updater(divId, url, {
                method: 'get',
                parameters: params,
                insertion: Insertion.Bottom,
                asynchronous: true
            });
        }

        function getLUC(divId, randomId, din) {
            var url = "LimitedUseCode.jsp";
            var params = "randomId=" + randomId + "&din=" + din;
            new Ajax.Updater(divId, url, {
                method: 'get',
                parameters: params,
                insertion: Insertion.Bottom,
                asynchronous: true
            });
        }

        function getCost(divId, randomId, din, qty) {
            var url = "DrugPrice.jsp";
            var params = "randomId=" + randomId + "&din=" + din + "&qty=" + qty;
            new Ajax.Updater(divId, url, {
                method: 'get',
                parameters: params,
                insertion: Insertion.Bottom,
                asynchronous: true
            });
        }

        function validateRxDate() {
            var x = true;
            jQuery('input[name^="rxDate__"]').each(function () {
                var str1 = jQuery(this).val();
                var dt = str1.split("-");
                if (dt.length > 3) {
                    jQuery(this).trigger( "focus" );
                    alert('Start Date wrong format! Must be yyyy or yyyy-mm or yyyy-mm-dd');
                    x = false;
                    return;
                }
                var dt1 = 1, mon1 = 0, yr1 = parseInt(dt[0], 10);
                if (isNaN(yr1) || yr1 < 0 || yr1 > 9999) {
                    jQuery(this).trigger( "focus" );
                    alert('Invalid Start Date! Please check the year');
                    x = false;
                    return;
                }
                if (dt.length > 1) {
                    mon1 = parseInt(dt[1], 10) - 1;
                    if (isNaN(mon1) || mon1 < 0 || mon1 > 11) {
                        jQuery(this).trigger( "focus" );
                        alert('Invalid Start Date! Please check the month');
                        x = false;
                        return;
                    }
                }
                if (dt.length > 2) {
                    dt1 = parseInt(dt[2], 10);
                    if (isNaN(dt1) || dt1 < 1 || dt1 > 31) {
                        jQuery(this).trigger( "focus" );
                        alert('Invalid Start Date! Please check the day');
                        x = false;
                        return;
                    }
                }
                var date1 = new Date(yr1, mon1, dt1);
                var now = new Date();
                if (date1 > now) {
                    jQuery(this).trigger( "focus" );
                    alert('Start Date cannot be in the future. (' + str1 + ')');
                    x = false;
                    return;
                }
            });
            return x;
        }

        function validateRxQuantity() {
            var x = true;
            jQuery('input[name^="quantity_"]').each(function () {
                var str1 = jQuery(this).val();
                if ((str1.length == 0) || (parseFloat(str1) == 0) || (isNaN(parseFloat(str1)))) {
                    jQuery(this).trigger( "focus" );
                    x = confirm('WARNING no quantity entered.\nProceed anyway?');
                    return;
                }
            });
            return x;
        }

        function validateWrittenDate() {
            var x = true;
            jQuery('input[name^="writtenDate_"]').each(function () {
                var str1 = jQuery(this).val();
                var dt = str1.split("-");
                if (dt.length > 3) {
                    jQuery(this).trigger( "focus" );
                    alert('Written Date wrong format! Must be yyyy or yyyy-mm or yyyy-mm-dd');
                    x = false;
                    return;
                }
                var dt1 = 1, mon1 = 0, yr1 = parseInt(dt[0], 10);
                if (isNaN(yr1) || yr1 < 0 || yr1 > 9999) {
                    jQuery(this).trigger( "focus" );
                    alert('Invalid Written Date! Please check the year');
                    x = false;
                    return;
                }
                if (dt.length > 1) {
                    mon1 = parseInt(dt[1], 10) - 1;
                    if (isNaN(mon1) || mon1 < 0 || mon1 > 11) {
                        jQuery(this).trigger( "focus" );
                        alert('Invalid Written Date! Please check the month');
                        x = false;
                        return;
                    }
                }
                if (dt.length > 2) {
                    dt1 = parseInt(dt[2], 10);
                    if (isNaN(dt1) || dt1 < 1 || dt1 > 31) {
                        jQuery(this).trigger( "focus" );
                        alert('Invalid Written Date! Please check the day');
                        x = false;
                        return;
                    }
                }
                var date1 = new Date(yr1, mon1, dt1);
                var now = new Date();
                if (date1 > now) {
                    jQuery(this).trigger( "focus" );
                    alert('Written Date cannot be in the future. (' + str1 + ')');
                    x = false;
                    return;
                }
            });
            return x;
        }
        <%
		ArrayList<Object> args = new ArrayList<Object>();
		args.add(String.valueOf(bean.getDemographicNo()));
		args.add(bean.getProviderNo());
		Study myMeds = StudyFactory.getFactoryInstance().makeStudy(Study.MYMEDS, args);
		out.write(myMeds.printInitcode());
	%>
        function updateSaveAllDrugsPrintContinue() {
            if (!validateWrittenDate()) {
                return false;
            }
            if (!validateRxDate()) {
                return false;
            }
            if (!validateRxQuantity()) {
                return false;
            }
            <%if (OscarProperties.getInstance().isPropertyActive("rx_strict_med_term")) {%>
            if (!checkMedTerm()) {
                return false;
            }
            <% } %>
            setPharmacyId();
             var prescriptionBatchId = "batch_" + Math.floor(Math.random() * 1000000);
            console.log("Generated prescriptionBatchId:", prescriptionBatchId); 
            var data = Form.serialize($('drugForm')) + "&prescriptionBatchId=" + encodeURIComponent(prescriptionBatchId);
            var url = "<c:out value="${ctx}"/>" + "/oscarRx/WriteScript.do?parameterValue=updateSaveAllDrugs&rand=" + Math.floor(Math.random() * 10001);
            new Ajax.Request(url,
                {
                    method: 'post', postBody: data, asynchronous: false,
                    onSuccess: function (transport) {

                        callReplacementWebService("ListDrugs.jsp", 'drugProfile');
                        popForm2(null, prescriptionBatchId);
                        resetReRxDrugList();
                    }
                });
            return false;
        }

        function updateSaveAllDrugsContinue() {
            if (!validateWrittenDate()) {
                return false;
            }
            if (!validateRxDate()) {
                return false;
            }
            <%if (OscarProperties.getInstance().isPropertyActive("rx_strict_med_term")) {%>
            if (!checkMedTerm()) {
                return false;
            }
            <% } %>
            setPharmacyId();
            var data = Form.serialize($('drugForm'));
            var url = "<c:out value="${ctx}"/>" + "/oscarRx/WriteScript.do?parameterValue=updateSaveAllDrugs&rand=" + Math.floor(Math.random() * 10001);
            new Ajax.Request(url,
                {
                    method: 'post', postBody: data, asynchronous: false,
                    onSuccess: function (transport) {
                        callReplacementWebService("ListDrugs.jsp", 'drugProfile');
                        resetReRxDrugList();
                        resetStash();
                    }
                });
            return false;
        }

        /**
         * Gets the selected preferred pharmacy id and then sets it into the
         * rxPharmacyId hidden input for submission with each drug in
         * a prescription.
         */
        function setPharmacyId() {
            var selectedPharmacy = jQuery("#Calcs option:selected").val();
            var selectedPharmacyId = "";
            if (selectedPharmacy) {
                selectedPharmacyId = JSON.parse(selectedPharmacy).id;
            }
            jQuery("#rxPharmacyId").val(selectedPharmacyId);
        }

        function checkEnterSendRx() {
            popupRxSearchWindow();
            return false;
        }

        <%if (OscarProperties.getInstance().isPropertyActive("rx_strict_med_term")) {%>
        function checkMedTerm() {
            var randId = 0;
            var isAnyTermChecked = false;
            jQuery("fieldset[id^='set_']").each(function () {
                randId = jQuery(this).attr("id").replace('set_', '');
                isAnyTermChecked = isMedTermChecked(randId);
            });

            if (!isAnyTermChecked) {
                alert("Please review drug(s) and specify medication term!");
            } else {
                return true;
            }
            return false;
        }// end checkMedTerm

        function isMedTermChecked(rnd) {
            var termChecked = false;
            var longTermY = jQuery("#longTermY_" + rnd);
            var longTermN = jQuery("#longTermN_" + rnd);
            var shortTerm = jQuery("#shortTerm_" + rnd);
            var medTermWrap = jQuery("#medTerm_" + rnd);

            if (longTermY.is(":checked") || longTermN.is(":checked")) {
                termChecked = true;
                medTermWrap.css('color', 'black');
            } else {
                termChecked = false;
                medTermWrap.css('color', 'red');
            }
            return termChecked;
        }

        <%} //end rx_strict_med_term check %>

        function medTermCheckOne(rnd, el) {
            var longTerm = jQuery("#longTerm_" + rnd);
            var shortTerm = jQuery("#shortTerm_" + rnd);

            if (el.prop("checked")) {
                if (el.attr("id") == "longTerm_" + rnd) {
                    shortTerm.attr("checked", false);
                } else {
                    longTerm.attr("checked", false);
                }
            }
        }

        jQuery(document).ready(function () {
            jQuery(document).on('change', '.med-term', function () {
                var randId = jQuery(this).attr("id").split("_").pop();

                <%if (OscarProperties.getInstance().isPropertyActive("rx_strict_med_term")) {%>
                isMedTermChecked(randId);
                <% } %>
                //var el = jQuery( this );
                //medTermCheckOne(randId, el);
            });
            setTimeout("document.getElementById('<%=defaultView%>').click();console.log('default view setting');", 3000);
            console.log("Timeout running");
        });
    </script>
    <script>
        function updateShortTerm(rand, val) {
            if (val) {
                jQuery("#shortTerm_" + rand).prop("checked", true);
            } else {
                jQuery("#shortTerm_" + rand).prop("checked", false);
            }

        }

        function updateLongTerm(rand, repeatEl) {
            <%if("true".equals(OscarProperties.getInstance().getProperty("rx_select_long_term_when_repeat", "true"))) { %>
            var repeats = jQuery('#repeats_' + rand).val().trim();
            if (!isNaN(repeats) && repeats > 0) {
                jQuery("#longTermY_" + rand).prop("checked", true);
            }
            <% } %>
        }

    </script>
    <script language="javascript" src="../commons/scripts/sort_table/css.js"></script>
    <script language="javascript" src="../commons/scripts/sort_table/common.js"></script>
    <script language="javascript" src="../commons/scripts/sort_table/standardista-table-sorting.js"></script>


<script type="text/javascript">

    // Pass the fetched values from JSP to JavaScript and escape them correctly
    var patientCompliance = <%= patientCompliance != null ? "\"" + patientCompliance.replace("\"", "\\\"") + "\"" : "\"\"" %>;
    var frequency = <%= frequency != null ? "\"" + frequency.replace("\"", "\\\"") + "\"" : "\"\"" %>;

    // Log the values for debugging
    console.log("Patient Compliance:", patientCompliance);
    console.log("Frequency:", frequency);
    
    // Function to calculate the end date based on start date and duration
    function calculateEndDate(randomId) {
        console.log("Triggered calculateEndDate for:", randomId);

        const startDateField = document.getElementById('startDate_' + randomId);
        const durationField = document.getElementById('duration_' + randomId);
        const endDateField = document.getElementById('endDate_' + randomId);

        if (!startDateField || !durationField || !endDateField) {
            console.error("One or more fields are missing for randomId:", randomId);
            return;
        }

        const startDate = startDateField.value; // Input in yyyy-MM-dd
        const duration = parseInt(durationField.value, 10); // Convert duration to integer
        console.log(`Start Date (${randomId}):`, startDate);
        console.log(`Duration (${randomId}):`, duration);

        if (startDate && !isNaN(duration)) {
            // Parse the start date
            const startDateObj = new Date(startDate);
            console.log(`Start Date Object (${randomId}):`, startDateObj);

            if (isNaN(startDateObj)) {
                console.error("Invalid Date Object for Start Date:", startDate);
                endDateField.value = "--"; // Set default value if date is invalid
                return;
            }

            // Calculate the end date
            startDateObj.setDate(startDateObj.getDate() + duration);

            // Directly format the end date to yyyy-MM-dd
            const formattedEndDate = startDateObj.toISOString().split('T')[0];
            console.log("Formatted End Date:", formattedEndDate);

            // Assign the formatted value to the field
            endDateField.value = formattedEndDate;
            console.log(`End Date Field Value (${randomId}):`, endDateField.value);
        } else {
            console.warn(`Invalid Inputs for End Date Calculation (${randomId}): Start Date or Duration`);
            endDateField.value = "--"; // Set default value
        }
    }

    // Function to attach event listeners to start date and duration fields
    function attachEventListeners(randomId) {
        console.log("Attaching event listeners for randomId:", randomId);

        const startDateField = document.getElementById('startDate_' + randomId);
        const durationField = document.getElementById('duration_' + randomId);

        if (startDateField) {
            startDateField.addEventListener('input', () => calculateEndDate(randomId));
        } else {
            console.error("Start Date field not found for randomId:", randomId);
        }

        if (durationField) {
            durationField.addEventListener('input', () => calculateEndDate(randomId));
        } else {
            console.error("Duration field not found for randomId:", randomId);
        }
    }

    // Function to initialize event listeners for all prescription fields
    function initializePrescriptionFields() {
        console.log("Initializing Prescription Fields...");
        document.querySelectorAll('[id^="startDate_"]').forEach((startDateField) => {
            const randomId = startDateField.id.split('_')[1];
            attachEventListeners(randomId);
        });
    }

    // Function to handle compliance change and toggle frequency visibility
    function handleComplianceChange(randomId) {
        var complianceField = document.getElementById('compliance_' + randomId);
        var frequencyDiv = document.getElementById('frequencyOptions_' + randomId);

        if (!complianceField || !frequencyDiv) {
            console.warn('Missing elements for randomId:', randomId);
            return;
        }

        if (complianceField.value === 'no') {
            // Show the frequency options
            frequencyDiv.style.display = 'block';
        } else {
            // Hide the frequency options
            frequencyDiv.style.display = 'none';
        }
    }

    // Function to populate the compliance and frequency fields
    function populateComplianceAndFrequency(randomId, patientCompliance, frequency) {
        console.log("Populating compliance and frequency for randomId:", randomId);

        const complianceField = document.getElementById('compliance_' + randomId);
        const frequencyDiv = document.getElementById('frequencyOptions_' + randomId);

        if (!complianceField || !frequencyDiv) {
            console.error("Missing fields for compliance and frequency:", randomId);
            return;
        }

        // Set the compliance value
        if (patientCompliance) {
            complianceField.value = patientCompliance;
            console.log(`Set compliance field (${randomId}) to:`, patientCompliance);

            handleComplianceChange(randomId); // Toggle frequency visibility
        }

        // Set the frequency value if it's provided and visible
        if (frequency && frequencyDiv.style.display === 'block')
{
        const attrr_value ='input[name="frequency_' + randomId + '"][value="' + frequency + '"]';
            const frequencyRadioButton = document.querySelector(attrr_value);
console.log({'random id': randomId ,'frequency': frequency,frequencyRadioButton,abc:`input[name="frequency_${randomId}"][value="monthly"]`,attrr_value});
            if (frequencyRadioButton) {
                frequencyRadioButton.checked = true;
                console.log(`Set frequency radio button (${randomId}) to:`, frequency);
            } else {
            console.error("No matching frequency radio button for value:", frequency);
        }
    } else {
        console.log("Frequency options are hidden or frequency div doesn't exist.");
    }
}

    // Function to initialize the compliance and frequency values based on the backend data
    function initializeComplianceAndFrequencyFields() {
        console.log("Initializing Compliance and Frequency Fields...");

        document.querySelectorAll('select[id^="compliance_"]').forEach(function (complianceField) {
            var randomId = complianceField.id.split('_')[1];

            console.log("Initializing compliance field with randomId:", randomId);

            complianceField.value = patientCompliance;  // Set the compliance value

            console.log(`Set compliance value for ${randomId} to:`, patientCompliance);

            handleComplianceChange(randomId); // Toggle frequency visibility

            if (frequency) {
                var frequencyRadioButton = document.querySelector(`input[name="frequency_${randomId}"][value="${frequency}"]`);
                if (frequencyRadioButton) {
                    frequencyRadioButton.checked = true;
                    console.log(`Set frequency radio button for ${randomId} to:`, frequency);
                }
            }
        });
    }

    // Function to watch for dynamically added fields (compliance and frequency) and populate them when added
    const complianceFrequencyObserver = new MutationObserver((mutations) => {
        mutations.forEach((mutation) => {
            mutation.addedNodes.forEach((node) => {
                if (node.nodeType === 1) {
                    const complianceField = node.querySelector('[id^="compliance_"]');
                    if (complianceField) {
                        const randomId = complianceField.id.split('_')[1];
                        console.log("Compliance field added dynamically with randomId:", randomId);
                        populateComplianceAndFrequency(randomId, patientCompliance, frequency);
                    }
                }
            });
        });
    });

    // Start observing the document for dynamically added nodes
    complianceFrequencyObserver.observe(document.body, { childList: true, subtree: true });

    // Run on page load
    document.addEventListener('DOMContentLoaded', function () {
        initializePrescriptionFields();
        initializeComplianceAndFrequencyFields(); // Populate compliance and frequency fields
    });

    // MutationObserver to dynamically initialize fields added later for start date and duration
    const prescriptionObserver = new MutationObserver((mutations) => {
        mutations.forEach((mutation) => {
            mutation.addedNodes.forEach((node) => {
                if (node.nodeType === 1) {
                    const startDateField = node.querySelector('[id^="startDate_"]');
                    if (startDateField) {
                        const randomId = startDateField.id.split('_')[1];
                        attachEventListeners(randomId);
                    }
                }
            });
        });
    });

    // Start observing the document for dynamically added nodes
    prescriptionObserver.observe(document.body, { childList: true, subtree: true });

    // Flag indicating if search bar was manually activated
let isSearchActive = false;

// Counter to keep track of drugs added
let drugCounter = 0;

// Adjusted checkForInstructionsField function
function checkForInstructionsField() {
    var instructionsFields = document.querySelectorAll("[id^='instructions_']");

    if (instructionsFields.length === 0) {
        const writeNewPrescription = document.getElementById("writeNewPrescription");
        if (writeNewPrescription) {
            writeNewPrescription.style.display = "block";
        }

        document.getElementById("searchString").style.display = "inline-block";
        document.getElementById("addDrugButton").style.display = "none";
        document.getElementById("saveButton").style.display = "none";

        isSearchActive = false;

        console.log("No drugs left. Showing initial state.");

    } else {
        drugCounter = instructionsFields.length;
        console.log(`${drugCounter} drug${drugCounter > 1 ? 's' : ''} added`);

        document.getElementById("saveButton").style.display = "inline-block";
        document.getElementById("writeNewPrescription").style.display = "none";

        if (isSearchActive) {
            // If search is active, hide "Add New Drug"
            document.getElementById("addDrugButton").style.display = "none";
            document.getElementById("searchString").style.display = "inline-block";
        } else {
            // If search is inactive, show "Add New Drug" button
            document.getElementById("addDrugButton").style.display = "inline-block";
            document.getElementById("searchString").style.display = "none";
        }
    }
}


// Show search bar explicitly when "Add New Drug" is clicked
function showSearchBar() {
    isSearchActive = true;  // User has manually activated search
    document.getElementById("searchString").style.display = "inline-block";
    document.getElementById("addDrugButton").style.display = "none";
    document.getElementById("searchString").focus();

    const writeNewPrescription = document.getElementById("writeNewPrescription");
    if (writeNewPrescription) {
        writeNewPrescription.style.display = "none";
    }
}

// Function to remove a drug and update state accordingly
function removeDrug(rand) {
    console.log("Removing drug with id: " + rand);
    document.getElementById("set_" + rand).remove();

    drugCounter--;
    console.log(`${drugCounter} drug${drugCounter > 1 ? 's' : ''} left`);

    checkForInstructionsField();
}

// Every 500ms, check the DOM for new instructions fields
setInterval(() => {
    const prevDrugCounter = drugCounter;  // Remember previous state
    checkForInstructionsField();

    // If new drug was detected (drugCounter increased), reset search state
    if (drugCounter > prevDrugCounter) {
        isSearchActive = false;  // User finished adding a drug
    }
}, 500);

function calculateRequiredQuantity(randomId) {
    const dose = parseInt(document.getElementById('dose_' + randomId)?.value || 0);
    const freqType = document.getElementById('fqy_' + randomId)?.value;
    const subFreq = document.getElementById('subFrequency_' + randomId)?.value;
    const duration = parseInt(document.getElementById('duration_' + randomId)?.value || 0);
    const quantityField = document.getElementById('quantity_' + randomId);
    const endDateField = document.getElementById('endDate_' + randomId);
    const startDateField = document.getElementById('startDate_' + randomId);
    const weeklyDayDropdown = document.getElementById('weeklyDay_' + randomId);
    const weeklyDayContainer = document.getElementById('weeklyDayContainer_' + randomId);
    const instructionsField = document.getElementById('siInput_' + randomId);
    const drugForm = document.getElementById('drugForm_' + randomId)?.value.trim().toLowerCase() || "tablet";

    let frequencyMultiplier = 0;
    let subFreqText = "";
    let sig = "";
    let quantity = 0;

    // Determine sub-frequency multiplier and text
    switch (subFreq) {
        case "OD": frequencyMultiplier = 1; subFreqText = "once"; break;
        case "BID": frequencyMultiplier = 2; subFreqText = "twice"; break;
        case "TID": frequencyMultiplier = 3; subFreqText = "three times a day"; break;
        case "QID": frequencyMultiplier = 4; subFreqText = "four times a day"; break;
        default: frequencyMultiplier = 0;
    }

    // Show/hide day selector for weekly
    if (freqType === "WEEKLY") {
        weeklyDayContainer.style.display = "block";
    } else {
        weeklyDayContainer.style.display = "none";
    }

    // --- Calculate Quantity ---
    let occurrences = 0;

    if (dose > 0 && frequencyMultiplier > 0 && duration > 0) {
        if (freqType === "WEEKLY") {
            const weeklyDay = parseInt(weeklyDayDropdown?.value);
            if (!isNaN(weeklyDay) && startDateField?.value) {
                const startDate = new Date(startDateField.value);
                for (let i = 0; i < duration; i++) {
                    const date = new Date(startDate);
                    date.setDate(date.getDate() + i);
                    if (date.getDay() === weeklyDay) {
                        occurrences++;
                    }
                }
                quantity = dose * frequencyMultiplier * occurrences;
            }
        } else if (freqType === "ALTERNATE") {
            const altDays = Math.ceil(duration / 2);
            quantity = dose * frequencyMultiplier * altDays;
        } else if (freqType === "MONTHLY") {
            const monthlyCycles = Math.ceil(duration / 30);
            quantity = dose * frequencyMultiplier * monthlyCycles;
        }  else { // DAILY
            quantity = dose * frequencyMultiplier * duration;
        }
        quantityField.value = quantity;
    } else {
        quantityField.value = "";
    }

    // --- Calculate End Date ---
    if (startDateField && endDateField && duration > 0) {
        const startDate = new Date(startDateField.value);
        if (!isNaN(startDate)) {
            startDate.setDate(startDate.getDate() + duration);
            endDateField.value = startDate.toISOString().split('T')[0];
        } else {
            endDateField.value = "";
        }
    }

    // --- Generate SIG String ---
    if (instructionsField && dose > 0 && duration > 0 && subFreqText && freqType) {
        const formText = dose > 1 ? drugForm + "s" : drugForm;
        const baseSig = "Take " + dose + " " + formText + " by mouth ";

if (freqType === "DAILY") {
    sig = baseSig + subFreqText + " daily for " + duration + " days.";
} else if (freqType === "ALTERNATE") {
    sig = baseSig + subFreqText + " every other day for " + duration + " days.";
} else if (freqType === "WEEKLY") {
    const dayText = weeklyDayDropdown?.options[weeklyDayDropdown.selectedIndex]?.text;
    sig = baseSig + subFreqText + " every week on " + dayText + ".";
} else if (freqType === "MONTHLY") {
    sig = baseSig + "every month." ;
}

        instructionsField.value = sig;
        updateSpecialInstruction('siInput_' + randomId); // ensure backend sync
    } else if (instructionsField) {
        instructionsField.value = "";
        updateSpecialInstruction('siInput_' + randomId);
    }
}

// function calculateRequiredQuantity(randomId) {
//     const dose = parseInt(document.getElementById('dose_' + randomId)?.value || 0);
//     const freq = parseInt(document.getElementById('fqy_' + randomId)?.value || 0);
//     const duration = parseInt(document.getElementById('duration_' + randomId)?.value || 0);
//     const quantityField = document.getElementById('quantity_' + randomId);

//     if (dose > 0 && freq > 0 && duration > 0 && quantityField) {
//         const quantity = dose * freq * duration;
//         quantityField.value = quantity;
//     } else {
//         quantityField.value = "";
//     }
// }


</script>

<div id="rerxLoaderOverlay">
    <div class="loaderSpinner"></div>
</div>

    </body>
</html:html>