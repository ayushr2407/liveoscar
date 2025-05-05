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
<%@ page import="java.time.LocalDate" %>
<%@ page import="java.time.Period" %>
<%@ page import="java.util.List, java.util.Arrays" %>
<%@ page import="java.io.File" %>
<%@ page import="java.io.BufferedReader" %>
<%@ page import="java.io.FileReader" %>
<%@ page import="java.io.BufferedWriter" %>
<%@ page import="java.io.FileWriter" %>
<%@ page import="java.io.IOException" %>


<%@ taglib uri="/WEB-INF/struts-bean.tld" prefix="bean"%>
<%@ taglib uri="/WEB-INF/struts-html.tld" prefix="html"%>
<%@ taglib uri="/WEB-INF/struts-logic.tld" prefix="logic"%>
<%@ taglib uri="/WEB-INF/oscarProperties-tag.tld" prefix="oscar"%>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c"%>

<%@ page import="org.apache.commons.lang.StringEscapeUtils"%>
<%@ page import="org.apache.logging.log4j.Logger" %>

<%@ page import="java.text.SimpleDateFormat"%>
<%@ page import="java.util.Date"%>
<%@ page import="java.lang.*"%>
<%@ page import="java.util.Locale"%>

<%@ page import="org.owasp.encoder.Encode" %>

<%@ page import="org.springframework.web.context.WebApplicationContext"%>
<%@ page import="org.springframework.web.context.support.WebApplicationContextUtils"%>

<%@ page import="oscar.*"%>
<%@ page import="oscar.oscarRx.data.*"%>
<%@ page import="oscar.oscarRx.data.RxPatientData"%>
<%@ page import="oscar.oscarRx.util.RxUtil"%>
<%@ page import="oscar.oscarProvider.data.ProSignatureData"%>
<%@ page import="oscar.oscarProvider.data.ProviderData"%>
<%@ page import="oscar.log.*"%>

<%@ page import="org.oscarehr.common.dao.UserPropertyDAO"%>
<%@ page import="org.oscarehr.common.model.UserProperty"%>
<%@ page import="org.oscarehr.util.SpringUtils"%>
<%@ page import="org.oscarehr.util.LocaleUtils"%>

<!-- Classes needed for signature injection -->
<%@ page import="org.oscarehr.util.SessionConstants"%>
<%@ page import="org.oscarehr.common.dao.*"%>
<%@ page import="org.oscarehr.common.model.*"%>
<%@ page import="org.oscarehr.util.LoggedInInfo"%>
<%@ page import="org.oscarehr.util.DigitalSignatureUtils"%>
<%@ page import="org.oscarehr.ui.servlet.ImageRenderingServlet"%>

<!-- end -->

<%
        Logger logger=org.oscarehr.util.MiscUtils.getLogger();
        LoggedInInfo loggedInInfo=LoggedInInfo.getLoggedInInfoFromSession(request);
        String providerNo=loggedInInfo.getLoggedInProviderNo();
        String scriptid=request.getParameter("scriptId");
        String rx_enhance = OscarProperties.getInstance().getProperty("rx_enhance");
    WebApplicationContext ctx = WebApplicationContextUtils.getRequiredWebApplicationContext(request.getSession().getServletContext());
    UserPropertyDAO userPropertyDAO = (UserPropertyDAO) ctx.getBean("UserPropertyDAO");
    UserProperty signatureProperty = userPropertyDAO.getProp(providerNo,UserProperty.PROVIDER_CONSULT_SIGNATURE);
    boolean stampSignature = (signatureProperty != null && signatureProperty.getValue() != null && !signatureProperty.getValue().trim().isEmpty());

%>
 <%
        // Get all available signature files for the provider
        String signatureDirectory = "/usr/share/oscar-emr/OscarDocument/oscar/eform/images";
        File dir = new File(signatureDirectory);
        File[] matchingFiles = dir.listFiles((d, name) -> name.startsWith("consult_sig_" + providerNo) && name.endsWith(".png"));

        // Default to the first available signature
String selectedSignature = (matchingFiles != null && matchingFiles.length > 0) ? matchingFiles[0].getName() : "";
    %>

<%@ taglib uri="/WEB-INF/security.tld" prefix="security"%>
<%
    String roleName$ = (String)session.getAttribute("userrole") + "," + (String) session.getAttribute("user");
    boolean authed=true;
%>
<security:oscarSec roleName="<%=roleName$%>" objectName="_rx" rights="r" reverse="<%=true%>">
        <%authed=false; %>
        <%response.sendRedirect("../securityError.jsp?type=_rx");%>
</security:oscarSec>
<%
        if(!authed) {
                return;
        }
%>


<html:html locale="true">
<head>
<script type="text/javascript" src="<%= request.getContextPath() %>/js/global.js"></script>
<script type="text/javascript" src="../share/javascript/prototype.js"></script>
<script type="text/javascript" src="../share/javascript/Oscar.js"/></script>
<title><bean:message key="RxPreview.title"/></title>
<style type="text/css" media="print">
 .noprint {
         display: none;
 }
 </style>
<html:base />

<logic:notPresent name="RxSessionBean" scope="session">
        <logic:redirect href="error.html" />
</logic:notPresent>
<logic:present name="RxSessionBean" scope="session">
        <bean:define id="bean" type="oscar.oscarRx.pageUtil.RxSessionBean"
                name="RxSessionBean" scope="session" />
        <logic:equal name="bean" property="valid" value="false">
                <logic:redirect href="error.html" />
        </logic:equal>
</logic:present>

<link rel="stylesheet" type="text/css" href="styles.css">
<script type="text/javascript" language="Javascript">


    function onPrint2(method) {

            document.getElementById("preview2Form").action = "../form/createcustomedpdf?__title=Rx&__method=" + method;
            document.getElementById("preview2Form").target="_blank";
            document.getElementById("preview2Form").submit();
       return true;
    }
</script>

</head>
<body topmargin="0" leftmargin="0" vlink="#0000FF"
<% if (stampSignature) { %> onload="electronicallySign()"<% } %>
>

<%
Date rxDate = oscar.oscarRx.util.RxUtil.Today();
Locale locale = request.getLocale();
//String rePrint = request.getParameter("rePrint");
String rePrint = (String)request.getSession().getAttribute("rePrint");
//String rePrint = (String)request.getSession().getAttribute("rePrint");
oscar.oscarRx.pageUtil.RxSessionBean bean;
oscar.oscarRx.data.RxProviderData.Provider provider;
String signingProvider;
if( rePrint != null && rePrint.equalsIgnoreCase("true") ) {
    bean = (oscar.oscarRx.pageUtil.RxSessionBean)session.getAttribute("tmpBeanRX");
    signingProvider = bean.getStashItem(0).getProviderNo();
    rxDate = bean.getStashItem(0).getRxDate();
    provider = new oscar.oscarRx.data.RxProviderData().getProvider(signingProvider);
//    session.setAttribute("tmpBeanRX", null);
    String ip = request.getRemoteAddr();
    //LogAction.addLog((String) session.getAttribute("user"), LogConst.UPDATE, LogConst.CON_PRESCRIPTION, String.valueOf(bean.getDemographicNo()), ip);
}
else {
    bean = (oscar.oscarRx.pageUtil.RxSessionBean)pageContext.findAttribute("bean");

    //set Date to latest in stash
    Date tmp;

    for( int idx = 0; idx < bean.getStashSize(); ++idx ) {
        tmp = bean.getStashItem(idx).getRxDate();
        if( tmp.after(rxDate) ) {
            rxDate = tmp;
        }
    }
    rePrint = "";
    signingProvider = bean.getProviderNo();
    provider = new oscar.oscarRx.data.RxProviderData().getProvider(bean.getProviderNo());
}


