/**
 * Copyright (c) 2001-2002. Department of Family Medicine, McMaster University. All Rights Reserved.
 * This software is published under the GPL GNU General Public License.
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version. 
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 *
 * This software was written for the
 * Department of Family Medicine
 * McMaster University
 * Hamilton
 * Ontario, Canada
 */


/*
 * RxManagePharmacyAction.java
 *
 * Created on September 29, 2004, 3:20 PM
 */

package oscar.oscarRx.pageUtil;

import java.io.IOException;
import java.util.HashMap;
import java.util.List;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import net.sf.json.JSONObject;

import org.apache.struts.action.ActionForm;
import org.apache.struts.action.ActionForward;
import org.apache.struts.action.ActionMapping;
import org.apache.struts.actions.DispatchAction;
import org.codehaus.jackson.map.ObjectMapper;
import org.oscarehr.common.model.PharmacyInfo;
import org.oscarehr.managers.PharmacyManager;
import org.oscarehr.util.LoggedInInfo;
import org.oscarehr.util.MiscUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.ApplicationContext;
import org.springframework.stereotype.Component;
import org.springframework.web.context.support.WebApplicationContextUtils;

import oscar.log.LogAction;
import oscar.log.LogConst;
import oscar.oscarRx.data.RxPharmacyData;
import java.util.Map;


/**
 *
 * @author  Jay Gallagher & Jackson Bi
 */
// @Component("rxManagePharmacyAction") // Specify the name of the Spring-managed bean
public final class RxManagePharmacyAction extends DispatchAction {

	// Add this as a field in RxManagePharmacyAction
@Autowired
private PharmacyManager pharmacyManager;


// public ActionForward fetchSortedPharmacies(ActionMapping mapping, ActionForm form, HttpServletRequest request, HttpServletResponse response) {
// 	System.out.println("fetchSortedPharmacies method triggered.");
// 	System.out.println("PharmacyManager instance: " + pharmacyManager); // Log the PharmacyManager instance

// 	try {
// 		String latParam = request.getParameter("lat");
// 		String lngParam = request.getParameter("lng");

// 		System.out.println("Latitude parameter: " + latParam);
// 		System.out.println("Longitude parameter: " + lngParam);

// 		if (latParam == null || lngParam == null) {
// 			response.setContentType("application/json");
// 			response.getWriter().write("{\"success\":false,\"message\":\"Latitude and Longitude are required.\"}");
// 			return null;
// 		}

// 		double lat = Double.parseDouble(latParam);
// 		double lng = Double.parseDouble(lngParam);

// 		System.out.println("Parsed Latitude: " + lat);
// 		System.out.println("Parsed Longitude: " + lng);

// 		// Confirm that PharmacyManager is non-null before using it
// 		if (pharmacyManager == null) {
// 			System.err.println("PharmacyManager is null! Dependency injection failed.");
// 			throw new NullPointerException("PharmacyManager is null.");
// 		}

// 		List<PharmacyInfo> sortedPharmacies = pharmacyManager.getPharmaciesSortedByDistance(null, lat, lng);

// 		System.out.println("Pharmacies found: " + sortedPharmacies.size());
// 		response.setContentType("application/json");
// 		new ObjectMapper().writeValue(response.getWriter(), sortedPharmacies);
// 	} catch (Exception e) {
// 		e.printStackTrace();
// 		try {
// 			response.setContentType("application/json");
// 			response.getWriter().write("{\"success\":false,\"message\":\"An error occurred: " + e.getMessage() + "\"}");
// 		} catch (IOException ioException) {
// 			ioException.printStackTrace();
// 		}
// 	}
// 	return null;
// }



