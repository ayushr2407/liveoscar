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
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Calendar;
import java.util.Date;
import java.util.Enumeration;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Vector;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import org.json.JSONArray;
import org.json.JSONObject;
import java.net.URLEncoder;


import org.apache.http.client.methods.HttpGet;
import org.apache.http.impl.client.CloseableHttpClient;
import org.apache.http.impl.client.HttpClients;
import org.apache.http.util.EntityUtils;
import org.apache.http.HttpResponse;


import org.apache.logging.log4j.Logger;
import org.apache.struts.action.ActionForm;
import org.apache.struts.action.ActionForward;
import org.apache.struts.action.ActionMapping;
import org.apache.struts.actions.DispatchAction;
import org.apache.struts.util.MessageResources;
import org.oscarehr.casemgmt.model.CaseManagementNote;
import org.oscarehr.casemgmt.model.CaseManagementNoteLink;
import org.oscarehr.casemgmt.service.CaseManagementManager;
import org.oscarehr.common.dao.DrugDao;
import org.oscarehr.common.dao.DrugReasonDao;
import org.oscarehr.common.dao.PartialDateDao;
import org.oscarehr.common.dao.UserPropertyDAO;
import org.oscarehr.common.model.Demographic;
import org.oscarehr.common.model.Drug;
import org.oscarehr.common.model.DrugReason;
import org.oscarehr.common.model.PartialDate;
import org.oscarehr.common.model.UserProperty;
import org.oscarehr.managers.CodingSystemManager;
import org.oscarehr.managers.DemographicManager;
import org.oscarehr.managers.SecurityInfoManager;
import org.oscarehr.util.LoggedInInfo;
import org.oscarehr.util.MiscUtils;
import org.oscarehr.util.SpringUtils;
import org.springframework.web.context.WebApplicationContext;
import org.springframework.web.context.support.WebApplicationContextUtils;

import oscar.log.LogAction;
import oscar.log.LogConst;
import oscar.oscarRx.data.RxDrugData;
import oscar.oscarRx.data.RxDrugData.DrugMonograph.DrugComponent;
import oscar.oscarRx.data.RxPrescriptionData;
import oscar.oscarRx.util.RxUtil;
import oscar.util.StringUtils;

import java.util.Map;


public final class RxWriteScriptAction extends DispatchAction {
	private SecurityInfoManager securityInfoManager = SpringUtils.getBean(SecurityInfoManager.class);
	
	private static final String PRIVILEGE_READ = "r";
	private static final String PRIVILEGE_WRITE = "w";

	private static final Logger logger = MiscUtils.getLogger();
	private static UserPropertyDAO userPropertyDAO;
	private static final String DEFAULT_QUANTITY = "30";
	private static final PartialDateDao partialDateDao = (PartialDateDao)SpringUtils.getBean("partialDateDao");

	DemographicManager demographicManager = SpringUtils.getBean(DemographicManager.class) ;
    
	String removeExtraChars(String s){
		return s.replace(""+((char) 130 ),"").replace(""+((char) 194 ),"").replace(""+((char) 195 ),"").replace(""+((char) 172 ),"");
	}
	

	public ActionForward unspecified(ActionMapping mapping, ActionForm form, HttpServletRequest request, HttpServletResponse response) throws IOException, ServletException, Exception {
		LoggedInInfo loggedInInfo = LoggedInInfo.getLoggedInInfoFromSession(request);
		checkPrivilege(loggedInInfo, PRIVILEGE_WRITE);
		
		RxWriteScriptForm frm = (RxWriteScriptForm) form;
		String fwd = "refresh";
		oscar.oscarRx.pageUtil.RxSessionBean bean = (oscar.oscarRx.pageUtil.RxSessionBean) request.getSession().getAttribute("RxSessionBean");

		if (bean == null) {
			response.sendRedirect("error.html");
			return null;
		}

		if (frm.getAction().startsWith("update")) {

			RxDrugData drugData = new RxDrugData();
			RxPrescriptionData.Prescription rx = bean.getStashItem(bean.getStashIndex());
			RxPrescriptionData prescription = new RxPrescriptionData();

			if (frm.getGCN_SEQNO() != 0) { // not custom
				if (frm.getBrandName().equals(rx.getBrandName()) == false) {
					rx.setBrandName(frm.getBrandName());
				} else {
					rx.setGCN_SEQNO(frm.getGCN_SEQNO());
				}
			} else { // custom
				rx.setBrandName(null);
				rx.setGCN_SEQNO(0);
				rx.setCustomName(frm.getCustomName());
			}

			rx.setRxDate(RxUtil.StringToDate(frm.getRxDate(), "yyyy-MM-dd"));
			rx.setWrittenDate(RxUtil.StringToDate(frm.getWrittenDate(), "yyyy-MM-dd"));
			rx.setTakeMin(frm.getTakeMinFloat());
			rx.setTakeMax(frm.getTakeMaxFloat());
			rx.setFrequencyCode(frm.getFrequencyCode());
			rx.setDuration(frm.getDuration());
			rx.setDurationUnit(frm.getDurationUnit());
			rx.setQuantity(frm.getQuantity());
			rx.setRepeat(frm.getRepeat());
			rx.setLastRefillDate(RxUtil.StringToDate(frm.getLastRefillDate(), "yyyy-MM-dd"));
			rx.setNosubs(frm.getNosubs());
			rx.setPrn(frm.getPrn());
			rx.setSpecial(removeExtraChars(frm.getSpecial()));
			rx.setAtcCode(frm.getAtcCode());
			rx.setRegionalIdentifier(frm.getRegionalIdentifier());
			rx.setUnit(removeExtraChars(frm.getUnit()));
			rx.setUnitName(frm.getUnitName());
			rx.setMethod(frm.getMethod());
			rx.setRoute(frm.getRoute());
			rx.setCustomInstr(frm.getCustomInstr());
			rx.setDosage(removeExtraChars(frm.getDosage()));
			rx.setOutsideProviderName(frm.getOutsideProviderName());
			rx.setOutsideProviderOhip(frm.getOutsideProviderOhip());
			rx.setLongTerm(frm.getLongTerm());
			rx.setShortTerm(frm.getShortTerm());
			rx.setPastMed(frm.getPastMed());
			rx.setPatientCompliance(frm.getPatientCompliance());

			try {
				rx.setDrugForm(drugData.getDrugForm(String.valueOf(frm.getGCN_SEQNO())));
			} catch (Exception e) {
				logger.error("Unable to get DrugForm from drugref");
			}

			logger.debug("SAVING STASH " + rx.getCustomInstr());
			if (rx.getSpecial() == null) {
				logger.error("Drug.special is null : " + rx.getSpecial() + " : " + frm.getSpecial());
			} else if (rx.getSpecial().length() < 6) {
				logger.warn("Drug.special appears to be empty : " + rx.getSpecial() + " : " + frm.getSpecial());
			}

			String annotation_attrib = request.getParameter("annotation_attrib");
			if (annotation_attrib == null) {
				annotation_attrib = "";
			}

			bean.addAttributeName(annotation_attrib, bean.getStashIndex());
			bean.setStashItem(bean.getStashIndex(), rx);
			rx = null;

			if (frm.getAction().equals("update")) {
				fwd = "refresh";
			}
			if (frm.getAction().equals("updateAddAnother")) {
				fwd = "addAnother";
			}
			if (frm.getAction().equals("updateAndPrint")) {
				// SAVE THE DRUG
				int i;
				String scriptId = prescription.saveScript(loggedInInfo, bean);
				@SuppressWarnings("unchecked")
				ArrayList<String> attrib_names = bean.getAttributeNames();
				// p("attrib_names", attrib_names.toString());
				StringBuilder auditStr = new StringBuilder();
				for (i = 0; i < bean.getStashSize(); i++) {
					rx = bean.getStashItem(i);

					rx.Save(scriptId);
					auditStr.append(rx.getAuditString());
					auditStr.append("\n");

					/* Save annotation */
					HttpSession se = request.getSession();
					WebApplicationContext ctx = WebApplicationContextUtils.getRequiredWebApplicationContext(se.getServletContext());
					CaseManagementManager cmm = (CaseManagementManager) ctx.getBean("caseManagementManager");
					String attrib_name = attrib_names.get(i);
					if (attrib_name != null) {
						CaseManagementNote cmn = (CaseManagementNote) se.getAttribute(attrib_name);
						if (cmn != null) {
							cmm.saveNoteSimple(cmn);
							CaseManagementNoteLink cml = new CaseManagementNoteLink();
							cml.setTableName(CaseManagementNoteLink.DRUGS);
							cml.setTableId((long) rx.getDrugId());
							cml.setNoteId(cmn.getId());
							cmm.saveNoteLink(cml);
							se.removeAttribute(attrib_name);
							LogAction.addLog(cmn.getProviderNo(), LogConst.ANNOTATE, CaseManagementNoteLink.DISP_PRESCRIP, scriptId, request.getRemoteAddr(), cmn.getDemographic_no(), cmn.getNote());
						}
					}
					rx = null;
				}
				fwd = "viewScript";
				String ip = request.getRemoteAddr();
				request.setAttribute("scriptId", scriptId);
				LogAction.addLog((String) request.getSession().getAttribute("user"), LogConst.ADD, LogConst.CON_PRESCRIPTION, scriptId, ip, "" + bean.getDemographicNo(), auditStr.toString());
			}
		}
		return mapping.findForward(fwd);
	}

