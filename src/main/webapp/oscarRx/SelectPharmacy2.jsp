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
<%@page import="java.io.StringWriter"%>
<%@page import="org.codehaus.jackson.map.ObjectMapper"%>
<%@page import="org.apache.commons.lang.StringEscapeUtils"%>
<%@page import="oscar.OscarProperties,oscar.log.*"%>
<%@ taglib uri="/WEB-INF/struts-bean.tld" prefix="bean"%>
<%@ taglib uri="/WEB-INF/struts-html.tld" prefix="html"%>
<%@ taglib uri="/WEB-INF/struts-logic.tld" prefix="logic"%>
<%@ taglib uri="/WEB-INF/security.tld" prefix="security"%>
<%@ page import="oscar.oscarRx.data.*,java.util.*"%>
<%@ page import="org.oscarehr.common.model.PharmacyInfo" %>
<%@ page import="org.owasp.encoder.Encode" %>
<%@ page import="oscar.oscarRx.util.PharmacyAPIFetcher" %>
<%@ page import="oscar.oscarRx.data.RxPharmacyData" %>
<%@ page import="java.util.List" %>
<%@ page import="org.oscarehr.common.model.PharmacyInfo" %>
<%@ page import="org.oscarehr.common.dao.DemographicDao" %>
<%@ page import="org.oscarehr.common.model.Demographic" %>

<%
    if ("update".equals(request.getParameter("action"))) {
        PharmacyAPIFetcher pharmacyAPIFetcher = new PharmacyAPIFetcher();
        pharmacyAPIFetcher.fetchAndSavePharmacies();
    }

    RxPharmacyData rxPharmacyData = new RxPharmacyData();
    List<PharmacyInfo> pharmacies = rxPharmacyData.getAllPharmacies();
    request.setAttribute("pharmacies", pharmacies);
%>



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
OscarProperties oscarProps = OscarProperties.getInstance();
String help_url = (oscarProps.getProperty("HELP_SEARCH_URL","https://oscargalaxy.org/knowledge-base/")).trim();
%>

<html:html locale="true">
<head>
<script src="${ pageContext.request.contextPath }/js/global.js"></script>
<script src="${ pageContext.request.contextPath }/library/jquery/jquery-3.6.4.min.js"></script>
<script src="${ pageContext.request.contextPath }/library/jquery/jquery-ui-1.12.1.min.js"></script>
<script src="${ pageContext.request.contextPath }/share/javascript/Oscar.js"></script>

<title><bean:message key="SelectPharmacy.title" /></title>

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

<%
oscar.oscarRx.pageUtil.RxSessionBean bean = (oscar.oscarRx.pageUtil.RxSessionBean)pageContext.findAttribute("bean");
%>

<bean:define id="patient"
	type="oscar.oscarRx.data.RxPatientData.Patient" name="Patient" />

<link rel="stylesheet" href="${ pageContext.request.contextPath }/oscarRx/styles.css">



<style>
#preferredList div {
    margin: 0 !important;
    border: none !important;
}

.status-active {
    display: block;
    width: 40px !important;
    background-color: green !important;
    color: white;
    padding: 5px 10px;
    border-radius: 5px;
    font-size: small;
    font-weight: bold;
}

.status-inactive {
    display: block;
    width: 40px !important;
    background-color: red !important;
    color: white;
    padding: 5px 10px;
    border-radius: 5px;
    font-size: small;
    font-weight: bold;
}


.preferred-pharmacy {
    background-color: #FDFEC7;
    padding: 10px;
    margin-bottom: 15px;
    border: 1px solid #CCCCCC;
    width: 30%; 
    display: inline-block; 
    vertical-align: top;
}

#preferredList {
    width: 100%; 
}


.search-section {
    width: 45%; 
    display: inline-block; 
    vertical-align: top;
    text-align: center; 
}

.search-fields {
    display: flex;
    flex-wrap: wrap;
    gap: 5px;
    justify-content: flex-start;
    align-items: center;
}