    public ActionForward unspecified(ActionMapping mapping,
				 ActionForm form,
				 HttpServletRequest request,
				 HttpServletResponse response)
	throws IOException, ServletException {

           RxManagePharmacyForm frm = (RxManagePharmacyForm) form;

           String actionType = frm.getPharmacyAction();
           RxPharmacyData pharmacy = new RxPharmacyData();

           if(actionType.equals("Add")){
              pharmacy.addPharmacy(frm.getName(), frm.getAddress(), frm.getCity(), frm.getProvince(), frm.getPostalCode(), frm.getPhone1(), frm.getPhone2(), frm.getFax(), frm.getEmail(),frm.getServiceLocationIdentifier(), frm.getNotes());
           }else if(actionType.equals("Edit")){
              pharmacy.updatePharmacy(frm.getID(),frm.getName(), frm.getAddress(), frm.getCity(), frm.getProvince(), frm.getPostalCode(), frm.getPhone1(), frm.getPhone2(), frm.getFax(), frm.getEmail(), frm.getServiceLocationIdentifier(), frm.getNotes());
           }else if(actionType.equals("Delete")){
              pharmacy.deletePharmacy(frm.getID());
           }

       return mapping.findForward("success");
    }
    
 public ActionForward delete(ActionMapping mapping, ActionForm form, HttpServletRequest request, HttpServletResponse response) throws IOException {
    	
	 
	String retVal = "{\"success\":true}";
    try {
    	String pharmacyId = request.getParameter("pharmacyId");
    	
    	RxPharmacyData pharmacy = new RxPharmacyData();
    	pharmacy.deletePharmacy(pharmacyId);
    	
    	LoggedInInfo loggedInfo = LoggedInInfo.getLoggedInInfoFromSession(request);
    	
    	LogAction.addLog(loggedInfo.getLoggedInProviderNo(), LogConst.DELETE, LogConst.CON_PHARMACY, pharmacyId);
    }
    catch( Exception e) {
    	MiscUtils.getLogger().error("CANNOT DELETE PHARMACY ",e);
    	retVal = "{\"success\":false}";
    }
    
    response.setContentType("text/x-json");
    JSONObject jsonObject = JSONObject.fromObject(retVal);
    jsonObject.write(response.getWriter());
    
    return null;
 }
    
    public ActionForward unlink(ActionMapping mapping, ActionForm form, HttpServletRequest request, HttpServletResponse response) {
    	
    	try {
    		String pharmId = request.getParameter("pharmacyId");
    		String demographicNo = request.getParameter("demographicNo");
    		
    		ObjectMapper mapper = new ObjectMapper();
    		RxPharmacyData pharmacy = new RxPharmacyData();
    		
    		pharmacy.unlinkPharmacy(pharmId, demographicNo);
    		
    		response.setContentType("text/x-json");
    		String retVal = "{\"id\":\"" + pharmId  + "\"}";
    		JSONObject jsonObject = JSONObject.fromObject(retVal);
    		jsonObject.write(response.getWriter());
    	}
    	catch( Exception e ) {
    		MiscUtils.getLogger().error("CANNOT UNLINK PHARMACY",e);
    	}
    	
    	return null;
    }
    
    // public ActionForward getPharmacyFromDemographic(ActionMapping mapping, ActionForm form, HttpServletRequest request, HttpServletResponse response) throws IOException {
    	
    // 	String demographicNo = request.getParameter("demographicNo");
    	
    // 	RxPharmacyData pharmacyData = new RxPharmacyData();
    //     List<PharmacyInfo> pharmacyList;
    //     pharmacyList = pharmacyData.getPharmacyFromDemographic(demographicNo);
        
    //     response.setContentType("text/x-json");
    //     ObjectMapper mapper = new ObjectMapper();
    //     mapper.writeValue(response.getWriter(), pharmacyList);
        
    // 	return null;
    // }


