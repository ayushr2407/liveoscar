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

package oscar.login;

import java.io.IOException;
import java.security.MessageDigest;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Properties;
import java.util.regex.Pattern;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import net.sf.cookierevolver.matrix.EncryptionUtil;
import net.sf.json.JSONObject;

import org.apache.logging.log4j.Logger;
import org.apache.struts.action.ActionForm;
import org.apache.struts.action.ActionForward;
import org.apache.struts.action.ActionMapping;
import org.apache.struts.actions.DispatchAction;
import org.oscarehr.PMmodule.dao.ProviderDao;
import org.oscarehr.PMmodule.service.ProviderManager;
import org.oscarehr.PMmodule.web.OcanForm;
import org.oscarehr.common.dao.FacilityDao;
import org.oscarehr.common.dao.ProviderPreferenceDao;
import org.oscarehr.common.dao.SecurityDao;
import org.oscarehr.common.dao.ServiceRequestTokenDao;
import org.oscarehr.common.dao.UserPropertyDAO;
import org.oscarehr.common.dao.SystemPreferencesDao;
import org.oscarehr.common.model.SystemPreferences;
import org.oscarehr.common.model.Facility;
import org.oscarehr.common.model.Provider;
import org.oscarehr.common.model.ProviderPreference;
import org.oscarehr.common.model.Security;
import org.oscarehr.common.model.ServiceRequestToken;
import org.oscarehr.common.model.UserProperty;
import org.oscarehr.decisionSupport.service.DSService;
import org.oscarehr.managers.AppManager;
import org.oscarehr.phr.util.MyOscarUtils;
import org.oscarehr.util.LoggedInInfo;
import org.oscarehr.util.LoggedInUserFilter;
import org.oscarehr.util.MiscUtils;
import org.oscarehr.util.SessionConstants;
import org.oscarehr.util.SpringUtils;
import org.owasp.encoder.Encode;
import org.springframework.context.ApplicationContext;
import org.springframework.web.context.support.WebApplicationContextUtils;
import oscar.oscarDemographic.data.DemographicData;
import org.oscarehr.common.model.Demographic;


import com.quatro.model.security.LdapSecurity;

import oscar.OscarProperties;
import oscar.log.LogAction;
import oscar.log.LogConst;
import oscar.oscarSecurity.CRHelper;
import oscar.util.AlertTimer;
import oscar.util.CBIUtil;
import oscar.util.ParameterActionForward;

import oscar.util.OscarEncryptionUtil;


public final class LoginAction extends DispatchAction {
	
	/**
	 * This variable is only intended to be used by this class and the jsp which sets the selected facility.
	 * This variable represents the queryString key used to pass the facility ID to this class.
	 */
    public static final String SELECTED_FACILITY_ID="selectedFacilityId";

    private static final Logger logger = MiscUtils.getLogger();
    private static final String LOG_PRE = "Login!@#$: ";
    
    
    private ProviderManager providerManager = (ProviderManager) SpringUtils.getBean("providerManager");
    private AppManager appManager = SpringUtils.getBean(AppManager.class);
    private FacilityDao facilityDao = (FacilityDao) SpringUtils.getBean("facilityDao");
    private ProviderPreferenceDao providerPreferenceDao = (ProviderPreferenceDao) SpringUtils.getBean("providerPreferenceDao");
    private ProviderDao providerDao = SpringUtils.getBean(ProviderDao.class);
    private UserPropertyDAO propDao =(UserPropertyDAO)SpringUtils.getBean("UserPropertyDAO");
	
