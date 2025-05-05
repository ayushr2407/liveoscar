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
<%@ taglib uri="/WEB-INF/oscar-tag.tld" prefix="oscar" %>
<%@ taglib uri="/WEB-INF/struts-bean.tld" prefix="bean" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/core" prefix="c" %>
<%@page import="oscar.oscarRx.data.RxDrugData,java.util.*" %>
<%@page import="java.text.SimpleDateFormat" %>
<%@page import="java.util.Calendar" %>
<%@page import="oscar.oscarRx.data.*" %>
<%@page import="oscar.oscarRx.util.*" %>
<%@page import="oscar.OscarProperties"%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Prescription Form</title>

    <!-- Include Bootstrap CSS -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">

</head>
<body>

<c:set var="ctx" value="${pageContext.request.contextPath}" />

<%@ taglib uri="/WEB-INF/security.tld" prefix="security"%>

<%
    // Extract the technical reasons passed from Action.java
    List<String> technicalReasons = (List<String>) request.getAttribute("technicalReasons");
    if (technicalReasons == null) {
        technicalReasons = new ArrayList<>();
    }

// Extract the SIG map passed from Action.java
    Map<String, List<String>> sigMap = (Map<String, List<String>>) request.getAttribute("sigMap");
    if (sigMap == null) {
        sigMap = new HashMap<>();
    }

 // Convert the sigMap to JSON manually
    org.json.JSONObject sigMapJson = new org.json.JSONObject();
    for (Map.Entry<String, List<String>> entry : sigMap.entrySet()) {
        org.json.JSONArray sigArray = new org.json.JSONArray(entry.getValue());
        sigMapJson.put(entry.getKey(), sigArray);
    }

%>

<%
String rand = "";
%>


<%
    String roleName$ = (String)session.getAttribute("userrole") + "," + (String) session.getAttribute("user");
    boolean authed=true;
%>
<security:oscarSec roleName="<%=roleName$%>" objectName="_rx" rights="w" reverse="<%=true%>">
	<%authed=false; %>
	<%response.sendRedirect("../securityError.jsp?type=_rx");%>
</security:oscarSec>
<%
	if(!authed) {
		return;
	}
%>

  <% 
   String startDate = (String) request.getAttribute("startDate");
   String duration = (String) request.getAttribute("duration");
   String endDate = (String) request.getAttribute("endDate");
   if (startDate == null) startDate = ""; // Default empty value
   if (duration == null) duration = "";   // Default empty value
   if (endDate == null) endDate = "";     // Default empty value
%>

  
    <%

List<RxPrescriptionData.Prescription> listRxDrugs=(List)request.getAttribute("listRxDrugs");
oscar.oscarRx.pageUtil.RxSessionBean bean = (oscar.oscarRx.pageUtil.RxSessionBean)request.getSession().getAttribute("RxSessionBean");