	public ActionForward updateReRxDrug(ActionMapping mapping, ActionForm form, HttpServletRequest request, HttpServletResponse response) throws IOException {
		checkPrivilege(LoggedInInfo.getLoggedInInfoFromSession(request), PRIVILEGE_WRITE);
		
		oscar.oscarRx.pageUtil.RxSessionBean bean = (oscar.oscarRx.pageUtil.RxSessionBean) request.getSession().getAttribute("RxSessionBean");
		if (bean == null) {
			response.sendRedirect("error.html");
			return null;
		}
		List<String> reRxDrugIdList = bean.getReRxDrugIdList();
		String action = request.getParameter("action");
		String drugId = request.getParameter("reRxDrugId");
		if (action.equals("addToReRxDrugIdList") && !reRxDrugIdList.contains(drugId)) {
			reRxDrugIdList.add(drugId);
		} else if (action.equals("removeFromReRxDrugIdList") && reRxDrugIdList.contains(drugId)) {
			reRxDrugIdList.remove(drugId);
		} else if (action.equals("clearReRxDrugIdList")) {
			bean.clearReRxDrugIdList();
		} else {
			logger.warn("WARNING: reRxDrugId not updated");
		}

		return null;

	}

	public ActionForward saveCustomName(ActionMapping mapping, ActionForm form, HttpServletRequest request, HttpServletResponse response) throws IOException {
		checkPrivilege(LoggedInInfo.getLoggedInInfoFromSession(request), PRIVILEGE_WRITE);
		
		oscar.oscarRx.pageUtil.RxSessionBean bean = (oscar.oscarRx.pageUtil.RxSessionBean) request.getSession().getAttribute("RxSessionBean");
		if (bean == null) {
			response.sendRedirect("error.html");
			return null;
		}
		try {
			String randomId = request.getParameter("randomId");
			String customName = request.getParameter("customName");
			RxPrescriptionData.Prescription rx = bean.getStashItem2(Integer.parseInt(randomId));
			if (rx == null) {
				logger.error("rx is null", new NullPointerException());
				return null;
			}
			rx.setCustomName(customName);
			rx.setBrandName(null);
			rx.setGenericName(null);
			bean.setStashItem(bean.getIndexFromRx(Integer.parseInt(randomId)), rx);

		} catch (Exception e) {
			logger.error("Error", e);
		}

		return null;
	}

	private void setDefaultQuantity(final HttpServletRequest request) {
		try {
			WebApplicationContext ctx = WebApplicationContextUtils.getRequiredWebApplicationContext(request.getSession().getServletContext());
			String provider = (String) request.getSession().getAttribute("user");
			if (provider != null) {
				userPropertyDAO = (UserPropertyDAO) ctx.getBean("UserPropertyDAO");
				UserProperty prop = userPropertyDAO.getProp(provider, UserProperty.RX_DEFAULT_QUANTITY);
				if (prop != null) RxUtil.setDefaultQuantity(prop.getValue());
				else RxUtil.setDefaultQuantity(DEFAULT_QUANTITY);
			} else {
				logger.error("Provider is null", new NullPointerException());
			}
		} catch (Exception e) {
			logger.error("Error", e);
		}
	}

	private RxPrescriptionData.Prescription setCustomRxDurationQuantity(RxPrescriptionData.Prescription rx) {
		String quantity = rx.getQuantity();
		if (RxUtil.isMitte(quantity)) {
			String duration = RxUtil.getDurationFromQuantityText(quantity);
			String durationUnit = RxUtil.getDurationUnitFromQuantityText(quantity);
			rx.setDuration(duration);
			rx.setDurationUnit(durationUnit);
			rx.setQuantity(RxUtil.getQuantityFromQuantityText(quantity));
			rx.setUnitName(RxUtil.getUnitNameFromQuantityText(quantity));// this is actually an indicator for Mitte rx
		} else rx.setDuration(RxUtil.findDuration(rx));

		return rx;
	}

	public ActionForward newCustomNote(ActionMapping mapping, ActionForm form, HttpServletRequest request, HttpServletResponse response) throws IOException {
		logger.debug("=============Start newCustomNote RxWriteScriptAction.java===============");
		LoggedInInfo loggedInInfo = LoggedInInfo.getLoggedInInfoFromSession(request);
		checkPrivilege(loggedInInfo, PRIVILEGE_WRITE);
		
		oscar.oscarRx.pageUtil.RxSessionBean bean = (oscar.oscarRx.pageUtil.RxSessionBean) request.getSession().getAttribute("RxSessionBean");
		if (bean == null) {
			response.sendRedirect("error.html");
			return null;
		}

		try {
			RxPrescriptionData rxData = new RxPrescriptionData();

			// create Prescription
			RxPrescriptionData.Prescription rx = rxData.newPrescription(bean.getProviderNo(), bean.getDemographicNo());
			String ra = request.getParameter("randomId");
			rx.setRandomId(Integer.parseInt(ra));
			rx.setCustomNote(true);
			rx.setGenericName(null);
			rx.setBrandName(null);
			rx.setDrugForm("");
			rx.setRoute("");
			rx.setDosage("");
			rx.setUnit("");
			rx.setGCN_SEQNO(0);
			rx.setRegionalIdentifier("");
			rx.setAtcCode("");
			RxUtil.setDefaultSpecialQuantityRepeat(rx);
			rx = setCustomRxDurationQuantity(rx);
			bean.addAttributeName(rx.getAtcCode() + "-" + String.valueOf(bean.getStashIndex()));
			List<RxPrescriptionData.Prescription> listRxDrugs = new ArrayList();

			if (RxUtil.isRxUniqueInStash(bean, rx)) {
				listRxDrugs.add(rx);
			}
			int rxStashIndex = bean.addStashItem(loggedInInfo, rx);
			bean.setStashIndex(rxStashIndex);

			String today = null;
			Calendar calendar = Calendar.getInstance();
			SimpleDateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd");
			try {
				today = dateFormat.format(calendar.getTime());
				// p("today's date", today);
			} catch (Exception e) {
				logger.error("Error", e);
			}
			Date tod = RxUtil.StringToDate(today, "yyyy-MM-dd");
			rx.setRxDate(tod);
			rx.setWrittenDate(tod);

			request.setAttribute("listRxDrugs", listRxDrugs);
		} catch (Exception e) {
			logger.error("Error", e);
		}
		logger.debug("=============END newCustomNote RxWriteScriptAction.java===============");
		return (mapping.findForward("newRx"));
	}

	public ActionForward listPreviousInstructions(ActionMapping mapping, ActionForm form, HttpServletRequest request, HttpServletResponse response) throws IOException {
		checkPrivilege(LoggedInInfo.getLoggedInInfoFromSession(request), PRIVILEGE_READ);
		
		logger.debug("=============Start listPreviousInstructions RxWriteScriptAction.java===============");
		String randomId = request.getParameter("randomId");
		randomId = randomId.trim();
		// get rx from randomId.
		// if rx is normal drug, if din is not null, use din to find it
		// if din is null, use BN to find it
		// if rx is custom drug, use customName to find it.
		// append results to a list.
		RxSessionBean bean = (RxSessionBean) request.getSession().getAttribute("RxSessionBean");
		if (bean == null) {
			response.sendRedirect("error.html");
			return null;
		}
		// create Prescription
		RxPrescriptionData.Prescription rx = bean.getStashItem2(Integer.parseInt(randomId));
		List<HashMap<String, String>> retList = new ArrayList();
		retList = RxUtil.getPreviousInstructions(rx);

		bean.setListMedHistory(retList);
		return null;
	}