	public ActionForward getPharmacyFromDemographic(ActionMapping mapping, ActionForm form, HttpServletRequest request, HttpServletResponse response) throws IOException {
		// Step 1: Get demographic number from request
		String demographicNo = request.getParameter("demographicNo");
	
		// Step 2: Fetch pharmacy data for the demographic
		RxPharmacyData pharmacyData = new RxPharmacyData();
		List<PharmacyInfo> pharmacyList = pharmacyData.getPharmacyFromDemographic(demographicNo);
	
		// Step 3: Convert the pharmacy list to JSON
		response.setContentType("text/x-json");
		ObjectMapper mapper = new ObjectMapper();
		String jsonResponse = mapper.writeValueAsString(pharmacyList); // Convert list to JSON string
			
		// Step 5: Write the JSON response to the client
		response.getWriter().write(jsonResponse);
	
		return null;
	}
	
    
	public ActionForward setPreferred(ActionMapping mapping, ActionForm form, HttpServletRequest request, HttpServletResponse response) {
		RxPharmacyData pharmacy = new RxPharmacyData();
		try {
			String pharmId = request.getParameter("pharmId");
			String demographicNo = request.getParameter("demographicNo");
			
			PharmacyInfo pharmacyInfo = pharmacy.addPharmacyToDemographic(pharmId, demographicNo, "1");
			
			Map<String, Object> result = new HashMap<>();
			result.put("success", true);
			result.put("id", pharmacyInfo.getId());
			result.put("pharmacyName", pharmacyInfo.getName());
			result.put("address", pharmacyInfo.getAddress());
			result.put("phone", pharmacyInfo.getPhone1());
			
			ObjectMapper mapper = new ObjectMapper();
			response.setContentType("application/json");
			mapper.writeValue(response.getWriter(), result);
		}
		catch( Exception e ) {
			MiscUtils.getLogger().error("ERROR SETTING PREFERRED PHARMACY", e);
			try {
				response.setContentType("application/json");
				response.getWriter().write("{\"success\":false,\"message\":\"" + e.getMessage() + "\"}");
			} catch (IOException ioException) {
				MiscUtils.getLogger().error("Error writing error response", ioException);
			}
		}
		
		return null;
	}
    public ActionForward add(ActionMapping mapping, ActionForm form, HttpServletRequest request, HttpServletResponse response) {
    	RxPharmacyData pharmacy = new RxPharmacyData();
    	
    	String status = "{\"success\":true}";
    	
    	try {
    		pharmacy.addPharmacy(request.getParameter("pharmacyName"), request.getParameter("pharmacyAddress"), request.getParameter("pharmacyCity"), 
    			request.getParameter("pharmacyProvince"), request.getParameter("pharmacyPostalCode"), request.getParameter("pharmacyPhone1"), request.getParameter("pharmacyPhone2"), 
    			request.getParameter("pharmacyFax"), request.getParameter("pharmacyEmail"), request.getParameter("pharmacyServiceLocationId"), request.getParameter("pharmacyNotes"));
    	}
    	catch( Exception e ) {
    		MiscUtils.getLogger().error("Error Updating Pharmacy " + request.getParameter("pharmacyId"), e);
    		status = "{\"success\":false}";    		
    	}
    	
    	JSONObject jsonObject = JSONObject.fromObject(status);
    	
    	try {
    		response.setContentType("text/x-json");
    		jsonObject.write(response.getWriter());
    	}
    	catch( IOException e ) {
    		MiscUtils.getLogger().error("Cannot write response", e);    		
    	}
    	
    	return null;
    }
    