if(listRxDrugs!=null){
            String specStr=RxUtil.getSpecialInstructions();

  for(RxPrescriptionData.Prescription rx : listRxDrugs ){
        rand            = Long.toString(rx.getRandomId());
         String instructions    = rx.getSpecial();
         String specialInstruction=rx.getSpecialInstruction();
         String startDateStr = (rx.getStartDate() != null) ? RxUtil.DateToString(rx.getStartDate(), "yyyy-MM-dd") : "";
         String endDatestr = (rx.getEndDate() != null) ? RxUtil.DateToString(rx.getEndDate(), "yyyy-MM-dd") : "";
         String writtenDate     = RxUtil.DateToString(rx.getWrittenDate(), "yyyy-MM-dd");
         String lastRefillDate  = RxUtil.DateToString(rx.getLastRefillDate(), "yyyy-MM-dd");
         int gcn=rx.getGCN_SEQNO();//if gcn is 0, rx is customed drug.
         String customName      = rx.getCustomName();
         Boolean patientCompliance  = rx.getPatientCompliance();
         String frequency       = rx.getFrequencyCode();
         String route           = rx.getRoute();
         String durationUnit    = rx.getDurationUnit();
         boolean prn            = rx.getPrn();
         String repeats         = Integer.toString(rx.getRepeat());
         String takeMin         = rx.getTakeMinString();
         String takeMax         = rx.getTakeMaxString();
         Boolean longTerm       = rx.getLongTerm();
         boolean shortTerm		= rx.getShortTerm();
      //   boolean isCustomNote   =rx.isCustomNote();
         String outsideProvOhip = rx.getOutsideProviderOhip();
         String brandName       = rx.getBrandName();
         String ATC             = rx.getAtcCode();
         String ATCcode			= rx.getAtcCode();
         String genericName     = rx.getGenericName();
         String dosage = rx.getDosage();

         String pickupDate      = RxUtil.DateToString(rx.getPickupDate(), "yyyy-MM-dd");
         String pickupTime      = RxUtil.DateToString(rx.getPickupTime(), "HH:mm");
         String eTreatmentType  = rx.getETreatmentType()!=null ? rx.getETreatmentType() : "";
         String rxStatus        = rx.getRxStatus()!=null ? rx.getRxStatus() : "";
		String protocol		= rx.getProtocol()!=null ? rx.getProtocol() : "";
		/*  Field not required. Commented out because it may be reactivated in the future.
         String priorRxProtocol	= rx.getPriorRxProtocol()!=null ? rx.getPriorRxProtocol() : "";
         */
         String drugForm		= rx.getDrugForm();
         //remove from the rerx list
         int DrugReferenceId = rx.getDrugReferenceId();

         if( ATCcode == null || ATCcode.trim().length() == 0 ) {
             ATCcode = "";
         }

         if(ATC != null && ATC.trim().length()>0)
             ATC="ATC: "+ATC;
         String drugName;
         boolean isSpecInstPresent=false;
         if(gcn==0){//it's a custom drug
            drugName=customName;
         }else{
            drugName=brandName;
         }
         if(specialInstruction!=null&&!specialInstruction.equalsIgnoreCase("null")&&specialInstruction.trim().length()>0){
            isSpecInstPresent=true;
         }
         //for display
         if(drugName==null || drugName.equalsIgnoreCase("null"))
             drugName="" ;

         String comment  = rx.getComment();
         if(rx.getComment() == null) {
        	 comment = "";
         }
         Boolean pastMed            = rx.getPastMed();
         boolean dispenseInternal = rx.getDispenseInternal();
         boolean nonAuthoritative   = rx.isNonAuthoritative();
         boolean nosubs = rx.getNosubs();
         String quantity            = rx.getQuantity();
         String quantityText="";
         String unitName=rx.getUnitName();
         if(unitName==null || unitName.equalsIgnoreCase("null") || unitName.trim().length()==0){
             quantityText=quantity;
         }
         else{
             quantityText=quantity+" "+rx.getUnitName();
         }
          duration        = rx.getDuration();
         String method          = rx.getMethod();
         String outsideProvName = rx.getOutsideProviderName();
         boolean isDiscontinuedLatest = rx.isDiscontinuedLatest();
         String archivedDate="";
         String archivedReason="";
         boolean isOutsideProvider ;
         int refillQuantity=rx.getRefillQuantity();
         int refillDuration=rx.getRefillDuration();
         String dispenseInterval=rx.getDispenseInterval();
         if(isDiscontinuedLatest){
                archivedReason=rx.getLastArchReason();
                archivedDate=rx.getLastArchDate();
         }

          if((outsideProvOhip!=null && !outsideProvOhip.equals("")) || (outsideProvName!=null && !outsideProvName.equals(""))){
             isOutsideProvider=true;
         }
         else{
             isOutsideProvider=false;
         }
         if(route==null || route.equalsIgnoreCase("null")) route="";
                    String methodStr = method;
                    String routeStr = route;
                    String frequencyStr = frequency;
                    String minimumStr = takeMin;
                    String maximumStr = takeMax;
                    String durationStr = duration;
                    String durationUnitStr = durationUnit;
                    String quantityStr = quantityText;
                    String unitNameStr="";
                    if(rx.getUnitName()!=null && !rx.getUnitName().equalsIgnoreCase("null"))
                        unitNameStr=rx.getUnitName();
                    String prnStr="";
                    if(prn)
                        prnStr="prn";
                drugName=drugName.replace("'", "\\'");
                drugName=drugName.replace("\"","\\\"");
                byte[] drugNameBytes = drugName.getBytes("ISO-8859-1");
                drugName= new String(drugNameBytes, "UTF-8");

%>

<style>

 .bubble {
        background-color: #f0f0f0;
        border-radius: 4px;
        padding: 2px 4px;
        font-size: 12px;
        color: #000;
        cursor: pointer;
        transition: all 0.3s;
        margin-bottom: 5px;
        border: 1px solid #e1e1e1;
    }
    
    .bubble:hover {
        background-color: #3b73af;
        color: #fff;
    }

.card-body {
    padding: 0 !important;
}

input#saveButton {
    background: #0b5ed7;
}

input.ControlPushButton.btn {
    background: #cdcdcd;
}

.form-label {
    margin-bottom: 0 !important;
}

label {
    font-size: 12px !important;
    text-transform: uppercase !important;
}

.tooltip {
  position: relative;
  display: inline-block;
}

.tooltip .tooltiptext {
  visibility: hidden;
  width: 210px;
  background-color: black;
  color: #fff;
  text-align: center;
  border-radius: 6px;
  padding: 5px 0;

  /* Position the tooltip */
  position: absolute;
  z-index: 1;
}

.tooltip:hover .tooltiptext {
  visibility: visible;
}
</style>

<fieldset style="margin-top:2px;width:810px;" id="set_<%=rand%>">
<a tabindex="-1" href="javascript:void(0);"
   style="float:right;margin-left:5px;margin-top:0px;padding-top:0px;"
   onclick="removeDrug('<%=rand%>')">
   <img src='<c:out value="${ctx}/images/close.png"/>' border="0">
</a>
    <%-- <a tabindex="-1" href="javascript:void(0);"  style="float:right;margin-left:5px;margin-top:0px;padding-top:0px;" onclick="$('set_<%=rand%>').remove();deletePrescribe('<%=rand%>');removeReRxDrugId('<%=DrugReferenceId%>')"><img src='<c:out value="${ctx}/images/close.png"/>' border="0"></a> --%>
    <%-- <a tabindex="-1" href="javascript:void(0);" style="float:right;margin-left:5px;margin-top:0px;padding-top:0px;" onclick="checkRxInteract();" title="Drug-Drug interactions limited to this Rx">dd</a>
    <a tabindex="-1" href="javascript:void(0);"  style="float:right;;margin-left:5px;margin-top:0px;padding-top:0px;" title="Add to Favorites" onclick="addFav('<%=rand%>','<%=drugName%>')">F</a> --%>
    <%-- <a tabindex="-1" href="javascript:void(0);" style="float:right;margin-top:0px;padding-top:0px;" onclick="$('rx_more_<%=rand%>').toggle();">  <span id="moreLessWord_<%=rand%>" onclick="updateMoreLess(id)" >more</span> </a> --%>

    <%-- with key "drug form" --%>
    <%-- <input tabindex="-1" type="text" id="drugName_<%=rand%>"  name="drugName_<%=rand%>"  size="40" <%if(gcn==0){%> onkeyup="saveCustomName(this);" value="<%=drugName%>"<%} else{%> value='<%=drugName%>'  onchange="changeDrugName('<%=rand%>','<%=drugName%>');" <%}%> TITLE="<%=drugName%>"/>&nbsp;<bean:message key="WriteScript.msgDrugForm"/>:
                <%if(rx.getDrugFormList()!=null && rx.getDrugFormList().indexOf(",")!=-1){ %>
                <select name="drugForm_<%=rand%>">
                	<%
                		String[] forms = rx.getDrugFormList().split(",");
                		for(String form:forms) {
                	%>
                		<option value="<%=form%>" <%=form.equals(drugForm)?"selected":"" %>><%=form%></option>
                	<% } %>
                </select>
				<%} else { %>
					<%=drugForm%>
				<% } %> --%>

                <div class="container">
    <div class="card p-3"> <!-- Added Card Class -->
        <div class="card-body">
            <!-- First Row: Name and Drug Form -->
            <div class="row mb-2 align-items-center">
                <div class="col-md-6">
                    <label for="drugName_<%=rand%>" class="form-label">Name</label>
                    <input type="hidden" name="atcCode" value="<%=ATCcode%>" />
                    <input tabindex="-1" type="text" id="drugName_<%=rand%>" name="drugName_<%=rand%>" class="form-control"
                        <% if (gcn == 0)  { %> readonly="readonly" value="<%=drugName%>"
                         <% } else { %> readonly="readonly" value="<%=drugName%>" <% } %>
                        title="<%=drugName%>" />
                    <!-- Drug Form Below Name -->
                    <small class="text-muted">
                        <% if (rx.getDrugFormList() != null && rx.getDrugFormList().indexOf(",") != -1) { %>
                            <select name="drugForm_<%=rand%>" class="form-select form-select-sm mt-1" style="font-size: 11px;">
                                <% String[] forms = rx.getDrugFormList().split(",");
                                for (String form : forms) { %>
                                    <option value="<%=form%>" <%=form.equals(drugForm) ? "selected" : "" %>><%=form%></option>
                                <% } %>
                            </select>
                        <% } else { %>
                <span class="form-control-plaintext mt-1" style="font-size: 11px; margin: 0 !important; padding: 0 !important;">
                <input type="hidden" id="drugForm_<%=rand%>" value="<%=drugForm%>" />
                    <c:out value="${drugForm}" />
                    <c:if test="${not empty drugCategory}"> - <c:out value="${drugCategory}" /></c:if>
                    <c:if test="${not empty drugRoute}"> - <c:out value="${drugRoute}" /></c:if>
                </span>
                <input type="hidden" name="route_<%=rand%>" value="${drugRoute}">
                        <%-- api works - <span class="form-control-plaintext mt-1" style="font-size: 11px; margin: 0 !important; padding: 0 !important;"><c:out value="${drugForm}" /></span> --%>
                        <%-- <span class="form-control-plaintext mt-1" style="font-size: 11px; margin: 0 !important; padding: 0 !important;"><%=drugForm%></span>  --%>
                        <% } %>
                    </small>
                </div>

                <div class="col-md-3">
                    <select id="longTerm_<%=rand%>" name="longTerm_<%=rand%>" class="form-select w-auto" onchange="syncLongTermRadio(this, '<%=rand%>')">
                        <option value="" disabled <%= (rx.getLongterm_p() == null) ? "selected" : "" %>>Long Term</option>
                        <option value="yes" <% if (rx.getLongterm_p() != null && rx.getLongterm_p()) { %> selected <% } %>>Yes</option>
                        <option value="no" <% if (rx.getLongterm_p() != null && !rx.getLongterm_p()) { %> selected <% } %>>No</option>
                    </select>
                </div>
            </div>

        <script>
    var technicalReasons = <%= new org.json.JSONArray(technicalReasons).toString() %>;
    console.log("Technical Reasons Loaded:", technicalReasons);  // For debugging

    // Create a master object to store SIG maps for all drugs
    window.allSigMaps = window.allSigMaps || {};

    // Store SIG map for the current drug using `rand` as the key
    window.allSigMaps['<%= rand %>'] = <%= sigMapJson.toString() %>;
    console.log("All SIG Maps Loaded:", allSigMaps);  // For debugging

    // Function to handle when a reason is selected
    window.appendToInstructions = function(reason, inputId, sigContainerId, rand) {
        const instructionsInput = document.getElementById(inputId);
        if (instructionsInput) {
            instructionsInput.value = reason;  // Set the selected reason in the Instructions input field
            displaySIGs(reason, sigContainerId, rand);  // Pass `rand` to access correct SIG map
        } else {
            console.error("Input field not found for ID:", inputId);
        }
    }

    // Function to display SIGs for the selected reason
    function displaySIGs(reason, sigContainerId, rand) {
        const sigContainer = document.getElementById(sigContainerId);  // Use the `sigContainerId` passed as an argument
        sigContainer.innerHTML = "";  // Clear previous SIGs

        console.log("Reason in display sigs:", reason);
        console.log("SIG Map for drug " + rand + ":", allSigMaps[rand]);  // Correct way to print the current drug's SIG map

        // Check if there are SIGs for the selected reason
        const sigMap = allSigMaps[rand] || {};  // Fetch the SIG map for the current drug
        const sigs = sigMap[reason] || [];  // Default to an empty array if no SIGs found

        if (sigs.length > 0) {
            // Iterate over each SIG and create a bubble for it
            sigs.forEach(function(sig) {
                const sigBubble = document.createElement("div");
                sigBubble.className = "bubble";
                sigBubble.innerText = sig;

                // When a SIG bubble is clicked, set it in the Special Instructions field
                sigBubble.onclick = function() {
                    appendToSpecialInstructions(sig, 'siInput_' + rand);  // Dynamically set SIG to the correct input field based on `rand`
                };

                sigContainer.appendChild(sigBubble);  // Add the bubble to the container
            });
        } else {
            sigContainer.innerHTML = "<p style='color: #666; font-style: italic;'>No SIGs available</p>";
        }
    }

    // Function to append SIG to Special Instructions field
    function appendToSpecialInstructions(sig, inputId) {
        const specialInstructionsInput = document.getElementById(inputId);
        if (specialInstructionsInput) {
            specialInstructionsInput.value = sig;  // Set the selected SIG in Special Instructions field
            updateSpecialInstruction(inputId);
        } else {
            console.error("Special Instructions input field not found for ID:", inputId);
        }
    }
</script>


<div class="row mb-2">
    <div class="col">
        <label for="instructions_<%=rand%>" class="form-label">Indication</label>
        <div class="input-group">
            <input type="text" id="instructions_<%=rand%>" name="instructions_<%=rand%>" class="form-control"
                onkeypress="handleEnter(this,event);" value="" onchange="parseIntr(this);" />
        </div>
    </div>
</div>

<!-- Bubble Suggestions Container (Technical Reasons) -->
<div id="bubble-container" style="display: flex; flex-wrap: wrap; gap: 5px; margin-bottom: 10px;">
    <%
        // Display technical reasons as clickable bubbles and append them to Instructions
        if (technicalReasons != null && !technicalReasons.isEmpty()) {
            for (String reason : technicalReasons) {
    %>
                <div class="bubble" 
    onclick="appendToInstructions('<%= org.apache.commons.lang.StringEscapeUtils.escapeJavaScript(reason) %>', 
    'instructions_<%=rand%>', 'sig-container_<%=rand%>', '<%=rand%>')">
    <%= reason %>
</div>

    <%
            }
        } else {
    %>
        <p style="color: #666; font-style: italic;">No suggestions available</p>
    <%
        }
    %>