    public ActionForward execute(ActionMapping mapping, ActionForm form, HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        // System.out.println("LoginAction invoked");
    	boolean ajaxResponse = request.getParameter("ajaxResponse") != null?Boolean.valueOf(request.getParameter("ajaxResponse")):false;
    	
    	String ip = request.getRemoteAddr();
        Boolean isMobileOptimized = request.getSession().getAttribute("mobileOptimized") != null;
    	
        LoginCheckLogin cl = new LoginCheckLogin();
        String oneIdKey = request.getParameter("nameId");
        String oneIdEmail = request.getParameter("email");
        String userName = "";
        String password = "";
        String pin = "";
        String nextPage= "";
        boolean forcedpasswordchange = true;
        String where = "failure";
        
    	if (request.getParameter("forcedpasswordchange") != null && request.getParameter("forcedpasswordchange").equalsIgnoreCase("true")) {
    		// Coming back from force password change.
            // Allow a username upto the schema of varchar 30 but force letters and numbers
    	    userName = (String) request.getSession().getAttribute("userName");
            if(! Pattern.matches("[a-zA-Z0-9]{1,30}", userName)) {
        	    userName = "Invalid Username";
			}
    	    password = (String) request.getSession().getAttribute("password");
    	    pin = (String) request.getSession().getAttribute("pin");
            if(! Pattern.matches("[0-9]{4,255}", pin) ) { // 4 is the minimal pin length, 255 is the maximal length of security.pin
        	    pin = "";
            }
    	    nextPage = (String) request.getSession().getAttribute("nextPage");
    	    
    	    String newPassword = ((LoginForm) form).getNewPassword();
    	    String confirmPassword = ((LoginForm) form).getConfirmPassword();
    	    String oldPassword = ((LoginForm) form).getOldPassword();
    	   
    	    
    	    try{
        	    String errorStr = errorHandling(password, newPassword, confirmPassword, encodePassword(oldPassword), oldPassword);
        	    
        	    //Error Handling
        	    if (errorStr != null && !errorStr.isEmpty()) {
    	        	String newURL = mapping.findForward("forcepasswordreset").getPath();
    	        	newURL = newURL + errorStr;  	        	
    	            return(new ActionForward(newURL));  
        	    }
        	   
        	    persistNewPassword(userName, newPassword);
        	            	    
        	    password = newPassword;
        	            	    
        	    //Remove the attributes from session
        	    removeAttributesFromSession(request);
         	}  
         	catch (Exception e) {
         		logger.error("Error", e);
                String newURL = mapping.findForward("error").getPath();
                newURL = newURL + "?errormsg=Setting values to the session.";   
                
        	    //Remove the attributes from session
        	    removeAttributesFromSession(request);
        	    
                return(new ActionForward(newURL));  
         	}

    	    //make sure this checking doesn't happen again
    	    forcedpasswordchange = false;
    	    
    	} else {
            // Check if credentials are forwarded via request attributes (from RelayLoginAction)
            // userName = (String) request.getAttribute("username");
            // password = (String) request.getAttribute("password");
            // pin = (String) request.getAttribute("pin");
        
            // If attributes are null, fall back to form-based credentials
            userName = ((LoginForm) form).getUsername();
            if (userName == null || userName.isEmpty()) {
                userName = (String) request.getAttribute("username");
            }
            
            password = ((LoginForm) form).getPassword();
            if (password == null || password.isEmpty()) {
                password = (String) request.getAttribute("password");
            }
            
            pin = ((LoginForm) form).getPin();
            if (pin == null || pin.isEmpty()) {
                pin = (String) request.getAttribute("pin");
            }
            
            // System.out.println("Received username: " + userName);
            // System.out.println("Received password: " + (password != null ? "[HIDDEN]" : "NULL"));
            // System.out.println("Received pin: " + pin);

        
            // Validate inputs
            if (!Pattern.matches("[a-zA-Z0-9]{1,30}", userName)) {
                userName = "Invalid Username";
            }
            if (!Pattern.matches("[0-9]{4,255}", pin)) { // 4 is the minimal pin length, 255 is the maximal length of security.pin
                pin = "";
            }
        
            // Get next page
            nextPage = request.getParameter("nextPage");

             // Add your debug log here
    // logger.debug("Received credentials - Username: " + userName + ", Password: [HIDDEN], PIN: " + pin);
    // System.out.println("Received credentials in loginaction.java - Username: " + userName + ", Password: [HIDDEN], PIN: " + pin);
    		        
	        logger.debug("nextPage: "+nextPage);
	        if (nextPage!=null) {
	        	// set current facility
	            String facilityIdString=request.getParameter(SELECTED_FACILITY_ID);
	            Facility facility=facilityDao.find(Integer.parseInt(facilityIdString));
	            request.getSession().setAttribute(SessionConstants.CURRENT_FACILITY, facility);
	            String username=(String)request.getSession().getAttribute("user");
	            LogAction.addLog(username, LogConst.LOGIN, LogConst.CON_LOGIN, "facilityId="+facilityIdString, ip);
	            if(facility.isEnableOcanForms()) {
	            	request.getSession().setAttribute("ocanWarningWindow", OcanForm.getOcanWarningMessage(facility.getId()));
	            }
	            return mapping.findForward(nextPage);
	        }
	        
	        if (cl.isBlock(ip, userName)) {
	        	logger.info(LOG_PRE + " Blocked: " + userName);
	            // return mapping.findForward(where); //go to block page
	            // change to block page
	            String newURL = mapping.findForward("error").getPath();
	            newURL = newURL + "?errormsg=Your account is locked. Please try again after 10 minutes or contact your administrator to unlock.";
	            
	            if(ajaxResponse) {
	            	JSONObject json = new JSONObject();
	            	json.put("success", false);
	            	json.put("error", "Your account is locked. Please contact your administrator to unlock.");
	            	response.setContentType("text/x-json");
	            	json.write(response.getWriter());
	            	return null;
	            }
	            
	            return(new ActionForward(newURL));
	        }
	                
	        logger.debug("ip was not blocked: "+ip);
        
    	}
        
        String[] strAuth;
        try {
            strAuth = cl.auth(userName, password, pin, ip);
        }
        catch (Exception e) {
        	logger.error("Error", e);
            String newURL = mapping.findForward("error").getPath();
            if (e.getMessage() != null && e.getMessage().startsWith("java.lang.ClassNotFoundException")) {
                newURL = newURL + "?errormsg=Database driver " + e.getMessage().substring(e.getMessage().indexOf(':') + 2) + " not found.";
            }
            else {
                newURL = newURL + "?errormsg=Database connection error: " + e.getMessage() + ".";
            }
            
            if(ajaxResponse) {
            	JSONObject json = new JSONObject();
            	json.put("success", false);
            	json.put("error", "Database connection error:"+e.getMessage() + ".");
            	response.setContentType("text/x-json");
            	json.write(response.getWriter());
            	return null;
            }
            
            return(new ActionForward(newURL));
        }
        logger.debug("strAuth : "+Arrays.toString(strAuth));
        if (strAuth != null && strAuth.length != 1) { // login successfully
        	
        	
        	
        	//is the provider record inactive?
            Provider p = providerDao.getProvider(strAuth[0]);
            if(p == null || (p.getStatus() != null && p.getStatus().equals("0"))) {
            	logger.info(LOG_PRE + " Inactive: " + userName);           
            	LogAction.addLog(strAuth[0], "login", "failed", "inactive");
            	
                String newURL = mapping.findForward("error").getPath();
                newURL = newURL + "?errormsg=Your account is inactive. Please contact your administrator to activate.";
                return(new ActionForward(newURL));
            }
            
            /* 
             * This section is added for forcing the initial password change.
             */
            Security security = getSecurity(userName);
            if (!OscarProperties.getInstance().getBooleanProperty("mandatory_password_reset", "false") && 
            	security.isForcePasswordReset() != null && security.isForcePasswordReset() && forcedpasswordchange	) {
            	
            	String newURL = mapping.findForward("forcepasswordreset").getPath();
            	
            	try{
            	   setUserInfoToSession( request, userName,  password,  pin, nextPage);
            	}  
            	catch (Exception e) {
            		logger.error("Error", e);
                    newURL = mapping.findForward("error").getPath();
                    newURL = newURL + "?errormsg=Setting values to the session.";            		
            	}

                return(new ActionForward(newURL));            	
            }
                        
            // invalidate the existing session
            HttpSession session = request.getSession(false);
            if (session != null) {
            	if(request.getParameter("invalidate_session") != null && request.getParameter("invalidate_session").equals("false")) {
            		//don't invalidate in this case..messes up authenticity of OAUTH
            	} else {
                    // System.out.println("not invalidating");
            		session.invalidate();
            	}
            }
            session = request.getSession(); // Create a new session for this user
            // set session max interval from system preference
            SystemPreferencesDao systemPreferencesDao = SpringUtils.getBean(SystemPreferencesDao.class);
            SystemPreferences forceLogoutInactivePref = systemPreferencesDao.findPreferenceByName("force_logout_when_inactive");
            SystemPreferences forceLogoutInactiveTimePref = systemPreferencesDao.findPreferenceByName("force_logout_when_inactive_time");
            session.setMaxInactiveInterval((forceLogoutInactivePref != null && forceLogoutInactivePref.getValueAsBoolean() && forceLogoutInactiveTimePref != null ? Integer.parseInt(forceLogoutInactiveTimePref.getValue()) : 120) * 60);
            
          //If the ondIdKey parameter is not null and is not an empty string
        	if (oneIdKey != null && !oneIdKey.equals("")) {
        		String providerNumber = strAuth[0];
        		SecurityDao securityDao = (SecurityDao) SpringUtils.getBean(SecurityDao.class);
        		Security securityRecord = securityDao.getByProviderNo(providerNumber);
        		
        		if (securityRecord.getOneIdKey() == null || securityRecord.getOneIdKey().equals("")) {
        			securityRecord.setOneIdKey(oneIdKey);
        			securityRecord.setOneIdEmail(oneIdEmail);
        			securityDao.updateOneIdKey(securityRecord);
        			session.setAttribute("oneIdEmail", oneIdEmail);
        		}
        		else {
        			logger.error("The account for provider number " + providerNumber + " already has a ONE ID key associated with it");
        			return mapping.findForward("error");
        		}
        	}
            
            logger.debug("Assigned new session for: " + strAuth[0] + " : " + strAuth[3] + " : " + strAuth[4]);
            LogAction.addLog(strAuth[0], LogConst.LOGIN, LogConst.CON_LOGIN, "", ip);

            // initial db setting
            Properties pvar = OscarProperties.getInstance();
            MyOscarUtils.setDeterministicallyMangledPasswordSecretKeyIntoSession(session, password);
            

            String providerNo = strAuth[0];
            session.setAttribute("user", strAuth[0]);
            session.setAttribute("userfirstname", strAuth[1]);
            session.setAttribute("userlastname", strAuth[2]);
            session.setAttribute("userrole", strAuth[4]);
            session.setAttribute("oscar_context_path", request.getContextPath());
            session.setAttribute("expired_days", strAuth[5]);
            // If a new session has been created, we must set the mobile attribute again
            if (isMobileOptimized) session.setAttribute("mobileOptimized","true");
            // initiate security manager
            String default_pmm = null;

            // System.out.println("strAuth[0] (User/Provider ID): " + strAuth[0]);
            // System.out.println("strAuth[1] (First Name): " + strAuth[1]);
            // System.out.println("strAuth[2] (Last Name): " + strAuth[2]);
            // System.out.println("strAuth[4] (Role): " + strAuth[4]);

            // // Use the correct variable for the username
            // System.out.println("Username: " + userName);

            // Combine credentials (username, password, PIN)
            String credentials = userName + ":" + password + ":" + pin; // strAuth[0] is username
            try {
                // Print the constructed credentials to Tomcat logs (for debugging)
                // System.out.println("Constructed Credentials String: " + credentials);

                // Encrypt the credentials
                String encryptedCredentials = OscarEncryptionUtil.encrypt(credentials);

                // Store the encrypted credentials in the session
                session.setAttribute("encryptedCredentials", encryptedCredentials);

                // Log the encrypted credentials for debugging (optional, avoid in production)
                // System.out.println("Encrypted Credentials: " + encryptedCredentials);

            } catch (Exception e) {
                logger.error("Failed to encrypt credentials", e);
                // Optional: Handle encryption errors gracefully if required
            }


            
            
            
            // get preferences from preference table
        	ProviderPreference providerPreference=providerPreferenceDao.find(providerNo);
        	
            
                
        	if (providerPreference==null) providerPreference=new ProviderPreference();
         	
        	session.setAttribute(SessionConstants.LOGGED_IN_PROVIDER_PREFERENCE, providerPreference);
        	
            if (org.oscarehr.common.IsPropertiesOn.isCaisiEnable()) {
            	String tklerProviderNo = null;
            	UserProperty prop = propDao.getProp(providerNo, UserProperty.PROVIDER_FOR_TICKLER_WARNING);
        		if (prop == null) {
        			tklerProviderNo = providerNo;
        		} else {
        			tklerProviderNo = prop.getValue();
        		}
            	session.setAttribute("tklerProviderNo",tklerProviderNo);
            	
                session.setAttribute("newticklerwarningwindow", providerPreference.getNewTicklerWarningWindow());
                session.setAttribute("default_pmm", providerPreference.getDefaultCaisiPmm());
                session.setAttribute("caisiBillingPreferenceNotDelete", String.valueOf(providerPreference.getDefaultDoNotDeleteBilling()));
                
                default_pmm = providerPreference.getDefaultCaisiPmm();
                @SuppressWarnings("unchecked")
                ArrayList<String> newDocArr = (ArrayList<String>)request.getSession().getServletContext().getAttribute("CaseMgmtUsers");    
                if("enabled".equals(providerPreference.getDefaultNewOscarCme())) {
                	newDocArr.add(providerNo);
                	session.setAttribute("CaseMgmtUsers", newDocArr);
                }
            }
            session.setAttribute("starthour", providerPreference.getStartHour().toString());
            session.setAttribute("endhour", providerPreference.getEndHour().toString());
            session.setAttribute("everymin", providerPreference.getEveryMin().toString());
            session.setAttribute("groupno", providerPreference.getMyGroupNo());
                
            // where = "provider";

String action = request.getParameter("action");
session = request.getSession();
// System.out.println("[Before Forwarding to addeform] Session ID = " + session.getId());
// System.out.println("LOGGED_IN_SECURITY present: " + (session.getAttribute(SessionConstants.LOGGED_IN_SECURITY) != null));



// Redirection to addeform from Bimble
if ("addeform".equals(action)) {
    // Retrieve necessary parameters
    String demographicNo = request.getParameter("demographic_no");
    if (demographicNo != null) {
        // System.out.println("Original demographicNo: '" + demographicNo + "'");
        demographicNo = demographicNo.trim();
        // System.out.println("Trimmed demographicNo: '" + demographicNo + "'");
    }
    String appointmentNo = request.getParameter("appointment");
    String formId = request.getParameter("fid"); // Use dynamic formId from request

    // Ensure parameters exist with default values
    if (demographicNo == null) demographicNo = "0";  
    if (appointmentNo == null) appointmentNo = "0";  

    // Set session attributes
    session.setAttribute("demographicNo", demographicNo);
    session.setAttribute("appointmentNo", appointmentNo);
    session.setAttribute("formId", formId);

    //LoggedInInfo is set properly
    LoggedInInfo loggedInInfo = (LoggedInInfo) session.getAttribute(SessionConstants.LOGGED_IN_INFO);
    if (loggedInInfo == null) {
        System.out.println("ERROR: LoggedInInfo is missing. Creating new instance...");
        loggedInInfo = new LoggedInInfo();
        loggedInInfo.setSession(session);
        session.setAttribute(SessionConstants.LOGGED_IN_INFO, loggedInInfo);
    }

    //LOGGED_IN_PROVIDER is set
    Provider provider = (Provider) session.getAttribute(SessionConstants.LOGGED_IN_PROVIDER);
    if (provider == null) {
        System.out.println("ERROR: LOGGED_IN_PROVIDER missing! Fetching manually...");

        ProviderDao providerDao = SpringUtils.getBean(ProviderDao.class);
        provider = providerDao.getProvider((String) session.getAttribute("user"));

        if (provider != null) {
            session.setAttribute(SessionConstants.LOGGED_IN_PROVIDER, provider);
            loggedInInfo.setLoggedInProvider(provider);
            // System.out.println("Restored Provider: " + provider.getProviderNo());
        } else {
            System.out.println("ERROR: Unable to fetch Provider from database.");
        }
    }

    //LOGGED_IN_SECURITY is set
    security = (Security) session.getAttribute(SessionConstants.LOGGED_IN_SECURITY);
    if (security == null) {
        System.out.println("ERROR: LOGGED_IN_SECURITY missing! Fetching manually...");

        SecurityDao securityDao = SpringUtils.getBean(SecurityDao.class);
        security = securityDao.getByProviderNo((String) session.getAttribute("user"));

        if (security != null) {
            session.setAttribute(SessionConstants.LOGGED_IN_SECURITY, security);
            loggedInInfo.setLoggedInSecurity(security);
            // System.out.println("Restored LOGGED_IN_SECURITY for ProviderNo: " + security.getProviderNo());
        } else {
            System.out.println("ERROR: Failed to restore LOGGED_IN_SECURITY!");
        }
    }

    //`_demographic` is properly set (AFTER security is set)
    if (session.getAttribute("_demographic") == null) {
        System.out.println("ERROR: _demographic session attribute missing. Initializing...");

        try {
            DemographicData demoData = new DemographicData();
            Demographic demographic = demoData.getDemographic(loggedInInfo, demographicNo);

            if (demographic != null) {
                session.setAttribute("_demographic", demographic);
                // System.out.println("_demographic successfully set.");
            } else {
                System.out.println("ERROR: Failed to retrieve demographic data.");
            }
        } catch (Exception e) {
            e.printStackTrace();
            System.out.println("ERROR: Exception while fetching demographic data: " + e.getMessage());
        }
    }

    // before redirect
    // System.out.println("🔍 Final Check Before Redirect:");
    // System.out.println("LOGGED_IN_SECURITY present: " + (session.getAttribute(SessionConstants.LOGGED_IN_SECURITY) != null));
    // System.out.println("LOGGED_IN_PROVIDER present: " + (session.getAttribute(SessionConstants.LOGGED_IN_PROVIDER) != null));
    // System.out.println("LoggedInInfo present: " + (session.getAttribute(SessionConstants.LOGGED_IN_INFO) != null));
    // System.out.println("_demographic present: " + (session.getAttribute("_demographic") != null));

    // Construct redirect URL
    String baseUrl = request.getScheme() + "://" + request.getServerName() + ":" + request.getServerPort() + request.getContextPath();
    String redirectUrl = baseUrl + "/eform/efmformadd_data.jsp?fid=" + formId +
                     "&demographic_no=" + demographicNo + 
                     "&demographicNo=" + demographicNo + 
                     "&appointment=" + appointmentNo +
                     "&JSESSIONID=" + session.getId();

    System.out.println("🚀 Redirecting to: " + redirectUrl);

    return new ActionForward(redirectUrl, true);
}



// Redirection to viewdoc from Bimble
if ("viewdoc".equals(action)) {
    // Retrieve document number
    String docNo = request.getParameter("doc_no");

    // Construct base URL dynamically
    String baseUrl = request.getScheme() + "://" + request.getServerName() + ":" + request.getServerPort() + request.getContextPath();
    String redirectUrl = baseUrl + "/dms/ManageDocument.do?method=display&doc_no=" + docNo;

    System.out.println("Redirecting to: " + redirectUrl);

    // Force manual redirection instead of using findForward()
    return new ActionForward(redirectUrl, true);
}
    // Default case: Redirect to provider control panel
    where = "provider";

            if (where.equals("provider") && default_pmm != null && "enabled".equals(default_pmm)) {
                where = "caisiPMM";
            }
            
            if (where.equals("provider") && OscarProperties.getInstance().getProperty("useProgramLocation", "false").equals("true") ) {
                where = "programLocation";
            }

            String quatroShelter = OscarProperties.getInstance().getProperty("QUATRO_SHELTER");
            if(quatroShelter!= null && quatroShelter.equals("on")) {
            	where = "shelterSelection";
            }
        
            /*
             * if (OscarProperties.getInstance().isTorontoRFQ()) { where = "caisiPMM"; }
             */
            // Lazy Loads AlertTimer instance only once, will run as daemon for duration of server runtime
            if (pvar.getProperty("billregion").equals("BC")) {
                String alertFreq = pvar.getProperty("ALERT_POLL_FREQUENCY");
                if (alertFreq != null) {
                    Long longFreq = new Long(alertFreq);
                    String[] alertCodes = OscarProperties.getInstance().getProperty("CDM_ALERTS").split(",");
                    AlertTimer.getInstance(alertCodes, longFreq.longValue());
                }
            }
            CRHelper.recordLoginSuccess(userName, strAuth[0], request);

            String username = (String) session.getAttribute("user");
            Provider provider = providerManager.getProvider(username);
            session.setAttribute(SessionConstants.LOGGED_IN_PROVIDER, provider);
            session.setAttribute(SessionConstants.LOGGED_IN_SECURITY, cl.getSecurity());

            LoggedInInfo loggedInInfo = LoggedInUserFilter.generateLoggedInInfoFromSession(request);
            
            if (where.equals("provider")) {
                UserProperty drugrefProperty = propDao.getProp(UserProperty.MYDRUGREF_ID);
                if (drugrefProperty != null || appManager.isK2AUser(loggedInInfo)) {
                    DSService service =   SpringUtils.getBean(DSService.class);  
                    service.fetchGuidelinesFromServiceInBackground(loggedInInfo);
                }
            }
            
		    MyOscarUtils.attemptMyOscarAutoLoginIfNotAlreadyLoggedIn(loggedInInfo, true);
            
            List<Integer> facilityIds = providerDao.getFacilityIds(provider.getProviderNo());
            if (facilityIds.size() > 1) {
                return(new ActionForward("/select_facility.jsp?nextPage=" + where));
            }
            else if (facilityIds.size() == 1) {
                // set current facility
                Facility facility=facilityDao.find(facilityIds.get(0));
                request.getSession().setAttribute("currentFacility", facility);
                LogAction.addLog(strAuth[0], LogConst.LOGIN, LogConst.CON_LOGIN, "facilityId="+facilityIds.get(0), ip);
                if(facility.isEnableOcanForms()) {
                	request.getSession().setAttribute("ocanWarningWindow", OcanForm.getOcanWarningMessage(facility.getId()));
                }
                if(facility.isEnableCbiForm()) {
                	request.getSession().setAttribute("cbiReminderWindow", CBIUtil.getCbiSubmissionFailureWarningMessage(facility.getId(),provider.getProviderNo() ));
                }
            }
            else {
        		List<Facility> facilities = facilityDao.findAll(true);
        		if(facilities!=null && facilities.size()>=1) {
        			Facility fac = facilities.get(0);
        			int first_id = fac.getId();
        			ProviderDao.addProviderToFacility(providerNo, first_id);
        			Facility facility=facilityDao.find(first_id);
        			request.getSession().setAttribute("currentFacility", facility);
        			LogAction.addLog(strAuth[0], LogConst.LOGIN, LogConst.CON_LOGIN, "facilityId="+first_id, ip);
            	}
            }

            if( pvar.getProperty("LOGINTEST","").equalsIgnoreCase("yes")) {
                String proceedURL = mapping.findForward(where).getPath();
                request.getSession().setAttribute("proceedURL", proceedURL);               
                return mapping.findForward("LoginTest");
            }
            
            //are they using the new UI?
            if("true".equals(OscarProperties.getInstance().getProperty("newui.enabled", "false"))) {
	            UserProperty prop = propDao.getProp(provider.getProviderNo(), UserProperty.COBALT);
	            if(prop != null && prop.getValue() != null && prop.getValue().equals("yes")) {
	            	where="cobalt";
	            }
            }
        }
        // expired password
        else if (strAuth != null && strAuth.length == 1 && strAuth[0].equals("expired")) {
        	logger.warn("Expired password");
            cl.updateLoginList(ip, userName);
            String newURL = mapping.findForward("error").getPath();
            newURL = newURL + "?errormsg=Your account is expired. Please contact your administrator.";
            
            if(ajaxResponse) {
            	JSONObject json = new JSONObject();
            	json.put("success", false);
            	json.put("error", "Your account is expired. Please contact your administrator.");
            	response.setContentType("text/x-json");
            	json.write(response.getWriter());
            	return null;
            }
            
            return(new ActionForward(newURL));
        }
        else { 
            logger.error("go to normal directory");
        
            cl.updateLoginList(ip, userName);
            CRHelper.recordLoginFailure(userName, request);
        
            // Check if the username exists
            SecurityDao securityDao = (SecurityDao) SpringUtils.getBean("securityDao");
            List<Security> userExistCheck = securityDao.findByUserName(userName);
        
            if (userExistCheck.isEmpty()) {
                System.out.println("Invalid Username: " + userName);
                request.setAttribute("usernameError", "Invalid username.");
            } else {
                // Retrieve correct credentials from DB
                Security userSecurity = userExistCheck.get(0);
                String correctPassword = userSecurity.getPassword(); // Assuming password is stored encrypted
                String correctPin = userSecurity.getPin(); // Ensure PIN is stored securely
                
                boolean isPasswordIncorrect = false;

                try {
                    isPasswordIncorrect = !encodePassword(password).equals(correctPassword);
                } catch (Exception e) {
                    System.out.println("Error encoding password: " + e.getMessage());
                    request.setAttribute("generalError", "An error occurred during login. Please try again.");
                    return mapping.findForward("failure"); // Redirect user back to login page
                }
                                boolean isPinIncorrect = !pin.equals(correctPin); // Direct comparison (ensure it's properly validated)
        
                if (isPasswordIncorrect && isPinIncorrect) {
                    System.out.println("Incorrect password and PIN for username: " + userName);
                    request.setAttribute("passwordError", "Incorrect password.");
                    request.setAttribute("pinError", "Incorrect PIN.");
                } else if (isPasswordIncorrect) {
                    System.out.println("Incorrect password for username: " + userName);
                    request.setAttribute("passwordError", "Incorrect password.");
                } else if (isPinIncorrect) {
                    System.out.println("Incorrect PIN for username: " + userName);
                    request.setAttribute("pinError", "Incorrect PIN.");
                }
            }
        
            // General error message for failed login
            request.setAttribute("generalError", "Invalid login credentials. Please try again.");
        
            // Handle AJAX response (if applicable)
            if (ajaxResponse) {
                JSONObject json = new JSONObject();
                json.put("success", false);
                if (request.getAttribute("passwordError") != null) {
                    json.put("error", "Incorrect password.");
                } else if (request.getAttribute("pinError") != null) {
                    json.put("error", "Incorrect PIN.");
                } else {
                    json.put("error", "Invalid Credentials");
                }
                response.setContentType("text/x-json");
                json.write(response.getWriter());
                return null;
            }
        
            // Redirect user back to login page
            return mapping.findForward("failure");
        }
        


    	logger.debug("checking oauth_token");
        if(request.getParameter("oauth_token") != null) {
    		String proNo = (String)request.getSession().getAttribute("user");
    		ServiceRequestTokenDao serviceRequestTokenDao = SpringUtils.getBean(ServiceRequestTokenDao.class);
    		ServiceRequestToken srt = serviceRequestTokenDao.findByTokenId(request.getParameter("oauth_token"));
    		if(srt != null) {
    			srt.setProviderNo(proNo);
    			serviceRequestTokenDao.merge(srt);
    		}
    	}
        
        if(ajaxResponse) {
        	logger.debug("rendering ajax response");
        	Provider prov = providerDao.getProvider((String)request.getSession().getAttribute("user"));
        	JSONObject json = new JSONObject();
        	json.put("success", true);
        	json.put("providerName", Encode.forJavaScript(prov.getFormattedName()));
        	json.put("providerNo", prov.getProviderNo());
        	response.setContentType("text/x-json");
        	json.write(response.getWriter());
        	return null;
        }
        
    	logger.debug("rendering standard response : "+where);
        return mapping.findForward(where);
    }
    