	public ActionForward newCustomDrug(ActionMapping mapping, ActionForm form, HttpServletRequest request, HttpServletResponse response) throws IOException {
		logger.debug("=============Start newCustomDrug RxWriteScriptAction.java===============");
		LoggedInInfo loggedInInfo = LoggedInInfo.getLoggedInInfoFromSession(request);
		checkPrivilege(loggedInInfo, PRIVILEGE_WRITE);
		
		MessageResources messages = getResources(request);
		// set default quantity;
		setDefaultQuantity(request);

		oscar.oscarRx.pageUtil.RxSessionBean bean = (oscar.oscarRx.pageUtil.RxSessionBean) request.getSession().getAttribute("RxSessionBean");
		if (bean == null) {
			response.sendRedirect("error.html");
			return null;
		}
		
		String customDrugName = request.getParameter("name");

		try {
			RxPrescriptionData rxData = new RxPrescriptionData();

			// create Prescription
			RxPrescriptionData.Prescription rx = rxData.newPrescription(bean.getProviderNo(), bean.getDemographicNo());
			String ra = request.getParameter("randomId");
			
			if(customDrugName != null && !customDrugName.isEmpty()) {
				rx.setCustomName(customDrugName);
			}
			rx.setRandomId(Integer.parseInt(ra));
			rx.setGenericName(null);
			rx.setBrandName(null);
			rx.setDrugForm("");
			rx.setRoute("");
			rx.setDosage("");
			rx.setUnit("");
			rx.setGCN_SEQNO(0);
			rx.setRegionalIdentifier("");
			rx.setAtcCode("");
			RxUtil.setDefaultSpecialQuantityRepeat(rx);// 1 OD, 20, 0;
			rx = setCustomRxDurationQuantity(rx);
			bean.addAttributeName(rx.getAtcCode() + "-" + String.valueOf(bean.getStashIndex()));
			List<RxPrescriptionData.Prescription> listRxDrugs = new ArrayList();

			if (RxUtil.isRxUniqueInStash(bean, rx)) {
				listRxDrugs.add(rx);
			}
			int rxStashIndex = bean.addStashItem(loggedInInfo, rx);
			bean.setStashIndex(rxStashIndex);

			String today = null;
			Calendar calendar = Calendar.getInstance();
			SimpleDateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd");
			try {
				today = dateFormat.format(calendar.getTime());
				// p("today's date", today);
			} catch (Exception e) {
				logger.error("Error", e);
			}
			Date tod = RxUtil.StringToDate(today, "yyyy-MM-dd");
			rx.setRxDate(tod);
			rx.setWrittenDate(tod);

			request.setAttribute("listRxDrugs", listRxDrugs);
		} catch (Exception e) {
			logger.error("Error", e);
		}
		return (mapping.findForward("newRx"));
	}

	public ActionForward normalDrugSetCustom(ActionMapping mapping, ActionForm form, HttpServletRequest request, HttpServletResponse response) throws IOException {
		checkPrivilege(LoggedInInfo.getLoggedInInfoFromSession(request), PRIVILEGE_WRITE);
		
		oscar.oscarRx.pageUtil.RxSessionBean bean = (oscar.oscarRx.pageUtil.RxSessionBean) request.getSession().getAttribute("RxSessionBean");
		if (bean == null) {
			response.sendRedirect("error.html");
			return null;
		}
		String randomId = request.getParameter("randomId");
		String customDrugName = request.getParameter("customDrugName");
		logger.debug("radomId=" + randomId);
		if (randomId != null && customDrugName != null) {
			RxPrescriptionData.Prescription normalRx = bean.getStashItem2(Integer.parseInt(randomId));
			if (normalRx != null) {// set other fields same as normal drug, set some fields null like custom drug, remove normal drugfrom stash,add customdrug to stash,
				// forward to prescribe.jsp
				RxPrescriptionData rxData = new RxPrescriptionData();
				RxPrescriptionData.Prescription customRx = rxData.newPrescription(bean.getProviderNo(), bean.getDemographicNo());
				customRx = normalRx;
				customRx.setCustomName(customDrugName);
				customRx.setRandomId(Long.parseLong(randomId));
				customRx.setGenericName(null);
				customRx.setBrandName(null);
				customRx.setDrugForm("");
				customRx.setRoute("");
				customRx.setDosage("");
				customRx.setUnit("");
				customRx.setGCN_SEQNO(0);
				customRx.setRegionalIdentifier("");
				customRx.setAtcCode("");
				bean.setStashItem(bean.getIndexFromRx(Integer.parseInt(randomId)), customRx);
				List<RxPrescriptionData.Prescription> listRxDrugs = new ArrayList();
				if (RxUtil.isRxUniqueInStash(bean, customRx)) {
					// p("unique");
					listRxDrugs.add(customRx);
				}
				request.setAttribute("listRxDrugs", listRxDrugs);
				return (mapping.findForward("newRx"));
			} else {

				return null;
			}
		} else {

			return null;
		}
	}

	

public ActionForward createNewRx(ActionMapping mapping, ActionForm form, HttpServletRequest request, HttpServletResponse response) throws IOException {
    logger.debug("=============Start createNewRx RxWriteScriptAction.java===============");
    LoggedInInfo loggedInInfo = LoggedInInfo.getLoggedInInfoFromSession(request);
    checkPrivilege(loggedInInfo, PRIVILEGE_WRITE);

    String success = "newRx";
    setDefaultQuantity(request);
    userPropertyDAO = (UserPropertyDAO) SpringUtils.getBean("UserPropertyDAO");

    oscar.oscarRx.pageUtil.RxSessionBean bean = (oscar.oscarRx.pageUtil.RxSessionBean) request.getSession().getAttribute("RxSessionBean");
    if (bean == null) {
        response.sendRedirect("error.html");
        return null;
    }

    try {
        RxPrescriptionData rxData = new RxPrescriptionData();
        RxPrescriptionData.Prescription rx = rxData.newPrescription(bean.getProviderNo(), bean.getDemographicNo());

        String ra = request.getParameter("randomId");
        int randomId = Integer.parseInt(ra);
        rx.setRandomId(randomId);
        String drugId = request.getParameter("drugId");
        String text = request.getParameter("text");
		String din = request.getParameter("din");
		// System.out.println("Drug DIN from Request in create new rx is: " + din);


		// System.out.println("drugid is: " + drugId);

        // API call to get drug data
        // String apiUrl = "https://oatrx.ca/api/fetch-drug-data?search=" + drugId;
		String apiUrl = "https://oatrx.ca/api/fetch-drug-data?search=" + URLEncoder.encode(din, "UTF-8");
		// System.out.println("Fetching drug data from API: " + apiUrl);

        CloseableHttpClient httpClient = HttpClients.createDefault();
        HttpGet httpGet = new HttpGet(apiUrl);
        HttpResponse apiResponse = httpClient.execute(httpGet);
        String jsonResponse = EntityUtils.toString(apiResponse.getEntity());
        httpClient.close();

        // Parse JSON response
        // Log raw API response
// System.out.println("Raw API Response: " + jsonResponse);

JSONObject dmono = new JSONObject(jsonResponse);
JSONArray dataArray = dmono.optJSONArray("data");
String drugForm = "";          // Initialize empty variables
String brandName = "";
String genericName = "";
String atcCode = "";
String regionalIdentifier = "";
String drugCategory = ""; 
String route = "";

if (dataArray != null) {
    // System.out.println("Data Array Found. Size: " + dataArray.length());
} else {
    System.out.println("Data Array is null!");
}

if (dataArray != null && dataArray.length() > 0) {
    JSONObject firstDrug = dataArray.getJSONObject(0);
    // System.out.println("First Drug Object: " + firstDrug.toString());

    // Log all keys
    // for (String key : firstDrug.keySet()) {
    //     System.out.println("Key in first object: [" + key + "]");
    // }

    Object routeObj = firstDrug.opt("route");

    if (routeObj instanceof JSONArray) {
        JSONArray routeArray = (JSONArray) routeObj;
        if (routeArray.length() > 0) {
            route = routeArray.getString(0); // Take the first one
        }
    } else if (routeObj instanceof String) {
        route = (String) routeObj;
    }

    if (!route.isEmpty()) {
		route = route.trim();
		rx.setRoute(route);
		request.setAttribute("drugRoute", route); // Optional: for use in JSP
	
		// Log to Tomcat console
		System.out.println("===== Route fetched from API in create new rx: " + route);
	}
	

    // Extract and log dosage_form
    drugForm = firstDrug.optString("dosage_form", "Not Found");

	drugCategory = firstDrug.optString("drug_category", "Not Found");

// Extract the group name directly
String groupName = firstDrug.optString("group_name", "Not Found");

// Use groupName directly for drugName
String drugName = groupName;          // Use "group_name" for drugName

// Extract technical reasons and SIGs from the API response
JSONArray technicalReasonsArray = firstDrug.optJSONArray("technical_reasons");
List<String> technicalReasons = new ArrayList<>();
Map<String, List<String>> sigMap = new HashMap<>();  // Map to store SIGs for each reason

if (technicalReasonsArray != null) {
    for (int i = 0; i < technicalReasonsArray.length(); i++) {
        JSONObject reasonObject = technicalReasonsArray.getJSONObject(i);
        String technicalReason = reasonObject.optString("technical_reason", "");

        if (!technicalReason.isEmpty()) {
            technicalReasons.add(technicalReason);

            // Extract SIGs for each reason
            JSONArray sigsArray = reasonObject.optJSONArray("sigs");
            List<String> sigs = new ArrayList<>();
            if (sigsArray != null) {
                for (int j = 0; j < sigsArray.length(); j++) {
                    String sig = sigsArray.getJSONObject(j).optString("sig", "");
                    if (!sig.isEmpty()) {
                        sigs.add(sig);
                    }
                }
            }
            sigMap.put(technicalReason, sigs);  // Store SIGs for the reason
        }
    }
}

// Pass technical reasons and SIG map to JSP
request.setAttribute("technicalReasons", technicalReasons);
request.setAttribute("sigMap", sigMap);  // Pass SIG map
// System.out.println("Technical Reasons: " + technicalReasons);
// System.out.println("SIG Map: " + sigMap);




// Use drugName directly for brandName and genericName
brandName = drugName;          // Use "name" for brandName
genericName = drugName;        // Use "name" for genericName


    // Extract and log atcCode (if it exists)
    atcCode = firstDrug.optString("atc", "Not Found");

    // Extract and log regionalIdentifier (if it exists)
    regionalIdentifier = firstDrug.optString("regionalIdentifier", "Not Found");

} else {
    System.out.println("No valid data in API response.");
}



        // Handle drug components
        JSONArray components = dmono.optJSONArray("components");
        StringBuilder stringBuilder = new StringBuilder();
        if (components != null && components.length() > 0) {
            for (int i = 0; i < components.length(); i++) {
                JSONObject drugComponent = components.getJSONObject(i);
                stringBuilder.append(drugComponent.optString("name", ""))
                             .append(" ")
                             .append(drugComponent.optString("strength", ""))
                             .append(" ")
                             .append(drugComponent.optString("unit", ""));
                if (i < components.length() - 1) {
                    stringBuilder.append(" / ");
                }
            }
        }
        rx.setGenericName(stringBuilder.length() > 0 ? stringBuilder.toString() : genericName);
        rx.setBrandName(brandName);

        // Set drug form
        if (drugForm.contains(",")) {
            rx.setDrugForm(drugForm.split(",")[0]);
        } else {
            rx.setDrugForm(drugForm);
        }
        rx.setDrugFormList(drugForm);

		// Pass the drug form to the JSP page
		request.setAttribute("drugForm", rx.getDrugForm());
		request.setAttribute("drugCategory", drugCategory);

        // Handle dosage and unit
        String dosage = "";
        String unit = "";
        if (components != null) {
            for (int i = 0; i < components.length(); i++) {
                JSONObject drugComp = components.getJSONObject(i);
                String strength = drugComp.optString("strength", "");
                unit = drugComp.optString("unit", "");
                dosage += " " + strength + " " + unit;
            }
        }
        rx.setDosage(removeExtraChars(dosage));
        rx.setUnit(removeExtraChars(unit));

        // Set other drug information
        rx.setGCN_SEQNO(Integer.parseInt(drugId));
        rx.setRegionalIdentifier(regionalIdentifier);
        rx.setAtcCode(atcCode);
        RxUtil.setSpecialQuantityRepeat(rx);
        rx = setCustomRxDurationQuantity(rx);

        // Save to session
        List<RxPrescriptionData.Prescription> listRxDrugs = new ArrayList<>();
        if (RxUtil.isRxUniqueInStash(bean, rx)) {
            listRxDrugs.add(rx);
        }
        bean.addAttributeName(rx.getAtcCode() + "-" + bean.getStashIndex());
        int rxStashIndex = bean.addStashItem(loggedInInfo, rx);
        bean.setStashIndex(rxStashIndex);

        // Set dates
        String today = new SimpleDateFormat("yyyy-MM-dd").format(Calendar.getInstance().getTime());
        Date tod = RxUtil.StringToDate(today, "yyyy-MM-dd");
        rx.setRxDate(tod);
        rx.setWrittenDate(tod);
        rx.setDiscontinuedLatest(RxUtil.checkDiscontinuedBefore(rx));

        request.setAttribute("listRxDrugs", listRxDrugs);
    } catch (Exception e) {
        logger.error("Error", e);
    }
    logger.debug("=============END createNewRx RxWriteScriptAction.java===============");
    return mapping.findForward(success);
}