.search-fields input, 
.ControlPushButton {
    width: 120px;
    padding: 8px;
    border: 1px solid #CCCCCC;
    border-radius: 4px;
    margin-bottom: 5px;
}

.search-heading {
    font-size: 16px;
    font-weight: bold;
    margin-bottom: 10px;
    text-align: center; 
}

.ControlPushButton {
    background-color: #00008B;
    color: white;
    text-align: center;
    text-decoration: none;
    display: inline-block;
    cursor: pointer;
}

.ControlPushButton:hover {
    background-color: #000099; 
}

.search-section,
.preferred-pharmacy {
    margin-right: 2%; 
}

th {
    font-size: 14px;
    text-align: left;
    padding: 8px;
    border-bottom: 2px solid #CCCCCC;
}

#pharmacyList {
    width: 100%;
    border-collapse: collapse;
}

#pharmacyList td, #pharmacyList th {
    padding: 8px;
    text-align: left;
    vertical-align: top;
    border-bottom: 1px solid #CCCCCC;
    font-size: 14px;
}

#pharmacyList tr:nth-child(even) {
    background-color: #f9f9f9;
}

#pharmacyList tr:hover {
    background-color: #f1f1f1;
}

.DivCCBreadCrumbs a {
    color: black;
    text-decoration: none;
    margin-left: 5px;
    margin-right: 5px;
}

.DivCCBreadCrumbs a:hover {
    text-decoration: underline;
}

@media (max-width: 768px) {
    .preferred-pharmacy,
    .search-section {
        width: 100%;
        text-align: center;
    }

    .search-fields {
        flex-direction: column;
        align-items: flex-start;
    }

    .search-fields input {
        width: 100%;
    }

    .ControlPushButton {
        width: 100%;
    }
}
</style>

<script>
  function updatePharmacyList() {
    if (confirm('<bean:message key="SelectPharmacy.confirmUpdate" />')) {
        $.ajax({
            url: '<%=request.getContextPath()%>/oscarRx/SelectPharmacy2.jsp?action=update',
            method: 'GET',
            success: function(response) {
                alert('<bean:message key="SelectPharmacy.updateSuccess" />');
                window.location.reload();
            },
            error: function() {
                alert('<bean:message key="SelectPharmacy.updateError" />');
            }
        });
    }
}

