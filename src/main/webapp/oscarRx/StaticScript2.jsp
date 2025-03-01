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
<%@page import="org.oscarehr.util.LoggedInInfo"%>

<%@page import="org.apache.commons.lang.StringEscapeUtils" %>
<%@page import="java.util.ArrayList"%>
<%@page import="java.util.List"%>

<%@page import="oscar.oscarRx.data.RxPrescriptionData"%>
<%@page import="oscar.oscarRx.util.RxUtil" %>
<%@page import="org.oscarehr.common.dao.DrugDao"%>
<%@page import="org.oscarehr.common.dao.PartialDateDao" %>
<%@page import="org.oscarehr.common.model.PartialDate" %>
<%@page import="org.oscarehr.common.model.Drug"%>
<%@page import="org.oscarehr.PMmodule.caisi_integrator.CaisiIntegratorManager"%>
<%@page import="org.oscarehr.caisi_integrator.ws.DemographicWs"%>
<%@page import="org.oscarehr.util.SessionConstants"%>
<%@page import="org.oscarehr.util.SpringUtils"%>
<%@page import="org.oscarehr.oscarRx.StaticScriptBean"%>


<%@ taglib uri="/WEB-INF/struts-bean.tld" prefix="bean"%>
<%@ taglib uri="/WEB-INF/struts-html.tld" prefix="html"%>
<%@ taglib uri="/WEB-INF/struts-logic.tld" prefix="logic"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@ taglib uri="/WEB-INF/oscar-tag.tld" prefix="oscar" %>

<%@ taglib uri="/WEB-INF/security.tld" prefix="security"%>
<%
    String roleName2$ = (String)session.getAttribute("userrole") + "," + (String) session.getAttribute("user");
    boolean authed=true;
%>
<security:oscarSec roleName="<%=roleName2$%>" objectName="_rx" rights="r" reverse="<%=true%>">
	<%authed=false; %>
	<%response.sendRedirect("../securityError.jsp?type=_rx");%>
</security:oscarSec>
<%
	if(!authed) {
		return;
	}
%>
<!DOCTYPE html>
<html:html locale="true">
<head>
<script src="<%= request.getContextPath() %>/js/global.js"></script>
<script src="<%= request.getContextPath() %>/share/javascript/Oscar.js"></script>

<title><bean:message key="StaticScript.title" /></title>
<!-- jquery -->
    <script src="<%=request.getContextPath()%>/library/jquery/jquery-3.6.4.min.js"></script>
    <script src="<%=request.getContextPath()%>/library/DataTables/datatables.min.js"></script> <!-- DataTables 1.13.4 -->

<!-- Bootstrap 2.3.1 -->
    <link href="<%=request.getContextPath()%>/css/bootstrap.css" rel="stylesheet" >
<link href="${pageContext.request.contextPath}/css/DT_bootstrap.css" rel="stylesheet">
<link href="${pageContext.request.contextPath}/library/DataTables-1.10.12/media/css/jquery.dataTables.min.css" rel="stylesheet">
<html:base />

<%
LoggedInInfo loggedInInfo=LoggedInInfo.getLoggedInInfoFromSession(request);
oscar.oscarRx.pageUtil.RxSessionBean rxBean = null;
%>
<%if(request.getParameter("demographicNo") != null) {
	rxBean = new oscar.oscarRx.pageUtil.RxSessionBean();

	rxBean.setProviderNo((String)session.getAttribute("user"));
	rxBean.setDemographicNo(Integer.parseInt(request.getParameter("demographicNo")));

	request.getSession().setAttribute("RxSessionBean", rxBean);
 } %>

<logic:notPresent name="RxSessionBean" scope="session">
	<logic:redirect href="/error.html" />
</logic:notPresent>

<logic:present name="RxSessionBean" scope="session">
	<bean:define id="bean" type="oscar.oscarRx.pageUtil.RxSessionBean" name="RxSessionBean" scope="session" />
	<logic:equal name="bean" property="valid" value="false">
		<logic:redirect href="error.html" />
	</logic:equal>