	@SuppressWarnings("unused")
	public ActionForward updateDrug(ActionMapping mapping, ActionForm form, HttpServletRequest request, HttpServletResponse response) throws IOException {
		checkPrivilege(LoggedInInfo.getLoggedInInfoFromSession(request), PRIVILEGE_WRITE);
		
		oscar.oscarRx.pageUtil.RxSessionBean bean = (oscar.oscarRx.pageUtil.RxSessionBean) request.getSession().getAttribute("RxSessionBean");
		if (bean == null) {
			response.sendRedirect("error.html");
			return null;
		}

		String action = request.getParameter("action");

		if ("parseInstructions".equals(action)) {

			try {
				String randomId = request.getParameter("randomId");
				RxPrescriptionData.Prescription rx = bean.getStashItem2(Integer.parseInt(randomId));
				if (rx == null) {
					logger.error("rx is null", new NullPointerException());
				}

				String instructions = request.getParameter("instruction");
				logger.debug("instruction:"+instructions);
				rx.setSpecial(instructions);
				RxUtil.instrucParser(rx);
				bean.addAttributeName(rx.getAtcCode() + "-" + String.valueOf(bean.getIndexFromRx(Integer.parseInt(randomId))));
				bean.setStashItem(bean.getIndexFromRx(Integer.parseInt(randomId)), rx);
				
				HashMap<String, Object> hm = new HashMap<String, Object>();

				if (rx.getRoute() == null || rx.getRoute().equalsIgnoreCase("null")) {
					rx.setRoute("");
				}

				hm.put("method", rx.getMethod());
				hm.put("takeMin", rx.getTakeMin());
				hm.put("takeMax", rx.getTakeMax());
				hm.put("duration", rx.getDuration());
				hm.put("frequency", rx.getFrequencyCode());
				hm.put("route", rx.getRoute());
				hm.put("durationUnit", rx.getDurationUnit());
				hm.put("prn", rx.getPrn());
				hm.put("calQuantity", rx.getQuantity());
				hm.put("unitName", rx.getUnitName());
				hm.put("policyViolations", rx.getPolicyViolations());
				JSONObject jsonObject = new JSONObject(hm);
				logger.debug("jsonObject:"+jsonObject.toString());
				response.getOutputStream().write(jsonObject.toString().getBytes());
			} catch (Exception e) {
				logger.error("Error", e);
			}
			
		} else if ("updateQty".equals(action)) {
			
			try {
				String quantity = request.getParameter("quantity");
				String randomId = request.getParameter("randomId");
				RxPrescriptionData.Prescription rx = bean.getStashItem2(Integer.parseInt(randomId));
				// get rx from randomId
				if (quantity == null || quantity.equalsIgnoreCase("null")) {
					quantity = "";
				}
				// check if quantity is same as rx.getquantity(), if yes, do nothing.
				if (quantity.equals(rx.getQuantity()) && rx.getUnitName() == null) {
					// do nothing
				} else {

					if (RxUtil.isStringToNumber(quantity)) {
						rx.setQuantity(quantity);
						rx.setUnitName(null);
					} else if (RxUtil.isMitte(quantity)) {// set duration for mitte

						String duration = RxUtil.getDurationFromQuantityText(quantity);
						String durationUnit = RxUtil.getDurationUnitFromQuantityText(quantity);
						rx.setDuration(duration);
						rx.setDurationUnit(durationUnit);
						rx.setQuantity(RxUtil.getQuantityFromQuantityText(quantity));
						rx.setUnitName(RxUtil.getUnitNameFromQuantityText(quantity));// this is actually an indicator for Mitte rx
					} else {
						rx.setQuantity(RxUtil.getQuantityFromQuantityText(quantity));
						rx.setUnitName(RxUtil.getUnitNameFromQuantityText(quantity));
					}

					String frequency = rx.getFrequencyCode();
					String takeMin = rx.getTakeMinString();
					String takeMax = rx.getTakeMaxString();
					String durationUnit = rx.getDurationUnit();
					double nPerDay = 0d;
					double nDays = 0d;
					if (rx.getUnitName() != null || takeMin.equals("0") || takeMax.equals("0") || frequency.equals("")) {
					} else {
						if (durationUnit.equals("")) {
							durationUnit = "D";
						}

						nPerDay = RxUtil.findNPerDay(frequency);
						nDays = RxUtil.findNDays(durationUnit);
						if (RxUtil.isStringToNumber(quantity) && !rx.isDurationSpecifiedByUser()) {// don't not caculate duration if it's already specified by the user
							double qtyD = Double.parseDouble(quantity);
							// quantity=takeMax * nDays * duration * nPerDay
							double durD = qtyD / ((Double.parseDouble(takeMax)) * nPerDay * nDays);
							int durI = (int) durD;
							rx.setDuration(Integer.toString(durI));
						} else {
							// don't calculate duration if quantity can't be parsed to string
						}
						rx.setDurationUnit(durationUnit);
					}
					// duration=quantity divide by no. of pills per duration period.
					// if not, recalculate duration based on frequency if frequency is not empty
					// if there is already a duration uni present, use that duration unit. if not, set duration unit to days, and output duration in days
				}
				bean.addAttributeName(rx.getAtcCode() + "-" + String.valueOf(bean.getIndexFromRx(Integer.parseInt(randomId))));
				bean.setStashItem(bean.getIndexFromRx(Integer.parseInt(randomId)), rx);

				if (rx.getRoute() == null) {
					rx.setRoute("");
				}
				HashMap<String, Object> hm = new HashMap<String, Object>();
				hm.put("method", rx.getMethod());
				hm.put("takeMin", rx.getTakeMin());
				hm.put("takeMax", rx.getTakeMax());
				hm.put("duration", rx.getDuration());
				hm.put("frequency", rx.getFrequencyCode());
				hm.put("route", rx.getRoute());
				hm.put("durationUnit", rx.getDurationUnit());
				hm.put("prn", rx.getPrn());
				hm.put("calQuantity", rx.getQuantity());
				hm.put("unitName", rx.getUnitName());
				JSONObject jsonObject = new JSONObject(hm);
				response.getOutputStream().write(jsonObject.toString().getBytes());
			} catch (Exception e) {
				logger.error("Error", e);
			}
		} else if ("updateLongTerm".equals(action)) {

			try {
				String randomId = request.getParameter("randomId");
				String longTermValue = request.getParameter("longTerm");
				RxPrescriptionData.Prescription rx = bean.getStashItem2(Integer.parseInt(randomId));
		
				if (longTermValue != null) {
					Boolean longTerm = "true".equalsIgnoreCase(longTermValue); // Parse string to Boolean
					rx.setLongTerm(longTerm);
				}
		
				// Update the RxSessionBean with the modified Prescription
				bean.addAttributeName(rx.getAtcCode() + "-" + String.valueOf(bean.getIndexFromRx(Integer.parseInt(randomId))));
				bean.setStashItem(bean.getIndexFromRx(Integer.parseInt(randomId)), rx);
		
				response.getWriter().write("LongTerm updated successfully");
			} catch (Exception e) {
				logger.error("Error updating longTerm", e);
			}
		}else if ("updateStartDate".equals(action)) {

			try {
				String randomId = request.getParameter("randomId");
				String startDate = request.getParameter("startDate");
				RxPrescriptionData.Prescription rx = bean.getStashItem2(Integer.parseInt(randomId));
		
				if (startDate != null && !startDate.isEmpty()) {
					rx.setRxDate(RxUtil.StringToDate(startDate, "yyyy-MM-dd"));
				}
		
				bean.addAttributeName(rx.getAtcCode() + "-" + String.valueOf(bean.getIndexFromRx(Integer.parseInt(randomId))));
				bean.setStashItem(bean.getIndexFromRx(Integer.parseInt(randomId)), rx);
				response.getWriter().write("Start date updated successfully");
			} catch (Exception e) {
				logger.error("Error", e);
			}
		
		}else if ("updateDuration".equals(action)) {

			try {
				String randomId = request.getParameter("randomId");
				String duration = request.getParameter("duration");
				RxPrescriptionData.Prescription rx = bean.getStashItem2(Integer.parseInt(randomId));
		
				if (duration != null && !duration.isEmpty()) {
					rx.setDuration(duration);
				}
		
				bean.addAttributeName(rx.getAtcCode() + "-" + String.valueOf(bean.getIndexFromRx(Integer.parseInt(randomId))));
				bean.setStashItem(bean.getIndexFromRx(Integer.parseInt(randomId)), rx);
				response.getWriter().write("Duration updated successfully");
			} catch (Exception e) {
				logger.error("Error", e);
			}
		
		}else if ("updateEndDate".equals(action)) {

			try {
				String randomId = request.getParameter("randomId");
				String endDate = request.getParameter("endDate");
				RxPrescriptionData.Prescription rx = bean.getStashItem2(Integer.parseInt(randomId));
		
				if (endDate != null && !endDate.isEmpty()) {
					rx.setEndDate(RxUtil.StringToDate(endDate, "yyyy-MM-dd"));
				}
		
				bean.addAttributeName(rx.getAtcCode() + "-" + String.valueOf(bean.getIndexFromRx(Integer.parseInt(randomId))));
				bean.setStashItem(bean.getIndexFromRx(Integer.parseInt(randomId)), rx);
				response.getWriter().write("End date updated successfully");
			} catch (Exception e) {
				logger.error("Error", e);
			}
		}
			
		return null;

	}