</div>


<!-- Frequency Type + Sub Frequency + Dose + Duration -->
<div class="row mb-2 align-items-center">

    <!-- Frequency Type -->
    <div class="col-md-3">
        <label class="form-label">Frequency</label>
        <select id="fqy_<%=rand%>" class="form-select" onchange="calculateRequiredQuantity('<%=rand%>')">
            <option value="">Select</option>
            <option value="DAILY">Daily</option>
            <option value="ALTERNATE">Alternate</option>
            <option value="WEEKLY">Weekly</option>
            <option value="MONTHLY">Monthly</option>
        </select>
    </div>

    <!-- Sub-Frequency -->
    <div class="col-md-3">
        <label class="form-label">Sub-Frequency</label>
        <select id="subFrequency_<%=rand%>" class="form-select" onchange="calculateRequiredQuantity('<%=rand%>')">
            <option value="">Select</option>
            <option value="OD">OD</option>
            <option value="BID">BID</option>
            <option value="TID">TID</option>
            <option value="QID">QID</option>
        </select>
    </div>

    <!-- Weekly Day (Shown only if Weekly is selected) -->
    <div class="col-md-3" id="weeklyDayContainer_<%=rand%>" style="display: none;">
        <label class="form-label">Day of the Week</label>
        <select id="weeklyDay_<%=rand%>" class="form-select" onchange="calculateRequiredQuantity('<%=rand%>')">
            <option value="">Select</option>
            <option value="1">Monday</option>
            <option value="2">Tuesday</option>
            <option value="3">Wednesday</option>
            <option value="4">Thursday</option>
            <option value="5">Friday</option>
            <option value="6">Saturday</option>
            <option value="0">Sunday</option>
        </select>
    </div>

    <!-- Dose -->
    <div class="col-md-3">
        <label class="form-label">Dose</label>
        <div class="input-group">
            <input type="number" id="dose_<%=rand%>" class="form-control" min="1"
                oninput="calculateRequiredQuantity('<%=rand%>')">
            <span class="input-group-text"><%=drugForm%>(s)</span>
        </div>
    </div>
