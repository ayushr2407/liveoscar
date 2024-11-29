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

 package org.oscarehr.fax.admin;

 import net.sf.json.JSONArray;
 import java.io.IOException;
 import javax.servlet.http.HttpServletRequest;
 import javax.servlet.http.HttpServletResponse;
 
 import net.sf.json.JSONObject;
 
 import org.apache.struts.action.ActionForm;
 import org.apache.struts.action.ActionForward;
 import org.apache.struts.action.ActionMapping;
 import org.apache.struts.actions.DispatchAction;
 import org.oscarehr.common.dao.FaxConfigDao;
 import org.oscarehr.common.model.FaxConfig;
 import org.oscarehr.util.SpringUtils;
 import java.util.List;

 public class ConfigureFaxAction extends DispatchAction {
 
    public ActionForward configure(ActionMapping mapping, ActionForm form, HttpServletRequest request, HttpServletResponse response) {
        JSONObject jsonObject = new JSONObject();
    
        try {
            String faxUser = request.getParameter("faxUser");
            String faxPasswd = request.getParameter("faxPassword");
            String faxNumber = request.getParameter("faxNumber");
            String senderEmail = request.getParameter("senderEmail");
            boolean isActive = "on".equals(request.getParameter("isActive"));
    
            FaxConfigDao faxConfigDao = SpringUtils.getBean(FaxConfigDao.class);
    
            // If this configuration is set to active, deactivate all other configurations
            if (isActive) {
                List<FaxConfig> allConfigs = faxConfigDao.findAll(null, null);
                for (FaxConfig config : allConfigs) {
                    config.setActive(false);
                    faxConfigDao.merge(config);
                }
            }
    
            // Create a new FaxConfig object
            FaxConfig faxConfig = new FaxConfig();
            faxConfig.setFaxUser(faxUser);
            faxConfig.setFaxPasswd(faxPasswd);
            faxConfig.setFaxNumber(faxNumber);
            faxConfig.setSenderEmail(senderEmail);
            faxConfig.setActive(isActive);
    
            // Set other fields to null
            faxConfig.setUrl(null);
            faxConfig.setSiteUser(null);
            faxConfig.setPasswd(null);
            faxConfig.setQueue(null);
    
            // Save the FaxConfig object to the database
            faxConfigDao.persist(faxConfig);
    
            jsonObject.put("success", true);
            jsonObject.put("message", "Configuration saved successfully. Active status: " + isActive);
        } catch (Exception ex) {
            jsonObject.put("success", false);
            jsonObject.put("error", ex.getMessage());
            ex.printStackTrace();
        }
    
        try {
            response.setContentType("application/json");
            response.getWriter().write(jsonObject.toString());
        } catch (IOException e) {
            e.printStackTrace();
        }
    
        return null;
    }

    public ActionForward getAllConfigurations(ActionMapping mapping, ActionForm form, HttpServletRequest request, HttpServletResponse response) {
        JSONObject jsonObject = new JSONObject();

        try {
            FaxConfigDao faxConfigDao = SpringUtils.getBean(FaxConfigDao.class);
            List<FaxConfig> faxConfigs = faxConfigDao.findAll(null, null);

            JSONArray configArray = new JSONArray();
            for (FaxConfig config : faxConfigs) {
                JSONObject configJson = new JSONObject();
                configJson.put("id", config.getId());
                configJson.put("faxUser", config.getFaxUser());
                configJson.put("faxNumber", config.getFaxNumber());
                configJson.put("senderEmail", config.getSenderEmail());
                configJson.put("active", config.isActive());
                configArray.add(configJson);
            }

            jsonObject.put("success", true);
            jsonObject.put("configurations", configArray);
        } catch (Exception ex) {
            jsonObject.put("success", false);
            jsonObject.put("error", ex.getMessage());
            ex.printStackTrace();
        }

        try {
            response.setContentType("application/json");
            response.getWriter().write(jsonObject.toString());
        } catch (IOException e) {
            e.printStackTrace();
        }

        return null;
    }

    public ActionForward deleteConfiguration(ActionMapping mapping, ActionForm form, HttpServletRequest request, HttpServletResponse response) {
                JSONObject jsonObject = new JSONObject();
        
                try {
                    Integer id = Integer.parseInt(request.getParameter("id"));
                    FaxConfigDao faxConfigDao = SpringUtils.getBean(FaxConfigDao.class);
                    faxConfigDao.remove(id);
        
                    jsonObject.put("success", true);
                } catch (Exception ex) {
                    jsonObject.put("success", false);
                    jsonObject.put("error", ex.getMessage());
                    ex.printStackTrace();
                }
        
                try {
                    response.setContentType("application/json");
                    response.getWriter().write(jsonObject.toString());
                } catch (IOException e) {
                    e.printStackTrace();
                }
        
                return null;
            }
}



