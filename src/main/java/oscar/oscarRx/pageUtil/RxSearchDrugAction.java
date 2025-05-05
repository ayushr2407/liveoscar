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


package oscar.oscarRx.pageUtil;

import java.io.IOException;
import java.io.Writer;
import java.util.Hashtable;
import java.util.Map;
import java.util.Vector;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import net.sf.json.JSONObject;
import net.sf.json.JSONSerializer;

import org.apache.commons.lang.StringUtils;
import org.apache.logging.log4j.Logger;
import org.apache.struts.action.ActionForm;
import org.apache.struts.action.ActionForward;
import org.apache.struts.action.ActionMapping;
import org.apache.struts.actions.DispatchAction;
import org.oscarehr.managers.SecurityInfoManager;
import org.oscarehr.util.LoggedInInfo;
import org.oscarehr.util.MiscUtils;
import org.oscarehr.util.SpringUtils;

import oscar.OscarProperties;
import oscar.oscarRx.data.RxDrugData;
import oscar.oscarRx.util.RxDrugRef;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;
import net.sf.json.JSONArray;

import java.util.HashMap;
import java.util.Map; 

import java.util.HashSet;
import java.util.Set;
import java.net.URLEncoder;
import java.io.UnsupportedEncodingException;




public final class RxSearchDrugAction extends DispatchAction {
	private SecurityInfoManager securityInfoManager = SpringUtils.getBean(SecurityInfoManager.class);

	private RxDrugRef drugref;
	private static Logger logger = MiscUtils.getLogger(); 
	
	public RxSearchDrugAction() {
		this.drugref = new RxDrugRef();
	}
	
    @Override
    public ActionForward unspecified(ActionMapping mapping,
    		ActionForm form,
    		HttpServletRequest request,
    		HttpServletResponse response)
    				throws IOException, ServletException {

		if (!securityInfoManager.hasPrivilege(LoggedInInfo.getLoggedInInfoFromSession(request), "_rx", "r", null)) {
			throw new RuntimeException("missing required security object (_rx)");
		}


    	// Setup variables
    	RxSearchDrugForm reqForm = (RxSearchDrugForm) form;
    	String genericSearch = reqForm.getGenericSearch();
    	String searchString = reqForm.getSearchString();
    	String searchRoute = reqForm.getSearchRoute();
    	if (searchRoute==null) searchRoute = "";

    	RxDrugData drugData = new RxDrugData();             

    	RxDrugData.DrugSearch drugSearch = null;

    	try{
    		if (genericSearch != null ){                    
    			drugSearch = drugData.listDrugFromElement(genericSearch);
    		}
    		else if (!searchRoute.equals("")){
    			drugSearch = drugData.listDrugByRoute(searchString, searchRoute);
    		} else {
    			drugSearch = drugData.listDrug(searchString);
    		}
    	}catch(Exception connEx){
    		MiscUtils.getLogger().error("Error", connEx);
    	}
    	request.setAttribute("drugSearch", drugSearch);
    	request.setAttribute("demoNo", reqForm.getDemographicNo());

    	return (mapping.findForward("success"));
    }
    
    @SuppressWarnings({ "unused", "rawtypes", "unchecked" })
    public ActionForward searchAllCategories(
    		ActionMapping mapping,
    		ActionForm form,
    		HttpServletRequest request,
    		HttpServletResponse response) {
    	logger.debug("Calling searchAllCategories");
    	Parameter.setParameters( request.getParameterMap() );
    	Vector<Hashtable<String,Object>> results = null;         

    	
    	try {
    		results = drugref.list_drug_element3(Parameter.SEARCH_STRING, wildCardRight(Parameter.WILDCARD));        
    		jsonify(results, response);
    	} catch (IOException e) {
    		logger.error("Exception while attempting to contact DrugRef", e);
    		return mapping.findForward("error");
    	} catch (Exception e) {
    		logger.error("Unknown Error", e);
    		return mapping.findForward("error");
    	} 
    	
    	return null;
    }
    