    public ActionForward save(ActionMapping mapping, ActionForm form, HttpServletRequest request, HttpServletResponse response) {
    	
    	
    	RxPharmacyData pharmacy = new RxPharmacyData();
    	PharmacyInfo pharmacyInfo = new PharmacyInfo();
    	pharmacyInfo.setId(Integer.parseInt(request.getParameter("pharmacyId")));
    	pharmacyInfo.setName(request.getParameter("pharmacyName"));
    	pharmacyInfo.setAddress(request.getParameter("pharmacyAddress"));
    	pharmacyInfo.setCity(request.getParameter("pharmacyCity"));
    	pharmacyInfo.setProvince(request.getParameter("pharmacyProvince"));
    	pharmacyInfo.setPostalCode(request.getParameter("pharmacyPostalCode"));
    	pharmacyInfo.setPhone1(request.getParameter("pharmacyPhone1"));
    	pharmacyInfo.setPhone2(request.getParameter("pharmacyPhone2"));
    	pharmacyInfo.setFax(request.getParameter("pharmacyFax"));
    	pharmacyInfo.setEmail(request.getParameter("pharmacyEmail"));
    	pharmacyInfo.setServiceLocationIdentifier(request.getParameter("pharmacyServiceLocationId"));
    	pharmacyInfo.setNotes(request.getParameter("pharmacyNotes"));
    	
    	try {
    		pharmacy.updatePharmacy(request.getParameter("pharmacyId"),request.getParameter("pharmacyName"), request.getParameter("pharmacyAddress"), request.getParameter("pharmacyCity"), 
    			request.getParameter("pharmacyProvince"), request.getParameter("pharmacyPostalCode"), request.getParameter("pharmacyPhone1"), request.getParameter("pharmacyPhone2"), 
    			request.getParameter("pharmacyFax"), request.getParameter("pharmacyEmail"), request.getParameter("pharmacyServiceLocationId"), request.getParameter("pharmacyNotes"));
    	}
    	catch( Exception e ) {
    		MiscUtils.getLogger().error("Error Updating Pharmacy " + request.getParameter("pharmacyId"), e);
    		return null;
    	}
    	
    	try {
    		response.setContentType("text/x-json");
    		ObjectMapper mapper = new ObjectMapper();
    		mapper.writeValue(response.getWriter(), pharmacyInfo);    		
    		
    	}
    	catch( IOException e ) {
    		MiscUtils.getLogger().error("Error writing response",e);
    	}
    	
    	return null;
    }
    
    public ActionForward search(ActionMapping mapping, ActionForm form, HttpServletRequest request, HttpServletResponse response) {
    	
    	String searchStr = request.getParameter("term");    	
    	
    	RxPharmacyData pharmacy = new RxPharmacyData();
    	
    	List<PharmacyInfo>pharmacyList = pharmacy.searchPharmacy(searchStr);
    	
    	response.setContentType("text/x-json");
    	ObjectMapper mapper = new ObjectMapper();
    	
    	try {
    		mapper.writeValue(response.getWriter(), pharmacyList);
    	}
    	catch( IOException e ) {
    		MiscUtils.getLogger().error("ERROR WRITING RESPONSE ",e);
    	}
    	
    	return null;
    	
    }
    
    public ActionForward searchCity(ActionMapping mapping, ActionForm form, HttpServletRequest request, HttpServletResponse response) {
    	
    	String searchStr = request.getParameter("term");    	
    	
    	RxPharmacyData pharmacy = new RxPharmacyData();
    	
    	response.setContentType("text/x-json");
    	ObjectMapper mapper = new ObjectMapper();
    	
    	List<String> cityList = pharmacy.searchPharmacyCity(searchStr);
    	
    	try {    		
    		mapper.writeValue(response.getWriter(), cityList);
    	}
    	catch( IOException e ) {
    		MiscUtils.getLogger().error("ERROR WRITING RESPONSE ",e);
    	}
    	
    	return null;
    }

    public ActionForward getPharmacyInfo(ActionMapping mapping, ActionForm form, HttpServletRequest request, HttpServletResponse response) throws IOException {
        String pharmacyId=request.getParameter("pharmacyId");
        MiscUtils.getLogger().debug("pharmacyId="+pharmacyId);
        if(pharmacyId==null) return null;
        RxPharmacyData pharmacyData = new RxPharmacyData();
        PharmacyInfo pharmacy=pharmacyData.getPharmacy(pharmacyId);
        HashMap<String,String> hm=new HashMap<String,String>();
       if(pharmacy!=null){
           hm.put("address", pharmacy.getAddress());
            hm.put("city", pharmacy.getCity());
            hm.put("email", pharmacy.getEmail());
            hm.put("fax", pharmacy.getFax());
            hm.put("name", pharmacy.getName());
            hm.put("phone1", pharmacy.getPhone1());
            hm.put("phone2", pharmacy.getPhone2());
            hm.put("postalCode", pharmacy.getPostalCode());
            hm.put("province", pharmacy.getProvince());
            hm.put("serviceLocationIdentifier", pharmacy.getServiceLocationIdentifier());
            hm.put("notes", pharmacy.getNotes());
            JSONObject jsonObject = JSONObject.fromObject(hm);
            response.getOutputStream().write(jsonObject.toString().getBytes());
       }
        return null;
    }

}