( function($) {
	$(function() {
		var demo = $("#demographicNo").val();
		$.get("<%=request.getContextPath() + "/oscarRx/managePharmacy.do?method=getPharmacyFromDemographic&demographicNo="%>"+demo,
			function( data ) {
                if(data && data.length && data.length > 0){
					$("#preferredList").html("");
					var json;
					var preferredPharmacyInfo;
					for( var idx = 0; idx < data.length; ++idx  ) {
						preferredPharmacyInfo = data[idx];
						json = JSON.stringify(preferredPharmacyInfo);

						
    // Determine status and CSS class
            var statusText = preferredPharmacyInfo.status === "1" ? "Active" : "Inactive";
            var statusClass = preferredPharmacyInfo.status === "1" ? "status-active" : "status-inactive";


 // Build pharmacy details
                        var pharm = "<div prefOrder='" + idx + "' pharmId='" + preferredPharmacyInfo.id + "' style='border: none; margin: 0; font-size: small;'><table><tr>";
                        pharm += "<td rowspan='3' style='font-size: small;'>";
                        pharm += "<div style='white-space: nowrap; font-size: 18px; font-weight: bold;'>" + preferredPharmacyInfo.name + "</div>"; // Pharmacy name with nowrap
                        pharm += "<div class='" + statusClass + "' style='font-weight: normal;'>" + statusText + "</div>"; // Status badge below name
                        pharm += preferredPharmacyInfo.address + ", " + preferredPharmacyInfo.city + " " + preferredPharmacyInfo.province + "<br />";
                        pharm += preferredPharmacyInfo.postalCode + "<br />";
                        pharm += "Phone: " + preferredPharmacyInfo.phone1 + "<br />";
                        pharm += "Fax: " + preferredPharmacyInfo.fax + "<br />";
                        // pharm += "<a href='#'  onclick='viewPharmacy(" + preferredPharmacyInfo.id + ");'>View Details</a>" + "</td>";
                        pharm += "</tr></table></div>";


						$("#preferredList").append(pharm);
					}

					$(".prefUnlink").on( "click", function(){
						  var data = "pharmacyId=" + $(this).closest("div").attr("pharmId") + "&demographicNo=" + demo;
						  $.post("<%=request.getContextPath()%>/oscarRx/managePharmacy.do?method=unlink",
							  data, function( data ) {
								if( data.id ) {
									window.location.reload(false);
								}
								else {
									alert("Unable to unlink pharmacy");
								}
							}, "json");
					  });

					$(".prefUp").on( "click", function(){
						if($(this).closest("div").prev() != null){
							var $curr = $(this).closest("div");
							var $prev = $(this).closest("div").prev();

							var data = "pharmId=" + $curr.attr("pharmId") + "&demographicNo=" + demo + "&preferredOrder=" + (parseInt($curr.attr("prefOrder")) - 1);
							$.post("<%=request.getContextPath()%>/oscarRx/managePharmacy.do?method=setPreferred",
							  data, function( data2 ) {
									if( data2.id ) {
										data = "pharmId=" + $prev.attr("pharmId") + "&demographicNo=" + demo + "&preferredOrder=" + (parseInt($prev.attr("prefOrder")) + 1);
										$.post("<%=request.getContextPath()%>/oscarRx/managePharmacy.do?method=setPreferred",
										  data, function( data3 ) {
												if( data3.id ) {
													window.location.reload(false);
												}
										}, "json");
									}
							}, "json");
						}
					  });

					$(".prefDown").on( "click", function(){
						if($(this).closest("div").next() != null){
							var $curr = $(this).closest("div");
							var $next = $(this).closest("div").next();

							var data = "pharmId=" + $curr.attr("pharmId") + "&demographicNo=" + demo + "&preferredOrder=" + (parseInt($curr.attr("prefOrder")) + 1);
							$.post("<%=request.getContextPath()%>/oscarRx/managePharmacy.do?method=setPreferred",
							  data, function( data2 ) {
									if( data2.id ) {
										data = "pharmId=" + $next.attr("pharmId") + "&demographicNo=" + demo + "&preferredOrder=" + (parseInt($next.attr("prefOrder")) - 1);
										$.post("<%=request.getContextPath()%>/oscarRx/managePharmacy.do?method=setPreferred",
										  data, function( data3 ) {
												if( data3.id ) {
													window.location.reload(false);
												}
										}, "json");
									}
							}, "json");
						}
					  });
				}
		}, "json");

		var pharmacyNameKey = new RegExp($("#pharmacySearch").val(), "i");
		var pharmacyCityKey = new RegExp($("#pharmacyCitySearch").val(), "i");
		var pharmacyPostalCodeKey =  new RegExp($("#pharmacyPostalCodeSearch").val(), "i");
		var pharmacyFaxKey = new RegExp($("#pharmacyFaxSearch").val(), "i");
		var pharmacyPhoneKey = new RegExp($("#pharmacyPhoneSearch").val(), "i");
		var pharmacyAddressKey =  new RegExp($("#pharmacyAddressSearch").val(), "i");

		$("#pharmacySearch").on( "keyup", function(){
			updateSearchKeys();
		  $(".pharmacyItem").hide();
		  $.each($(".pharmacyName"), function( key, value ) {
			if($(value).html().toLowerCase().search(pharmacyNameKey) >= 0){
				if($(value).siblings(".city").html().search(pharmacyCityKey) >= 0){
                    if($(value).siblings(".postalCode").html().search(pharmacyPostalCodeKey) >= 0) {
                        if ($(value).siblings(".fax").html().search(pharmacyFaxKey) >= 0) {
							if ($(value).siblings(".fax").html().search(pharmacyAddressKey) >= 0) {
								$(value).parent().show();
							}
                        }
                    }
				}
			}
		  });
	  });

	  $("#pharmacyCitySearch").on( "keyup", function(){
		  updateSearchKeys();
		  $(".pharmacyItem").hide();
		  $.each($(".city"), function( key, value ) {
			if($(value).html().toLowerCase().search(pharmacyCityKey) >= 0){
				if($(value).siblings(".pharmacyName").html().search(pharmacyNameKey) >= 0){
                    if($(value).siblings(".postalCode").html().search(pharmacyPostalCodeKey) >= 0) {
                        if ($(value).siblings(".fax").html().search(pharmacyFaxKey) >= 0) {
							if ($(value).siblings(".fax").html().search(pharmacyAddressKey) >= 0) {
								$(value).parent().show();
							}
                        }
                    }
				}
			}
		  });
	  });

        $("#pharmacyPostalCodeSearch").on( "keyup", function(){
			updateSearchKeys();
            $(".pharmacyItem").hide();
            $.each($(".postalCode"), function( key, value ) {
                if($(value).html().toLowerCase().search(pharmacyPostalCodeKey) >= 0){
                    if($(value).siblings(".pharmacyName").html().search(pharmacyNameKey) >= 0){
                        if($(value).siblings(".city").html().search(pharmacyCityKey) >= 0){
                            if($(value).siblings(".fax").html().search(pharmacyFaxKey) >= 0){
                                $(value).parent().show();
                            }
                        }
					}
                }
            });
        });

	  $("#pharmacyFaxSearch").on( "keyup", function(){
		  updateSearchKeys();
		  $(".pharmacyItem").hide();
		  $.each($(".fax"), function( key, value ) {
			if($(value).html().search(pharmacyFaxKey) >= 0 || $(value).html().split("-").join("").search(pharmacyFaxKey) >= 0){
				if($(value).siblings(".pharmacyName").html().search(pharmacyNameKey) >= 0) {
					if ($(value).siblings(".city").html().search(pharmacyCityKey) >= 0) {
						if ($(value).siblings(".postalCode").html().search(pharmacyPostalCodeKey) >= 0) {
							$(value).parent().show();
						}
					}
				}
			}
		  });
	  });

        $("#pharmacyPhoneSearch").on( "keyup", function(){
			updateSearchKeys();
            $(".pharmacyItem").hide();
            $.each($(".phone"), function( key, value ) {
                if($(value).html().search(pharmacyPhoneKey) >= 0 || $(value).html().split("-").join("").search(pharmacyPhoneKey) >= 0){
                    if($(value).siblings(".pharmacyName").html().search(pharmacyNameKey) >= 0){
                        if($(value).siblings(".city").html().search(pharmacyCityKey) >= 0){
                            if($(value).siblings(".postalCode").html().search(pharmacyPostalCodeKey) >= 0) {
                                $(value).parent().show();
                            }
                        }
                    }
                }
            });
        });

		$("#pharmacyAddressSearch").on( "keyup", function(){
			updateSearchKeys()
			$(".pharmacyItem").hide();
			$.each($(".address"), function( key, value ) {
				if($(value).html().search(pharmacyAddressKey) >= 0 || $(value).html().split("-").join("").search(pharmacyAddressKey) >= 0){
					if($(value).siblings(".pharmacyName").html().search(pharmacyNameKey) >= 0){
						if($(value).siblings(".city").html().search(pharmacyCityKey) >= 0){
							if($(value).siblings(".postalCode").html().search(pharmacyPostalCodeKey) >= 0) {
								$(value).parent().show();
							}
						}
					}
				}
			});
		});

$(".pharmacyItem").on("click", function() {
  var pharmId = $(this).attr("pharmId");
  var demo = $("#demographicNo").val();

  var data = "pharmId=" + pharmId + "&demographicNo=" + demo;

  $.ajax({
    url: "<%=request.getContextPath()%>/oscarRx/managePharmacy.do?method=setPreferred",
    method: 'POST',
    data: data,
    dataType: 'json',
    success: function(response) {
      if (response.success) {
        // Clear existing preferred pharmacy
        $("#preferredList").empty();

        // Add the new preferred pharmacy
        var newPharmacy = $("<div>").addClass("linkedPrefPharmacy")
                                    .attr("pharmId", pharmId)
                                    .html("Preferred Pharmacy: " + response.pharmacyName + "<br>" +
                                          "Address: " + response.address + "<br>" +
                                          "Phone: " + response.phone);
        $("#preferredList").append(newPharmacy);

        // Update the pharmacy list to reflect the change
        $(".pharmacyItem").removeClass("preferred");
        $(".pharmacyItem[pharmId='" + pharmId + "']").addClass("preferred");

        alert("Preferred pharmacy updated successfully");
      } else {
        alert("Error updating preferred pharmacy: " + (response.message || "Unknown error"));
      }
    },
    error: function() {
      alert("Error communicating with the server");
    }
  });
});

    //    $(".pharmacyItem").on( "click", function(){
	// 	  var pharmId = $(this).attr("pharmId");

	// 	  $("#preferredList div").each(function(){
	// 		  if($(this).attr("pharmId") == pharmId){
	// 			  alert("Selected pharamacy is already selected");
	// 			  return false;
	// 		  }
	// 	  });

	// 	  var data = "pharmId=" + pharmId + "&demographicNo=" + demo + "&preferredOrder=" + $("#preferredList div").length;

	// 	  $.post("<%=request.getContextPath() + "/oscarRx/managePharmacy.do?method=setPreferred"%>", data, function( data ) {
	// 		if( data.id ) {
	// 			window.location.reload(false);
	// 		}
	// 		else {
	// 			alert("There was an error setting your preferred Pharmacy");
	// 		}
	// 	  },"json");
    //   });

	$(".deletePharm").on( "click", function(){
		if( confirm("You are about to remove this pharmacy for all users. Are you sure you want to continue?")) {
			var data = "pharmacyId=" + $(this).closest("tr").attr("pharmId");
			$.post("<%=request.getContextPath()%>/oscarRx/managePharmacy.do?method=delete",
					data, function( data ) {
				if( data.success ) {
					window.location.reload(false);
				}
				else {
					alert("There was an error deleting the Pharmacy");
				}
			},"json");
		}
	});


		function updateSearchKeys() {
			pharmacyNameKey = new RegExp($("#pharmacySearch").val(), "i");
			pharmacyCityKey = new RegExp($("#pharmacyCitySearch").val(), "i");
			pharmacyPostalCodeKey =  new RegExp($("#pharmacyPostalCodeSearch").val(), "i");
			pharmacyFaxKey = new RegExp($("#pharmacyFaxSearch").val(), "i");
			pharmacyPhoneKey = new RegExp($("#pharmacyPhoneSearch").val(), "i");
			pharmacyAddressKey =  new RegExp($("#pharmacyAddressSearch").val(), "i");
		}
})}) ( jQuery );