    @SuppressWarnings({ "unused", "rawtypes", "unchecked" })
    public ActionForward searchBrandName(
    		ActionMapping mapping,
    		ActionForm form,
    		HttpServletRequest request,
    		HttpServletResponse response) {  	
    	logger.debug("Calling searchBrandName");
    	Parameter.setParameters( request.getParameterMap() );
    	Vector catVec = new Vector();
    	catVec.add(RxDrugRef.CAT_BRAND);
    	Vector<Hashtable<String,Object>> results = drugref.list_search_element_select_categories(
    			Parameter.SEARCH_STRING,
    			catVec,
    			wildCardRight(Parameter.WILDCARD));
    	try {
	        jsonify(results, response);
        } catch (IOException e) {
        	logger.error("Exception creating JSON Object for " + results, e);
        	return mapping.findForward("error");
        }
    	return null;
    }
    
    @SuppressWarnings({ "unused", "rawtypes", "unchecked" })
    public ActionForward searchGenericName(
    		ActionMapping mapping,
    		ActionForm form,
    		HttpServletRequest request,
    		HttpServletResponse response) {
    	logger.debug("Calling searchGenericName");
    	Parameter.setParameters( request.getParameterMap() );
    	
    	Vector catVec = new Vector();
    	catVec.add(RxDrugRef.CAT_AI_COMPOSITE_GENERIC);
    	Vector<Hashtable<String,Object>> results = drugref.list_search_element_select_categories(
    			Parameter.SEARCH_STRING,
    			catVec,
    			wildCardRight(Parameter.WILDCARD));
    	try {
	        jsonify(results, response);
        } catch (IOException e) {
        	logger.error("Exception creating JSON Object for " + results, e);
        	return mapping.findForward("error");
        }
    	return null;
    }
    
    @SuppressWarnings({ "unused", "unchecked", "rawtypes" })
    public ActionForward searchActiveIngredient(
    		ActionMapping mapping,
    		ActionForm form,
    		HttpServletRequest request,
    		HttpServletResponse response)  {
    	logger.debug("Calling searchActiveIngredient");
    	Parameter.setParameters( request.getParameterMap() );

    	Vector catVec = new Vector();
    	catVec.add(RxDrugRef.CAT_ACTIVE_INGREDIENT);
    	Vector<Hashtable<String,Object>> results = drugref.list_search_element_select_categories(
    			Parameter.SEARCH_STRING, 
        		catVec, 
        		wildCardRight(Parameter.WILDCARD) );
    	try {
	        jsonify(results, response );
        } catch (IOException e) {
        	logger.error("Exception creating JSON Object for " + results, e);
        	return mapping.findForward("error");
        }
    	
    	return null;
    }
    
    @SuppressWarnings({ "unused", "unchecked", "rawtypes" })
    public ActionForward searchNaturalRemedy(
    		ActionMapping mapping,
    		ActionForm form,
    		HttpServletRequest request,
    		HttpServletResponse response)  {
    	
    	return null;
    }
    

