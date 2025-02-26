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


 package oscar.eform.actions;

 import java.util.ArrayList;
 import java.util.Arrays;
 import java.text.SimpleDateFormat;
 import java.util.Date;
 import java.util.Locale;
 import java.util.Enumeration;
 import java.util.List;
 
 import javax.servlet.http.HttpServletRequest;
 import javax.servlet.http.HttpServletResponse;
 import javax.servlet.http.HttpSession;
 
 import org.apache.logging.log4j.Logger;
 import org.apache.struts.action.Action;
 import org.apache.struts.action.ActionForm;
 import org.apache.struts.action.ActionForward;
 import org.apache.struts.action.ActionMapping;
 import org.apache.struts.action.ActionMessage;
 import org.apache.struts.action.ActionMessages;
 import org.oscarehr.common.dao.EFormDataDao;
 import org.oscarehr.common.model.Demographic;
 import org.oscarehr.common.model.EFormData;
 import org.oscarehr.managers.DemographicManager;
 import org.oscarehr.managers.SecurityInfoManager;
 import org.oscarehr.match.IMatchManager;
 import org.oscarehr.match.MatchManager;
 import org.oscarehr.match.MatchManagerException;
 import org.oscarehr.util.LoggedInInfo;
 import org.oscarehr.util.MiscUtils;
 import org.oscarehr.util.SpringUtils;
 
 import oscar.eform.EFormAttachDocs;
 import oscar.eform.EFormAttachEForms;
 import oscar.eform.EFormAttachHRMReports;
 import oscar.eform.EFormAttachLabs;
 import oscar.eform.EFormLoader;
 import oscar.eform.EFormUtil;
 import oscar.eform.data.DatabaseAP;
 import oscar.eform.data.EForm;
 import oscar.oscarEncounter.data.EctProgram;
 import oscar.util.StringUtils;
 
 import com.itextpdf.html2pdf.HtmlConverter;
 import java.io.FileOutputStream;
 import java.io.File;
 import org.oscarehr.common.dao.DocumentDao;
 import org.oscarehr.common.model.Document;
 import org.oscarehr.common.dao.CtlDocumentDao;
import org.oscarehr.common.model.CtlDocument;
import org.oscarehr.common.model.CtlDocumentPK;

import java.util.regex.*;
import java.net.URLDecoder;
import java.nio.charset.StandardCharsets;

import com.itextpdf.kernel.pdf.*;
import com.itextpdf.kernel.pdf.canvas.PdfCanvas;
import com.itextpdf.kernel.geom.PageSize;
import com.itextpdf.io.image.ImageDataFactory;
import com.itextpdf.layout.element.Image;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.rendering.PDFRenderer;
import java.awt.image.BufferedImage;
import javax.imageio.ImageIO;
import com.itextpdf.forms.PdfAcroForm;
import com.itextpdf.forms.fields.PdfFormField;
import com.itextpdf.kernel.pdf.annot.PdfAnnotation;
import java.util.Map;

import com.itextpdf.kernel.pdf.PdfReader;
import com.itextpdf.html2pdf.ConverterProperties;
import java.nio.file.StandardCopyOption;