</logic:present>
<c:set var="ctx" value="${pageContext.request.contextPath}" />
<%
	if( rxBean == null ) {
		rxBean=(oscar.oscarRx.pageUtil.RxSessionBean)pageContext.findAttribute("bean");
	}
	com.quatro.service.security.SecurityManager securityManager = new com.quatro.service.security.SecurityManager();
%>

<%
       if(session.getAttribute("user") == null )
            response.sendRedirect("../logout.jsp");
	String curUser_no = (String) session.getAttribute("user");
	String regionalIdentifier=request.getParameter("regionalIdentifier");
	String cn=request.getParameter("cn");
	String bn=request.getParameter("bn");
	Integer currentDemographicNo=rxBean.getDemographicNo();
	String atc = request.getParameter("atc");

	ArrayList<StaticScriptBean.DrugDisplayData> drugs=StaticScriptBean.getDrugList(loggedInInfo, currentDemographicNo, regionalIdentifier, cn,bn,atc);

	oscar.oscarRx.data.RxPatientData.Patient patient=oscar.oscarRx.data.RxPatientData.getPatient(loggedInInfo, currentDemographicNo);
	String annotation_display=org.oscarehr.casemgmt.model.CaseManagementNoteLink.DISP_PRESCRIP;
%>

<script>
    function ShowDrugInfo(gn){
        window.open("drugInfo.do?GN=" + escape(gn), "_blank",
            "location=no, menubar=no, toolbar=no, scrollbars=yes, status=yes, resizable=yes");
    }

    function addFavorite2(drugId, brandName){
        var favoriteName = window.prompt('Please enter a name for the Favorite:',  brandName);

       if (favoriteName.length > 0){
            var url= "<%=request.getContextPath()%>" + "/oscarRx/addFavorite2.do?parameterValue=addFav2";
            oscarLog(url);
            favoriteName=encodeURIComponent(favoriteName);
            var data="drugId="+drugId+"&favoriteName="+favoriteName;

            jQuery.ajax({
			    type: "GET",
			    url: url,
			    data: data,
			    success: function(transport) {
			        window.location.href="StaticScript2.jsp?regionalIdentifier="+'<%=regionalIdentifier%>'+"&cn="+'<%=cn%>';
			    }
            });

       }
    }

    //represcribe a drug
    function reRxDrugSearch3(reRxDrugId){
        var dataUpdateId="reRxDrugId="+reRxDrugId+"&action=addToReRxDrugIdList&rand="+Math.floor(Math.random()*10001);
        var urlUpdateId= "<c:out value="${ctx}"/>" + "/oscarRx/WriteScript.do?parameterValue=updateReRxDrug";
        new Ajax.Request(urlUpdateId, {method: 'get',parameters:dataUpdateId});
            var data="drugId="+reRxDrugId;
            var url= "<c:out value="${ctx}"/>" + "/oscarRx/rePrescribe2.do?method=saveReRxDrugIdToStash";
            new Ajax.Request(url, {method: 'post',parameters:data,asynchronous:false,onSuccess:function(transport){
                 location.href="SearchDrug3.jsp?";
        }});

        jQuery.ajax({
			type: "GET",
			url: "<c:out value="${ctx}"/>" + "/oscarRx/rePrescribe2.do?method=saveReRxDrugIdToStash",
			data: "drugId="+reRxDrugId,
			success: function(transport) {
			    jQuery.ajax({
			        type: "POST",
			        url: "<c:out value="${ctx}"/>" + "/oscarRx/rePrescribe2.do?method=saveReRxDrugIdToStash",
			        data: "drugId="+reRxDrugId,
			        success: function(transport) {
			            location.href="SearchDrug3.jsp?";
			        }
                });
			}
        });


    }
$(document).ready(function(){
    oTable=jQuery('#rxtbl').DataTable({
        "order": [],
        "language": {
        "url": "<%=request.getContextPath() %>/library/DataTables/i18n/<bean:message key="global.i18nLanguagecode"/>.json"
        }
    });

});