</div>

<!-- Duration, Quantity, Start Date, End Date, Repeats -->
<div class="row mb-2 align-items-center">

    <!-- Duration -->
    <div class="col-md-3">
        <label class="form-label">Duration (days)</label>
        <input type="number" id="duration_<%=rand%>" name="duration_<%=rand%>" class="form-control"
            value="<%= (duration != null) ? duration : "" %>"
            oninput="calculateRequiredQuantity('<%=rand%>')">
    </div>

    <!-- Required Quantity -->
    <div class="col-md-3">
        <label class="form-label">Total Quantity</label>
        <div class="input-group">
            <input type="number" id="quantity_<%=rand%>" name="quantity_<%=rand%>" class="form-control"
                value="<%= quantityText %>" min="1" required readonly>
            <span class="input-group-text"><%=drugForm%>(s)</span>
        </div>
    </div>

    <!-- Start Date -->
    <div class="col-md-3">
        <label class="form-label">Start Date</label>
        <input type="date" id="startDate_<%=rand%>" name="startDate_<%=rand%>" class="form-control"
            value="<%= new java.text.SimpleDateFormat("yyyy-MM-dd").format(new java.util.Date()) %>"
            onchange="calculateRequiredQuantity('<%=rand%>')" required>
    </div>

    <!-- End Date -->
    <div class="col-md-3">
        <label class="form-label">End Date</label>
        <input type="date" id="endDate_<%=rand%>" name="endDate_<%=rand%>" class="form-control" readonly>
    </div>
</div>

<!-- Repeats -->
<div class="row mb-2 align-items-center">
    <div class="col-md-3">
        <label class="form-label">Refills</label>
        <input type="number" id="repeats_<%=rand%>" name="repeats_<%=rand%>" class="form-control"
            value="<%=repeats%>" min="0" required oninput="updateLongTerm('<%=rand%>',this)" onblur="updateProperty(this.id)">
    </div>
</div>

<!-- Auto-generated Instructions (SIG) -->
<div class="row mb-2">
    <div class="col">
        <label for="siInput_<%=rand%>" class="form-label">Instructions</label>
        <div class="input-group">
            <input type="text" id="siInput_<%=rand%>" name="siInput_<%=rand%>" class="form-control"
                readonly
                onkeypress="handleEnter(this,event);" value=""
                onchange="updateSpecialInstruction('siInput_<%=rand%>'); parseIntr(this);" />
        </div>
    </div>
</div>

<%-- <!-- Third Row: Instructions -->
<div class="row mb-2">
    <div class="col">
        <label for="siInput_<%=rand%>" class="form-label">Instructions</label>
        <div class="input-group">
            <input type="text" id="siInput_<%=rand%>" name="siInput_<%=rand%>" class="form-control"
                onkeypress="handleEnter(this,event);" value=""
                onchange="updateSpecialInstruction('siInput_<%=rand%>'); parseIntr(this);" />
        </div>
    </div>
</div>

<!-- SIG Bubble Container Below Special Instructions Field -->
<div id="sig-container_<%=rand%>" style="margin-top: 5px; display: flex; flex-wrap: wrap; gap: 5px;">
<span style="color: #919191; font-style: italic; font-size: 12px; line-height: 0; margin-bottom: 20px;">
    Select a reason to view SIGs
</span>
</div>

           <!-- Fourth Row: Dose, Frequency, Duration, Quantity -->
<div class="row mb-2 align-items-center">
    <!-- Dose -->
    <div class="col-md-3">
        <label class="form-label">Dose</label>
        <input type="number" id="dose_<%=rand%>" class="form-control" value="" min="1"
               oninput="calculateRequiredQuantity('<%=rand%>')">
    </div>

    <!-- Frequency -->
    <div class="col-md-3">
        <label class="form-label">FQY</label>
        <select id="fqy_<%=rand%>" class="form-select" onchange="calculateRequiredQuantity('<%=rand%>')">
            <option value="">Select</option>
            <option value="1">OD</option>
            <option value="2">BID</option>
            <option value="3">TID</option>
            <option value="4">QID</option>
        </select>
    </div>

    <!-- Duration -->
    <div class="col-md-3">
        <label class="form-label">Duration</label>
        <input type="text" id="duration_<%=rand%>" name="duration_<%=rand%>" class="form-control"
            value="<%= (duration != null) ? duration : "" %>"
            oninput="calculateEndDate('<%=rand%>'); calculateRequiredQuantity('<%=rand%>')">
    </div>

    <!-- Required Quantity -->
    <div class="col-md-3">
        <label class="form-label">Required Quantity</label>
        <input type="number" id="quantity_<%=rand%>" name="quantity_<%=rand%>" class="form-control"
            value="<%= quantityText %>" min="1" required readonly>
    </div>