//  public class ConfigureFaxAction extends DispatchAction {
 
// 	 public ActionForward configure(ActionMapping mapping, ActionForm form, HttpServletRequest request, HttpServletResponse response) {
// 		 JSONObject jsonObject = new JSONObject();
 
// 		 try {
// 			 // Retrieve parameters from the request
// 			 String faxUser = request.getParameter("faxUser");
// 			 String faxPasswd = request.getParameter("faxPassword");
// 			 String faxNumber = request.getParameter("faxNumber");
// 			 String senderEmail = request.getParameter("senderEmail");
 
// 			 // Create a new FaxConfig object
// 			 FaxConfig faxConfig = new FaxConfig();
// 			 faxConfig.setFaxUser(faxUser);
// 			 faxConfig.setFaxPasswd(faxPasswd);
// 			 faxConfig.setFaxNumber(faxNumber);
// 			 faxConfig.setSenderEmail(senderEmail);
// 			 faxConfig.setActive(true);
 
// 			 // Set other fields to null
// 			 faxConfig.setUrl(null);
// 			 faxConfig.setSiteUser(null);
// 			 faxConfig.setPasswd(null);
// 			 faxConfig.setQueue(null);
 
// 			 // Save the FaxConfig object to the database
// 			 FaxConfigDao faxConfigDao = SpringUtils.getBean(FaxConfigDao.class);
// 			 faxConfigDao.persist(faxConfig);
 
// 			 jsonObject.put("success", true);
// 		 } catch (Exception ex) {
// 			 jsonObject.put("success", false);
// 			 jsonObject.put("error", ex.getMessage());
// 			 ex.printStackTrace(); // Log the error
// 		 }
 
// 		 try {
// 			 response.setContentType("application/json");
// 			 response.getWriter().write(jsonObject.toString());
// 		 } catch (IOException e) {
// 			 e.printStackTrace(); // Handle the exception
// 		 }
 
// 		 return null; // Return null as we are handling the response ourselves
// 	 }
// 	 public ActionForward getAllConfigurations(ActionMapping mapping, ActionForm form, HttpServletRequest request, HttpServletResponse response) {
//         JSONObject jsonObject = new JSONObject();

//         try {
//             FaxConfigDao faxConfigDao = SpringUtils.getBean(FaxConfigDao.class);
//             List<FaxConfig> faxConfigs = faxConfigDao.findAll(null, null);

//             JSONArray configArray = new JSONArray();
//             for (FaxConfig config : faxConfigs) {
//                 JSONObject configJson = new JSONObject();
//                 configJson.put("id", config.getId());
//                 configJson.put("faxUser", config.getFaxUser());
//                 configJson.put("faxNumber", config.getFaxNumber());
//                 configJson.put("senderEmail", config.getSenderEmail());
//                 configArray.add(configJson);
//             }

//             jsonObject.put("success", true);
//             jsonObject.put("configurations", configArray);
//         } catch (Exception ex) {
//             jsonObject.put("success", false);
//             jsonObject.put("error", ex.getMessage());
//             ex.printStackTrace();
//         }

//         try {
//             response.setContentType("application/json");
//             response.getWriter().write(jsonObject.toString());
//         } catch (IOException e) {
//             e.printStackTrace();
//         }

//         return null;
//     }

// 	public ActionForward deleteConfiguration(ActionMapping mapping, ActionForm form, HttpServletRequest request, HttpServletResponse response) {
//         JSONObject jsonObject = new JSONObject();

//         try {
//             Integer id = Integer.parseInt(request.getParameter("id"));
//             FaxConfigDao faxConfigDao = SpringUtils.getBean(FaxConfigDao.class);
//             faxConfigDao.remove(id);

//             jsonObject.put("success", true);
//         } catch (Exception ex) {
//             jsonObject.put("success", false);
//             jsonObject.put("error", ex.getMessage());
//             ex.printStackTrace();
//         }

//         try {
//             response.setContentType("application/json");
//             response.getWriter().write(jsonObject.toString());
//         } catch (IOException e) {
//             e.printStackTrace();
//         }

//         return null;
//     }
//  }
 