function activateWindow(arg){
    window.open(arg.href,"_blank","width="+arg.width+",height="+arg.height);
}

function addPharmacy(){
	activateWindow({
		href: "<%= request.getContextPath() %>/oscarRx/ManagePharmacy2.jsp?type=Add",
		width: 450,
		height: 750
	});
}

function editPharmacy(id){
	activateWindow({
		href: "<%= request.getContextPath() %>/oscarRx/ManagePharmacy2.jsp?type=Edit&ID=" + id,
		width: 450,
		height: 750
	});
}

function viewPharmacy(id){
    activateWindow({
        href: "<%= request.getContextPath() %>/oscarRx/ViewPharmacy.jsp?type=View&ID=" + id,
        width: 395,
        height: 450
    });
}



function returnToRx(){
	//var rx_enhance = <%=OscarProperties.getInstance().getProperty("rx_enhance")%>;

	//if(rx_enhance){
	//    opener.window.refresh();
	//    window.close();
	//} else {
        window.location.href="SearchDrug3.jsp";
	//}
}

</script>
</head>
<body>
    <form id="pharmacyForm">
        <input type="hidden" id="demographicNo" name="demographicNo" value="<%=bean.getDemographicNo()%>">

        <!-- Breadcrumbs and Return to Rx Button -->
        <div class="DivCCBreadCrumbs" style="display: flex; justify-content: space-between; align-items: center;">
            <div>
                <a href="SearchDrug3.jsp"> <bean:message key="SearchDrug.title" /></a> >  
                <bean:message key="SelectPharmacy.title" />
            </div>
            <input type="button" class="ControlPushButton" onclick="returnToRx();" value="<bean:message key='SelectPharmacy.ReturnToRx' />">
        </div>
        <hr style="border:1px solid black;">

        <!-- Patient Details and Search Section -->
        <div style="display: flex; justify-content: space-between; align-items: flex-start;">
            <!-- Patient Name and Preferred Pharmacy -->
            <div class="preferred-pharmacy">
                    <div style="font-size: 20px; font-weight: bold;">
                        <b><bean:message key="SearchDrug.nameText" /></b>
                        <jsp:getProperty name="patient" property="surname" />,
                        <jsp:getProperty name="patient" property="firstName" />
                    </div>
                    <div id="preferredList">
                        <bean:message key="SelectPharmacy.noPharmaciesSelected" />
                    </div>
            </div>

            <!-- Search Section -->
            <div class="search-section">
                <div class="search-heading" style="text-align: left;">Search Pharmacy</div>
                <div class="search-fields">
                    <!-- Left Column -->
                    <div>
                        <input placeholder="Pharmacy Name" type="text" id="pharmacySearch">
                        <input placeholder="Postal" type="text" id="pharmacyPostalCodeSearch">
                        <input placeholder="Fax" type="text" id="pharmacyFaxSearch">
                        <%-- <a href="javascript:void(0)" onclick="addPharmacy();" class="ControlPushButton">Add a New Pharmacy</a> --%>
                    </div>
                    <!-- Right Column -->
                    <div>
                        <input placeholder="City" type="text" id="pharmacyCitySearch">
                        <input placeholder="Phone" type="text" id="pharmacyPhoneSearch">
                        <input placeholder="Address" type="text" id="pharmacyAddressSearch">
                        <%-- <a href="javascript:void(0)" onclick="updatePharmacyList();" class="ControlPushButton">Update Pharmacy List</a> --%>
                        <a href="javascript:void(0)" onclick="updatePharmacyList();" class="ControlPushButton">Update Pharmacy List</a>
                    </div>
                </div>
            </div>
        </div>

        <!-- Help and About Links -->
        <div style="text-align: right; margin-bottom: 10px;">
            <a style="color:black;" href="<%=help_url%>pharmacies/" target="_blank">Help</a> |
            <a style="color:black;" href="<%=request.getContextPath() %>/oscarEncounter/About.jsp" target="_blank">About</a>
        </div>

        <!-- Instruction Text -->
        <div style="padding: 4px; background-color: #FDFEC7; font-size: 12px; text-align: center; border: 1px solid #CCCCCC; margin-bottom: 10px;">
            <bean:message key="SelectPharmacy.instructions" />
        </div>

        <!-- Pharmacy List -->
        <div style="width: 100%; height: 560px; overflow: auto;">
          <table id="pharmacyList" style="width: 100%; border-collapse: collapse;">
    <thead style="background-color: #f1f1f1; border: 1px solid #e1e1e1;">
        <tr>
            <th style="width: 20%;">Pharmacy Name</th>
            <th style="width: 20%;">Address</th>
            <th style="width: 10%;">City</th>
            <th style="width: 10%;">Postal</th>
            <th style="width: 15%;">Phone</th>
            <th style="width: 15%;">Fax</th>
            <th style="width: 10%;">Distance</th>
        </tr>
    </thead>
    <tbody></tbody>