	public ActionForward iterateStash(ActionMapping mapping, ActionForm form, HttpServletRequest request, HttpServletResponse response)  {
		oscar.oscarRx.pageUtil.RxSessionBean bean = (oscar.oscarRx.pageUtil.RxSessionBean) request.getSession().getAttribute("RxSessionBean");
		List<RxPrescriptionData.Prescription> listP = Arrays.asList(bean.getStash());
		if (listP.size() == 0) {
			return null;
		} else {
			request.setAttribute("listRxDrugs", listP);
			return (mapping.findForward("newRx"));
		}

	}

	public ActionForward updateSpecialInstruction(ActionMapping mapping, ActionForm form, HttpServletRequest request, HttpServletResponse response) throws Exception {
		checkPrivilege(LoggedInInfo.getLoggedInInfoFromSession(request), PRIVILEGE_WRITE);
		
		// get special instruction from parameter
		// get rx from random Id
		// rx.setspecialisntruction
		String randomId = request.getParameter("randomId");
		String specialInstruction = request.getParameter("specialInstruction");
		oscar.oscarRx.pageUtil.RxSessionBean bean = (oscar.oscarRx.pageUtil.RxSessionBean) request.getSession().getAttribute("RxSessionBean");
		RxPrescriptionData.Prescription rx = bean.getStashItem2(Integer.parseInt(randomId));
		if (specialInstruction.trim().length() > 0 && !specialInstruction.trim().equalsIgnoreCase("Enter Special Instruction")) {
			rx.setSpecialInstruction(specialInstruction.trim());
		} else {
			rx.setSpecialInstruction(null);
		}

		return null;
	}

	public ActionForward updateProperty(ActionMapping mapping, ActionForm form, HttpServletRequest request, HttpServletResponse response) throws Exception {
		checkPrivilege(LoggedInInfo.getLoggedInInfoFromSession(request), PRIVILEGE_WRITE);
		
		oscar.oscarRx.pageUtil.RxSessionBean bean = (oscar.oscarRx.pageUtil.RxSessionBean) request.getSession().getAttribute("RxSessionBean");
		String elem = request.getParameter("elementId");
		String val = request.getParameter("propertyValue");
		val = val.trim();
		if (elem != null && val != null) {
			String[] strArr = elem.split("_");
			if (strArr.length > 1) {
				String num = strArr[1];
				num = num.trim();
				RxPrescriptionData.Prescription rx = bean.getStashItem2(Integer.parseInt(num));
				if (elem.equals("method_" + num)) {
					if (!val.equals("") && !val.equalsIgnoreCase("null")) rx.setMethod(val);
				} else if (elem.equals("route_" + num)) {
					if (!val.equals("") && !val.equalsIgnoreCase("null")) rx.setRoute(val);
				} else if (elem.equals("frequency_" + num)) {
					if (!val.equals("") && !val.equalsIgnoreCase("null")) rx.setFrequencyCode(val);
				} else if (elem.equals("minimum_" + num)) {
					if (!val.equals("") && !val.equalsIgnoreCase("null")) rx.setTakeMin(Float.parseFloat(val));
				} else if (elem.equals("maximum_" + num)) {
					if (!val.equals("") && !val.equalsIgnoreCase("null")) rx.setTakeMax(Float.parseFloat(val));
				} else if (elem.equals("duration_" + num)) {
					if (!val.equals("") && !val.equalsIgnoreCase("null")) rx.setDuration(val);
				} else if (elem.equals("durationUnit_" + num)) {
					if (!val.equals("") && !val.equalsIgnoreCase("null")) rx.setDurationUnit(val);
				} else if (elem.equals("repeats_" + num)) {
					if (!val.equals("") && !val.equalsIgnoreCase("null")) rx.setRepeat(Integer.parseInt(val));
				} else if (elem.equals("prnVal_" + num)) {
					if (!val.equals("") && !val.equalsIgnoreCase("null")) {
						if (val.equalsIgnoreCase("true")) rx.setPrn(true);
						else rx.setPrn(false);
					} else rx.setPrn(false);
				}
			}
		}
		return null;
	}