    @SuppressWarnings({ "unchecked", "unused" })
		public ActionForward jsonSearch(
			ActionMapping mapping,
			ActionForm form,
			HttpServletRequest request,
			HttpServletResponse response) {
		
			if (!securityInfoManager.hasPrivilege(LoggedInInfo.getLoggedInInfoFromSession(request), "_rx", "r", null)) {
				throw new RuntimeException("missing required security object (_rx)");
			}
		
			String searchStr = request.getParameter("query");
			if (searchStr == null) {
				searchStr = request.getParameter("name");
			}
			String encodedSearchStr = "";
			try {
				encodedSearchStr = URLEncoder.encode(searchStr, "UTF-8");
			} catch (UnsupportedEncodingException e) {
				System.out.println("Error encoding search string: " + e.getMessage());
				// You can handle this error or throw it again depending on your requirements
				throw new RuntimeException("Unsupported encoding for search string");
			}
			
		
			// System.out.println("User searched for: " + encodedSearchStr);
		
			String apiUrl = "https://oatrx.ca/api/fetch-drug-data?search=" + encodedSearchStr;
			// System.out.println("Fetching drug data from API: " + apiUrl);
		
			Vector<Hashtable<String, Object>> vec = new Vector<>();
		
			try {
				URL url = new URL(apiUrl);
				HttpURLConnection conn = (HttpURLConnection) url.openConnection();
				conn.setRequestMethod("GET");
				conn.setRequestProperty("Accept", "application/json");
		
				if (conn.getResponseCode() != 200) {
					System.out.println("API request failed! HTTP Error Code: " + conn.getResponseCode());
					return mapping.findForward("error");
				}
		
				BufferedReader br = new BufferedReader(new InputStreamReader(conn.getInputStream()));
				StringBuilder jsonResponse = new StringBuilder();
				String line;
				while ((line = br.readLine()) != null) {
					jsonResponse.append(line);
				}
				br.close();
				conn.disconnect();
		
				// System.out.println("API Response received: " + jsonResponse.toString());
		
				JSONObject responseObject = JSONObject.fromObject(jsonResponse.toString());
		
				if (responseObject.getBoolean("success")) {
					JSONArray drugGroups = responseObject.getJSONArray("data");
		
					// Create a map to store dosage info based on group ID
					// Create a set to track added group names to avoid duplicates
					Set<Integer> addedGroups = new HashSet<>();
	Map<Integer, String> groupDosageMap = new HashMap<>();  // Keep this if needed later

	for (int i = 0; i < drugGroups.size(); i++) {
		JSONObject group = drugGroups.getJSONObject(i);
		int groupId = group.getInt("id");  // Get group_id
		JSONArray drugs = group.getJSONArray("drugs");

		// Get group name
		String groupName = group.optString("group_name", "Unknown Group");

		// Check if the group name is already added to avoid duplicates
		if (!addedGroups.contains(groupId)) {
			addedGroups.add(groupId);		

			// Use the first drug's ID and DIN for unique identification
			if (drugs.size() > 0) {
				JSONObject firstDrug = drugs.getJSONObject(0);
				int firstDrugId = firstDrug.getInt("id");
				String firstDrugDin = firstDrug.getString("din");

// Create a list of active ingredients with strength and unit
JSONArray activeIngredients = group.optJSONArray("active_ingredients");
StringBuilder activeIngredientsList = new StringBuilder();

// Check if active ingredients are present
if (activeIngredients != null && activeIngredients.size() > 0) {
    // Loop through all active ingredients and append them
    for (int j = 0; j < activeIngredients.size(); j++) {  
        JSONObject ingredient = activeIngredients.getJSONObject(j);
        String ingredientName = ingredient.optString("ingredient_name", "Unknown Ingredient");
        String strength = ingredient.optString("strength", "").trim();
        String strengthUnit = ingredient.optString("strength_unit", "").trim();

        if (j > 0) {
            activeIngredientsList.append(", ");  // Add separator for multiple ingredients
        }

        // Append ingredient with strength and unit if available
        if (!strength.isEmpty() && !strengthUnit.isEmpty()) {
            activeIngredientsList.append(ingredientName).append(" (").append(strength).append(" ").append(strengthUnit).append(")");
        } else {
            activeIngredientsList.append(ingredientName);  // No strength or unit available
        }
    }
}

// Debug: Check the list of active ingredients
// System.out.println("Active Ingredients List: " + activeIngredientsList.toString());

// Create display name with group name first
String displayName = groupName;  // Start with group name

// Store active ingredients in a separate variable (this is now independent of displayName)
String activeIngredientsText = "";
if (activeIngredientsList.length() > 0) {
    activeIngredientsText = "<span class='ingredient'>" + activeIngredientsList.toString() + "</span>";
}

// Debug: Check the final active ingredients text
// System.out.println("Active Ingredients Text: " + activeIngredientsText);

// Add active ingredients below the group name in the display name
displayName = groupName + activeIngredientsText.replace("&", "&amp;")
                                               .replace("<", "&lt;")
                                               .replace(">", "&gt;")
                                               .replace("\"", "&quot;")
                                               .replace("'", "&#039;");

//    System.out.println("Adding groupId: " + groupId + ", Name: " + groupName);


	// Create a new hashtable to store group data
	Hashtable<String, Object> groupData = new Hashtable<>();
	groupData.put("id", firstDrugId);        // Use first drug's ID for unique ID
	groupData.put("name", displayName);      // Display group name + active ingredient in dropdown
	groupData.put("din", firstDrugDin);      // Use first drug's DIN for unique ID

	vec.add(groupData);  // Add group data to vector

			}
		}
	}

				} else {
					System.out.println("API returned no results.");
				}
		
				jsonify(vec, response);
		
			} catch (Exception e) {
				System.out.println("Exception while fetching data: " + e.getMessage());
				e.printStackTrace();
				return mapping.findForward("error");
			}
		
			return null;
		}


	
// 	public ActionForward jsonSearch(
//     ActionMapping mapping,
//     ActionForm form,
//     HttpServletRequest request,
//     HttpServletResponse response) {

//     if (!securityInfoManager.hasPrivilege(LoggedInInfo.getLoggedInInfoFromSession(request), "_rx", "r", null)) {
//         throw new RuntimeException("missing required security object (_rx)");
//     }

//     // Capture user input from the search box
//     String searchStr = request.getParameter("query");
//     if (searchStr == null) {
//         searchStr = request.getParameter("name");
//     }

//     System.out.println("User searched for: " + searchStr);

//     // Construct API URL
//     String apiUrl = "https://oatrx.ca/api/fetch-drug-data?search=" + searchStr;
//     System.out.println("Fetching drug data from API: " + apiUrl);

//     Vector<Hashtable<String, Object>> vec = new Vector<>();

//     try {
//         // Make HTTP request
//         URL url = new URL(apiUrl);
//         HttpURLConnection conn = (HttpURLConnection) url.openConnection();
//         conn.setRequestMethod("GET");
//         conn.setRequestProperty("Accept", "application/json");

//         if (conn.getResponseCode() != 200) {
//             System.out.println("API request failed! HTTP Error Code: " + conn.getResponseCode());
//             return mapping.findForward("error");
//         }

//         // Read API response
//         BufferedReader br = new BufferedReader(new InputStreamReader(conn.getInputStream()));
//         StringBuilder jsonResponse = new StringBuilder();
//         String line;
//         while ((line = br.readLine()) != null) {
//             jsonResponse.append(line);
//         }
//         br.close();
//         conn.disconnect();

//         System.out.println("API Response received: " + jsonResponse.toString());

//         // Parse JSON response
//         JSONObject responseObject = JSONObject.fromObject(jsonResponse.toString());

//         if (responseObject.getBoolean("success")) {
//             JSONArray drugGroups = responseObject.getJSONArray("data");

//             for (int i = 0; i < drugGroups.size(); i++) {
//                 JSONObject group = drugGroups.getJSONObject(i);
//                 JSONArray drugs = group.getJSONArray("drugs");

//                 for (int j = 0; j < drugs.size(); j++) {
//                     JSONObject drug = drugs.getJSONObject(j);
//                     Hashtable<String, Object> drugData = new Hashtable<>();

//                     drugData.put("id", drug.getInt("id"));
//                     drugData.put("name", drug.getString("name"));
//                     drugData.put("din", drug.getString("din"));

//                     vec.add(drugData);
//                     System.out.println("   - Drug: " + drug.getString("name") + ", ID: " + drug.getInt("id") + ", DIN: " + drug.getString("din"));
//                 }
//             }
//         } else {
//             System.out.println("API returned no results.");
//         }

//         jsonify(vec, response);

//     } catch (Exception e) {
//         System.out.println("Exception while fetching data: " + e.getMessage());
//         e.printStackTrace();
//         return mapping.findForward("error");
//     }

//     return null;
// }

//////////////////////////////////////////////


//     public ActionForward jsonSearch(
//     ActionMapping mapping,
//     ActionForm form,
//     HttpServletRequest request,
//     HttpServletResponse response) {

//     if (!securityInfoManager.hasPrivilege(LoggedInInfo.getLoggedInInfoFromSession(request), "_rx", "r", null)) {
//         throw new RuntimeException("missing required security object (_rx)");
//     }

//     // Capture user input from the search box
//     String searchStr = request.getParameter("query");
//     if (searchStr == null) {
//         searchStr = request.getParameter("name");
//     }

//     System.out.println("User searched for: " + searchStr);

//     String wildcardRightOnly = OscarProperties.getInstance().getProperty("rx.search_right_wildcard_only", "false");                      
//     Vector<Hashtable<String, Object>> vec = null;

//     try {
//         // Send search query to DrugRef
//         System.out.println("Sending search query to DrugRef: " + searchStr + ", WildcardRightOnly: " + wildcardRightOnly);
//         vec = drugref.list_drug_element3(searchStr, wildCardRight(wildcardRightOnly));

//         // Print returned drug list
//         System.out.println("Drug search results received:");
//         if (vec != null && !vec.isEmpty()) {
//             for (Hashtable<String, Object> drug : vec) {
//                 System.out.println("   - Drug: " + drug.get("name") + ", ID: " + drug.get("id"));
//             }
//         } else {
//             System.out.println("No results found.");
//         }

//         jsonify(vec, response);
//     } catch (IOException e) {
//         System.out.println("Exception while attempting to contact DrugRef: " + e.getMessage());
//         e.printStackTrace();
//         return mapping.findForward("error");
//     } catch (Exception e) {
//         System.out.println("Unknown Error: " + e.getMessage());
//         e.printStackTrace();
//         return mapping.findForward("error");
//     }

//     return null;
// }