    /**
     * Removes attributes from session
     * @param request
     */
    private void removeAttributesFromSession(HttpServletRequest request) {
	    request.getSession().removeAttribute("userName");
	    request.getSession().removeAttribute("password");
	    request.getSession().removeAttribute("pin");
	    request.getSession().removeAttribute("nextPage");
    }
    
    /**
     * Set user info to session
     * @param request
     * @param userName
     * @param password
     * @param pin
     * @param nextPage
     */
    private void setUserInfoToSession(HttpServletRequest request,String userName, String password, String pin,String nextPage) throws Exception{
    	request.getSession().setAttribute("userName", userName);
    	request.getSession().setAttribute("password", encodePassword(password));
    	request.getSession().setAttribute("pin", pin);
    	request.getSession().setAttribute("nextPage", nextPage);
    
    }
    
     /**
      * Performs the error handling
     * @param password
     * @param newPassword
     * @param confirmPassword
     * @param oldPassword
     * @return
     */
    private String errorHandling(String password, String  newPassword, String  confirmPassword, String  encodedOldPassword, String  oldPassword){
	    
    	String newURL = "";

	    if (!encodedOldPassword.equals(password)) {
     	   newURL = newURL + "?errormsg=Your old password, does NOT match the password in the system. Please enter your old password.";  
     	} else if (!newPassword.equals(confirmPassword)) {
      	   newURL = newURL + "?errormsg=Your new password, does NOT match the confirmed password. Please try again.";  
      	} else if (!Boolean.parseBoolean(OscarProperties.getInstance().getProperty("IGNORE_PASSWORD_REQUIREMENTS")) && newPassword.equals(oldPassword)) {
       	   newURL = newURL + "?errormsg=Your new password, is the same as your old password. Please choose a new password.";  
       	} 
    	    
	    return newURL;
     }
    
    
    /**
     * This method encodes the password, before setting to session.
     * @param password
     * @return
     * @throws Exception
     */
    private String encodePassword(String password) throws Exception{

    	MessageDigest md = MessageDigest.getInstance("SHA");
    	
    	StringBuilder sbTemp = new StringBuilder();
	    byte[] btNewPasswd= md.digest(password.getBytes());
	    for(int i=0; i<btNewPasswd.length; i++) sbTemp = sbTemp.append(btNewPasswd[i]);
	
	    return sbTemp.toString();
	    
    }
    
    
    /**
     * get the security record based on the username
     * @param username
     * @return
     */
    private Security getSecurity(String username) {

		SecurityDao securityDao = (SecurityDao) SpringUtils.getBean("securityDao");
		List<Security> results = securityDao.findByUserName(username);
		Security security = null;
		if (results.size() > 0) security = results.get(0);

		if (security == null) {
			return null;
		} else if (OscarProperties.isLdapAuthenticationEnabled()) {
			security = new LdapSecurity(security);
		}
		
		return security;
    }	
    
    
    /**
     * Persists the new password
     * @param userName
     * @param newPassword
     * @return
     */
    private void  persistNewPassword(String userName, String newPassword) throws Exception{
    
	    Security security = getSecurity(userName);
	    security.setPassword(encodePassword(newPassword));
	    security.setForcePasswordReset(Boolean.FALSE);
	    SecurityDao securityDao = (SecurityDao) SpringUtils.getBean("securityDao");	    
	    securityDao.saveEntity(security); 
		
    }
         
	public ApplicationContext getAppContext() {
		return WebApplicationContextUtils.getWebApplicationContext(getServlet().getServletContext());
	}
}