oscar.oscarRx.data.RxPatientData.Patient patient = RxPatientData.getPatient(loggedInInfo, bean.getDemographicNo());
String patientAddress = patient.getAddress()==null ? "" : patient.getAddress();
String patientCity = patient.getCity()==null ? "" : patient.getCity();
String patientProvince = patient.getProvince()==null ? "" : patient.getProvince();
String patientPostal = patient.getPostal()==null ? "" : patient.getPostal();
String patientPhone = patient.getPhone()==null ? "" : patient.getPhone();
String patientHin = patient.getHin()==null ? "" : patient.getHin();
String patientGender = patient.getSex();
if ("M".equalsIgnoreCase(patientGender)) {
        patientGender = "Male";
    } else if ("F".equalsIgnoreCase(patientGender)) {
        patientGender = "Female";
    } else if ("T".equalsIgnoreCase(patientGender)) {
        patientGender = "Transgender";
    } else if ("O".equalsIgnoreCase(patientGender)) {
        patientGender = "Other";
    } else {
        patientGender = "Undefined"; // Handle the case for 'U' or any other undefined value
    }
List<org.oscarehr.common.model.Allergy> activeAllergies = Arrays.asList(patient.getActiveAllergies());

StringBuilder allergiesStr = new StringBuilder();
for (org.oscarehr.common.model.Allergy allergy : activeAllergies) {
    if (allergiesStr.length() > 0) allergiesStr.append(", ");
    allergiesStr.append(allergy.getDescription());
}

String patientAllergies = allergiesStr.length() > 0 ? allergiesStr.toString() : "NA";



oscar.oscarRx.data.RxPrescriptionData.Prescription rx = null;
int i;
ProSignatureData sig = new ProSignatureData();
boolean hasSig = sig.hasSignature(signingProvider);
String doctorName = "";
if (hasSig){
   doctorName = sig.getSignature(signingProvider);
}else{
   doctorName = (provider.getFirstName() + ' ' + provider.getSurname());
}

//doctorName = doctorName.replaceAll("\\d{6}","");
//doctorName = doctorName.replaceAll("\\-","");

OscarProperties props = OscarProperties.getInstance();
 String deliveryOption = request.getParameter("deliveryOption");
    if (deliveryOption == null) {
        deliveryOption = "";  // Set a default value if it's null
    }
String pracNo = provider.getPractitionerNo();
String strUser = (String)session.getAttribute("user");
ProviderData user = new ProviderData(strUser);
String pharmaFax = "";
String pharmaFax2 = "";
String pharmaName = "";
String pharmaTel="";
String pharmaAddress1="";
String pharmaAddress2="";
String pharmaEmail="";
String pharmaNote="";
RxPharmacyData pharmacyData = new RxPharmacyData();
PharmacyInfo pharmacy = null;
String pharmacyId = request.getParameter("pharmacyId");

if (pharmacyId != null && !"null".equalsIgnoreCase(pharmacyId)) {
    pharmacy = pharmacyData.getPharmacy(pharmacyId);
    if( pharmacy != null ) {
        pharmaName = pharmacy.getName();
                pharmaFax = pharmacy.getFax();
                pharmaFax2 = "<bean:message key='RxPreview.msgFax'/>"+": " + pharmacy.getFax();
                pharmaTel = pharmacy.getPhone1() + ((pharmacy.getPhone2()!=null && !pharmacy.getPhone2().isEmpty())? "," + pharmacy.getPhone2():"");
                pharmaAddress1 = pharmacy.getAddress();
                pharmaAddress2 = pharmacy.getCity() + ", " + pharmacy.getProvince() + " " +pharmacy.getPostalCode();
                pharmaEmail = pharmacy.getEmail();
                pharmaNote = pharmacy.getNotes();
    }
}

String patientDOBStr=RxUtil.DateToString(patient.getDOB(), "MMM d, yyyy") ;
boolean showPatientDOB=true;

//check if user prefer to show dob in print

UserProperty prop = userPropertyDAO.getProp(signingProvider, UserProperty.RX_SHOW_PATIENT_DOB);
if(prop!=null && prop.getValue().equalsIgnoreCase("yes")){
    showPatientDOB=true;
}
%>

<%

    // Prescription Number Generation Code with Continuous Increment
    String prescriptionNumber = "";
    String dateFormat = "yyMM";
    String todayStr = new SimpleDateFormat(dateFormat).format(new Date());
if (pracNo == null || pracNo.isEmpty()) {
    pracNo = "00000"; // Default value if pracNo is not provided
}
    // Define folder path to organize files by month and by doctor (pracNo)
    String folderPath = application.getRealPath("/") + "prescriptionnumber/";
    String fileName = "prescription_" + pracNo + ".txt";
    String filePath = folderPath + fileName;

    int continuousCount = 1; // Start the count at 1

    // Ensure the folder exists; create if not
    File folder = new File(folderPath);
    if (!folder.exists()) {
        boolean folderCreated = folder.mkdirs();  // Creates the directory if it doesn't exist
        System.out.println("Folder created: " + folderPath + " | Success: " + folderCreated); // Debugging: confirm folder creation
    } else {
        System.out.println("Folder already exists: " + folderPath); // Folder exists, no need to create
    }

    File counterFile = new File(filePath);

    synchronized (this) {
        // Check if the file exists and read the last count, else start from 1
        try (BufferedReader reader = counterFile.exists() ? new BufferedReader(new FileReader(counterFile)) : null) {
            if (reader != null) {
                String lastCountStr = reader.readLine();
                if (lastCountStr != null && !lastCountStr.isEmpty()) {
                    continuousCount = Integer.parseInt(lastCountStr) + 1; // Increment by 1
                }
            }
        } catch (IOException | NumberFormatException e) {
            e.printStackTrace();
        }

        // Generate the prescription number with pracNo, current month, and incremented count
        prescriptionNumber = pracNo + todayStr + String.format("%03d", continuousCount);

        // Debugging: Check the generated prescription number
        System.out.println("Generated Prescription Number: " + prescriptionNumber);
    }

%>


<%
int age = 0; // Default age to 0
if (patient.getDOB() != null) {
    LocalDate birthDate = patient.getDOB().toInstant().atZone(java.time.ZoneId.systemDefault()).toLocalDate();
    LocalDate currentDate = LocalDate.now();
    age = Period.between(birthDate, currentDate).getYears();
}
%>