</table>
        </div>
    </form>

      <% 
        // Fetch the demographicNo from the bean
        int demographicNumber = bean.getDemographicNo();

        // Create an instance of DemographicDAO
        DemographicDao demographicDao = new DemographicDao();

        // Call the method to fetch demographic details
        Demographic demographic = demographicDao.getDemographicDetails(demographicNumber);

        // Check if the demographic details were fetched
        if (demographic != null) {
            System.out.println("Fetched Demographic address Details: " + demographic.getAddress() + ", " + demographic.getCity() + ", " + demographic.getProvince() + ", " + demographic.getPostal());
        } else {
            System.out.println("No demographic details found for demographicNo: " + demographicNumber);
        }
    %>
    

<script>
    document.addEventListener('DOMContentLoaded', function() {
        <% if (demographic != null) { %>
            // Construct the full address using demographic details
            const fullAddress = "<%= demographic.getAddress() %>, <%= demographic.getCity() %>, <%= demographic.getProvince() %>, <%= demographic.getPostal() %>";
            console.log('[Debug] Automatically triggering geocoding for address:', fullAddress);

            // Call the triggerGeocoding function
            triggerGeocoding(fullAddress);
        <% } else { %>
            console.error('[Debug] Demographic details are null. Cannot trigger geocoding.');
        <% } %>
    });


    function triggerGeocoding(fullAddress) {
    console.log('[Debug] Triggering geocoding for address: ' + fullAddress);

    var cleanAddress = fullAddress.trim();
    if (!cleanAddress) {
        console.error('[Geocoding Script] Full Address is empty. Falling back to default.');
        fetchPharmaciesSortedByDistance(0, 0); // Fallback
        return;
    }

    var encodedAddress = encodeURIComponent(cleanAddress);
    var apiKey = 'AIzaSyBzuzGR9_XoLdb7nx-L9UdPPmIwZyiSOdM';
    var apiUrl = 'https://maps.googleapis.com/maps/api/geocode/json?address=' + encodedAddress + '&key=' + apiKey;
    
    console.log('[Debug] Geocoding API URL: ' + apiUrl);

    fetch(apiUrl)
        .then(response => {
            if (!response.ok) {
                throw new Error('HTTP Error! Status: ' + response.status);
            }
            return response.json();
        })
        .then(data => {
            if (data.results && data.results.length > 0) {
                var location = data.results[0].geometry.location;
                console.log('[Geocoding Script] Latitude: ' + location.lat + ', Longitude: ' + location.lng);

                // Call pharmacy API with actual lat/lng
                fetchPharmaciesSortedByDistance(location.lat, location.lng);
            } else {
                console.error('[Geocoding Script] No results found for geocoding. Falling back to default.');
                fetchPharmaciesSortedByDistance(0, 0); // Fallback
            }
        })
        .catch(error => {
            console.error('[Geocoding Script] Error during geocoding:', error);
            fetchPharmaciesSortedByDistance(0, 0); // Fallback
        });
}


   function fetchPharmaciesSortedByDistance(lat, lng) {
    if (typeof lat !== "number" || isNaN(lat) || typeof lng !== "number" || isNaN(lng)) {
        console.warn("[Warning] Invalid latitude or longitude. Fetching all pharmacies without sorting.");
        var pharmacyApiUrl = `https://oatrx.ca/api/fetch-all-pharmacies`; // Fallback
    } else {
        console.log("[Info] Fetching pharmacies using coordinates: Lat =", lat, "Lng =", lng);
        var pharmacyApiUrl = 'https://oatrx.ca/api/fetch-all-pharmacies?lat= ' + lat +'&long='+ lng;
    }

    console.log("[Debug] Constructed Pharmacy API URL:", pharmacyApiUrl);

    fetch(pharmacyApiUrl)
        .then(response => {
            if (!response.ok) throw new Error("HTTP Error! Status: " + response.status);
            return response.json();
        })
        .then(data => {
            if (data.success && Array.isArray(data.data) && data.data.length > 0) {
                populatePharmacyTable(data.data);
            } else {
                console.warn("[Warning] No pharmacies found, displaying empty list.");
                document.querySelector("#pharmacyList tbody").innerHTML = `<tr><td colspan="8">No pharmacies found</td></tr>`;
            }
        })
        .catch(error => {
            console.error("[Error] Failed to fetch pharmacies:", error);
            document.querySelector("#pharmacyList tbody").innerHTML = `<tr><td colspan="8">Error fetching pharmacies</td></tr>`;
        });
}