	public ActionForward updateSaveAllDrugs(ActionMapping mapping, ActionForm form, HttpServletRequest request, HttpServletResponse response) throws IOException, ServletException, Exception {
		checkPrivilege(LoggedInInfo.getLoggedInInfoFromSession(request), PRIVILEGE_WRITE);

		// Generate a unique prescription batch ID for this prescription session
		String prescriptionBatchId = request.getParameter("prescriptionBatchId");
		// System.out.println("Generated Prescription Batch ID in updatesavealldrugs writescriptclass: " + prescriptionBatchId);

		
		oscar.oscarRx.pageUtil.RxSessionBean bean = (oscar.oscarRx.pageUtil.RxSessionBean) request.getSession().getAttribute("RxSessionBean");
		request.getSession().setAttribute("rePrint", null);// set to print.
		List<String> paramList = new ArrayList<String>();
		Enumeration em = request.getParameterNames();
		List<String> randNum = new ArrayList<String>();
		while (em.hasMoreElements()) {
			String ele = em.nextElement().toString();
			paramList.add(ele);
			if (ele.startsWith("drugName_")) {
				String rNum = ele.substring(9);
				if (!randNum.contains(rNum)) {
					randNum.add(rNum);
				}
			}
		}

		List<Integer> allIndex = new ArrayList();
		for (int i = 0; i < bean.getStashSize(); i++) {
			allIndex.add(i);
		}

		List<Integer> existingIndex = new ArrayList();
		for (String num : randNum) {
			int stashIndex = bean.getIndexFromRx(Integer.parseInt(num));
			try {
				if (stashIndex == -1) {
					continue;
				} else {
					existingIndex.add(stashIndex);
					RxPrescriptionData.Prescription rx = bean.getStashItem(stashIndex);

					Boolean patientCompliance = null;
					boolean isOutsideProvider = false;
					Boolean isLongTerm = null;
					boolean isShortTerm = false;
					Boolean isPastMed = null;
					boolean isDispenseInternal=false;
					boolean isStartDateUnknown = false;
	                boolean isNonAuthoritative = false;
	                boolean nosubs = false;
	                Date pickupDate = null;
	                Date pickupTime = null;

					em = request.getParameterNames();
					while (em.hasMoreElements()) {
						String elem = (String) em.nextElement();
						String val = request.getParameter(elem);
						val = val.trim();
						if (elem.startsWith("drugName_" + num)) {
							if (rx.isCustom()) {
								rx.setCustomName(val);
								rx.setBrandName(null);
								rx.setGenericName(null);
							} else {
								rx.setBrandName(val);
							}
						} else if("rxPharmacyId".equals(elem)) {
							if(val != null && ! val.isEmpty()) {
								rx.setPharmacyId(Integer.parseInt(val));
							}
						} else if (elem.equals("repeats_" + num)) {
							if (val.equals("") || val == null) {
								rx.setRepeat(0);
							} else {
								rx.setRepeat(Integer.parseInt(val));
							}
						
						}else if (elem.equals("route_" + num)) {
							System.out.println("[DEBUG] Setting route: " + val);
							rx.setRoute(val); // Make sure your Prescription class has a route field and setter
						} else if (elem.equals("startDate_" + num)) {
							rx.setStartDate(RxUtil.StringToDate(val, "yyyy-MM-dd"));
						} else if (elem.equals("duration_" + num)) {
							rx.setDuration(val);
						} else if (elem.equals("endDate_" + num)) {
							String endDateValue = val.trim(); 
							rx.setEndDate_p(endDateValue);
							if ((endDateValue == null) || (endDateValue.equals(""))) {
								rx.setEndDate(null); 
								// System.out.println("DEBUG: endDate is empty, set to NULL.");
							} else {
								Date parsedEndDate = RxUtil.StringToDate(endDateValue, "yyyy-MM-dd");
								rx.setEndDate(parsedEndDate);  
								// System.out.println("DEBUG: endDate received: " + endDateValue);
								// System.out.println("DEBUG: endDate set to: " + rx.getEndDate());
							}
						}
						
						 else if(elem.equals("codingSystem_" + num)) {
							if(val != null) {
								rx.setDrugReasonCodeSystem(val);
							}
							
						} else if(elem.equals("reasonCode_" + num)) {
							if(val != null) {
								rx.setDrugReasonCode(val);
							}
						} else if (elem.equals("instructions_" + num)) {
							rx.setSpecial(val);
						} else if (elem.equals("quantity_" + num)) {
							if (val.equals("") || val == null) {
								rx.setQuantity("0");
							} else {
								if (RxUtil.isStringToNumber(val)) {
									rx.setQuantity(val);
									rx.setUnitName(null);
								} else {
									rx.setQuantity(RxUtil.getQuantityFromQuantityText(val));
									rx.setUnitName(RxUtil.getUnitNameFromQuantityText(val));
								}
							}
						} if (elem.equals("longTerm_" + num)) {
							switch (val.toLowerCase()) {
								case "yes":
									rx.setLongTerm(true);
									break;
								case "no":
									rx.setLongTerm(false);
									break;
								default:
									rx.setLongTerm(null);  // For "Long Term" or unexpected values
							}
							// System.out.println("DEBUG: Payload Value for longTerm: " + val);
							// System.out.println("DEBUG: Converted LongTerm Value Set: " + rx.getLongTerm());
						}
						 else if (elem.equals("compliance_" + num)) {
							String complianceValue = val.trim().toLowerCase(); // Retrieve dropdown value
							rx.setPatientCompliance_p(complianceValue); // Map dropdown to Prescription class
						
							if ("no".equals(complianceValue)) {
								String frequencyValue = request.getParameter("frequency_" + num);
								if (frequencyValue != null && !frequencyValue.isEmpty()) {
									rx.setFrequency(frequencyValue); // Map frequency to Prescription class
								}
							}
						}
						
						else if (elem.equals("shortTerm_" + num)) {
							if (val.equals("on")) {
								isShortTerm = true;
							} else {
								isShortTerm = false;
							}	
                        } else if (elem.equals("nonAuthoritativeN_" + num)) {
							if (val.equals("on")) {
								isNonAuthoritative = true;
							} else {
								isNonAuthoritative = false;
							}
                        } else if (elem.equals("nosubs_" + num)) {
							nosubs = "on".equals(val);
                        } else if(elem.equals("refillDuration_"+num)) {
                        	rx.setRefillDuration(Integer.parseInt(val));
                        } else if(elem.equals("refillQuantity_"+num)) {
                        	rx.setRefillQuantity(Integer.parseInt(val));
                        } else if(elem.equals("dispenseInterval_"+num)) {
                        	rx.setDispenseInterval(val);
                        } else if(elem.equals("protocol_"+num)) {
                        	rx.setProtocol(val);
                        } else if(elem.equals("priorRxProtocol_"+num)) {
                        	rx.setPriorRxProtocol(val);
						} else if (elem.equals("lastRefillDate_" + num)) {
							rx.setLastRefillDate(RxUtil.StringToDate(val, "yyyy-MM-dd"));
						}else if (elem.equals("startDate_" + num)) {  // Check if startDate is passed from frontend
							if ((val == null) || (val.equals(""))) {
								rx.setRxDate(null);  // Save as NULL if empty
								// System.out.println("DEBUG: startDate is empty, rxDate set to NULL.");
							} else {
								Date parsedDate = RxUtil.StringToDate(val, "yyyy-MM-dd");
								rx.setRxDate(parsedDate);  // Save startDate as rxDate
								// System.out.println("DEBUG: startDate received: " + val);
								// System.out.println("DEBUG: rxDate set to: " + rx.getRxDate());
							}							
						}
						 else if (elem.equals("pickupDate_" + num)) {
							if ((val != null) && (! val.equals(""))) {
								pickupDate = RxUtil.StringToDate(val, "yyyy-MM-dd");
							} 														
                       } else if (elem.equals("pickupTime_" + num)) {
							if ((val != null) && (!val.equals(""))) {
								pickupTime = RxUtil.StringToDate(val, "hh:mm");
							}							
						} else if (elem.equals("writtenDate_" + num)) {
							if (val == null || (val.equals(""))) {
								rx.setWrittenDate(RxUtil.StringToDate("0000-00-00", "yyyy-MM-dd"));
							} else {
								rx.setWrittenDateFormat(partialDateDao.getFormat(val));
								rx.setWrittenDate(partialDateDao.StringToDate(val));
							}

						} else if (elem.equals("outsideProviderName_" + num)) {
							rx.setOutsideProviderName(val);
						} else if (elem.equals("outsideProviderOhip_" + num)) {
							if (val.equals("") || val == null) {
								rx.setOutsideProviderOhip("0");
							} else {
								rx.setOutsideProviderOhip(val);
							}
						} else if (elem.equals("ocheck_" + num)) {
							if (val.equals("on")) {
								isOutsideProvider = true;
							} else {
								isOutsideProvider = false;
							}
						} else if (elem.equals("pastMed_" + num)) {
							if ("yes".equals(val)) {
								isPastMed = true;
							} else if("no".equals(val)) {
								isPastMed = false;
							} 
						} else if (elem.equals("dispenseInternal_" + num)) {
							if (val.equals("on")) {
								isDispenseInternal = true;
							} else {
								isDispenseInternal = false;
							}
						} else if (elem.equals("startDateUnknown_" + num)) {
							if (val.equals("on")) {
								isStartDateUnknown = true;
							} else {
								isStartDateUnknown = false;
							}
						} else if (elem.equals("instructions_" + num)) {
							// System.out.println("Received instructions value for comment: " + val);
							rx.setComment(val);
						} else if (elem.equals("patientCompliance_" + num)) {
							if ("yes".equals(val)) {
								patientCompliance = true;
							} else if ("no".equals(val)) {
								patientCompliance = false;
							}
						} else if (elem.equals("eTreatmentType_"+num)){
							if("--".equals(val)){
							   rx.setETreatmentType(null);
							}else{
							   rx.setETreatmentType(val);
							}
						} else if (elem.equals("rxStatus_"+num)){
							if("--".equals(val)){
							   rx.setRxStatus(null);
							}else{
							   rx.setRxStatus(val);
							}
						} else if (elem.equals("drugForm_"+num)){
							rx.setDrugForm(val);
						}

					}

					if (!isOutsideProvider) {
						rx.setOutsideProviderName("");
						rx.setOutsideProviderOhip("");
					}
					rx.setPastMed(isPastMed);
					rx.setDispenseInternal(isDispenseInternal);
					rx.setPatientCompliance(patientCompliance);
					rx.setStartDateUnknown(isStartDateUnknown);
					// rx.setLongTerm(isLongTerm);
					rx.setShortTerm(isShortTerm);
                    rx.setNonAuthoritative(isNonAuthoritative);
                    rx.setNosubs(nosubs);
					String newline = System.getProperty("line.separator");
					
					if( pickupDate != null && pickupTime != null ) {
						rx.setPickupDate(RxUtil.combineDateTime(pickupDate, pickupTime));
					} else if(pickupTime != null) {
						rx.setPickupDate(RxUtil.combineDateTime(new Date(), pickupTime));
					} else {
						rx.setPickupDate(pickupDate);
					}

					String special;
					if (rx.isCustomNote()) {
						rx.setQuantity(null);
						rx.setUnitName(null);
						rx.setRepeat(0);
						special = rx.getCustomName() + newline + rx.getSpecial();
						if (rx.getSpecialInstruction() != null && !rx.getSpecialInstruction().equalsIgnoreCase("null") && rx.getSpecialInstruction().trim().length() > 0) special += newline + rx.getSpecialInstruction();
					} else if (rx.isCustom()) {// custom drug
						if (rx.getUnitName() == null) {
							special = rx.getCustomName() + newline + rx.getSpecial();
							if (rx.getSpecialInstruction() != null && !rx.getSpecialInstruction().equalsIgnoreCase("null") && rx.getSpecialInstruction().trim().length() > 0) special += newline + rx.getSpecialInstruction();
							special += newline + "Qty:" + rx.getQuantity() + " Repeats:" + "" + rx.getRepeat();
						} else {
							special = rx.getCustomName() + newline + rx.getSpecial();
							if (rx.getSpecialInstruction() != null && !rx.getSpecialInstruction().equalsIgnoreCase("null") && rx.getSpecialInstruction().trim().length() > 0) special += newline + rx.getSpecialInstruction();
							special += newline + "Qty:" + rx.getQuantity() + " " + rx.getUnitName() + " Repeats:" + "" + rx.getRepeat();
						}
					} else {// non-custom drug
						if (rx.getUnitName() == null) {
							special = rx.getBrandName() + newline + rx.getSpecial();
							if (rx.getSpecialInstruction() != null && !rx.getSpecialInstruction().equalsIgnoreCase("null") && rx.getSpecialInstruction().trim().length() > 0) special += newline + rx.getSpecialInstruction();

							special += newline + "Qty:" + rx.getQuantity() + " Repeats:" + "" + rx.getRepeat();
						} else {
							special = rx.getBrandName() + newline + rx.getSpecial();
							if (rx.getSpecialInstruction() != null && !rx.getSpecialInstruction().equalsIgnoreCase("null") && rx.getSpecialInstruction().trim().length() > 0) special += newline + rx.getSpecialInstruction();
							special += newline + "Qty:" + rx.getQuantity() + " " + rx.getUnitName() + " Repeats:" + "" + rx.getRepeat();
						}
					}

					if (!rx.isCustomNote() && rx.isMitte()) {
						special = special.replace("Qty", "Mitte");
					}

					rx.setSpecial(special.trim());

					bean.addAttributeName(rx.getAtcCode() + "-" + String.valueOf(stashIndex));
					bean.setStashItem(stashIndex, rx);
				}
			} catch (Exception e) {
				logger.error("Error", e);
				continue;
			}
		}
		for (Integer n : existingIndex) {
			if (allIndex.contains(n)) {
				allIndex.remove(n);
			}
		}
		List<Integer> deletedIndex = allIndex;
		// remove closed Rx from stash
		for (Integer n : deletedIndex) {
			bean.removeStashItem(n);
			if (bean.getStashIndex() >= bean.getStashSize()) {
				bean.setStashIndex(bean.getStashSize() - 1);
			}
		}

		saveDrug(request, prescriptionBatchId);
		return null;
	}