</script>
</head>
<body>
<div class="well">
<table style="width:100%; height:100%" id="AutoNumber1">

	<tr>
		<%@ include file="SideLinksNoEditFavorites2.jsp"%><!-- <td></td>Side Bar File --->
		<td style="width:100%; vertical-align:top; border-left: 2px solid #A9A9A9; padding-left:10px;">
		<table style="width:100%; height:100%">
			<tr>
				<td style="width:0%; vertical-align:top;">
				<div class="DivCCBreadCrumbs"><a href="SearchDrug3.jsp"> <bean:message key="SearchDrug.title" /></a> &gt; <b><bean:message key="StaticScript.title" /></b></div>
				</td>
			</tr>
			<!----Start new rows here-->

			<tr>
				<td><br />
				<br />
				<b>Patient Name:</b> <%=patient.getFirstName()%> <%=patient.getSurname()%> <br />
				<br />
				</td>
			</tr>
			<tr>
				<td>
<table id="rxtbl" class="table table-striped">
    <thead>
        <tr>
            <th><b><bean:message key="SelectReason.table.provider" /></b></th>
            <th><b><bean:message key="Appointment.formDate" /></b></th>
            <th><b><bean:message key="WriteScript.startDate" /></b></th>
            <th><b><bean:message key="WriteScript.endDate" /></b></th>
            <th><b><bean:message key="SearchDrug.msgPrescription" /></b></th>
            <th></th>
            <th></th>
        </tr>
    </thead>
    <tbody>
					<%
						PartialDateDao partialDateDao = (PartialDateDao)SpringUtils.getBean("partialDateDao");
						for (StaticScriptBean.DrugDisplayData drug : drugs)
							{
								String arch="";
								if (drug.isArchived)
								{
									arch="text-decoration: line-through;";
								}
					%>
					<tr style="height:20px;<%=arch%>">
						<td><%=drug.providerName%></td>
						<td><%
						if(!drug.writtenDate.equals("0001/01/01") ){
						out.print(partialDateDao.getDatePartial(drug.writtenDate, PartialDate.DRUGS, drug.localDrugId, PartialDate.DRUGS_WRITTENDATE));
						}
						%></td>
						<td><%
						if(!drug.startDate.equals("0001/01/01") ){
							out.print(partialDateDao.getDatePartial(drug.startDate, PartialDate.DRUGS, drug.localDrugId, PartialDate.DRUGS_STARTDATE));
							/*
							String startDate = drug.startDate;
		            		PartialDate pd = partialDateDao.getPartialDate(PartialDate.DRUGS , drug.localDrugId, PartialDate.DRUGS_STARTDATE);
		            		if(pd != null) {
		            			startDate = startDate.substring(0,pd.getFormat().length());
		            		}
							out.print(startDate);
							*/
						}
						%></td>
						<td><%
						if(!drug.startDate.equals("0001/01/01") ){
							out.print(drug.endDate);
						}
						%></td>
                        <td><%if(drug.localDrugId != null){ %>
                            <a href="javascript:void(0);"  title="<bean:message key="oscarencounter.guidelinelist.moreinfo" />" onclick="popup(600, 425,'DisplayRxRecord.jsp?id=<%=drug.localDrugId%>','displayRxWindow')">
                        <%}%><%=drug.prescriptionDetails%>
                        <%if(drug.localDrugId != null){ %>
                             </a>
                         <%}%>
                        <% if (drug.nonAuthoritative) { %>
                        &nbsp;<bean:message key="WriteScript.msgNonAuthoritative" />
                        <%   } %>
                        <% if (drug.pickupDate!=null &&  !drug.pickupDate.equals("") && !drug.pickupDate.equals("0000-00-00")){%>
                        <br><bean:message key="WriteScript.msgPickUpDate" />&nbsp;<%=drug.pickupDate%>&nbsp;
                        <% if (!((drug.pickupTime).equals("")) && !((drug.pickupTime).equals("12:00 AM"))){ %>
                        &nbsp;<%=drug.pickupTime%>&nbsp;
                        <% } } %>
                        <%if(drug.eTreatmentType != null && !drug.eTreatmentType.equals("null")){ %>
                        &nbsp;<bean:message key="WriteScript.msgETreatmentType"/>:
                        <%if (drug.eTreatmentType.equals("CHRON")){%>
                        <bean:message key="WriteScript.msgETreatment.Continuous"/>
                        <%}else  if (drug.eTreatmentType.equals("ACU")){%>
						<bean:message key="WriteScript.msgETreatment.Acute"/>
						<%}else  if (drug.eTreatmentType.equals("ONET")){%>
						<bean:message key="WriteScript.msgETreatment.OneTime"/>
						<%}else  if (drug.eTreatmentType.equals("PRNL")){%>
						<bean:message key="WriteScript.msgETreatment.LongTermPRN"/>
						<%}else  if (drug.eTreatmentType.equals("PRNS")){%>
						<bean:message key="WriteScript.msgETreatment.ShortTermPRN"/>
                        <%} }%>
                        <%if(drug.rxStatus != null && !drug.rxStatus.equals("null")){ %>
                        &nbsp;<bean:message key="WriteScript.msgRxStatus"/>: <%=drug.rxStatus%>
                        <%}%>
                        <!-- <% if (drug.customName==null){
						%> <a href="javascript:ShowDrugInfo('<%=drug.genericName%>');">Info</a> <%
							}
						%> -->
						</td>
						<%if(securityManager.hasWriteAccess("_rx",roleName2$,true)) {%>
						<td>
							<%	if (drug.isLocal) { %>
							<a href="javascript:void(0))" title="<bean:message key="WriteScript.msgAnnotation" />" onclick="window.open('<%= request.getContextPath() %>/annotation/annotation.jsp?display=<%=annotation_display%>&table_id=<%=drug.localDrugId%>&demo=<%=currentDemographicNo%>','anwin','width=400,height=500');">
<img src="<%= request.getContextPath() %>/images/notes.gif" alt="rxAnnotation" ></a>
									<% } %>
						</td>
						<td>
							<%	if (drug.isLocal) {	%>
                                                                      <%--  <html:form action="">
							<html:hidden property="drugList" value="<%=drug.localDrugId.toString()%>" />
							<input type="hidden" name="method" value="represcribe">
                            <html:submit style="width:100px" styleClass="btn"  onclick="javascript:reRxDrugSearch3('<%=drug.localDrugId%>');" value="Re-prescribe" />
										</html:form> --%>
                         <input type="button" value="<bean:message key="SearchDrug.msgReprescribe" />" title="<bean:message key="SearchDrug.msgReprescribe" />" style="width: 100px" class="btn" onclick="javascript:reRxDrugSearch3('<%=drug.localDrugId%>');" /><input type="button" value="<bean:message key="WriteScript.msgAddtoFavorites" />" class="btn btn-link" onclick="javascript:addFavorite2(<%=drug.localDrugId%>, '<%=StringEscapeUtils.escapeJavaScript((drug.customName!=null&&(!drug.customName.equalsIgnoreCase("null")))?drug.customName:drug.brandName)%>');" />
                            <%
								}
								else
								{
									%>
										<form action="<%=request.getContextPath()%>/oscarRx/searchDrug.do" method="post">
											<input type="hidden" name="demographicNo" value="<%=currentDemographicNo%>" />
											<%
												String searchString=drug.brandName;
												if (searchString==null) searchString=drug.customName;
												if (searchString==null) searchString=drug.genericName;
												if (searchString==null) searchString=drug.prescriptionDetails;
											%>
											<input type="hidden" name="searchString" value="<%=searchString%>" />
											<input type="submit" class="btn" value="Search to Re-prescribe" />
										</form>
									<%
								}
							%>
						</td>
						<% } %>
					</tr>
					<%
						}
					%>
    </tbody>
</table>

				</td>
			</tr>
			<tr>
				<td><br />
				<br />
				<input type="button" value="<bean:message key="oscarrx.editfavorites.backtosearchfordrug" />" class="btn" onclick="javascript:window.location.href='SearchDrug3.jsp';" /></td>
			</tr>
			<!----End new rows here-->
			<tr height="100%">
				<td></td>
			</tr>
		</table>
		</td>
	</tr>
	<tr>
		<td></td>
		<td></td>
	</tr>
	<tr>
		<td>&nbsp;</td>
	</tr>
	<tr>
		<td colspan="2"></td>
	</tr>
</table>
</div>
</body>
</html:html>