function populatePharmacyTable(pharmacies) {
    const tableBody = document.querySelector("#pharmacyList tbody"); // Select the table body
    if (!tableBody) {
        console.error("[Pharmacy Table Script] Table body not found!");
        return;
    }

    // Clear existing rows
    tableBody.innerHTML = "";

    // Check if pharmacies exist
    if (!pharmacies || pharmacies.length === 0) {
        const noDataRow = `
            <tr>
                <td colspan="7">No pharmacies found</td>
            </tr>
        `;
        tableBody.innerHTML = noDataRow;
        return;
    }

    // Populate table rows
    pharmacies.forEach(pharmacy => {
        // console.log("[Pharmacy Table Script] Pharmacy:", pharmacy);

        const name = String(pharmacy.name || "Unknown Pharmacy").trim();
        const address = String(pharmacy.address || "No Address").trim();
        const city = String(pharmacy.city || "No City").trim();
        const postalCode = String(pharmacy.zip_code || "No Postal Code").trim();
        const phone = String(pharmacy.phone || "No Phone").trim();
        const fax = String(pharmacy.fax || "No Fax").trim();
        const distance = (pharmacy.distance !== undefined && pharmacy.distance !== null && !isNaN(pharmacy.distance))
                            ? String(pharmacy.distance).trim() + ' kms away'
                            : 'Undetermined';


        // const distance = pharmacy.distance !== undefined && !isNaN(pharmacy.distance)
        //     ? `${pharmacy.distance} kms away`
        //     : "Distance undefined";

        const row = 
        '<tr class="pharmacyItem" pharmId="' + pharmacy.id + '">' +
            '<td class="pharmacyName">' + name + '</td>' +
            '<td class="address">' + address + '</td>' +
            '<td class="city">' + city + '</td>' +
            '<td class="postalCode">' + postalCode + '</td>' +
            '<td class="phone">' + phone + '</td>' +
            '<td class="fax">' + fax + '</td>' +
            '<td class="distance">' + distance + '</td>' +
        '</tr>';

        tableBody.insertAdjacentHTML('beforeend', row);

    });

      // Rebind the click event to the newly created rows
    bindPharmacyRowClickEvent();
}