<html:form action="/form/formname" styleId="preview2Form">

        <input type="hidden" name="demographic_no" value="<%=bean.getDemographicNo()%>"/>
    <%-- <p id="pharmInfo" style="float:right;">
    </p> --%>
   <table>
        <tr>
            <td>
                            <table id="pwTable" style="width: 400px; height: 650px; border:bold;" cellspacing=0 cellpadding=5 >
                                    <tr>
                                            <td valign=top style="width:40%; border-right: 1px solid #cfcfcf;" ><input type="image"
                                                    src="/clinic_data/logo/logo2.png" border="0" alt="[Submit]"
                                                    name="submit" title="Print in a half letter size paper"
                                                     width="100" onclick="<%=rePrint.equalsIgnoreCase("true") ? "javascript:return onPrint2('rePrint');" : "javascript:return onPrint2('print');" %>" style="display: block; margin-bottom: 5px;" />
                                                 <%-- img/oscarrx.gif --%>
        <!-- Date, Doctor Name, and License Number -->
        <p>Date: <b><%= oscar.oscarRx.util.RxUtil.DateToString(rxDate, "MMMM d, yyyy", locale) %></b><br /></p>
        <%-- <%= StringEscapeUtils.escapeHtml(doctorName) %><br> --%>
        <%-- License #<%= StringEscapeUtils.escapeHtml(pracNo) %><br> --%>
        <br>
        <!-- Clinic Details Block -->
        <c:choose>
            <c:when test="${empty infirmaryView_programAddress}">
                <%= Encode.forHtml(provider.getClinicName().replaceAll("\\(\\d{6}\\)", "")) %><br>
                <%= Encode.forHtml(provider.getClinicAddress()) %><br>
                <%= Encode.forHtml(provider.getClinicCity()) %>&nbsp;&nbsp;<%= provider.getClinicProvince() %> <br />
                <%= Encode.forHtml(provider.getClinicPostal()) %><br>

                <%-- <%
                    if (provider.getPractitionerNo() != null && !provider.getPractitionerNo().equals("")) {
                %>
                    <bean:message key="RxPreview.PractNo" />:<%= Encode.forHtml(provider.getPractitionerNo()) %><br> --%>
                <%

                    // Define finalPhone and finalFax within this block
                    UserProperty phoneProp = userPropertyDAO.getProp(provider.getProviderNo(), "rxPhone");
                    UserProperty faxProp = userPropertyDAO.getProp(provider.getProviderNo(), "faxnumber");

                    String finalPhone = provider.getClinicPhone();
                    String finalFax = provider.getClinicFax();

                    if (phoneProp != null && phoneProp.getValue().length() > 0) {
                        finalPhone = phoneProp.getValue();
                    }

                    if (faxProp != null && faxProp.getValue().length() > 0) {
                        finalFax = faxProp.getValue();
                    }
                %>
                <input type="hidden" name="clinicFax" value="<%= StringEscapeUtils.escapeHtml(finalFax) %>" />

                <bean:message key="RxPreview.msgTel" />: <%= Encode.forHtml(finalPhone) %><br>
                <oscar:oscarPropertiesCheck property="RXFAX" value="yes">
                    <bean:message key="RxPreview.msgFax" />: <%= Encode.forHtml(finalFax) %><br>
                </oscar:oscarPropertiesCheck>
            </c:when>

            <c:otherwise>
                <c:out value="${infirmaryView_programAddress}" escapeXml="false" /><br>

                <%
                    UserProperty phoneProp = userPropertyDAO.getProp(provider.getProviderNo(), "rxPhone");
                    UserProperty faxProp = userPropertyDAO.getProp(provider.getProviderNo(), "faxnumber");

                    String finalPhone = (String) session.getAttribute("infirmaryView_programTel");
                    String finalFax = (String) session.getAttribute("infirmaryView_programFax");

                    if (phoneProp != null && phoneProp.getValue().length() > 0) {
                        finalPhone = phoneProp.getValue();
                    }

                    if (faxProp != null && faxProp.getValue().length() > 0) {
                        finalFax = faxProp.getValue();
                    }
                %>

                <bean:message key="RxPreview.msgTel" />: <%= Encode.forHtml(finalPhone) %><br>
                <oscar:oscarPropertiesCheck property="RXFAX" value="yes">
                    <bean:message key="RxPreview.msgFax" />: <%= Encode.forHtml(finalFax) %><br>
                </oscar:oscarPropertiesCheck>
            </c:otherwise>
        </c:choose><hr>

       <!-- delivery details -->
       <p id="deliveryOption" style="font-weight: bold;"></p>



        <!-- Pharmacy Details Block -->
<%
    if (pharmacy != null) { // Check if the pharmacy details are available
%>
    <%-- <br><br> <!-- Add some spacing before the pharmacy details --> --%>

       <p style=" margin: 0;">Recipient<br /></p>
    <br><strong><%= Encode.forHtml(pharmaName) %></strong><br>
     <%= Encode.forHtml(pharmaAddress1) %>, <%= Encode.forHtml(pharmaAddress2) %><br>
    Ph. <%= Encode.forHtml(pharmaTel) %><br>
    Fax. <%= Encode.forHtml(pharmaFax) %><br>
<%
    }
%>



                                            <!--input type="hidden" name="printPageSize" value="PageSize.A6" /--> <%
                                            String clinicTitle = provider.getClinicName().replaceAll("\\(\\d{6}\\)","") + "<br>" ;
                                            clinicTitle += provider.getClinicAddress() + "<br>" ;
                                            clinicTitle += provider.getClinicCity() + "  " + provider.getClinicProvince();

String clinicPostal = provider.getClinicPostal(); // Added separate variable


                                            if (rx_enhance!=null && rx_enhance.equals("true")) {

                                                SimpleDateFormat formatter=new SimpleDateFormat("yyyy/MM/dd");
                                                        String patientDOB = patient.getDOB() == null ? "" : formatter.format(patient.getDOB());

                                                String docInfo = doctorName + "\n"+provider.getClinicName().replaceAll("\\(\\d{6}\\)","")
                                                                                                                +"<bean:message key='RxPreview.PractNo'/>"+ pracNo
                                                                                                                + "\n" + provider.getClinicAddress() + "\n"
                                                                                                                + provider.getClinicCity() + "   "
                                                                                                                + provider.getClinicPostal() + "\n"
                                                                                                                +"<bean:message key='RxPreview.msgTel'/>"+": "
                                                                                                                + provider.getClinicPhone() + "\n"
                                                                                                                +"<bean:message key='RxPreview.msgFax'/>"+": "
                                                                                                                + provider.getClinicFax();

                                                String patientInfo = patient.getFirstName() + " "
                                                                                                                + patient.getSurname() + "\n"
                                                                                                                + patientAddress + "\n"
                                                                                                                + patientCity + "   "
                                                                                                                + patientPostal + "\n"
                                                                                                                + "<bean:message key='RxPreview.msgTel'/>"+": "+ patientPhone
                                                                                                                + (patientDOB != null && !patientDOB.trim().equals("") ? "\n"
                                                                                                                +"<bean:message key='RxPreview.msgDOB'/>"+": "+ patientDOB : "")
                                                                                                                + (!patientHin.trim().equals("") ? "\n"+"<bean:message key='oscar.oscarRx.hin'/>"+": " + patientHin : "");
                                            }

                                            %> <input type="hidden" name="doctorName"
                                                    value="<%= StringEscapeUtils.escapeHtml(doctorName) %>" /> <c:choose>
                                                    <c:when test="${empty infirmaryView_programAddress}">
                                               <%
                                                        UserProperty phoneProp = userPropertyDAO.getProp(provider.getProviderNo(),"rxPhone");


                                                        String finalPhone = provider.getClinicPhone();

                                                        //if(providerPhone != null) {
                                                        //      finalPhone = providerPhone;
                                                        //}
                                                        if(phoneProp != null && phoneProp.getValue().length()>0) {

                                                                finalPhone = phoneProp.getValue();
                                                        }



                                                        request.setAttribute("phone",finalPhone);

                                                %>
<input type="hidden" name="clinicName" value="<%= StringEscapeUtils.escapeHtml(provider.getClinicName().replaceAll("\\(\\d{6}\\)", "")) %>" />
<input type="hidden" name="clinicAddress" value="<%= StringEscapeUtils.escapeHtml(provider.getClinicAddress()) %>" />
<input type="hidden" name="clinicCity" value="<%= StringEscapeUtils.escapeHtml(provider.getClinicCity()) %>" />
<input type="hidden" name="clinicProvince" value="<%= StringEscapeUtils.escapeHtml(provider.getClinicProvince()) %>" />
<input type="hidden" name="clinicPostal" value="<%= StringEscapeUtils.escapeHtml(clinicPostal) %>" />
                                                            <input type="hidden" name="clinicPhone"
                                                                    value="<%= StringEscapeUtils.escapeHtml(finalPhone) %>" />
                                                            <input type="hidden" id="finalFax" name="clinicFax"
                                                                    value="" />
                                                    </c:when>
                                                    <c:otherwise>
                                               <%
                                                        UserProperty phoneProp = userPropertyDAO.getProp(provider.getProviderNo(),"rxPhone");
                                                        UserProperty faxProp = userPropertyDAO.getProp(provider.getProviderNo(),"faxnumber");

                                                        String finalPhone = (String)session.getAttribute("infirmaryView_programTel");
                                                        String finalFax =(String)session.getAttribute("infirmaryView_programFax");

                                                        //if(providerPhone != null) {
                                                        //      finalPhone = providerPhone;
                                                        //}
                                                        if(phoneProp != null && phoneProp.getValue().length()>0) {

                                                                finalPhone = phoneProp.getValue();
                                                        }

                                                        if(faxProp != null && faxProp.getValue().length()>0) {

                                                                finalFax = faxProp.getValue();
                                                        }

                                                        request.setAttribute("phone",finalPhone);

                                                %>
                                                            <input type="hidden" name="clinicName"
                                                                    value="<c:out value="${infirmaryView_programAddress}"/>" />
                                                            <input type="hidden" name="clinicPhone"
                                                                    value="<%=finalPhone%>" />
                                                            <input type="hidden" id="finalFax" name="clinicFax"
                                                                    value="" />
                                                    </c:otherwise>
                                            </c:choose>

                                                            <input type="hidden" name="patientName"
                                                    value="<%= StringEscapeUtils.escapeHtml(patient.getFirstName())+ " " +StringEscapeUtils.escapeHtml(patient.getSurname()) %>" />
                                            <input type="hidden" name="patientDOB" value="<%= StringEscapeUtils.escapeHtml(patientDOBStr) %>" />
                                            <input type="hidden" name="patientGender" value="<%= StringEscapeUtils.escapeHtml(patientGender) %>" />
                                            <input type="hidden" name="patientAllergies" value="<%= StringEscapeUtils.escapeHtml(allergiesStr.toString()) %>" />
                                            <input type="hidden" name="pharmaFax" value="<%=pharmaFax%>" />
                                            <input type="hidden" name="pharmaName" value="<%=pharmaName%>" />
                                            <input type="hidden" name="pharmaTel" value="<%=pharmaTel%>" />
                                            <input type="hidden" name="pharmaAddress1" value="<%=pharmaAddress1%>" />
                                            <input type="hidden" name="pharmaAddress2" value="<%=pharmaAddress2%>" />
                                            <input type="hidden" name="pharmaEmail" value="<%=pharmaEmail%>" />
                                            <input type="hidden" name="pharmaNote" value="<%=pharmaNote%>" />
                                            <input type="hidden" name="pharmaShow" id="pharmaShow" value="false" />
                                            <input type="hidden" name="pracNo" value="<%= StringEscapeUtils.escapeHtml(pracNo) %>" />
                                            <input type="hidden" name="showPatientDOB" value="<%=showPatientDOB%>"/>
                                            <input type="hidden" name="pdfId" id="pdfId" value="" />
                                            <input type="hidden" name="deliveryOption" value="<%= StringEscapeUtils.escapeHtml(deliveryOption) %>" />
                                            <input type="hidden" name="patientAddress" value="<%= StringEscapeUtils.escapeHtml(patientAddress) %>" />
                                            <%
                                                                                        int check = (patientCity.trim().length()>0 ? 1 : 0) | (patientProvince.trim().length()>0 ? 2 : 0);
                                                                                        String patientCityPostal = String.format("%s%s%s %s",
                                                                                        patientCity,
                                                                                        check == 3 ? ", " : check == 2 ? "" : " ",
                                                                                        patientProvince,
                                                                                        patientPostal);

                                                                                        String ptChartNo = "";
                                                                                        if(props.getProperty("showRxChartNo", "").equalsIgnoreCase("true")) {
                                                                                                ptChartNo = patient.getChartNo()==null ? "" : patient.getChartNo();
                                                                                        }
                                            %>
                                            <input type="hidden" name="patientCityPostal" value="<%= StringEscapeUtils.escapeHtml(patientCityPostal)%>" />
                                            <input type="hidden" name="patientHIN" value="<%= StringEscapeUtils.escapeHtml(patientHin) %>" />
                                            <input type="hidden" name="patientChartNo" value="<%=StringEscapeUtils.escapeHtml(ptChartNo)%>" />
                                            <input type="hidden" name="patientPhone"
                                                    value="<bean:message key="RxPreview.msgTel"/><%=StringEscapeUtils.escapeHtml(patientPhone) %>" />

                                            <input type="hidden" name="rxDate"
                                                    value="<%= StringEscapeUtils.escapeHtml(oscar.oscarRx.util.RxUtil.DateToString(rxDate, "MMMM d, yyyy")) %>" />
                                            <input type="hidden" name="sigDoctorName" value="<%= StringEscapeUtils.escapeHtml(doctorName) %>" /> <!--img src="img/rx.gif" border="0"-->
                                            </td>
                                            <td  valign=top style="width:60%; position: relative;">
                                                 <table width=100% cellspacing=0 cellpadding=5>
                                                    <tr>
                                                            <td align=left valign=top>
                                                            <div style="position: absolute; top: 10px; right: 10px; font-size: 10px">
<%
    String rawBatchId = request.getParameter("prescriptionBatchId");
    String cleanBatchId = (rawBatchId != null && rawBatchId.startsWith("batch_")) ? rawBatchId.replace("batch_", "") : rawBatchId;
%>
<input type="hidden" name="prescriptionBatchId" value="<%= cleanBatchId %>">
Order <strong>#<%= cleanBatchId %></strong>
                                                             </div>
                                                            <h3>Patient Details</h3>
                                                                <%= Encode.forHtml(patient.getFirstName()) %> <%= Encode.forHtml(patient.getSurname()) %> <br>
                                                                (PHN <% if(!props.getProperty("showRxHin", "").equals("false")) { %>
                                                           <%= Encode.forHtml(patientHin) %> <% } %>) <br>
<%= Encode.forHtml(patientGender) %> / <%if(showPatientDOB){%>&nbsp;&nbsp;<%= StringEscapeUtils.escapeHtml(patientDOBStr) %> <%}%> / <%= age %> years old<br>
                                                            <%= Encode.forHtml(patientAddress) %><br>
                                                            <%= Encode.forHtml(patientCityPostal) %><br>
                                                            Phone (H): <%= Encode.forHtml(patientPhone) %><br>

                                                                <% if(props.getProperty("showRxChartNo", "").equalsIgnoreCase("true")) { %>
                                                            <bean:message key="oscar.oscarRx.chartNo" /><%= Encode.forHtml(ptChartNo)%><% } %>
                                                            <br>
                                                            <p>Drug Allergies<br /><strong><%= patientAllergies %></strong></p>
                                                            <hr>

<%
    String strRx = "";
    StringBuffer strRxNoNewLines = new StringBuffer();

    for (i = 0; i < bean.getStashSize(); i++) {
        rx = bean.getStashItem(i);
        String fullOutLine = rx.getFullOutLine();
        System.out.println("Prescription " + (i + 1) + ": " + fullOutLine);

        if (fullOutLine == null || fullOutLine.length() <= 6) {
            logger.error("Drug full outline was null or too short");
            fullOutLine = "<span style=\"color:red;font-size:16;font-weight:bold\">An error occurred, please write a new prescription.</span><br />" + fullOutLine;
        } else {
            // Variables for structured prescription data
            String medicationName = "";
            String instructions = "";
            String specialInstructions = "";
            String quantity = "";
            String repeats = "";
            String startDate = "";
            String endDate_p = "";
            String duration = "";
            String patientCompliance = "";
            String frequency = "";
            String longTerm = "";
            String drugForm = "";
            String route = "";


            // Use regex patterns to capture specific fields in fullOutLine
            java.util.regex.Pattern qtyPattern = java.util.regex.Pattern.compile("Qty:\\s*(\\S+)");
            java.util.regex.Pattern repeatsPattern = java.util.regex.Pattern.compile("Repeats:\\s*(\\S+);?");
            java.util.regex.Pattern startDatePattern = java.util.regex.Pattern.compile("StartDate:(\\d{4}-\\d{2}-\\d{2});?");
            java.util.regex.Pattern endDatePattern = java.util.regex.Pattern.compile("EndDate:(\\d{4}-\\d{2}-\\d{2});?");
            java.util.regex.Pattern durationPattern = java.util.regex.Pattern.compile("Duration:(\\d+\\s*Days);?");
            java.util.regex.Pattern compliancePattern = java.util.regex.Pattern.compile("PatientCompliance:(\\S+);?");
            java.util.regex.Pattern frequencyPattern = java.util.regex.Pattern.compile("\\(Frequency:(\\S+)\\);?");
            java.util.regex.Pattern longTermPattern = java.util.regex.Pattern.compile("LongTerm:(\\S+);?");
            java.util.regex.Pattern formPattern = java.util.regex.Pattern.compile("Form:\\s*([^;]+);?");
            java.util.regex.Pattern routePattern = java.util.regex.Pattern.compile("Route:\\s*([^;]+);?");


            java.util.regex.Matcher qtyMatcher = qtyPattern.matcher(fullOutLine);
            java.util.regex.Matcher repeatsMatcher = repeatsPattern.matcher(fullOutLine);
            java.util.regex.Matcher startDateMatcher = startDatePattern.matcher(fullOutLine);
            java.util.regex.Matcher endDateMatcher = endDatePattern.matcher(fullOutLine);
            java.util.regex.Matcher durationMatcher = durationPattern.matcher(fullOutLine);
            java.util.regex.Matcher complianceMatcher = compliancePattern.matcher(fullOutLine);
            java.util.regex.Matcher frequencyMatcher = frequencyPattern.matcher(fullOutLine);
            java.util.regex.Matcher longTermMatcher = longTermPattern.matcher(fullOutLine);
            java.util.regex.Matcher formMatcher = formPattern.matcher(fullOutLine);
            java.util.regex.Matcher routeMatcher = routePattern.matcher(fullOutLine);


            // Extract Quantity
            if (qtyMatcher.find()) {
                quantity = qtyMatcher.group(1);
            }

            // Extract Repeats
            if (repeatsMatcher.find()) {
                repeats = repeatsMatcher.group(1);
            }
            if (formMatcher.find()) {
                drugForm = formMatcher.group(1);
            }
            if (routeMatcher.find()) {
                route = routeMatcher.group(1).trim();
            }

            // Extract Start Date
            SimpleDateFormat inputDateFormat = new SimpleDateFormat("yyyy-MM-dd");
            SimpleDateFormat outputDateFormat = new SimpleDateFormat("MMM dd, yyyy");

            // Format Start Date
            if (startDateMatcher.find()) {
                String extractedStartDate = startDateMatcher.group(1);
                try {
                    Date date = inputDateFormat.parse(extractedStartDate);
                    startDate = outputDateFormat.format(date);
                } catch (Exception e) {
                    System.err.println("Failed to parse start date: " + e.getMessage());
                    startDate = extractedStartDate; // Fallback to original if parsing fails
                }
            }

            // Format End Date
            if (endDateMatcher.find()) {
                String extractedEndDate = endDateMatcher.group(1);
                try {
                    Date date = inputDateFormat.parse(extractedEndDate);
                    endDate_p = outputDateFormat.format(date);
                } catch (Exception e) {
                    System.err.println("Failed to parse end date: " + e.getMessage());
                    endDate_p = extractedEndDate; // Fallback to original if parsing fails
                }
            }

            // Extract Duration (exclude if "0 Days")
            if (durationMatcher.find()) {
                String extractedDuration = durationMatcher.group(1);
                if (!extractedDuration.equals("0 Days")) {
                    duration = extractedDuration;
                }
            }

            // Extract Patient Compliance
            if (complianceMatcher.find()) {
                patientCompliance = complianceMatcher.group(1);
            }

            // Extract Frequency (if applicable to Patient Compliance)
            if (frequencyMatcher.find() && "no".equals(patientCompliance)) {
                frequency = frequencyMatcher.group(1);
            }

            // Extract Long Term
            if (longTermMatcher.find()) {
                longTerm = longTermMatcher.group(1);
            }

            // Clean the fullOutLine for clearer parsing (remove fields already extracted)
            String cleanedLine = fullOutLine
                    .replaceAll("Qty:\\s*\\S+;?", "") // Remove "Qty:"
                    .replaceAll("Repeats:\\s*\\S+;?", "") // Remove "Repeats:"
                    .replaceAll("StartDate:\\d{4}-\\d{2}-\\d{2};?", "") // Remove "StartDate:"
                    .replaceAll("EndDate:\\d{4}-\\d{2}-\\d{2};?", "") // Remove "EndDate:"
                    .replaceAll("Duration:\\d+\\s*Days;?", "") // Remove "Duration:"
                    .replaceAll("PatientCompliance:\\S+\\s*(\\(Frequency:\\S+\\))?;?", "") // Remove "PatientCompliance:" and "Frequency:"
                    .replaceAll("LongTerm:\\S+;?", "") // Remove "LongTerm:"
                    .replaceAll("Form:\\s*[^;]+;?", "") 
                    .replaceAll("Route:\\s*[^;]+;?", "")
                    .trim();

            // Separate Medication Name, Instructions, and Special Instructions
            int firstSemicolon = cleanedLine.indexOf(";"); // First ';' indicates end of Medication Name
            if (firstSemicolon > -1) {
                medicationName = cleanedLine.substring(0, firstSemicolon).trim(); // Text before first ';' as Medication Name

                // Find second semicolon for separating instructions and special instructions
                String remainingLine = cleanedLine.substring(firstSemicolon + 1).trim();
                int secondSemicolon = remainingLine.indexOf(";");
                if (secondSemicolon > -1) {
                    instructions = remainingLine.substring(0, secondSemicolon).trim(); // Between first and second ';' is Instructions
                    specialInstructions = remainingLine.substring(secondSemicolon + 1).trim(); // Text after second ';' as Special Instructions
                } else {
                    instructions = remainingLine.trim(); // If no second ';', treat remaining as Instructions
                }
            } else {
                medicationName = cleanedLine; // If no ';', treat entire line as Medication Name
            }

            // Remove any trailing semicolons from instructions and special instructions
            instructions = instructions.replaceAll(";$", "");
            specialInstructions = specialInstructions.replaceAll(";$", "");

            // Append the raw fullOutLine for hidden input values
            strRx += fullOutLine + ";;";
            strRxNoNewLines.append(fullOutLine.replaceAll(";", " ") + "\n");
%>
           <div class="prescription-details">
            <p><strong><%= medicationName %><% if (!route.isEmpty()) { %> (<%= route %>)<% } %></strong></p>
    <%
        // Append frequency dispense to instructions when compliance is "no"
        String modifiedInstructions = instructions;
        if ("no".equals(patientCompliance) && !frequency.isEmpty()) {
            modifiedInstructions += " (" + frequency.substring(0, 1).toUpperCase() + frequency.substring(1).toLowerCase() + " Dispense)";
        }
    %>
    <%-- <% if (!modifiedInstructions.isEmpty()) { %>
        <p style="margin: 2px 0; font-size: 7.5pt;"><%= modifiedInstructions %></p>

    <% } %> --%>
    <% if (!specialInstructions.isEmpty()) { %>
        <p style="margin: 2px 0; font-size: 7.5pt;"><%= specialInstructions %></p>

    <% } %>
    <table style="width: 100%;">

     <% if (!startDate.isEmpty() || !endDate_p.isEmpty() || !duration.isEmpty()) { %>
            <tr>
                <td colspan="2" style="text-align: left;">
                    <%
                        String formattedDateRange = "";
                        if (!startDate.isEmpty() && !endDate_p.isEmpty()) {
                            formattedDateRange = startDate + " - " + endDate_p;
                        } else if (!startDate.isEmpty()) {
                            formattedDateRange = startDate;
                        } else if (!endDate_p.isEmpty()) {
                            formattedDateRange = endDate_p;
                        }

                        if (!duration.isEmpty()) {
                            formattedDateRange += " (" + duration + ")";
                        }
                    %>
                    <%= formattedDateRange %>
                </td>
            </tr>
        <% } %>
        <% if (!longTerm.isEmpty()) { %>
            <tr>
                <td colspan="2" style="text-align: left;">
                    Long Term: <%= longTerm %>
                </td>
            </tr>
        <% } %>
        <tr>
            <% if (!quantity.isEmpty()) { %>
                <!-- Quantity -->
                <td style="width: 50%; text-align: left;">
                    Quantity: <%= quantity %>
                    <% if (!drugForm.isEmpty()) { %>
                        (<%= drugForm %>)
                    <% } %>
                </td>

            <% } %>
            <% if (!repeats.isEmpty()) { %>
                <!-- Repeats -->
                <td style="width: 50%; text-align: left;">
                    Repeats: <%= repeats.replaceAll(";$", "") %>
                </td>

                    <% } %>
                </tr>
                    </table>
        </div>
        <% if (i < bean.getStashSize() - 1) { %>
            <hr>
        <% } %>

        <%
    // Strip trailing semicolon before storing in hidden field
    repeats = repeats.replaceAll(";+\\s*$", "");
%>

            <!-- Hidden fields for each prescription entry -->
            <input type="hidden" name="medicationName_<%=i%>" value="<%= StringEscapeUtils.escapeHtml(medicationName) %>" />
            <input type="hidden" name="instructions_<%=i%>" value="<%= StringEscapeUtils.escapeHtml(instructions) %>" />
            <input type="hidden" name="specialInstructions_<%=i%>" value="<%= StringEscapeUtils.escapeHtml(specialInstructions) %>" />
            <input type="hidden" name="quantity_<%=i%>" value="<%= StringEscapeUtils.escapeHtml(quantity) %>" />
            <input type="hidden" name="repeats_<%=i%>" value="<%= StringEscapeUtils.escapeHtml(repeats) %>" />
            <input type="hidden" name="startDate_<%=i%>" value="<%= StringEscapeUtils.escapeHtml(startDate) %>" />
            <input type="hidden" name="endDate_p_<%=i%>" value="<%= StringEscapeUtils.escapeHtml(endDate_p) %>" />
            <input type="hidden" name="duration_<%=i%>" value="<%= StringEscapeUtils.escapeHtml(duration) %>" />
            <input type="hidden" name="patientCompliance_<%=i%>" value="<%= StringEscapeUtils.escapeHtml(patientCompliance) %>" />
            <input type="hidden" name="frequency_<%=i%>" value="<%= StringEscapeUtils.escapeHtml(frequency) %>" />
            <input type="hidden" name="longTerm_<%=i%>" value="<%= StringEscapeUtils.escapeHtml(longTerm) %>" />
            <input type="hidden" name="form_<%=i%>" value="<%= StringEscapeUtils.escapeHtml(drugForm) %>" />
            <input type="hidden" name="route_<%=i%>" value="<%= StringEscapeUtils.escapeHtml(route) %>" />


<%
        }
    }
%>
<!-- Hidden inputs to preserve prescription details -->
<input type="hidden" name="rx" value="<%= StringEscapeUtils.escapeHtml(strRx.replaceAll(";", "\\\n")) %>" />
<input type="hidden" name="rx_no_newlines" value="<%= strRxNoNewLines.toString() %>" />
<input type="hidden" name="prescriptionCount" value="<%= bean.getStashSize() %>" />


                                                            <input type="hidden" name="additNotes" value=""/>
<br />
<p id="additNotes"></p>

<br><br>
    <div style="position: absolute; bottom: 0; left: 0; right: 0; text-align: center; background-color: #ffffff; padding: 10px;">
<%

String signatureRequestId = null;

String imageUrl=null;

String startimageUrl=null;

String statusUrl=null;


signatureRequestId=loggedInInfo.getLoggedInProviderNo();

imageUrl=request.getContextPath()+"/imageRenderingServlet?source="+ImageRenderingServlet.Source.signature_preview.name()+"&"+DigitalSignatureUtils.SIGNATURE_REQUEST_ID_KEY+"="+signatureRequestId;

startimageUrl=request.getContextPath()+"/images/1x1.gif";

statusUrl = request.getContextPath()+"/PMmodule/ClientManager/check_signature_status.jsp?" + DigitalSignatureUtils.SIGNATURE_REQUEST_ID_KEY+"="+signatureRequestId;

String imgFile = "";
                                                                    String signatureMessage="";


                                                                    if (stampSignature) {

                                                                        String eAuth = LocaleUtils.getMessage(locale,"RxPreview.eAuth") != "RxPreview.eAuth" ? LocaleUtils.getMessage(locale,"RxPreview.eAuth") : "Authorized Electronically by";
                                                                        String at = LocaleUtils.getMessage(locale,"RxPreview.at") != "RxPreview.at" ? LocaleUtils.getMessage(locale,"RxPreview.at") : "at";

    signatureMessage = eAuth + " " + Encode.forHtml(doctorName.replace("Dr. ", "").replaceAll("\\d{5}",""))

                                                        + " " + at + " " + oscar.oscarRx.util.RxUtil.DateToString(new Date(), "HH:mma",locale);


    signatureRequestId=loggedInInfo.getLoggedInProviderNo();
                                                                                                                                                                                                                                                imageUrl=request.getContextPath()+"/eform/displayImage.do?imagefile="+signatureProperty.getValue();

    startimageUrl=request.getContextPath() + "/images/1x1.gif";

    statusUrl = request.getContextPath()+"/PMmodule/ClientManager/check_signature_status.jsp?" + DigitalSignatureUtils.SIGNATURE_REQUEST_ID_KEY+"="+signatureRequestId;

} else {

    signatureRequestId = loggedInInfo.getLoggedInProviderNo();
                                                                                                                                            imageUrl = request.getContextPath() + "/eform/displayImage.do?imagefile=" + selectedSignature;
                                                                                                                           startimageUrl = request.getContextPath() + "/images/1x1.gif";

    statusUrl = request.getContextPath() + "/PMmodule/ClientManager/check_signature_status.jsp?" + DigitalSignatureUtils.SIGNATURE_REQUEST_ID_KEY + "=" + signatureRequestId;

}


%>

<!-- Display selected signature -->
<img id="signature" style="width:150px; height:auto"
     src="<%= request.getContextPath() %>/eform/displayImage.do?imagefile=<%= selectedSignature %>"
     alt="digital_signature" />

     <!-- Change Signature Button -->
<button type="button" id="changeSignatureBtn" onclick="changeSignature()">Change Signature</button>

<!-- Hidden input to store the selected signature file -->

<%-- <%
    System.out.println("DEBUG (JSP): Selected Signature File Before Submitting to Servlet = " + selectedSignature);
%> --%>
<input type="hidden" name="imgFile" id="imgFile" value="<%= selectedSignature %>" />
<input type="hidden" id="electronicSignature" name="electronicSignature" value=""/>


<input type="hidden" id="contextPath" value="<%= request.getContextPath() %>" />

<!-- JavaScript for Random Signature Selection -->
<script>
    // List of available signature files
    var availableSignatures = [
        <% 
            if (matchingFiles != null && matchingFiles.length > 0) {
                for (int j = 0; j < matchingFiles.length; j++) { // Changed 'i' to 'j'
                    out.print("\"" + matchingFiles[j].getName() + "\"");
                    if (j < matchingFiles.length - 1) out.print(", ");
                }
            }
        %>
    ];

    function changeSignature() {
        if (availableSignatures.length === 0) {
            console.warn("No available signatures to select from.");
            return;
        }

        // Select a random signature
        var randomIndex = Math.floor(Math.random() * availableSignatures.length);
        var selectedSignature = availableSignatures[randomIndex];

        // Update the signature image
        var signatureImg = document.getElementById("signature");
        var contextPath = "<%= request.getContextPath() %>";
        signatureImg.src = contextPath + "/eform/displayImage.do?imagefile=" + encodeURIComponent(selectedSignature);

        // Update the hidden input field to reflect the selected signature
        document.getElementById("imgFile").value = selectedSignature;

        console.log("Changed Signature to: " + selectedSignature);
    }
</script>

<script type="text/javascript">

        var POLL_TIME=2500;

        var counter=0;


        function refreshImage()

                {

                counter=counter+1;

                var img=document.getElementById("signature");

                img.src='<%=imageUrl%>&rand='+counter;


                var request = dojo.io.bind({

                            url: '<%=statusUrl%>',

                            method: "post",

                            mimetype: "text/html",

                            load: function(type, data, evt){

                                var x = data.trim();

                                    //document.getElementById('signature_status').value=x;

                            }

                        });


                }

                </script>


<% if (props.getProperty("signature_tablet", "").equals("yes")) { %>
                                                            <input type="button" value=<bean:message key="RxPreview.digitallySign"/> class="noprint" onclick="setInterval('refreshImage()', POLL_TIME); document.location='<%=request.getContextPath()%>/signature_pad/topaz_signature_pad.jnlp.jsp?<%=DigitalSignatureUtils.SIGNATURE_REQUEST_ID_KEY%>=<%=signatureRequestId%>'"  />
                                                                <% }
                                                                    if (stampSignature) { %>
                                                                            <!--<input type="button" value=<bean:message key="RxPreview.digitallySign"/> class="noprint" onclick="electronicallySign();"  />-->
                                                                    <script type="text/javascript">
                                                                    function electronicallySign() {
    // console.log("DEBUG (JS): Running electronicallySign() function...");

    var electronicSignatureField = document.getElementById('electronicSignature');
    var signatureLine = document.getElementById('sline');
    var signatureImg = document.getElementById("signature");
    var imgFileInput = document.getElementById("imgFile");

    var selectedSignature = imgFileInput.value;

    // console.log("DEBUG (JS): Static signature (imgFile) before signing: ", selectedSignature);

    if (!selectedSignature) {
        console.warn("WARNING: No static signature is selected!");
    }

    // if (electronicSignatureField) {
    //     electronicSignatureField.value = "<%=signatureMessage%>";
    //     console.log("DEBUG (JS): electronicSignature field updated.");
    // }
    if (electronicSignatureField) {
    var canvas = document.getElementById("signatureCanvas");  // Get the drawing canvas

    if (canvas && canvas.toDataURL) {
        var drawnSignature = canvas.toDataURL("image/png");  // Convert canvas drawing to Base64
        electronicSignatureField.value = drawnSignature;  // Store drawn signature in hidden input

        // console.log("DEBUG (JS): Drawn signature captured and stored.");
    } else {
        // console.warn("WARNING: No drawn signature found, keeping static signature.");
        electronicSignatureField.value = "";  // Ensure the field is cleared if no drawn signature
    }
}


    if (signatureLine) {
        signatureLine.textContent = "<%=signatureMessage%>";
        // console.log("DEBUG (JS): Signature line updated.");
    }

    if (signatureImg) {
        var newImageUrl = '<%=imageUrl%>?t=' + new Date().getTime(); // Cache-buster
        // console.log("DEBUG (JS): Updating signature image src to: " + newImageUrl);
        signatureImg.src = newImageUrl;
    } else {
        console.error("ERROR: Signature image element not found!");
    }

    if (imgFileInput) {
        imgFileInput.value = selectedSignature;  // Ensure it remains the same
        // console.log("DEBUG (JS): imgFile input value confirmed: " + imgFileInput.value);
    } else {
        console.error("ERROR: imgFile input element not found!");
    }

    <% if (OscarProperties.getInstance().isRxFaxEnabled() && pharmacy != null) { %>
        var hasFaxNumber = <%= pharmacy != null && pharmacy.getFax().trim().length() > 0 ? "true" : "false" %>;
        var faxButton = parent.document.getElementById("faxButton");

        if (faxButton) {
            faxButton.disabled = !hasFaxNumber;
            faxButton.className = "btn btn-primary";
            console.log("DEBUG (JS): Fax button updated.");
        } else {
            console.error("ERROR: Fax button element not found!");
        }
    <% } %>

    // Ensure signature refresh happens after updates
    setTimeout(function() {
        console.log("DEBUG (JS): Running refreshImage()...");
        refreshImage();
    }, 500);
}

    //                                                             function electronicallySign() {
    //     console.log("DEBUG: Running electronicallySign() function...");

    //     var electronicSignatureField = document.getElementById('electronicSignature');
    //     var signatureLine = document.getElementById('sline');
    //     var signatureImg = document.getElementById("signature");
    //     var imgFileInput = document.getElementById("imgFile");

    //     if (electronicSignatureField) {
    //         electronicSignatureField.value = "<%=signatureMessage%>";
    //         console.log("DEBUG: electronicSignature field updated.");
    //     }

    //     if (signatureLine) {
    //         signatureLine.textContent = "<%=signatureMessage%>";
    //         console.log("DEBUG: Signature line updated.");
    //     }

    //     if (signatureImg) {
    //         var newImageUrl = '<%=imageUrl%>?t=' + new Date().getTime(); // Cache-buster
    //         console.log("DEBUG: Updating signature image src to: " + newImageUrl);
    //         signatureImg.src = newImageUrl;
    //     } else {
    //         console.error("ERROR: Signature image element not found!");
    //     }

    //     if (imgFileInput) {
    //         imgFileInput.value = '<%=imgFile%>';
    //         console.log("DEBUG: Image file input updated: " + imgFileInput.value);
    //     } else {
    //         console.error("ERROR: imgFile input element not found!");
    //     }

    //     <% if (OscarProperties.getInstance().isRxFaxEnabled() && pharmacy != null) { %>
    //         var hasFaxNumber = <%= pharmacy != null && pharmacy.getFax().trim().length() > 0 ? "true" : "false" %>;
    //         var faxButton = parent.document.getElementById("faxButton");

    //         if (faxButton) {
    //             faxButton.disabled = !hasFaxNumber;
    //             faxButton.className = "btn btn-primary";
    //             console.log("DEBUG: Fax button updated.");
    //         } else {
    //             console.error("ERROR: Fax button element not found!");
    //         }
    //     <% } %>

    //     // Ensure signature refresh happens after updates
    //     setTimeout(function() {
    //         console.log("DEBUG: Running refreshImage()...");
    //         refreshImage();
    //     }, 500);
    // }
                                                                                // function electronicallySign() {
                                                                                //      document.getElementById('electronicSignature').value = "<%=signatureMessage%>";
                                                                                //      document.getElementById('sline').textContent = "<%=signatureMessage%>";
                                                                        //     var img=document.getElementById("signature");

        //      img.src='<%=imageUrl%>';
                                                                        //     var imgF=document.getElementById("imgFile");

        //      imgF.value='<%=imgFile%>';
                                                                                    // <% if (OscarProperties.getInstance().isRxFaxEnabled() && pharmacy != null) { %>
                                                                                    //  var hasFaxNumber = <%= pharmacy != null && pharmacy.getFax().trim().length() > 0 ? "true" : "false" %>;
                                                                                    //  parent.document.getElementById("faxButton").disabled = !hasFaxNumber;
                                                                        //     parent.document.getElementById("faxButton").className="btn btn-primary";


                                                                                // <% } %>
                                                                        //  }

                                                                            </script>
                                                                                                                       <% } else {
                                                                                                                                                                                                                                            if (stampSignature && OscarProperties.getInstance().isRxFaxEnabled() && pharmacy != null) { %>

<script type="text/javascript">
                                                                        var hasFaxNumber = <%= pharmacy != null && pharmacy.getFax().trim().length() > 0 ? "true" : "false" %>;
                                                                        parent.document.getElementById("faxButton").disabled = !hasFaxNumber;
                                                                        //parent.document.getElementById("faxPasteButton").disabled = !hasFaxNumber;

</script>
                                                                                                                                                                                                                                            <% } %>
                                                                <% } %>
<p><%= doctorName%> <% if ( pracNo != null && ! pracNo.equals("") && !pracNo.equalsIgnoreCase("null")) { %>
                                                                <br /><bean:message key="RxPreview.PractNo"/> <%= pracNo%> <% } %></p>
                                                                </div>
                                                            </td>


                                                    </tr>
                                                 </table>
                                            </td>
                                    </tr>





                                                    <% if ( oscar.OscarProperties.getInstance().getProperty("RX_FOOTER") != null ){ out.write(oscar.OscarProperties.getInstance().getProperty("RX_FOOTER")); }%>


                            </table>
                        </td>
                </tr>
        </table>
</html:form>
</body>
</html:html>
