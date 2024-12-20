<%--

    Copyright (c) 2008-2012 Indivica Inc.

    This software is made available under the terms of the
    GNU General Public License, Version 2, 1991 (GPLv2).
    License details are available via "indivica.ca/gplv2"
    and "gnu.org/licenses/gpl-2.0.html".

--%>
<%--

This Page creates the fax form for eforms.

--%>
<%@page import="org.oscarehr.util.LoggedInInfo"%>
<%@ page import="java.sql.*, java.util.ArrayList, oscar.eform.data.*, oscar.SxmlMisc, org.oscarehr.common.model.Demographic, oscar.oscarDemographic.data.DemographicData,oscar.OscarProperties,org.springframework.web.context.support.WebApplicationContextUtils, org.springframework.web.context.WebApplicationContext"%>
<%@page import="org.apache.commons.lang.StringUtils"%>
<%@ taglib uri="/WEB-INF/struts-bean.tld" prefix="bean"%>
<%@ taglib uri="/WEB-INF/struts-html.tld" prefix="html"%>
<%@ taglib uri="/WEB-INF/struts-logic.tld" prefix="logic"%>
<%@ page import="org.oscarehr.common.model.*,org.oscarehr.common.dao.*"%>
<jsp:useBean id="displayServiceUtil" scope="request" class="oscar.oscarEncounter.oscarConsultationRequest.config.pageUtil.EctConDisplayServiceUtil" />
<%

	OscarProperties props = OscarProperties.getInstance();
	if (props.isEFormFaxEnabled()) {

		displayServiceUtil.estSpecialist();
		String demo = request.getParameter("demographicNo");
		DemographicData demoData = null;
		Demographic demographic = null;
		String rdohip = "";
		if (!"".equals(demo))
		{
			demoData = new oscar.oscarDemographic.data.DemographicData();
			demographic = demoData.getDemographic(LoggedInInfo.getLoggedInInfoFromSession(request), demo);
			rdohip = SxmlMisc.getXmlContent(StringUtils.trimToEmpty(demographic.getFamilyDoctor()),"rdohip");
			rdohip = SxmlMisc.getXmlContent(demographic.getFamilyDoctor(),"rdohip").trim();
		}

%>

<table style="width:100%; font-family:arial; font-size:12px;">
<tr>

	<td class="tite4" style="width:110px;"> <bean:message key='global.fax.providers'/>: </td>
	<td class="tite3" >
		<select id="otherFaxSelect" style="width:180px;">
		<%
		String rdName = "";
		String rdFaxNo = "";
		for (int i=0;i < displayServiceUtil.specIdVec.size(); i++) {
                             String  specId     = (String) displayServiceUtil.specIdVec.elementAt(i);
                             String  fName      = (String) displayServiceUtil.fNameVec.elementAt(i);
                             String  lName      = (String) displayServiceUtil.lNameVec.elementAt(i);
                             String  proLetters = (String) displayServiceUtil.proLettersVec.elementAt(i);
                             String  address    = (String) displayServiceUtil.addressVec.elementAt(i);
                             String  phone      = (String) displayServiceUtil.phoneVec.elementAt(i);
                             String  fax        = (String) displayServiceUtil.faxVec.elementAt(i);
                             String  referralNo = (displayServiceUtil.referralNoVec.size() > 0 ? displayServiceUtil.referralNoVec.get(i).trim() : "");
                             if (rdohip != null && !"".equals(rdohip) && rdohip.equals(referralNo)) {
                            	 rdName = String.format("%s, %s", lName, fName);
                            	 rdFaxNo = fax;
                             }
			if (!"".equals(fax) && fax != null) {
			%>
			<option value="<%= fax %>"> <%= String.format("%s, %s", lName, fName) %> <%= fax %> </option>
			<%
			}
		} %>
		</select>
	</td>
	<td class="tite3">
		<button class="btn" onclick="AddOtherFaxProvider(); return false;"><bean:message key='global.fax.btnaddprovider'/></button>
	</td>
</tr>
<tr>
	<td class="tite4"><bean:message key='global.fax.otherfaxno'/>: </td>
	<td class="tite3">
		<input type="text" id="otherFaxInput" style="width:100px;"></input>
		<font size="1">(xxx-xxx-xxxx)  </font>
	</td>
	<td class="tite3">
		<button class="btn" onclick="AddOtherFax(); return false;"><bean:message key='global.fax.btnaddanotherrecipient'/></button>
	</td>
</tr>
<tr>
	<td colspan=3>
		<ul id="faxRecipients">
		<%
		WebApplicationContext ctx = WebApplicationContextUtils.getRequiredWebApplicationContext(getServletContext());
        UserPropertyDAO userPropertyDAO = (UserPropertyDAO) ctx.getBean("UserPropertyDAO");
        String provider = (String) request.getSession().getAttribute("user");
        UserProperty prop = userPropertyDAO.getProp(provider, UserProperty.EFORM_REFER_FAX);
        boolean eformFaxRefer = prop != null && !"no".equals(prop.getValue());

		if (eformFaxRefer && !"".equals(rdName) && !"".equals(rdFaxNo)) {
			%>
			<li>
			<%=rdName %> <b><bean:message key='global.fax.faxno'/>: </b><%= rdFaxNo %> <a href="javascript:void(0);" onclick="removeRecipient(this)"><bean:message key='REMOVE'/></a>
				<input type="hidden" name="faxRecipients" value="<%= rdFaxNo %>" />
			</li>
			<%
		}
		%>
		</ul>
	</td>
</tr>
</table>
<% } // end if (props.isRichEFormFaxEnabled()) { %>