</div>

            <!-- Fifth Row: Start Date, Duration, End Date -->
            <div class="row mb-2">
                <div class="col">
                    <label class="form-label">Start Date</label>
                    <input type="date" id="startDate_<%=rand%>" name="startDate_<%=rand%>" class="form-control"
                        value="<%= new java.text.SimpleDateFormat("yyyy-MM-dd").format(new java.util.Date()) %>"
                        min="<%= new java.text.SimpleDateFormat("yyyy-MM-dd").format(new java.util.Date()) %>" required>
                </div>
                <div class="col">
                    <label class="form-label">End Date</label>
                    <input type="date" id="endDate_<%=rand%>" name="endDate_<%=rand%>" class="form-control" readonly>
                </div>
                <div class="col">
                 <label class="form-label">Refills</label>
                    <input type="number" id="repeats_<%=rand%>" name="repeats_<%=rand%>" class="form-control"
                        value="<%=repeats%>" min="0" required onInput="updateLongTerm('<%=rand%>',this)" onblur="updateProperty(this.id)">
                </div>
            </div> --%>

            <!-- Sixth Row: Patient Compliance & Frequency Options -->
            <div class="row mb-2 align-items-center">
                <label class="col-md-2 col-form-label">Patient Compliance</label>
                <div class="col-md-3">
                    <select id="compliance_<%=rand%>" name="compliance_<%=rand%>" class="form-select"
                        onchange="handleComplianceChange('<%=rand%>')">
                        <option value="">Select</option>
                        <option value="yes" <% if (patientCompliance != null && patientCompliance.equals("yes")) { %> selected <% } %>>Yes</option>
                        <option value="no" <% if (patientCompliance != null && patientCompliance.equals("no")) { %> selected <% } %>>No</option>
                        <option value="unknown" <% if (patientCompliance != null && patientCompliance.equals("unknown")) { %> selected <% } %>>Unknown</option>
                    </select>
                </div>
                <div id="frequencyOptions_<%=rand%>" class="col-md-7 compliance-options" style="<%= (patientCompliance != null && patientCompliance.equals("no")) ? "" : "display: none;" %>">
                    <input type="radio" name="frequency_<%=rand%>" value="daily" <% if ("daily".equals(frequency)) { %> checked <% } %>> Daily
                    <input type="radio" name="frequency_<%=rand%>" value="weekly" <% if ("weekly".equals(frequency)) { %> checked <% } %>> Weekly
                    <input type="radio" name="frequency_<%=rand%>" value="bi-weekly" <% if ("bi-weekly".equals(frequency)) { %> checked <% } %>> Bi-Weekly
                    <input type="radio" name="frequency_<%=rand%>" value="monthly" <% if ("monthly".equals(frequency)) { %> checked <% } %>> Monthly
                </div>
            </div>
        </div>
    </div>