function bindPharmacyRowClickEvent() {
    $(".pharmacyItem").on("click", function() {
        var pharmId = $(this).attr("pharmId");
        var demo = $("#demographicNo").val();

        var data = "pharmId=" + pharmId + "&demographicNo=" + demo;

        $.ajax({
            url: "<%=request.getContextPath()%>/oscarRx/managePharmacy.do?method=setPreferred",
            method: 'POST',
            data: data,
            dataType: 'json',
            success: function(response) {
                if (response.success) {
                    // Update preferred pharmacy UI
                    $("#preferredList").empty();
                    var newPharmacy = $("<div>")
                        .addClass("linkedPrefPharmacy")
                        .attr("pharmId", pharmId)
                        .html(
                            "Preferred Pharmacy: " + response.pharmacyName + "<br>" +
                            "Address: " + response.address + "<br>" +
                            "Phone: " + response.phone
                        );
                    $("#preferredList").append(newPharmacy);

                    // Highlight the preferred pharmacy in the table
                    $(".pharmacyItem").removeClass("preferred");
                    $(".pharmacyItem[pharmId='" + pharmId + "']").addClass("preferred");

                    alert("Preferred pharmacy updated successfully");
                } else {
                    alert("Error updating preferred pharmacy: " + (response.message || "Unknown error"));
                }
            },
            error: function() {
                alert("Error communicating with the server");
            }
        });
    });
}


</script>

</body>

</html:html>