        public ActionForward getDemoNameAndHIN(ActionMapping mapping, ActionForm form, HttpServletRequest request, HttpServletResponse response) throws IOException, Exception {
        	LoggedInInfo loggedInInfo = LoggedInInfo.getLoggedInInfoFromSession(request);
    		if (!securityInfoManager.hasPrivilege(loggedInInfo, "_demographic", PRIVILEGE_READ, null)) {
    			throw new RuntimeException("missing required security object (_demographic)");
    		}
        	
            String demoNo=request.getParameter("demoNo").trim();
            Demographic d=demographicManager.getDemographic(loggedInInfo, demoNo);
            HashMap hm=new HashMap();
            if(d!=null){
                hm.put("patientName", d.getDisplayName());
                hm.put("patientHIN", d.getHin());
            }else{
                hm.put("patientName", "Unknown");
                hm.put("patientHIN", "Unknown");
            }
            JSONObject jo = new JSONObject(hm);
            response.getOutputStream().write(jo.toString().getBytes());
            return null;
        }
        

        public ActionForward changeLongTerm(ActionMapping mapping, ActionForm form, HttpServletRequest request, HttpServletResponse response) throws IOException, Exception {
		checkPrivilege(LoggedInInfo.getLoggedInInfoFromSession(request), PRIVILEGE_WRITE);

		String strId = request.getParameter("ltDrugId");
		if (strId != null) {
			int drugId = Integer.parseInt(strId);
			RxSessionBean bean = (RxSessionBean) request.getSession().getAttribute("RxSessionBean");
			if (bean == null) {
				response.sendRedirect("error.html");
				return null;
			}

			RxPrescriptionData rxData = new RxPrescriptionData();
			RxPrescriptionData.Prescription oldRx = rxData.getPrescription(drugId);
			oldRx.SetLongTermAndSave(!oldRx.isLongTerm());
			HashMap hm = new HashMap();
			hm.put("success", true);
			JSONObject jsonObject = new JSONObject(hm);
			response.getOutputStream().write(jsonObject.toString().getBytes());
			return null;
		} else {
			HashMap hm = new HashMap();
			hm.put("success", false);
			JSONObject jsonObject = new JSONObject(hm);
			response.getOutputStream().write(jsonObject.toString().getBytes());
			return null;
		}
}