    /**
     * Utilty methods - should be split into a class if they get any bigger.
     */
    
    private static final boolean wildCardRight(final String wildcard) {   	
    	if(!StringUtils.isBlank(wildcard)) {
    		return Boolean.valueOf(wildcard);
    	}
    	return Boolean.FALSE;
    }
    
    private static void jsonify(final Vector<Hashtable<String,Object>> data, 
    		final HttpServletResponse response) throws IOException {
    	 
		Hashtable<String, Vector<Hashtable<String,Object>>> d = new Hashtable<String, Vector<Hashtable<String,Object>>>();
		d.put("results", data);
		response.setContentType("text/x-json");
		
		JSONObject jsonArray = (JSONObject) JSONSerializer.toJSON( d );
		Writer jsonWriter = jsonArray.write( response.getWriter() );
		
		jsonWriter.flush();
		jsonWriter.close();
		         
    }
    
    private static class Parameter {
    	
    	//public static String DRUG_STATUS;
    	public static String WILDCARD;
    	public static String SEARCH_STRING;
    	
    	private static void reset() {
    		//DRUG_STATUS = ""; 
        	WILDCARD = "";
        	SEARCH_STRING = "";
    	}

    	public static void setParameters(Map<String, String[]> parameters) {
    		reset();
    		
//    		if(parameters.containsKey("drugStatus")) {
//    			Parameter.DRUG_STATUS = parameters.get("drugStatus")[0];
//    		}
    		
    		if(parameters.containsKey("wildcard")) {
    			Parameter.WILDCARD = parameters.get("wildcard")[0];
    		}
    		
    		if(parameters.containsKey("searchString")) {
    			Parameter.SEARCH_STRING = parameters.get("searchString")[0];
    		}
    		
    	}
    	 
    }


}