import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.Base64;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.io.IOException;
import javax.servlet.http.Cookie;
import javax.servlet.http.HttpServletRequest;
 
 
 
 public class AddEFormAction extends Action {
 
	 private static final Logger logger=MiscUtils.getLogger();
	 private SecurityInfoManager securityInfoManager = SpringUtils.getBean(SecurityInfoManager.class);
	 private DocumentDao documentDao = SpringUtils.getBean(DocumentDao.class);  // Inject DocumentDao

	public String getSessionCookie(HttpServletRequest request) {
		String sessionId = null;
	
		// Get all cookies from the request
		Cookie[] cookies = request.getCookies();
		if (cookies != null) {
			for (Cookie cookie : cookies) {
				if ("JSESSIONID".equals(cookie.getName())) {
					sessionId = cookie.getValue();
					break;
				}
			}
		}
	
		return sessionId;
	}
	 
	 public ActionForward execute(ActionMapping mapping, ActionForm form,
			 HttpServletRequest request, HttpServletResponse response) {
		 
		 if(!securityInfoManager.hasPrivilege(LoggedInInfo.getLoggedInInfoFromSession(request), "_eform", "w", null)) {
			 throw new SecurityException("missing required security object (_eform)");
		 }
		 
		 logger.debug("==================SAVING ==============");
		 HttpSession se = request.getSession();
 
		 LoggedInInfo loggedInInfo=LoggedInInfo.getLoggedInInfoFromSession(request);
		 String providerNo=loggedInInfo.getLoggedInProviderNo();
 
		 boolean fax = "true".equals(request.getParameter("faxEForm"));
		 boolean print = "true".equals(request.getParameter("print"));
 
		 @SuppressWarnings("unchecked")
		 Enumeration<String> paramNamesE = request.getParameterNames();
		 //for each name="fieldname" value="myval"
		 ArrayList<String> paramNames = new ArrayList<String>();  //holds "fieldname, ...."
		 ArrayList<String> paramValues = new ArrayList<String>(); //holds "myval, ...."
		 String fid = request.getParameter("efmfid");
		 String demographic_no = request.getParameter("efmdemographic_no");
		 String eform_link = request.getParameter("eform_link");
		 String subject = request.getParameter("subject");
 
		 boolean doDatabaseUpdate = false;
 
		 List<String> oscarUpdateFields = new ArrayList<String>();
 
		 if (request.getParameter("_oscardodatabaseupdate") != null && request.getParameter("_oscardodatabaseupdate").equalsIgnoreCase("on"))
			 doDatabaseUpdate = true;
 
		 ActionMessages updateErrors = new ActionMessages();
 
		 // The fields in the _oscarupdatefields parameter are separated by %s.
		 if (!print && !fax && doDatabaseUpdate && request.getParameter("_oscarupdatefields") != null) {
 
			 oscarUpdateFields = Arrays.asList(request.getParameter("_oscarupdatefields").split("%"));
 
			 boolean validationError = false;
 
			 for (String field : oscarUpdateFields) {
				 EFormLoader.getInstance();
				 // Check for existence of appropriate databaseap
				 DatabaseAP currentAP = EFormLoader.getAP(field);
				 if (currentAP != null) {
					 if (!currentAP.isInputField()) {
						 // Abort! This field can't be updated
						 updateErrors.add(field, new ActionMessage("errors.richeForms.noInputMethodError", field));
						 validationError = true;
					 }
				 } else {
					 // Field doesn't exit
					 updateErrors.add(field, new ActionMessage("errors.richeForms.noSuchFieldError", field));
					 validationError = true;
				 }
			 }
 
			 if (!validationError) {
				 for (String field : oscarUpdateFields) {
					 EFormLoader.getInstance();
					 DatabaseAP currentAP = EFormLoader.getAP(field);
					 // We can add more of these later...
					 if (currentAP != null) {
						 String inSQL = currentAP.getApInSQL();
 
						 inSQL = DatabaseAP.parserReplace("demographic", demographic_no, inSQL);
						 inSQL = DatabaseAP.parserReplace("provider", providerNo, inSQL);
						 inSQL = DatabaseAP.parserReplace("fid", fid, inSQL);
 
						 inSQL = DatabaseAP.parserReplace("value", request.getParameter(field), inSQL);
 
						 //if(currentAP.getArchive() != null && currentAP.getArchive().equals("demographic")) {
						 //	demographicArchiveDao.archiveRecord(demographicManager.getDemographic(loggedInInfo,demographic_no));
						 //}
 
						 // Run the SQL query against the database
						 //TODO: do this a different way.
						 MiscUtils.getLogger().error("Error",new Exception("EForm is using disabled functionality for updating fields..update not performed"));
					 }
				 }
			 }
		 }
 
		 if (subject == null) subject="";
		 String curField = "";
		 while (paramNamesE.hasMoreElements()) {
			 curField = paramNamesE.nextElement();
			 if( curField.equalsIgnoreCase("parentAjaxId"))
				 continue;
			 if(request.getParameter(curField) != null && (!request.getParameter(curField).trim().equals("")) )
			 {
				 paramNames.add(curField);
				 paramValues.add(request.getParameter(curField));
			 }
			 
		 }
 
		 EForm curForm = new EForm(fid, demographic_no, providerNo);
 
		 //add eform_link value from session attribute
		 ArrayList<String> openerNames = curForm.getOpenerNames();
		 ArrayList<String> openerValues = new ArrayList<String>();
		 for (String name : openerNames) {
			 String lnk = providerNo+"_"+demographic_no+"_"+fid+"_"+name;
			 String val = (String)se.getAttribute(lnk);
			 openerValues.add(val);
			 if (val!=null) se.removeAttribute(lnk);
		 }
 
		 //----names parsed
		 ActionMessages errors = curForm.setMeasurements(paramNames, paramValues);
		 curForm.setFormSubject(subject);
		 curForm.setValues(paramNames, paramValues);
		 if (!openerNames.isEmpty()) curForm.setOpenerValues(openerNames, openerValues);
		 if (eform_link!=null) curForm.setEformLink(eform_link);
		 curForm.setImagePath();
		 curForm.setAction();
		 curForm.setNowDateTime();
		 if (!errors.isEmpty()) {
			 saveErrors(request, errors);
			 request.setAttribute("curform", curForm);
			 request.setAttribute("page_errors", "true");
			 return mapping.getInputForward();
		 }
 
		 //Check if eform same as previous, if same -> not saved
		 String prev_fdid = (String)se.getAttribute("eform_data_id");
		 se.removeAttribute("eform_data_id");
		 boolean sameform = false;
		 if (StringUtils.filled(prev_fdid)) {
			 EForm prevForm = new EForm(prev_fdid);
			 if (prevForm!=null) {
				 sameform = curForm.getFormHtml().equals(prevForm.getFormHtml());
			 }			
		 }
		 if (!sameform) { //save eform data
			// Get the eForm HTML
				String formHtml = curForm.getFormHtml();

				// Remove the Bottom Buttons section before saving
				String cleanedHtml = formHtml.replaceAll("(?s)<div class=\"DoNotPrint\" id=\"BottomButtons\">.*?</div>", "");

				// Remove any button with class "clearBtn DoNotPrint"
				cleanedHtml = cleanedHtml.replaceAll("(?s)<button[^>]*class=[\"'].*?clearBtn DoNotPrint.*?[\"'][^>]*>.*?</button>", "");

				// Ensure the CSS rule exists before saving
				String customStyle = ".noborderPrint { border-color: transparent !important; }\n";

				if (!cleanedHtml.contains(customStyle)) {
					if (cleanedHtml.contains("<style>")) {
						cleanedHtml = cleanedHtml.replaceFirst("(?s)(<style>)(.*?)</style>", "$1$2\n" + customStyle + "</style>");
					} else if (cleanedHtml.contains("</head>")) {
						cleanedHtml = cleanedHtml.replace("</head>", "<style>\n" + customStyle + "</style>\n</head>");
					} else {
						cleanedHtml = "<style>\n" + customStyle + "</style>\n" + cleanedHtml;
					}
				}
				// Debugging Logs (Remove in Production)
				// System.out.println("DEBUG: Original HTML:\n" + formHtml);
				// System.out.println("DEBUG: Cleaned HTML (Buttons Removed):\n" + cleanedHtml);
				// logger.info("DEBUG: Cleaned HTML saved to database.");
			 EFormDataDao eFormDataDao=(EFormDataDao)SpringUtils.getBean("EFormDataDao");
			 EFormData eFormData = toEFormData(curForm, cleanedHtml);  // Pass cleaned HTML
			 eFormDataDao.persist(eFormData); // Persist ensures a new ID

			 if (eFormData.getId() == null) {
				// System.out.println("ERROR: eFormData ID is NULL after persist!");
				 return mapping.findForward("error");
			 }
			 
			 String fdid = eFormData.getId().toString(); // Now safe
 


			String appointmentNo = request.getParameter("appointment");
			// System.out.println("request parameterappointmentNo = " + appointmentNo);

			// Declare document outside the try block
			Document document = null;
			try {
				String scheme = request.getScheme();  // http or https
				String serverName = request.getServerName(); // clinic2.clinic24.ca (or another domain)
				int serverPort = request.getServerPort(); // 80, 443, or another port
				String contextPath = request.getContextPath(); // /oscar

				String baseUrl = scheme + "://" + serverName + (serverPort == 80 || serverPort == 443 ? "" : ":" + serverPort) + contextPath;

				// System.out.println("DEBUG: Base URL = " + baseUrl);
				// logger.info("DEBUG: Base URL = " + baseUrl);

				String eformHtmlUrl = baseUrl + "/eform/efmshowform_data.jsp?fdid=" + fdid + "&appointment=" + appointmentNo + "&parentAjaxId=eforms";

				// Extract the title from the HTML content
				Pattern titlePattern = Pattern.compile("<title>(.*?)</title>", Pattern.DOTALL | Pattern.CASE_INSENSITIVE);
				Matcher titleMatcher = titlePattern.matcher(cleanedHtml);

				String title = "EForm"; // Default title in case extraction fails
				if (titleMatcher.find()) {
					title = titleMatcher.group(1).trim(); // Extract and trim title
				}

				// Sanitize title for a valid filename
				title = title.replaceAll("[^a-zA-Z0-9_\\-]", "_");

				// Get the current date in "MMMM dd, yyyy" format (e.g., "February 14, 2025")
				SimpleDateFormat dateFormat = new SimpleDateFormat("MMMM dd, yyyy", Locale.ENGLISH);
				String formattedDate = dateFormat.format(new Date());

				// Construct PDF filename as "<eform-title>_February 14, 2025.pdf"
				String pdfFileName = title + "_" + formattedDate + ".pdf";
				// System.out.println("Generated PDF Filename: " + pdfFileName); // Debugging statement

				String pdfFilePath = "/usr/share/oscar-emr/OscarDocument/oscar/document/" + pdfFileName;
		
		String tempPdfFilePath = "/tmp/temp_output_" + fdid + ".pdf";  // Temporary PDF
String finalPdfFilePath = "/usr/share/oscar-emr/OscarDocument/oscar/document/" + pdfFileName; // Final PDF

// Ensure document directory has correct permissions
new ProcessBuilder("chmod", "-R", "777", "/usr/share/oscar-emr/OscarDocument/oscar/document/").start().waitFor();

String sessionId = getSessionCookie(request);

if (sessionId == null || sessionId.isEmpty()) {
    System.out.println("Error: Session ID is missing!");
    logger.error("Error: Session ID is missing!");
    return mapping.findForward("error");
}

// System.out.println("Using session cookie: JSESSIONID=" + sessionId);

// Use Chrome Headless to directly convert the live page to PDF
ProcessBuilder pb = new ProcessBuilder(
    "/usr/bin/google-chrome",
    "--headless",
    "--disable-gpu",
    "--no-sandbox",
    "--disable-software-rasterizer",
    "--disable-crash-reporter",
    "--disable-dev-shm-usage",
    "--disable-extensions",
    "--disable-features=TFLiteLanguageDetection",
    "--user-data-dir=/tmp/chrome-profile",
    "--disk-cache-dir=/tmp/chrome-profile/cache",
    "--virtual-time-budget=1000", // Ensure JavaScript runs fully
    "--window-size=1280x2000",
    "--force-device-scale-factor=1",
    "--disable-features=PaintHolding",
    "--run-all-compositor-stages-before-draw",
    "--print-to-pdf=" + tempPdfFilePath,
    "--header=\"Cookie: JSESSIONID=" + sessionId + "\"",  //Pass session cookie in request headers
    "--header=\"User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36\"",
    eformHtmlUrl
);

// Force Chrome to use `/tmp/chrome-profile` instead of `/var/lib/tomcat`
pb.environment().put("HOME", "/tmp/chrome-profile");

pb.redirectErrorStream(true);
Process process = pb.start();

// Capture Chrome output logs for debugging
BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()));
String line;
while ((line = reader.readLine()) != null) {
    // System.out.println("Chrome Output: " + line);
}

int exitCode = process.waitFor();
// System.out.println("Chrome Exit Code: " + exitCode);

// Verify if the TEMPORARY PDF was created successfully
File tempPdfFile = new File(tempPdfFilePath);
if (!tempPdfFile.exists() || tempPdfFile.length() == 0) {
    System.out.println("PDF generation failed using Chrome Headless!");
    logger.error("PDF generation failed using Chrome Headless!");
    return mapping.findForward("error");
}

// Move the TEMP PDF to FINAL storage
Files.move(Paths.get(tempPdfFilePath), Paths.get(finalPdfFilePath), StandardCopyOption.REPLACE_EXISTING);
// System.out.println("PDF successfully moved to: " + finalPdfFilePath);

// Verify FINAL PDF before saving to the database
File finalPdfFile = new File(finalPdfFilePath);
if (finalPdfFile.exists() && finalPdfFile.length() > 0) {
			// System.out.println("PDF successfully generated: " + pdfFilePath);
			// logger.info("PDF successfully generated: " + pdfFilePath);
		
			// try (PDDocument pdDoc = PDDocument.load(pdfFile)) {
			// 	PDFRenderer pdfRenderer = new PDFRenderer(pdDoc);
			// 	String imagePdfPath = pdfFilePath.replace(".pdf", "_image.pdf");
		
			// 	// Create a new image-based PDF
			// 	try (PdfWriter writer = new PdfWriter(imagePdfPath);
			// 		 PdfDocument imgPdf = new PdfDocument(writer)) {
		
			// 		for (int page = 0; page < pdDoc.getNumberOfPages(); page++) {
			// 			BufferedImage bim = pdfRenderer.renderImageWithDPI(page, 300); // Convert PDF page to image
			// 			File tempImage = new File(pdfFilePath.replace(".pdf", "_" + (page + 1) + ".png"));
			// 			ImageIO.write(bim, "png", tempImage);
		
			// 			// Add image to the new PDF
			// 			Image img = new Image(ImageDataFactory.create(tempImage.getAbsolutePath()));
			// 			img.scaleToFit(PageSize.A4.getWidth(), PageSize.A4.getHeight());
		
			// 			PdfPage pdfPage = imgPdf.addNewPage(PageSize.A4);
			// 			PdfCanvas canvas = new PdfCanvas(pdfPage);
			// 			img.setFixedPosition(0, 0);
			// 			new com.itextpdf.layout.Document(imgPdf).add(img);
		
			// 			tempImage.delete(); // Remove temporary image file
			// 		}
			// 	}
		
			// 	pdDoc.close();
		
			// 	// Replace the original PDF with the image-based one
			// 	File imagePdf = new File(imagePdfPath);
			// 	if (imagePdf.exists()) {
			// 		pdfFile.delete();  // Remove original
			// 		imagePdf.renameTo(pdfFile); // Replace with image PDF
			// 	}
		
			// 	// System.out.println("PDF converted to image-based PDF successfully.");
			// 	// logger.info("PDF converted to image-based PDF successfully.");
				
			// } catch (Exception e) {
			// 	e.printStackTrace();
			// 	logger.error("Error converting PDF to image-based PDF: " + e.getMessage());
			// }
		
        
        document = new Document();
		document.setDoctype("others");
		document.setDocClass("");
		document.setDocSubClass("");
		document.setDocdesc(pdfFileName);
		document.setDocxml(null);
		document.setDocfilename(pdfFileName);
		document.setDoccreator(providerNo);
		document.setResponsible("");
		document.setSource("");
		document.setSourceFacility("");
		document.setProgramId(10034);
		document.setUpdatedatetime(new Date());
		document.setStatus('A');
		document.setContenttype("application/pdf");
		document.setContentdatetime(new Date());
		document.setPublic1(0);
		document.setObservationdate(new Date());
		document.setReviewer(null);
		document.setReviewdatetime(null);
		document.setNumberofpages(1);
		document.setAppointmentNo(null);
		document.setRestrictToProgram(false);
		document.setReceivedDate(null);
		document.setAbnormal(false);

        DocumentDao documentDao = (DocumentDao) SpringUtils.getBean("documentDao");
        documentDao.persist(document);
        
        // System.out.println("Document entry saved in database.");
        logger.info("Document entry saved in database.");
    } else {
        // System.out.println("PDF generation failed.");
        logger.error("PDF generation failed.");
    }

} catch (Exception e) {
    e.printStackTrace();
    // System.out.println("Error generating PDF: " + e.getMessage());
    logger.error("Error generating PDF: " + e.getMessage());
}

Integer documentNo = document.getDocumentNo();

if (documentNo != null) {
    // System.out.println("DEBUG: Saved document_no = " + documentNo);
    logger.info("DEBUG: Saved document_no = " + documentNo);

  CtlDocument ctlDocument = new CtlDocument();
  CtlDocumentPK ctlDocumentPK = new CtlDocumentPK();

  // Set primary key fields
  ctlDocumentPK.setModule("demographic");
  ctlDocumentPK.setModuleId(Integer.parseInt(demographic_no));  // Convert to Integer
  ctlDocumentPK.setDocumentNo(documentNo);

  ctlDocument.setId(ctlDocumentPK);
  ctlDocument.setStatus("A");

  CtlDocumentDao ctlDocumentDao = (CtlDocumentDao) SpringUtils.getBean("ctlDocumentDao");
  ctlDocumentDao.persist(ctlDocument);

//   System.out.println("CtlDocument entry saved in database.");
  logger.info("CtlDocument entry saved in database.");
} else {
//   System.out.println("ERROR: document_no is NULL after persist!");
  logger.error("ERROR: document_no is NULL after persist!");
}



// 			 // Step 2: Save Entry in `document` Table
// 			 Document document = new Document();
// document.setDoctype("eform");
// document.setDocClass("");
// document.setDocSubClass("");
// document.setDocdesc("EForm PDF - " + new Date());
// document.setDocxml(null);
// document.setDocfilename(pdfFileName);
// document.setDoccreator(providerNo);
// document.setResponsible("");
// document.setSource("");
// document.setSourceFacility("");
// document.setProgramId(10034);
// document.setUpdatedatetime(new Date());
// document.setStatus('A');
// document.setContenttype("application/pdf");
// document.setContentdatetime(new Date());
// document.setPublic1(0);
// document.setObservationdate(new Date());
// document.setReviewer(null);
// document.setReviewdatetime(null);
// document.setNumberofpages(1);
// document.setAppointmentNo(null);
// document.setRestrictToProgram(false);
// document.setReceivedDate(null);
// document.setAbnormal(false);

// // Save the document entry to the database
// DocumentDao documentDao = (DocumentDao) SpringUtils.getBean("documentDao");
// documentDao.persist(document);
 
 
 
			 EFormUtil.addEFormValues(paramNames, paramValues, new Integer(fdid), new Integer(fid), new Integer(demographic_no)); //adds parsed values
 
			 if(!StringUtils.isNullOrEmpty(request.getParameter("selectDocs"))) {
				 String docs = request.getParameter("selectDocs");
				 String[] parsedDocs = docs.split("\\|");
				 List<String> dList = new ArrayList<String>();
				 List<String> lList = new ArrayList<String>();
				 List<String> hList = new ArrayList<String>();
				 List<String> eList = new ArrayList<String>();
				 for(String d:parsedDocs) {
					 logger.info("need to save " + d + " to fdid " + fdid);
					 if(d.startsWith("D")) {
						 dList.add(d.substring(1));
					 }
					 if(d.startsWith("L")) {
						 lList.add(d.substring(1));
					 }
					 if(d.startsWith("H")) {
						 hList.add(d.substring(1));
					 }
					 if(d.startsWith("E")) {
						 eList.add(d.substring(1));
					 }
				 }
				 
				 EFormAttachDocs Doc = new EFormAttachDocs(providerNo,demographic_no,fdid,dList.toArray(new String[dList.size()]));
				 Doc.attach(loggedInInfo);
				 
				 EFormAttachLabs Lab = new EFormAttachLabs(providerNo,demographic_no,fdid,lList.toArray(new String[lList.size()]));
				 Lab.attach(loggedInInfo);
				 
				 EFormAttachHRMReports hrmReports = new EFormAttachHRMReports(providerNo, demographic_no, fdid, hList.toArray(new String[hList.size()]));
				 hrmReports.attach();
 
				 EFormAttachEForms eForms = new EFormAttachEForms(providerNo, demographic_no, fdid, eList.toArray(new String[eList.size()]));
				 eForms.attach(loggedInInfo);
				 
			 }
			 //post fdid to {eform_link} attribute
			 if (eform_link!=null) {
				 se.setAttribute(eform_link, fdid);
			 }
			 
			 if (fax) {
				 request.setAttribute("fdid", fdid);
				 return(mapping.findForward("fax"));
			 }
			 
			 else if (print) {
				 request.setAttribute("fdid", fdid);
				 return(mapping.findForward("print"));
			 }
 
			 else {
				 //write template message to echart
				 String program_no = new EctProgram(se).getProgram(providerNo);
				 String path = request.getRequestURL().toString();
				 String uri = request.getRequestURI();
				 path = path.substring(0, path.indexOf(uri));
				 path += request.getContextPath();
	 
				 EFormUtil.writeEformTemplate(LoggedInInfo.getLoggedInInfoFromSession(request),paramNames, paramValues, curForm, fdid, program_no, path);
			 }
			 
		 }
		 else {
			 logger.debug("Warning! Form HTML exactly the same, new form data not saved.");
			 if (fax) {
				 request.setAttribute("fdid", prev_fdid);
				 return(mapping.findForward("fax"));
			 }
			 
			 else if (print) {
				 request.setAttribute("fdid", prev_fdid);
				 return(mapping.findForward("print"));
			 }
		 }
		 
		 if (demographic_no != null) {
			 IMatchManager matchManager = new MatchManager();
			 DemographicManager demographicManager = SpringUtils.getBean(DemographicManager.class);
			 Demographic client = demographicManager.getDemographic(loggedInInfo,demographic_no);
			 try {
				 matchManager.<Demographic>processEvent(client, IMatchManager.Event.CLIENT_CREATED);
			 } catch (MatchManagerException e) {
				 MiscUtils.getLogger().error("Error while processing MatchManager.processEvent(Client)",e);
			 }
		 }
		 
 
		 return(mapping.findForward("close"));
	 }
 
	 private EFormData toEFormData(EForm eForm, String cleanedHtml) {
		 EFormData eFormData=new EFormData();
		 eFormData.setFormId(Integer.parseInt(eForm.getFid()));
		 eFormData.setFormName(eForm.getFormName());
		 eFormData.setSubject(eForm.getFormSubject());
		 eFormData.setDemographicId(Integer.parseInt(eForm.getDemographicNo()));
		 eFormData.setCurrent(true);
		 eFormData.setFormDate(new Date());
		 eFormData.setFormTime(eFormData.getFormDate());
		 eFormData.setProviderNo(eForm.getProviderNo());
		//  eFormData.setFormData(eForm.getFormHtml());
		eFormData.setFormData(cleanedHtml);

		 eFormData.setShowLatestFormOnly(eForm.isShowLatestFormOnly());
		 eFormData.setPatientIndependent(eForm.isPatientIndependent());
		 eFormData.setRoleType(eForm.getRoleType());
 
		 return(eFormData);
	 }
 }
 