	public void saveDrug(final HttpServletRequest request, String prescriptionBatchId) throws Exception {
		LoggedInInfo loggedInInfo = LoggedInInfo.getLoggedInInfoFromSession(request);
		checkPrivilege(loggedInInfo, PRIVILEGE_WRITE);
		
		oscar.oscarRx.pageUtil.RxSessionBean bean = (oscar.oscarRx.pageUtil.RxSessionBean) request.getSession().getAttribute("RxSessionBean");

		RxPrescriptionData.Prescription rx = null;
		RxPrescriptionData prescription = new RxPrescriptionData();
		String scriptId = prescription.saveScript(loggedInInfo, bean);
		StringBuilder auditStr = new StringBuilder();
		ArrayList<String> attrib_names = bean.getAttributeNames();
		
		for (int i = 0; i < bean.getStashSize(); i++) {
			try {
				rx = bean.getStashItem(i);
				// FIX: Ensure `prescriptionBatchId` is set before saving
				rx.setPrescriptionBatchId(prescriptionBatchId); 
				// System.out.println("DEBUG: Assigned prescriptionBatchId = " + rx.getPrescriptionBatchId());
				
				rx.Save(scriptId);// new drug id available after this line		
				bean.addRandomIdDrugIdPair(rx.getRandomId(), rx.getDrugId());
				auditStr.append(rx.getAuditString());
				auditStr.append("\n");
				// Debugging Output
				// System.out.println("Saving Drug ID from savedrug writescript class: " + rx.getDrugId() + " with Batch ID: " + prescriptionBatchId);
				
				// save drug reason. Method borrowed from 
				// RxReasonAction. 
				if( ! StringUtils.isNullOrEmpty( rx.getDrugReasonCode() ) ) {
					addDrugReason( rx.getDrugReasonCodeSystem(), 
							"false", "", rx.getDrugReasonCode(), 
							rx.getDrugId()+"", rx.getDemographicNo()+"",  
							rx.getProviderNo(), request );
				}

				//write partial date
				if (StringUtils.filled(rx.getWrittenDateFormat()))
					partialDateDao.setPartialDate(PartialDate.DRUGS, rx.getDrugId(), PartialDate.DRUGS_WRITTENDATE, rx.getWrittenDateFormat());
				
				if (StringUtils.filled(rx.getRxDateFormat()))
					partialDateDao.setPartialDate(PartialDate.DRUGS, rx.getDrugId(), PartialDate.DRUGS_STARTDATE, rx.getRxDateFormat());
			} catch (Exception e) {
				logger.error("Error", e);
			}

			// Save annotation
			HttpSession se = request.getSession();
			WebApplicationContext ctx = WebApplicationContextUtils.getRequiredWebApplicationContext(se.getServletContext());
			CaseManagementManager cmm = (CaseManagementManager) ctx.getBean("caseManagementManager");
			String attrib_name = attrib_names.get(i);
			if (attrib_name != null) {
				CaseManagementNote cmn = (CaseManagementNote) se.getAttribute(attrib_name);
				if (cmn != null) {
					cmm.saveNoteSimple(cmn);
					CaseManagementNoteLink cml = new CaseManagementNoteLink();
					cml.setTableName(CaseManagementNoteLink.DRUGS);
					cml.setTableId((long) rx.getDrugId());
					cml.setNoteId(cmn.getId());
					cmm.saveNoteLink(cml);
					se.removeAttribute(attrib_name);
					LogAction.addLog(cmn.getProviderNo(), LogConst.ANNOTATE, CaseManagementNoteLink.DISP_PRESCRIP, scriptId, request.getRemoteAddr(), cmn.getDemographic_no(), cmn.getNote());
				}
			}
			rx = null;
		}

		String ip = request.getRemoteAddr();
		request.setAttribute("scriptId", scriptId);
        
		List<String> reRxDrugList = new ArrayList<String>();
        reRxDrugList=bean.getReRxDrugIdList();        
        
        Iterator<String> i = reRxDrugList.iterator();
        
        DrugDao drugDao = (DrugDao) SpringUtils.getBean("drugDao"); 
        
        while (i.hasNext()) {
        
        String item = i.next();
        
        //archive drug(s)
        Drug drug = drugDao.find(Integer.parseInt(item));
        drug.setArchived(true);
        drug.setArchivedDate(new Date());
        drug.setArchivedReason(Drug.REPRESCRIBED);       
        drugDao.merge(drug);
              
        //log that this med is being re-prescribed
        LogAction.addLog((String) request.getSession().getAttribute("user"), LogConst.REPRESCRIBE, LogConst.CON_MEDICATION, "drugid="+item, ip, "" + bean.getDemographicNo(), auditStr.toString());
        
        //log that the med is being discontinued buy the system
        LogAction.addLog("-1", LogConst.DISCONTINUE, LogConst.CON_MEDICATION, "drugid="+item, "", "" + bean.getDemographicNo(), auditStr.toString());
        
        }
		LogAction.addLog((String) request.getSession().getAttribute("user"), LogConst.ADD, LogConst.CON_PRESCRIPTION, scriptId, ip, "" + bean.getDemographicNo(), auditStr.toString());

		return;
	}

	public ActionForward checkNoStashItem(ActionMapping mapping, ActionForm form, HttpServletRequest request, HttpServletResponse response) throws IOException, Exception {
		oscar.oscarRx.pageUtil.RxSessionBean bean = (oscar.oscarRx.pageUtil.RxSessionBean) request.getSession().getAttribute("RxSessionBean");
		int n = bean.getStashSize();
		HashMap hm = new HashMap();
		hm.put("NoStashItem", n);
		JSONObject jsonObject = new JSONObject(hm);
		response.getOutputStream().write(jsonObject.toString().getBytes());
		return null;
	}
	
	
	private void checkPrivilege(LoggedInInfo loggedInInfo, String privilege) {
		if (!securityInfoManager.hasPrivilege(loggedInInfo, "_rx", privilege, null)) {
			throw new RuntimeException("missing required security object (_rx)");
		}
	}

	private void addDrugReason(String codingSystem, 
			String primaryReasonFlagStr, String comments, 
			String code, String drugIdStr, String demographicNo,  
			String providerNo, HttpServletRequest request ) {
		
		MessageResources mResources = MessageResources.getMessageResources( "oscarResources" );
		DrugReasonDao drugReasonDao = (DrugReasonDao) SpringUtils.getBean("drugReasonDao");
		Integer drugId = Integer.parseInt(drugIdStr);
		
		// should this be instantiated with the Spring Utilities?
		CodingSystemManager codingSystemManager = new CodingSystemManager();

		if ( ! codingSystemManager.isCodeAvailable(codingSystem, code) ){
			request.setAttribute("message", mResources.getMessage("SelectReason.error.codeValid"));
			return;
		}

        if(drugReasonDao.hasReason(drugId, codingSystem, code, true)){
        	request.setAttribute("message", mResources.getMessage("SelectReason.error.duplicateCode"));
        	return;
        }

        MiscUtils.getLogger().debug("addDrugReasonCalled codingSystem "+codingSystem+ " code "+code+ " drugIdStr "+drugId);

        boolean primaryReasonFlag = true;
        if(!"true".equals(primaryReasonFlagStr)){
        	primaryReasonFlag = false;
        }

        DrugReason dr = new DrugReason();

        dr.setDrugId(drugId);
        dr.setProviderNo(providerNo);
        dr.setDemographicNo(Integer.parseInt(demographicNo));

        dr.setCodingSystem(codingSystem);
        dr.setCode(code);
        dr.setComments(comments);
        dr.setPrimaryReasonFlag(primaryReasonFlag);
        dr.setArchivedFlag(false);
        dr.setDateCoded(new Date());

        drugReasonDao.addNewDrugReason(dr);

        String ip = request.getRemoteAddr();
        LogAction.addLog((String) request.getSession().getAttribute("user"), LogConst.ADD, LogConst.CON_DRUGREASON, ""+dr.getId() , ip,demographicNo,dr.getAuditString());

	}
}