</div>


		<%-- <div id="medTerm_<%=rand%>">
			<label><bean:message key="WriteScript.msgLongTermMedication" />: </label>
			<span>
				<label for="longTermY_<%=rand%>" ><bean:message key="WriteScript.msgYes" /> </label>
			  	<input type="radio" id="longTermY_<%=rand%>"  name="longTerm_<%=rand%>" value="yes" class="med-term" <%if(longTerm != null && longTerm) {%> checked="checked" <%}%> onChange="updateShortTerm('<%=rand%>',false)"/>

			  	<label for="longTermN_<%=rand%>" ><bean:message key="WriteScript.msgNo" /> </label>
			  	<input type="radio" id="longTermN_<%=rand%>"  name="longTerm_<%=rand%>" value="no" class="med-term" <%if(longTerm != null && ! longTerm) {%> checked="checked" <%}%> onChange="updateShortTerm('<%=rand%>',true)"/>

			  	<label for="longTermE_<%=rand%>" ><bean:message key="WriteScript.msgUnset" /> </label>
			  	<input type="radio" id="longTermE_<%=rand%>"  name="longTerm_<%=rand%>" value="unset" class="med-term" <%if(longTerm == null) {%> checked="checked" <%}%> onChange="updateShortTerm('<%=rand%>',false)"/>
				<div style="display:none">
					<label for="shortTerm_<%=rand%>" ><bean:message key="WriteScript.msgSortTermMedication"/> </label>
	        		<input  type="checkbox" id="shortTerm_<%=rand%>"  name="shortTerm_<%=rand%>" class="med-term" <%if(shortTerm) {%> checked="checked" <%}%> />
	        	</div>
	        </span>
		</div> --%>

        <%-- <%if(genericName!=null&&!genericName.equalsIgnoreCase("null")){%> --%>
        <%-- <div class="tooltip">Ingredient:&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<a style="cursor:pointer;" onclick="window.open('<%=OscarProperties.getInstance().getProperty("rx_search_url","https://online.epocrates.com/results?query=")%><%=genericName%>',width=1030,height=895)"><%=genericName%></a><span class="tooltiptext"><%=OscarProperties.getInstance().getProperty("rx_search_text","See drug information on Epocrates")%></span></div><%}%> --%>
           </div>
       <%-- <div class="rxStr" title="not what you mean?" >
           <a tabindex="-1" href="javascript:void(0);" onclick="focusTo('method_<%=rand%>')">Method:</a><a   id="method_<%=rand%>" onclick="focusTo(this.id)" onfocus="lookEdittable(this.id)" onblur="lookNonEdittable(this.id);updateProperty(this.id);"><%=methodStr%></a>
           <a tabindex="-1" href="javascript:void(0);" onclick="focusTo('route_<%=rand%>')">Route:</a><a id="route_<%=rand%>" onclick="focusTo(this.id)" onfocus="lookEdittable(this.id)" onblur="lookNonEdittable(this.id);updateProperty(this.id);"> <%=routeStr%></a>
           <a tabindex="-1" href="javascript:void(0);" onclick="focusTo('frequency_<%=rand%>')">Frequency:</a><a  id="frequency_<%=rand%>" onclick="focusTo(this.id) " onfocus="lookEdittable(this.id)" onblur="lookNonEdittable(this.id);updateProperty(this.id);"> <%=frequencyStr%></a>
           <a tabindex="-1" href="javascript:void(0);" onclick="focusTo('minimum_<%=rand%>')">Min:</a><a  id="minimum_<%=rand%>" onclick="focusTo(this.id) " onfocus="lookEdittable(this.id)" onblur="lookNonEdittable(this.id);updateProperty(this.id);"> <%=minimumStr%></a>
           <a tabindex="-1" href="javascript:void(0);" onclick="focusTo('maximum_<%=rand%>')">Max:</a><a id="maximum_<%=rand%>" onclick="focusTo(this.id) " onfocus="lookEdittable(this.id)" onblur="lookNonEdittable(this.id);updateProperty(this.id);"> <%=maximumStr%></a>
           <a tabindex="-1" href="javascript:void(0);" onclick="focusTo('duration_<%=rand%>')">Duration:</a><a  id="duration_<%=rand%>" onclick="focusTo(this.id) " onfocus="lookEdittable(this.id)" onblur="lookNonEdittable(this.id);updateProperty(this.id);"> <%=durationStr%></a>
           <a tabindex="-1" href="javascript:void(0);" onclick="focusTo('durationUnit_<%=rand%>')">DurationUnit:</a><a  id="durationUnit_<%=rand%>" onclick="focusTo(this.id) " onfocus="lookEdittable(this.id)" onblur="lookNonEdittable(this.id);updateProperty(this.id);"> <%=durationUnitStr%></a>
           <a tabindex="-1" >Qty/Mitte:</a><a tabindex="-1" id="quantityStr_<%=rand%>"> <%=quantityStr%></a>
           <a> </a><a tabindex="-1" id="unitName_<%=rand%>"> </a>
           <a> </a><a tabindex="-1" href="javascript:void(0);" id="prn_<%=rand%>" onclick="setPrn('<%=rand%>');updateProperty('prnVal_<%=rand%>');"><%=prnStr%></a>
           <input id="prnVal_<%=rand%>"  style="display:none" <%if(prnStr.trim().length()==0){%>value="false"<%} else{%>value="true" <%}%> />
           <input id="rx_save_updates_<%=rand%>" type="button" value="Save Changes" onclick="saveLinks('<%=rand%>')"/>
       </div> --%>
       <%-- <div id="rx_more_<%=rand%>" style="display:none;padding:2px;"> --%>
        <%-- <div>
       	  <bean:message key="WriteScript.msgPrescribedRefill"/>:
       	  &nbsp;
       	  <bean:message key="WriteScript.msgPrescribedRefillDuration"/>
       	  <input type="text" size="6" id="refillDuration_<%=rand%>" name="refillDuration_<%=rand%>" value="<%=refillDuration%>"
       	   onchange="if(isNaN(this.value)||this.value<0){alert('Refill duration must be number (of days)');this.focus();return false;}return true;" /><bean:message key="WriteScript.msgPrescribedRefillDurationDays"/>
       	  &nbsp;
       	  <bean:message key="WriteScript.msgPrescribedRefillQuantity"/>
       	  <input type="text" size="6" id="refillQuantity_<%=rand%>" name="refillQuantity_<%=rand%>" value="<%=refillQuantity%>" />
       	  </div><div>

       	  <bean:message key="WriteScript.msgPrescribedDispenseInterval"/>
       	  <input type="text" size="6" id="dispenseInterval_<%=rand%>" name="dispenseInterval_<%=rand%>" value="<%=dispenseInterval%>" />
       	  </div>

	     <%if(OscarProperties.getInstance().getProperty("rx.enable_internal_dispensing","false").equals("true")) {%>
	       <div>
	       	   <bean:message key="WriteScript.msgDispenseInternal"/>
			  <input type="checkbox" name="dispenseInternal_<%=rand%>" id="dispenseInternal_<%=rand%>" <%if(dispenseInternal) {%> checked="checked" <%}%> />
      	 </div>
      	 <% } %>
		<div>
          <bean:message key="WriteScript.msgPrescribedByOutsideProvider"/>
          <input type="checkbox" id="ocheck_<%=rand%>" name="ocheck_<%=rand%>" onclick="$('otext_<%=rand%>').toggle();" <%if(isOutsideProvider){%> checked="checked" <%}else{}%>/>
          <div id="otext_<%=rand%>" <%if(isOutsideProvider){%>style="display:table;padding:2px;"<%}else{%>style="display:none;padding:2px;"<%}%> >
                <b><label style="float:left;width:80px;">Name :</label></b> <input type="text" id="outsideProviderName_<%=rand%>" name="outsideProviderName_<%=rand%>" <%if(outsideProvName!=null){%> value="<%=outsideProvName%>"<%}else {%> value=""<%}%> />
                <b><label style="width:80px;">OHIP No:</label></b> <input type="text" id="outsideProviderOhip_<%=rand%>" name="outsideProviderOhip_<%=rand%>"  <%if(outsideProvOhip!=null){%>value="<%=outsideProvOhip%>"<%}else {%> value=""<%}%>/>
          </div> --%>

    <%-- <div>

        <label for="pastMedSelection" title="Medications taken at home that were previously ordered."><bean:message key="WriteScript.msgPastMedication" /></label>

        <span id="pastMedSelection">
        	<label for="pastMedY_<%=rand%>"><bean:message key="WriteScript.msgYes"/></label>
            <input  type="radio" value="yes" name="pastMed_<%=rand%>" id="pastMedY_<%=rand%>" <%if(pastMed != null && pastMed) {%> checked="checked" <%}%>  />

            <label for="pastMedN_<%=rand%>"><bean:message key="WriteScript.msgNo"/></label>
            <input  type="radio" value="no" name="pastMed_<%=rand%>" id="pastMedN_<%=rand%>" <%if(pastMed != null && ! pastMed) {%> checked="checked" <%}%>  />

            <label for="pastMedE_<%=rand%>"><bean:message key="WriteScript.msgUnknown"/></label>
            <input  type="radio" value="unset" name="pastMed_<%=rand%>" id="pastMedE_<%=rand%>" <%if(pastMed == null) {%> checked="checked" <%}%>  />
         </span>
	</div> --%>
    
    <%-- <div>
          <bean:message key="WriteScript.msgNonAuthoritative"/>
            <input type="checkbox" name="nonAuthoritativeN_<%=rand%>" id="nonAuthoritativeN_<%=rand%>" <%if(nonAuthoritative) {%> checked="checked" <%}%> />
    </div> --%>
    <%-- <div>

    		<bean:message key="WriteScript.msgSubNotAllowed"/>
    		<input type="checkbox" name="nosubs_<%=rand%>" id="nosubs_<%=rand%>" <%if(nosubs) {%> checked="checked" <%}%> />
    </div> --%>
    <%-- <div>

        <label style="float:left;width:80px;">Start Date:</label>
           <input type="text" id="rxDate_<%=rand%>" name="rxDate_<%=rand%>" value="<%=startDate%>" <%if(startDateUnknown) {%> disabled="disabled" <%}%>/>
        <bean:message key="WriteScript.msgUnknown"/>
           <input  type="checkbox" name="startDateUnknown_<%=rand%>" id="startDateUnknown_<%=rand%>" <%if(startDateUnknown) {%> checked="checked" <%}%> onclick="toggleStartDateUnknown('<%=rand%>');"/>

           </div> --%>
           <%-- <div>
	<label style="">Last Refill Date:</label>
           <input type="text" id="lastRefillDate_<%=rand%>"  name="lastRefillDate_<%=rand%>" value="<%=lastRefillDate%>" />
	</div><div>
        <label style="float:left;width:80px;">Written Date:</label>
           <input type="text" id="writtenDate_<%=rand%>"  name="writtenDate_<%=rand%>" value="<%=writtenDate%>" />
           <a href="javascript:void(0);" style="float:right;margin-top:0px;padding-top:0px;" onclick="addFav('<%=rand%>','<%=drugName%>');return false;">Add to Favorite</a>

           </div><div>

			<bean:message key="WriteScript.msgProtocolReference"/>:
           <input type="text" id="protocol_<%=rand%>"  name="protocol_<%=rand%>" value="<%=protocol%>" /> --%>

           <%--  OMD Revalidation: field not required currently. Commented out as this may be used again in the future.
          <label style="">Prior Rx Protocol:</label>
           <input type="text" id="protocol_<%=rand%>"  name="priorRxProtocol_<%=rand%>" value="<%=priorRxProtocol%>" />
            --%>

           <%-- </div> --%>
           <%-- <div>

           <bean:message key="WriteScript.msgPickUpDate"/>:
           <input type="text" id="pickupDate_<%=rand%>"  name="pickupDate_<%=rand%>" value="<%=pickupDate%>" onchange="if (!isValidDate(this.value)) {this.value=null}" />
           <bean:message key="WriteScript.msgPickUpTime"/>:
           <input type="text" id="pickupTime_<%=rand%>"  name="pickupTime_<%=rand%>" value="<%=pickupTime%>" onchange="if (!isValidTime(this.value)) {this.value=null}" />
           </div><div>
           <bean:message key="WriteScript.msgComment"/>:
           <input type="text" id="comment_<%=rand%>" name="comment_<%=rand%>" value="<%=comment%>" size="60"/>
           </div><div>
           <bean:message key="WriteScript.msgETreatmentType"/>:
           <select name="eTreatmentType_<%=rand%>">
           		<option>--</option>
                         <option value="CHRON" <%=eTreatmentType.equals("CHRON")?"selected":""%>><bean:message key="WriteScript.msgETreatment.Continuous"/></option>
 				<option value="ACU" <%=eTreatmentType.equals("ACU")?"selected":""%>><bean:message key="WriteScript.msgETreatment.Acute"/></option>
 				<option value="ONET" <%=eTreatmentType.equals("ONET")?"selected":""%>><bean:message key="WriteScript.msgETreatment.OneTime"/></option>
 				<option value="PRNL" <%=eTreatmentType.equals("PRNL")?"selected":""%>><bean:message key="WriteScript.msgETreatment.LongTermPRN"/></option>
 				<option value="PRNS" <%=eTreatmentType.equals("PRNS")?"selected":""%>><bean:message key="WriteScript.msgETreatment.ShortTermPRN"/></option>           </select>
           <select name="rxStatus_<%=rand%>">
           		<option>--</option>
                         <option value="New" <%=rxStatus.equals("New")?"selected":""%>><bean:message key="WriteScript.msgRxStatus.New"/></option>
                         <option value="Active" <%=rxStatus.equals("Active")?"selected":""%>><bean:message key="WriteScript.msgRxStatus.Active"/></option>
                         <option value="Suspended" <%=rxStatus.equals("Suspended")?"selected":""%>><bean:message key="WriteScript.msgRxStatus.Suspended"/></option>
                         <option value="Aborted" <%=rxStatus.equals("Aborted")?"selected":""%>><bean:message key="WriteScript.msgRxStatus.Aborted"/></option>
                         <option value="Completed" <%=rxStatus.equals("Completed")?"selected":""%>><bean:message key="WriteScript.msgRxStatus.Completed"/></option>
                         <option value="Obsolete" <%=rxStatus.equals("Obsolete")?"selected":""%>><bean:message key="WriteScript.msgRxStatus.Obsolete"/></option>
                         <option value="Nullified" <%=rxStatus.equals("Nullified")?"selected":""%>><bean:message key="WriteScript.msgRxStatus.Nullified"/></option>
           </select>
                </div> --%>
                <%-- <div>
                <bean:message key="WriteScript.msgDrugForm"/>:
                <%if(rx.getDrugFormList()!=null && rx.getDrugFormList().indexOf(",")!=-1){ %>
                <select name="drugForm_<%=rand%>">
                	<%
                		String[] forms = rx.getDrugFormList().split(",");
                		for(String form:forms) {
                	%>
                		<option value="<%=form%>" <%=form.equals(drugForm)?"selected":"" %>><%=form%></option>
                	<% } %>
                </select>
				<%} else { %>
					<%=drugForm%>
				<% } %>




       			</div> --%>

        </div>

           <div id="renalDosing_<%=rand%>" ></div>
           <div id="luc_<%=rand%>" style="margin-top:2px;" >
            </div>


           <oscar:oscarPropertiesCheck property="RENAL_DOSING_DS" value="yes">
            <script type="text/javascript">getRenalDosingInformation('renalDosing_<%=rand%>','<%=rx.getAtcCode()%>');</script>
            </oscar:oscarPropertiesCheck>
           <oscar:oscarPropertiesCheck property="billregion" value="ON" >
               <script type="text/javascript">getLUC('luc_<%=rand%>','<%=rand%>','<%=rx.getRegionalIdentifier()%>');</script>
            </oscar:oscarPropertiesCheck>



</fieldset>

<style type="text/css" >


/*
 * jQuery UI Autocomplete 1.8.18
 *
 * Copyright 2011, AUTHORS.txt (http://jqueryui.com/about)
 * Dual licensed under the MIT or GPL Version 2 licenses.
 * http://jquery.org/license
 *
 * http://docs.jquery.com/UI/Autocomplete#theming
 */
.ui-autocomplete { position: absolute; cursor: default; }

/* workarounds */
* html .ui-autocomplete { width:1px; } /* without this, the menu expands to 100% in IE6 */

/*
 * jQuery UI Menu 1.8.18
 *
 * Copyright 2010, AUTHORS.txt (http://jqueryui.com/about)
 * Dual licensed under the MIT or GPL Version 2 licenses.
 * http://jquery.org/license
 *
 * http://docs.jquery.com/UI/Menu#theming
 */
.ui-menu {
	list-style:none;
	padding: 2px;
	margin: 0;
	display:block;
	float: left;
}
.ui-menu .ui-menu {
	margin-top: -3px;
}
.ui-menu .ui-menu-item {
	margin:0;
	padding: 0;
	zoom: 1;
	float: left;
	clear: left;
	width: 100%;
}
.ui-menu .ui-menu-item a {
	text-decoration:none;
	display:block;
	padding:.2em .4em;
	line-height:1.5;
	zoom:1;
}
.ui-menu .ui-menu-item a.ui-state-hover,
.ui-menu .ui-menu-item a.ui-state-active {
	font-weight: normal;
	margin: -1px;
}


	.ui-autocomplete-loading {
		background: white url('../images/ui-anim_basic_16x16.gif') right center no-repeat;
	}
	.ui-autocomplete {
		max-height: 200px;
		overflow-y: auto;
		overflow-x: hidden;
		background-color: whitesmoke;
			border:#ccc thin solid;
	}

	.ui-menu .ui-menu {

		background-color: whitesmoke;
	}

	.ui-menu .ui-menu-item a {
		border-bottom:white thin solid;
	}
	.ui-menu .ui-menu-item a.ui-state-hover,
	.ui-menu .ui-menu-item a.ui-state-active {
		background-color: yellow;
	}

</style>

<script type="text/javascript">
       jQuery("document").ready(function() {

               if ( window.document.documentMode ) {  // then its IE
                       jQuery('#rx_save_updates_<%=rand%>').show();
               } else {
                      jQuery('#rx_save_updates_<%=rand%>').hide();
               }

				var idindex = "";
               jQuery( "input[id*='jsonDxSearch']" ).autocomplete({
       			source: function(request, response) {

       				var elementid = this.element[0].id;
	   				if( elementid.indexOf("_") > 0 ) {
	   					idindex = "_" + elementid.split("_")[1];
	   				}

       				jQuery.ajax({
       				    url: ctx + "/dxCodeSearchJSON.do",
       				    type: 'POST',
       				    data: 'method=search' + ( jQuery( '#codingSystem' + idindex ).find(":selected").val() ).toUpperCase()
       				    				+ '&keyword='
       				    				+ jQuery( "#jsonDxSearch" + idindex ).val(),
       				  	dataType: "json",
       				    success: function(data) {
       						response(jQuery.map( data, function(item) {
       							return {
       								label: item.description.trim() + ' (' + item.code + ')',
       								value: item.code,
       								id: item.id
       							};
       				    	}))
       				    }
       				})
       			},
       			delay: 100,
       			minLength: 2,
       			select: function( event, ui) {
       				event.preventDefault();
       				jQuery( "#jsonDxSearch" + idindex ).val(ui.item.label);
       				jQuery( '#codeTxt' + idindex ).val(ui.item.value);
       			},
       			focus: function(event, ui, idindex) {
       		        event.preventDefault();
       		        jQuery( "#jsonDxSearch" + idindex ).val(ui.item.label);
       		    },
       			open: function() {
       				jQuery( this ).removeClass( "ui-corner-all" ).addClass( "ui-corner-top" );
       			},
       			close: function() {
       				jQuery( this ).removeClass( "ui-corner-top" ).addClass( "ui-corner-all" );
       			}
       		})



		<%--   Removed during OMD Re-Evaluation.  This function auto set the LongTerm field
		if number of refills more than 0.  This is not a definitive Long Term drug.
			jQuery("input[id^='repeats_']").on( "keyup", function(){
            	var rand = <%=rand%>;
            	var repeatsVal = this.value;
            	if(repeatsVal>0){
            		jQuery("#longTerm_"+rand).attr("checked","checked");
            		jQuery(".med-term").trigger('change');
            	}
            }); --%>


       });
</script>

        <script type="text/javascript">
            $('drugName_'+'<%=rand%>').value=decodeURIComponent(encodeURIComponent('<%=drugName%>'));
            calculateRxData('<%=rand%>');
            handleEnter=function handleEnter(inField, ev){
                var charCode;
                if(ev && ev.which)
                    charCode=ev.which;
                else if(window.event){
                    ev=window.event;
                    charCode=ev.keyCode;
                }
                var id=inField.id.split("_")[1];
                if(charCode==13)
                    showHideSpecInst('siAutoComplete_'+id);
            }
            showHideSpecInst=function showHideSpecInst(elementId){
              if($(elementId).getStyle('display')=='none'){
                  Effect.BlindDown(elementId);
              }else{
                  Effect.BlindUp(elementId);
              }
            }

            var specArr=new Array();
            var specStr='<%=org.apache.commons.lang.StringEscapeUtils.escapeJavaScript(specStr)%>';

            specArr=specStr.split("*");// * is used as delimiter
            //oscarLog("specArr="+specArr);
            YAHOO.example.BasicLocal = function() {
                // Use a LocalDataSource
                var oDS = new YAHOO.util.LocalDataSource(specArr);
                // Optional to define fields for single-dimensional array
                oDS.responseSchema = {fields : ["state"]};

                // Instantiate the AutoComplete
                var oAC = new YAHOO.widget.AutoComplete("siInput_<%=rand%>", "siContainer_<%=rand%>", oDS);
                oAC.prehighlightClassName = "yui-ac-prehighlight";
                oAC.useShadow = true;

                return {
                    oDS: oDS,
                    oAC: oAC
                };
            }();



            checkAllergy('<%=rand%>','<%=rx.getAtcCode()%>');
            checkIfInactive('<%=rand%>','<%=rx.getRegionalIdentifier()%>');

            var isDiscontinuedLatest=<%=isDiscontinuedLatest%>;
            //oscarLog("isDiscon "+isDiscontinuedLatest);
            //pause(1000);
            var archR='<%=archivedReason%>';
            if(isDiscontinuedLatest && archR!="represcribed"){
               var archD='<%=archivedDate%>';
               //oscarLog("in js discon "+archR+"--"+archD);

                    // if(confirm('This drug was discontinued on <%=archivedDate%> because of <%=archivedReason%> are you sure you want to continue it?')==true){
                    //     //do nothing
                    // }
                    // else{
                    //     $('set_<%=rand%>').remove();
                    //     //call java class to delete it from stash pool.
                    //     var randId='<%=rand%>';
                    //     deletePrescribe(randId);
                    // }
            }
            var listRxDrugSize=<%=listRxDrugs.size()%>;
            //oscarLog("listRxDrugsSize="+listRxDrugSize);
            counterRx++;
            //oscarLog("counterRx="+counterRx);
           var gcn_val=<%=gcn%>;
           if(gcn_val==0){
               $('drugName_<%=rand%>').focus();
           } else if(counterRx==listRxDrugSize){
               //oscarLog("counterRx="+counterRx+"--listRxDrugSize="+listRxDrugSize);
               $('instructions_<%=rand%>').focus();
           }
        </script>
                <%}%>

<script type="text/javascript">
counterRx=0;

if(skipParseInstr)
skipParseInstr=false;
</script>
<%}%>

<!-- Include Bootstrap JS -->
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>
