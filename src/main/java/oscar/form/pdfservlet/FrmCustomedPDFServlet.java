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


 package oscar.form.pdfservlet;

 import software.amazon.awssdk.auth.credentials.AwsBasicCredentials;
 import software.amazon.awssdk.auth.credentials.StaticCredentialsProvider;
 import software.amazon.awssdk.regions.Region;
 import software.amazon.awssdk.services.s3.S3Client;
 import software.amazon.awssdk.services.s3.model.PutObjectRequest;
 import software.amazon.awssdk.core.sync.RequestBody;
 import java.io.InputStreamReader;

 import org.apache.commons.codec.binary.Base64;
 import java.time.LocalDate;
 import java.time.Period;
 import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.time.LocalDateTime;

 import java.io.IOException;
 import java.io.ByteArrayOutputStream;
import java.io.BufferedReader;
import java.io.BufferedWriter;
 import java.io.File;
 import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileWriter;
 import java.io.FileOutputStream;
import java.io.FileReader;
import java.io.InputStream;
 import java.io.PrintWriter;
import java.nio.charset.StandardCharsets;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
 import java.util.Arrays;
 import java.util.Date;
 import java.util.Enumeration;
 import java.util.HashMap;
 import java.util.List;
 import java.util.Locale;
 import java.util.Properties;
 
 import javax.servlet.ServletContext;
import javax.servlet.ServletException;
import javax.servlet.ServletOutputStream;
 import javax.servlet.http.HttpServlet;
 import javax.servlet.http.HttpServletRequest;
 import javax.servlet.http.HttpServletResponse;
 
 import org.apache.commons.io.FileUtils;
 
 import net.sf.jasperreports.engine.JRException;
 import net.sf.jasperreports.engine.JasperRunManager;
 import net.sf.jasperreports.engine.data.JRBeanCollectionDataSource;
 
 import org.apache.logging.log4j.Logger;
 import org.oscarehr.common.dao.FaxConfigDao;
 import org.oscarehr.common.dao.FaxJobDao;
 import org.oscarehr.common.model.FaxConfig;
 import org.oscarehr.common.model.FaxJob;
 import org.oscarehr.common.printing.FontSettings;
 import org.oscarehr.common.printing.PdfWriterFactory;
 import org.oscarehr.util.LocaleUtils;
 import org.oscarehr.util.LoggedInInfo;
 import org.oscarehr.util.MiscUtils;
 import org.oscarehr.util.SpringUtils;
import org.xhtmlrenderer.pdf.ITextRenderer;

import oscar.OscarProperties;
 import oscar.log.LogAction;
 import oscar.log.LogConst;
 
 import com.itextpdf.text.pdf.PdfReader;
 import com.lowagie.text.Document;
 import com.lowagie.text.DocumentException;
 import com.lowagie.text.Element;
 import com.lowagie.text.Font;
 import com.lowagie.text.Image;
 import com.lowagie.text.PageSize;
 import com.lowagie.text.Paragraph;
 import com.lowagie.text.Phrase;
 import com.lowagie.text.Rectangle;
 import com.lowagie.text.pdf.BaseFont;
 import com.lowagie.text.pdf.ColumnText;
 import com.lowagie.text.pdf.PdfContentByte;
 import com.lowagie.text.pdf.PdfPTable;
 import com.lowagie.text.pdf.PdfPageEventHelper;
 import com.lowagie.text.pdf.PdfWriter;
 import com.lowagie.text.pdf.PdfPCell;
 import com.lowagie.text.*;
import com.lowagie.text.pdf.*;
import org.oscarehr.common.dao.DrugDao;


import java.time.format.DateTimeFormatterBuilder;



 public class FrmCustomedPDFServlet extends HttpServlet {
 
	 public static final String HSFO_RX_DATA_KEY = "hsfo.rx.data";
	 private static Logger logger = MiscUtils.getLogger();
 
	 @Override
public void service(HttpServletRequest req, HttpServletResponse res) throws ServletException, IOException {
    String prescriptionBatchId = req.getParameter("prescriptionBatchId"); // Retrieve batch ID
    System.out.println("Prescription Batch ID received in FrmCustomedPDFServlet: " + prescriptionBatchId);

    ByteArrayOutputStream baosPDF = null;

    try {
        Object[] result = generatePDFDocumentBytes(req, this.getServletContext());
        baosPDF = (ByteArrayOutputStream) result[0];
        String prescriptionNumber = (String) result[1];
        System.out.println("Prescription Number in Service Method: " + prescriptionNumber);
        String method = req.getParameter("__method");
        boolean isFax = method.equals("oscarRxFax");

        // if (isFax) {
        //     res.setContentType("text/html");
        //     PrintWriter writer = res.getWriter();
        //     String faxNo = req.getParameter("pharmaFax").trim().replaceAll("\\D", "");
        //     if (faxNo.length() < 7) {
        //         writer.println("<script>alert('Error: No fax number found!');window.close();</script>");
        //     } else {
        //         // Write to file
        //         String pdfFile = "prescription_" + prescriptionBatchId + ".pdf";
        //         String path = OscarProperties.getInstance().getProperty("DOCUMENT_DIR") + "/";
        //         FileOutputStream fos = new FileOutputStream(path + pdfFile);
        //         baosPDF.writeTo(fos);
        //         fos.close();
        //         String s3RelativePath = "batchid";

        //         // Ensure PDF filename is saved when faxing
        //         if (prescriptionBatchId != null && !prescriptionBatchId.isEmpty()) {
        //             DrugDao drugDao = SpringUtils.getBean(DrugDao.class);
        //             drugDao.updateDrugsWithPDF(prescriptionBatchId, s3RelativePath);
        //             System.out.println("PDF filename saved in drugs table where Batch ID: " + prescriptionBatchId);
        //         }


        //         String tempPath = OscarProperties.getInstance().getProperty(
        //             "fax_file_location", System.getProperty("java.io.tmpdir"));

        //         // Copying the fax pdf.
        //         String tempPdf = tempPath + "/prescription_" + req.getParameter("pdfId") + ".pdf";
        //         FileUtils.copyFile(new File(path + pdfFile), new File(tempPdf));

        //         String txtFile = tempPath + "/prescription_" + req.getParameter("pdfId") + ".txt";
        //         FileWriter fstream = new FileWriter(txtFile);
        //         BufferedWriter out = new BufferedWriter(fstream);
        //         try {
        //             out.write(faxNo);
        //         } finally {
        //             if (out != null) out.close();
        //         }

        //         String faxNumber = req.getParameter("clinicFax");
        //         String demo = req.getParameter("demographic_no");
        //         FaxJobDao faxJobDao = SpringUtils.getBean(FaxJobDao.class);
        //         FaxConfigDao faxConfigDao = SpringUtils.getBean(FaxConfigDao.class);
        //         List<FaxConfig> faxConfigs = faxConfigDao.findAll(null, null);
        //         String provider_no = LoggedInInfo.getLoggedInInfoFromSession(req).getLoggedInProviderNo();
        //         FaxJob faxJob;
        //         boolean validFaxNumber = false;

        //         for (FaxConfig faxConfig : faxConfigs) {
        //             if (faxConfig.getFaxNumber().equals(faxNumber)) {
        //                 PdfReader pdfReader = new PdfReader(path + pdfFile);

        //                 faxJob = new FaxJob();
        //                 faxJob.setDestination(faxNo);
        //                 faxJob.setFax_line(faxNumber);
        //                 faxJob.setFile_name(pdfFile);
        //                 faxJob.setUser(faxConfig.getFaxUser());
        //                 faxJob.setNumPages(pdfReader.getNumberOfPages());
        //                 faxJob.setStamp(new Date());
        //                 faxJob.setStatus(FaxJob.STATUS.SENT);
        //                 faxJob.setOscarUser(provider_no);
        //                 faxJob.setDemographicNo(Integer.parseInt(demo));

        //                 faxJobDao.persist(faxJob);
        //                 validFaxNumber = true;
        //                 break;
        //             }
        //         }

        //         if (validFaxNumber) {
        //             LogAction.addLog(provider_no, LogConst.SENT, LogConst.CON_FAX, "PRESCRIPTION " + pdfFile);
        //             String htm1 = "<html><head><link rel='stylesheet' type='text/css' href='../oscarEncounter/encounterStyles.css'></head><body onload=setTimeout('window.close()',2500);><table class='MainTable' id='scrollNumber1' name='encounterTable'><tr class='MainTableTopRow'><td class='MainTableTopRowLeftColumn'>Rx Fax</td><td class='MainTableTopRowRightColumn'></td></tr><tr style='vertical-align: top'><td class='MainTableLeftColumn' width='10%'>&nbsp;</td><td class='MainTableRightColumn'><table width='100%' height='100%'><tr><td>";
        //             String htm2 = "</td></tr><tr><td>This window will close in 5 seconds</td></tr><tr></tr></table></td></tr><tr><td class='MainTableBottomRowLeftColumn'></td><td class='MainTableBottomRowRightColumn'></td></tr></table></body></html>";
        //             writer.println(htm1 + req.getParameter("pharmaName") + " (" + req.getParameter("pharmaFax") + ")" + htm2 + "<script>window.parent.clearPendingFax();</script>");
        //         }
        //     }
        // }
        if (isFax) {
            res.setContentType("text/html");
            PrintWriter writer = res.getWriter();
            String faxNo = req.getParameter("pharmaFax").trim().replaceAll("\\D", "");
            if (faxNo.length() < 7) {
                writer.println("<script>alert('Error: No fax number found!');window.close();</script>");
            } else {
                // Write to file
                String pdfFile = "prescription_" + prescriptionBatchId + ".pdf";
                String path = OscarProperties.getInstance().getProperty("DOCUMENT_DIR") + "/";
                FileOutputStream fos = new FileOutputStream(path + pdfFile);
                baosPDF.writeTo(fos);
                fos.close();
                
                // Generate S3 Path
                int clinicId = Integer.parseInt(OscarProperties.getInstance().getProperty("CLINIC_ID", "0"));
                String year = String.valueOf(LocalDate.now().getYear());
                String month = String.format("%02d", LocalDate.now().getMonthValue());
                String s3FolderPath = clinicId + "/" + year + "/" + month + "/rxPdf/";
                String s3RelativePath = s3FolderPath + pdfFile;
        
                // Upload to S3
                boolean uploadSuccess = uploadToS3(baosPDF, s3FolderPath, pdfFile);
        
                if (uploadSuccess) {
                    System.out.println("PDF uploaded successfully to S3: " + s3RelativePath);
                } else {
                    System.out.println("Error uploading PDF to S3");
                }
        
                // Ensure PDF filename is saved when faxing
                if (prescriptionBatchId != null && !prescriptionBatchId.isEmpty()) {
                    DrugDao drugDao = SpringUtils.getBean(DrugDao.class);
                    drugDao.updateDrugsWithPDF(prescriptionBatchId, s3RelativePath);
                    System.out.println("PDF filename saved in drugs table where Batch ID: " + prescriptionBatchId);
                }
        
                String tempPath = OscarProperties.getInstance().getProperty(
                    "fax_file_location", System.getProperty("java.io.tmpdir"));
        
                // Copying the fax pdf.
                String tempPdf = tempPath + "/prescription_" + req.getParameter("pdfId") + ".pdf";
                FileUtils.copyFile(new File(path + pdfFile), new File(tempPdf));
        
                String txtFile = tempPath + "/prescription_" + req.getParameter("pdfId") + ".txt";
                FileWriter fstream = new FileWriter(txtFile);
                BufferedWriter out = new BufferedWriter(fstream);
                try {
                    out.write(faxNo);
                } finally {
                    if (out != null) out.close();
                }
        
                String faxNumber = req.getParameter("clinicFax");
                String demo = req.getParameter("demographic_no");
                FaxJobDao faxJobDao = SpringUtils.getBean(FaxJobDao.class);
                FaxConfigDao faxConfigDao = SpringUtils.getBean(FaxConfigDao.class);
                List<FaxConfig> faxConfigs = faxConfigDao.findAll(null, null);
                String provider_no = LoggedInInfo.getLoggedInInfoFromSession(req).getLoggedInProviderNo();
                FaxJob faxJob;
                boolean validFaxNumber = false;
        
                for (FaxConfig faxConfig : faxConfigs) {
                    if (faxConfig.getFaxNumber().equals(faxNumber)) {
                        PdfReader pdfReader = new PdfReader(path + pdfFile);
        
                        faxJob = new FaxJob();
                        faxJob.setDestination(faxNo);
                        faxJob.setFax_line(faxNumber);
                        faxJob.setFile_name(pdfFile);
                        faxJob.setUser(faxConfig.getFaxUser());
                        faxJob.setNumPages(pdfReader.getNumberOfPages());
                        faxJob.setStamp(new Date());
                        faxJob.setStatus(FaxJob.STATUS.SENT);
                        faxJob.setOscarUser(provider_no);
                        faxJob.setDemographicNo(Integer.parseInt(demo));
        
                        faxJobDao.persist(faxJob);
                        validFaxNumber = true;
                        break;
                    }
                }
        
                if (validFaxNumber) {
                    LogAction.addLog(provider_no, LogConst.SENT, LogConst.CON_FAX, "PRESCRIPTION " + pdfFile);
                    String htm1 = "<html><head><link rel='stylesheet' type='text/css' href='../oscarEncounter/encounterStyles.css'></head><body onload=setTimeout('window.close()',2500);><table class='MainTable' id='scrollNumber1' name='encounterTable'><tr class='MainTableTopRow'><td class='MainTableTopRowLeftColumn'>Rx Fax</td><td class='MainTableTopRowRightColumn'></td></tr><tr style='vertical-align: top'><td class='MainTableLeftColumn' width='10%'>&nbsp;</td><td class='MainTableRightColumn'><table width='100%' height='100%'><tr><td>";
                    String htm2 = "</td></tr><tr><td>This window will close in 5 seconds</td></tr><tr></tr></table></td></tr><tr><td class='MainTableBottomRowLeftColumn'></td><td class='MainTableBottomRowRightColumn'></td></tr></table></body></html>";
                    writer.println(htm1 + req.getParameter("pharmaName") + " (" + req.getParameter("pharmaFax") + ")" + htm2 + "<script>window.parent.clearPendingFax();</script>");
                }
            }
        }
        else {
            // Fetch Clinic ID from properties file
            int clinicId = Integer.parseInt(OscarProperties.getInstance().getProperty("CLINIC_ID", "0"));
            System.out.println("Clinic ID from propertiees file: " + clinicId);
        
            // Get current year and month
            String year = String.valueOf(LocalDate.now().getYear());
            String month = String.format("%02d", LocalDate.now().getMonthValue());
        
            // Construct the S3 folder path
            String s3FolderPath = clinicId + "/" + year + "/" + month + "/rxPdf/";
        
            // Construct the PDF filename
            String pdfFileName = "prescription_" + prescriptionBatchId + ".pdf";
        
            // Construct the relative S3 path to store in the database
            String s3RelativePath = s3FolderPath + pdfFileName;
        
            // Upload PDF to S3
            boolean uploadSuccess = uploadToS3(baosPDF, s3FolderPath, pdfFileName);
        
            if (uploadSuccess) {
                System.out.println("PDF uploaded successfully to S3: " + s3RelativePath);
        
                // Save only the relative S3 path to the database
                if (prescriptionBatchId != null && !prescriptionBatchId.isEmpty()) {
                    DrugDao drugDao = SpringUtils.getBean(DrugDao.class);
                    drugDao.updateDrugsWithPDF(prescriptionBatchId, s3RelativePath);
                    System.out.println("Relative S3 PDF path saved in drugs table where Batch ID: " + prescriptionBatchId);
                }
            } else {
                System.out.println("Error uploading PDF to S3");
            }
        
            // Send PDF directly to browser
            res.setHeader("Cache-Control", "max-age=0");
            res.setDateHeader("Expires", 0);
            res.setContentType("application/pdf");
            res.setHeader("Content-disposition", "inline; filename=" + pdfFileName);
            res.setContentLength(baosPDF.size());
        
            ServletOutputStream sos = res.getOutputStream();
            baosPDF.writeTo(sos);
            sos.flush();
        }
        
        // else {
        //     String pdfFileName = "prescription_" + prescriptionBatchId  + ".pdf";
        //     String path = OscarProperties.getInstance().getProperty("DOCUMENT_DIR") + "/";

        //     // Ensure the directory exists
        //     File directory = new File(path);
        //     if (!directory.exists()) {
        //         directory.mkdirs();
        //     }

        //     // Console output for debugging
        //     System.out.println("Saving PDF on Generate PDF button click: " + path + pdfFileName);

        //     // Save PDF to server
        //     try (FileOutputStream fos = new FileOutputStream(path + pdfFileName)) {
        //         baosPDF.writeTo(fos);
        //         logger.info("PDF successfully saved: " + path + pdfFileName);
        //     } catch (IOException e) {
        //         logger.error("Error saving PDF file: " + path + pdfFileName, e);
        //     }

        //     // Save PDF filename to database for matching batch_id in the drugs table
        //     if (prescriptionBatchId != null && !prescriptionBatchId.isEmpty()) {
        //         DrugDao drugDao = SpringUtils.getBean(DrugDao.class);
        //         drugDao.updateDrugsWithPDF(prescriptionBatchId);
        //         System.out.println("PDF filename saved in drugs table where Batch ID: " + prescriptionBatchId);
        //     }

        //     // Send PDF directly to browser
        //     res.setHeader("Cache-Control", "max-age=0");
        //     res.setDateHeader("Expires", 0);
        //     res.setContentType("application/pdf");
        //     res.setHeader("Content-disposition", "inline; filename=" + pdfFileName);
        //     res.setContentLength(baosPDF.size());

        //     ServletOutputStream sos = res.getOutputStream();
        //     baosPDF.writeTo(sos);
        //     sos.flush();
        // }
    } catch (DocumentException dex) {
        res.setContentType("text/html");
        PrintWriter writer = res.getWriter();
        writer.println("Exception from: " + this.getClass().getName() + " " + dex.getClass().getName() + "<br>");
        writer.println("<pre>");
        writer.println(dex.getMessage());
        writer.println("</pre>");
    } catch (FileNotFoundException fnfe) {
        res.setContentType("text/html");
        PrintWriter writer = res.getWriter();
        writer.println("<script>alert('Signature not found. Please sign the prescription.');</script>");
    } catch (Exception e) {  // Catch all other exceptions
        res.setContentType("text/html");
        PrintWriter writer = res.getWriter();
        writer.println("<script>alert('An unexpected error occurred. Please try again.');</script>");
        e.printStackTrace();  // Log the exception for debugging
    } finally {
        if (baosPDF != null) {
            baosPDF.reset();
        }
    }
}

 
	 // added by vic, hsfo
	 private ByteArrayOutputStream generateHsfoRxPDF(HttpServletRequest req) {
 
		 HsfoRxDataHolder rx = (HsfoRxDataHolder) req.getSession().getAttribute(HSFO_RX_DATA_KEY);
 
		 JRBeanCollectionDataSource ds = new JRBeanCollectionDataSource(rx.getOutlines());
		 InputStream is = Thread.currentThread().getContextClassLoader().getResourceAsStream("/oscar/form/prop/Hsfo_Rx.jasper");
 
		 ByteArrayOutputStream baos = new ByteArrayOutputStream();
		 try {
			 JasperRunManager.runReportToPdfStream(is, baos, rx.getParams(), ds);
		 } catch (JRException e) {
			 throw new RuntimeException(e);
		 }
		 return baos;
	 }
 
	 /**
	  * the form txt file has lines in the form: For Checkboxes: ie. ohip : left, 76, 193, 0, BaseFont.ZAPFDINGBATS, 8, \u2713 requestParamName : alignment, Xcoord, Ycoord, 0, font, fontSize, textToPrint[if empty, prints the value of the request param]
	  * NOTE: the Xcoord and Ycoord refer to the bottom-left corner of the element For single-line text: ie. patientCity : left, 242, 261, 0, BaseFont.HELVETICA, 12 See checkbox explanation For multi-line text (textarea) ie. aci : left, 20, 308, 0,
	  * BaseFont.HELVETICA, 8, _, 238, 222, 10 requestParamName : alignment, bottomLeftXcoord, bottomLeftYcoord, 0, font, fontSize, _, topRightXcoord, topRightYcoord, spacingBtwnLines NOTE: When working on these forms in linux, it helps to load the PDF file
	  * into gimp, switch to pt. coordinate system and use the mouse to find the coordinates. Prepare to be bored!
	  */
 
	 class EndPage extends PdfPageEventHelper {
 
		 private String clinicName;
		 private String clinicTel;
		 private String clinicFax;
		 private String patientPhone;
		 private String patientCityPostal;
		 private String patientAddress;
		 private String patientName;
		 private String patientDOB;
		 private String patientHIN;
		 private String patientChartNo;
		 private String patientBandNumber;
		 private String pracNo;
		 private String sigDoctorName;
		 private String rxDate;
		 private String promoText;
		 private String origPrintDate = null;
		 private String numPrint = null;
		 private String imgPath;
		 private String electronicSignature;
		 private String pharmaName;
		 private String pharmaTel;
		 private String pharmaFax;
		 private String pharmaAddress1;
		 private String pharmaAddress2;
		 private String pharmaEmail;
		 private String pharmaNote;
		 private boolean pharmaShow;
				 Locale locale = null;
				 
		 public EndPage() {
		 }
 
		 public EndPage(String clinicName, String clinicTel, String clinicFax, String patientPhone, String patientCityPostal, String patientAddress,
				 String patientName,String patientDOB, String sigDoctorName, String rxDate,String origPrintDate,String numPrint, String imgPath, String electronicSignature, String patientHIN, String patientChartNo, String patientBandNumber, String pracNo, String pharmaName, String pharmaAddress1, String pharmaAddress2, String pharmaTel, String pharmaFax, String pharmaEmail, String pharmaNote, boolean pharmaShow, Locale locale) {
			  this.clinicName = clinicName==null ? "" : clinicName;
			 this.clinicName = clinicName==null ? "" : clinicName;
			 this.clinicTel = clinicTel==null ? "" : clinicTel;
			 this.clinicFax = clinicFax==null ? "" : clinicFax;
			 this.patientPhone = patientPhone==null ? "" : patientPhone;
			 this.patientCityPostal = patientCityPostal==null ? "" : patientCityPostal;
			 this.patientAddress = patientAddress==null ? "" : patientAddress;
			 this.patientName = patientName;
			 this.patientDOB=patientDOB;
			 this.sigDoctorName = sigDoctorName==null ? "" : sigDoctorName;
			 this.rxDate = rxDate;
			 this.promoText = OscarProperties.getInstance().getProperty("FORMS_PROMOTEXT");
			 this.origPrintDate = origPrintDate;
			 this.numPrint = numPrint;
			 if (promoText == null) {
				 promoText = "";
			 }
			 this.imgPath = imgPath;
			 this.electronicSignature = electronicSignature;
			 this.patientHIN = patientHIN==null ? "" : patientHIN;
			 this.patientChartNo = patientChartNo==null ? "" : patientChartNo;
			 this.patientBandNumber = patientBandNumber==null ? "" : patientBandNumber;
			 this.pracNo = pracNo==null ? "" : pracNo;
			 this.pharmaName = pharmaName==null ? "" : pharmaName;
			 this.pharmaTel=pharmaTel==null ? "" : pharmaTel;
			 this.pharmaFax=pharmaFax==null ? "" : pharmaFax;
			 this.pharmaAddress1=pharmaAddress1==null ? "" : pharmaAddress1;
			 this.pharmaAddress2=pharmaAddress2==null ? "" : pharmaAddress2;
			 this.pharmaEmail=pharmaEmail==null ? "" : pharmaEmail;
			 this.pharmaNote=pharmaNote==null ? "" : pharmaNote;
			 this.pharmaShow=pharmaShow;
			 this.locale = locale;
		 }
 // test
		 @Override
		 public void onEndPage(PdfWriter writer, Document document) {
			try {
				renderPage(writer, document); // Call renderPage inside try-catch
			} catch (IOException e) {
				e.printStackTrace(); // Handle the exception (log it or show an error message)
				// Optionally, you could log or rethrow a runtime exception if needed.
			}
		
		 }
 
		 public void writeDirectContent(PdfContentByte cb, BaseFont bf, float fontSize, int alignment, String text, float x, float y, float rotation) {
			 cb.beginText();
			 cb.setFontAndSize(bf, fontSize);
			 cb.showTextAligned(alignment, text, x, y, rotation);
			 cb.endText();
		 }
		 
		 private String geti18nTagValue(Locale locale, String tag) {
			 return LocaleUtils.getMessage(locale,tag);
		 }
		 
		 public void renderPage(PdfWriter writer, Document document) throws IOException, DocumentException {
			Rectangle page = document.getPageSize();
			PdfContentByte cb = writer.getDirectContent();
			BaseFont bf = BaseFont.createFont(BaseFont.HELVETICA, BaseFont.CP1252, BaseFont.NOT_EMBEDDED);
		
			try {
				float height = page.getHeight();
				float width = page.getWidth();
		
				// Clinic Logo and Doctor's Information (Top Left)
				if (this.imgPath != null) {
					Image img = Image.getInstance(this.imgPath);
					img.scaleToFit(80, 80); // Adjust size of the logo
					img.setAbsolutePosition(36, height - 90); // Place logo at the top-left
					cb.addImage(img);
				}
				float clinicInfoY = height - 30;
				writeDirectContent(cb, bf, 10, PdfContentByte.ALIGN_LEFT, "Dr. " + this.sigDoctorName, 130, clinicInfoY, 0);
				writeDirectContent(cb, bf, 10, PdfContentByte.ALIGN_LEFT, "License #" + this.pracNo, 130, clinicInfoY - 15, 0);
				writeDirectContent(cb, bf, 10, PdfContentByte.ALIGN_LEFT, this.clinicName, 130, clinicInfoY - 30, 0);
				writeDirectContent(cb, bf, 10, PdfContentByte.ALIGN_LEFT, "Tel: " + this.clinicTel, 130, clinicInfoY - 45, 0);
				writeDirectContent(cb, bf, 10, PdfContentByte.ALIGN_LEFT, "Fax: " + this.clinicFax, 130, clinicInfoY - 60, 0);
		
				// Patient Information Box (Top Right)
				PdfPTable patientInfoTable = new PdfPTable(1);
				patientInfoTable.setTotalWidth(200);
				patientInfoTable.setLockedWidth(true);
				StringBuilder patientInfo = new StringBuilder();
				patientInfo.append(this.patientName).append("\n");
				if (this.patientDOB != null && !this.patientDOB.isEmpty()) {
					patientInfo.append("DOB: ").append(this.patientDOB).append("\n");
				}
				patientInfo.append(this.patientAddress).append("\n");
				if (this.patientCityPostal != null) patientInfo.append(this.patientCityPostal).append("\n");
				if (this.patientPhone != null) patientInfo.append("Tel: ").append(this.patientPhone).append("\n");
				if (this.patientHIN != null && !this.patientHIN.isEmpty()) {
					patientInfo.append("Health Ins #: ").append(this.patientHIN);
				}
		
				Phrase patientPhrase = new Phrase(patientInfo.toString(), new Font(bf, 10));
				PdfPCell patientCell = new PdfPCell(patientPhrase);
				patientCell.setPadding(8);
				patientCell.setBorder(Rectangle.BOX);
				patientInfoTable.addCell(patientCell);
				patientInfoTable.writeSelectedRows(0, -1, width - 230, height - 60, cb);
		
				// Pharmacy Information Box (Bottom Right)
				PdfPTable pharmacyInfoTable = new PdfPTable(1);
				pharmacyInfoTable.setTotalWidth(200);
				pharmacyInfoTable.setLockedWidth(true);
		
				StringBuilder pharmacyInfo = new StringBuilder();
				pharmacyInfo.append(this.pharmaName).append("\n")
							.append(this.pharmaAddress1).append("\n")
							.append(this.pharmaAddress2).append("\n")
							.append("Tel: ").append(this.pharmaTel).append("\n")
							.append("Fax: ").append(this.pharmaFax);
		
				Phrase pharmacyPhrase = new Phrase(pharmacyInfo.toString(), new Font(bf, 10));
				PdfPCell pharmacyCell = new PdfPCell(pharmacyPhrase);
				pharmacyCell.setPadding(8);
				pharmacyCell.setBorder(Rectangle.BOX);
				pharmacyInfoTable.addCell(pharmacyCell);
				pharmacyInfoTable.writeSelectedRows(0, -1, width - 230, 100, cb);
		
				// Signature Section (Bottom Left)
				float signatureY = 100;
				writeDirectContent(cb, bf, 10, PdfContentByte.ALIGN_LEFT, "Signature:", 36, signatureY + 40, 0);
				if (this.imgPath != null) {
					Image img = Image.getInstance(this.imgPath);
					img.scaleToFit(100, 50);
					img.setAbsolutePosition(60, signatureY);
					cb.addImage(img);
				} else if (this.electronicSignature != null && !this.electronicSignature.isEmpty()) {
					writeDirectContent(cb, bf, 10, PdfContentByte.ALIGN_LEFT, this.electronicSignature, 130, signatureY, 0);
				}
				writeDirectContent(cb, bf, 10, PdfContentByte.ALIGN_LEFT, "Dr. " + this.sigDoctorName, 36, signatureY - 20, 0);
				writeDirectContent(cb, bf, 10, PdfContentByte.ALIGN_LEFT, "License #" + this.pracNo, 36, signatureY - 35, 0);
		
				// Footer Section
				writeDirectContent(cb, bf, 10, PdfContentByte.ALIGN_CENTER, "Page " + writer.getPageNumber(), width / 2, 30, 0);
		
			} catch (Exception e) {
				e.printStackTrace();
			}
		}
		
		}
	 private HashMap<String,String> parseSCAddress(String s) {
		 HashMap<String,String> hm = new HashMap<String,String>();
		 String[] ar = s.split("</b>");
		 String[] ar2 = ar[1].split("<br>");
		 ArrayList<String> lst = new ArrayList<String>(Arrays.asList(ar2));
		 lst.remove(0);
		 String tel = lst.get(3);
		 tel = tel.replace("Tel: ", "");
		 String fax = lst.get(4);
		 fax = fax.replace("Fax: ", "");
		 String clinicName = lst.get(0) + "\n" + lst.get(1) + "\n" + lst.get(2);
		 logger.debug(tel);
		 logger.debug(fax);
		 logger.debug(clinicName);
		 hm.put("clinicName", clinicName);
		 hm.put("clinicTel", tel);
		 hm.put("clinicFax", fax);
 
		 return hm;
 
	 }

     private String calculateAge(String dob) {
    try {
        // Use a flexible DateTimeFormatter that supports single- and double-digit days
        DateTimeFormatter formatter = new DateTimeFormatterBuilder()
            .parseCaseInsensitive()
            .appendPattern("MMM d, yyyy") // Use "d" for single- and double-digit days
            .toFormatter(Locale.ENGLISH);

        // Parse the date using the formatter
        LocalDate birthDate = LocalDate.parse(dob.trim(), formatter);

        // Calculate age
        LocalDate currentDate = LocalDate.now();
        return String.valueOf(Period.between(birthDate, currentDate).getYears());
    } catch (DateTimeParseException e) {
        System.err.println("Invalid date format for dob: " + dob);
        e.printStackTrace();
        return "Unknown"; // Default value if parsing fails
    }
}


    //  private String calculateAge(String dob) {
    //     DateTimeFormatter formatter = DateTimeFormatter.ofPattern("MMM dd, yyyy");
    //     LocalDate birthDate = LocalDate.parse(dob, formatter);
    //     LocalDate currentDate = LocalDate.now();
    //     return String.valueOf(Period.between(birthDate, currentDate).getYears());
    // }

    private String escapeHtml(String input) {
        if (input == null) {
            return "";
        }
        return input.replace("&", "&amp;")
                    .replace("<", "&lt;")
                    .replace(">", "&gt;")
                    .replace("\"", "&quot;")
                    .replace("'", "&#39;");
    }
    
 
	protected Object[] generatePDFDocumentBytes(final HttpServletRequest req, final ServletContext ctx) throws Exception {
        logger.debug("***in generatePDFDocumentBytes2 FrmCustomedPDFServlet.java***");
    

        LocalDateTime now = LocalDateTime.now();
        DateTimeFormatter dateFormatter = DateTimeFormatter.ofPattern("MMM dd, yyyy");
        DateTimeFormatter timeFormatter = DateTimeFormatter.ofPattern("hh:mm a");
        String clinicName = req.getParameter("clinicName");
        String clinicAddress = req.getParameter("clinicAddress");
        String clinicCity = req.getParameter("clinicCity");
        String clinicProvince = req.getParameter("clinicProvince");
        String clinicPostal = req.getParameter("clinicPostal");
        String clinicTel = req.getParameter("clinicPhone");
        String clinicFax = req.getParameter("clinicFax");
        String patientName = req.getParameter("patientName");
        String patientDOB = req.getParameter("patientDOB");
        String patientPhone = req.getParameter("patientPhone");
        String patientAddress = req.getParameter("patientAddress");
        String patientCityPostal = req.getParameter("patientCityPostal");
        String patientHIN = req.getParameter("patientHIN");
        String sigDoctorName = req.getParameter("sigDoctorName");
        String pracNo = req.getParameter("pracNo");
        String rxDate = req.getParameter("rxDate");
        String rx = req.getParameter("rx");
        String rxNoNewlines = req.getParameter("rx_no_newlines");
        String rxQty = req.getParameter("rxQty");
        String rxRepeats = req.getParameter("rxRepeats");
        String rxStartDate = req.getParameter("rxStartDate");
        String additNotes = req.getParameter("additNotes");
        String rawBatchId = req.getParameter("prescriptionBatchId");
        String prescriptionBatchId = (rawBatchId != null && rawBatchId.startsWith("batch_"))
            ? rawBatchId.replace("batch_", "")
            : rawBatchId;


        int prescriptionCount = Integer.parseInt(req.getParameter("prescriptionCount")); // Get the count of prescriptions

        // Prescription details processing with splitting logic
StringBuilder prescriptionsHtml = new StringBuilder();

// Break prescriptions into independent chunks
for (int i = 0; i < prescriptionCount; i++) {
    StringBuilder prescriptionBlock = new StringBuilder();

    String medicationName = req.getParameter("medicationName_" + i);
    String instructions = req.getParameter("instructions_" + i);
    String specialInstructions = req.getParameter("specialInstructions_" + i);
    String quantity = req.getParameter("quantity_" + i);
    String repeats = req.getParameter("repeats_" + i);
    String startDate = req.getParameter("startDate_" + i);
    String endDate_p = req.getParameter("endDate_p_" + i);
    String duration = req.getParameter("duration_" + i);
    String patientCompliance = req.getParameter("patientCompliance_" + i);
    String frequency = req.getParameter("frequency_" + i);
    String longTerm = req.getParameter("longTerm_" + i);
    String form = req.getParameter("form_" + i);
    String route = req.getParameter("route_" + i);


     // String modifiedInstructions = instructions;
    // if ("no".equalsIgnoreCase(patientCompliance) && frequency != null && !frequency.isEmpty()) {
    //     modifiedInstructions += " (" + frequency.substring(0, 1).toUpperCase() + frequency.substring(1).toLowerCase() + " Dispense)";
    // }

    // prescriptionBlock.append("<div class='prescription-details' style='margin-bottom: 6px;'>")
    //     .append("<p style='margin: 0 0 2px; font-size: 10pt;'><strong>").append(escapeHtml(medicationName)).append("</strong></p>")
    //     .append("<p style='margin: 0 0 2px; font-size: 10pt;'>").append(escapeHtml(modifiedInstructions)).append("</p>");

    // if (specialInstructions != null && !specialInstructions.isEmpty()) {
    //     prescriptionBlock.append("<p style='margin: 0 0 2px; font-size: 10pt;'>").append(escapeHtml(specialInstructions)).append("</p>");
    // }


    String modifiedInstructions = specialInstructions;
    if ("no".equalsIgnoreCase(patientCompliance) && frequency != null && !frequency.isEmpty()) {
        modifiedInstructions += " (" + frequency.substring(0, 1).toUpperCase() + frequency.substring(1).toLowerCase() + " Dispense)";
    }

    prescriptionBlock.append("<div class='prescription-details' style='margin-bottom: 6px;'>")
    .append("<p style='margin: 0 0 2px; font-size: 10pt;'><strong>")
    .append(escapeHtml(medicationName))
    .append(route != null && !route.isEmpty() ? " (" + escapeHtml(route) + ")" : "")
    .append("</strong></p>")
    
        .append("<p style='margin: 0 0 2px; font-size: 10pt;'>").append(escapeHtml(modifiedInstructions)).append("</p>");

    // if (specialInstructions != null && !specialInstructions.isEmpty()) {
    //     prescriptionBlock.append("<p style='margin: 0 0 2px; font-size: 10pt;'>").append(escapeHtml(specialInstructions)).append("</p>");
    // }

    prescriptionBlock.append("<table style='width: 100%; border-collapse: collapse;'>");

  // Combined Start Date, End Date, and Duration
if ((startDate != null && !startDate.isEmpty()) || (endDate_p != null && !endDate_p.isEmpty()) || (duration != null && !duration.equals("0 Days") && !duration.isEmpty())) {
    String dateRange = "";
    if (startDate != null && !startDate.isEmpty()) {
        dateRange += startDate;
    }
    if (endDate_p != null && !endDate_p.isEmpty()) {
        dateRange += " - " + endDate_p;
    }
    if (duration != null && !duration.equals("0 Days") && !duration.isEmpty()) {
        dateRange += " (" + duration + ")";
    }

    prescriptionBlock.append("<tr style='padding: 0;'>")
        .append("<td colspan='2' style='text-align: left; padding: 0 0 2px; font-size: 10pt;'>")
        .append("Duration: ").append(escapeHtml(dateRange))
        .append("</td>")
        .append("</tr>");
}

        // Long Term
        if (longTerm != null && !longTerm.isEmpty()) {
            prescriptionBlock.append("<tr style='padding: 0;'>")
                .append("<td colspan='2' style='text-align: left; padding: 0 0 2px; font-size: 10pt;'>")
                .append("Long Term: ").append(escapeHtml(longTerm))
                .append("</td>")
                .append("</tr>");
        }

        if ((quantity != null && !quantity.isEmpty()) || (repeats != null && !repeats.isEmpty())) {
        prescriptionBlock.append("<tr style='padding: 0;'>")
            .append("<td colspan='2' style='text-align: left; padding: 0 0 2px; font-size: 10pt;'>");

        if (quantity != null && !quantity.isEmpty()) {
            prescriptionBlock.append("Quantity: ").append(escapeHtml(quantity));
            if (form != null && !form.trim().isEmpty()) {
                prescriptionBlock.append(" (").append(escapeHtml(form)).append(")");
            }
        }

        if (repeats != null && !repeats.isEmpty()) {
            if (quantity != null && !quantity.isEmpty()) {
                prescriptionBlock.append("&nbsp;&nbsp;&nbsp;");
            }
            prescriptionBlock.append("Repeats: ").append(escapeHtml(repeats));
        }

        prescriptionBlock.append("</td></tr>");
    }


    prescriptionBlock.append("</table></div>");

    if (i < prescriptionCount - 1) {
        prescriptionBlock.append("<hr style='margin: 4px 0;'/>");
    }

    prescriptionsHtml.append(prescriptionBlock);
}

    // // Adjust instructions if compliance is "no" and frequency is present
    // String modifiedInstructions = instructions;
    // if ("no".equalsIgnoreCase(patientCompliance) && frequency != null && !frequency.isEmpty()) {
    //     modifiedInstructions += " (" + frequency.substring(0, 1).toUpperCase() + frequency.substring(1).toLowerCase() + " Dispense)";
    // }

    // // Construct individual prescription block
    // prescriptionBlock.append("<div class='prescription-details'>")
    //         .append("<p><strong>").append(escapeHtml(medicationName)).append("</strong></p>")
    //         .append("<p style='margin-top: 10px;'>").append(escapeHtml(modifiedInstructions)).append("</p>");

    // // Add special instructions if present
    // if (specialInstructions != null && !specialInstructions.isEmpty()) {
    //     prescriptionBlock.append("<p>").append(escapeHtml(specialInstructions)).append("</p>");
    // }

    // // Add table with prescription details
    // prescriptionBlock.append("<table style='width: 100%;'>");

    // // Add Quantity and Repeats
    // if (quantity != null && !quantity.isEmpty()) {
    //     prescriptionBlock.append("<tr>")
    //             .append("<td style='width: 50%; text-align: left;'>Quantity: ").append(escapeHtml(quantity)).append("</td>");
    //     if (repeats != null && !repeats.isEmpty()) {
    //         prescriptionBlock.append("<td style='width: 50%; text-align: left;'>Repeats: ").append(escapeHtml(repeats)).append("</td>");
    //     }
    //     prescriptionBlock.append("</tr>");
    // }

    // // Add Start Date and Duration
    // if ((startDate != null && !startDate.isEmpty()) || (duration != null && !duration.equals("0 Days") && !duration.isEmpty())) {
    //     prescriptionBlock.append("<tr>");
    //     if (startDate != null && !startDate.isEmpty()) {
    //         prescriptionBlock.append("<td style='width: 50%; text-align: left;'>Start Date: ").append(escapeHtml(startDate)).append("</td>");
    //     }
    //     if (duration != null && !duration.equals("0 Days") && !duration.isEmpty()) {
    //         prescriptionBlock.append("<td style='width: 50%; text-align: left;'>Duration: ").append(escapeHtml(duration)).append("</td>");
    //     }
    //     prescriptionBlock.append("</tr>");
    // }

    //     // Add End Date and Long Term
    //     if ((endDate_p != null && !endDate_p.isEmpty()) || (longTerm != null && !longTerm.isEmpty())) {
    //         prescriptionBlock.append("<tr>");
    //         if (endDate_p != null && !endDate_p.isEmpty()) {
    //             prescriptionBlock.append("<td style='width: 50%; text-align: left;'>End Date: ").append(escapeHtml(endDate_p)).append("</td>");
    //         }
    //         if (longTerm != null && !longTerm.isEmpty()) {
    //             prescriptionBlock.append("<td style='width: 50%; text-align: left;'>Long Term: ").append(escapeHtml(longTerm)).append("</td>");
    //         }
    //         prescriptionBlock.append("</tr>");
    //     }

    //         prescriptionBlock.append("</table></div>");

    //         // Add horizontal rule if not the last prescription
    //         if (i < prescriptionCount - 1) {
    //             prescriptionBlock.append("<hr />");
    //         }

    //         // Append the block to the main content
    //         prescriptionsHtml.append(prescriptionBlock);

    // }

        // Print the entire prescriptionsHtml block to Tomcat console
        System.out.println("Complete Prescriptions HTML: " + prescriptionsHtml.toString());
        
        // Define folder path to organize files by month
        String folderPath = getServletContext().getRealPath("/") + "prescriptionnumber/";
        String fileName = "prescription_" + pracNo + ".txt"; // File name includes pracNo and date
        String filePath = folderPath + fileName;

        int continuousCount = 1; // Default value, to start from 1
        String prescriptionNumber = ""; // Declare the prescription number variable

        // Validate that pracNo is not null or empty
        if (pracNo == null || pracNo.isEmpty()) {
            pracNo = "00000"; // Default value if pracNo is not provided
        }

        // Ensure the folder exists, create it if not
        File folder = new File(folderPath);
        if (!folder.exists()) {
            folder.mkdirs();  // Creates the directory if it doesn't exist
        }

        // Get the current date in the desired format
        String dateFormat = "yyMM";
        String todayStr = new SimpleDateFormat(dateFormat).format(new Date());

        // Check if this is a fax request
        String isFaxRequest = req.getParameter("__method").trim();

        // If it's a fax request, we will write back to the file after incrementing
        if ("oscarRxFax".equals(isFaxRequest)) {
            // Fax request: Start with reading and writing to the file
            File counterFile = new File(filePath);
            synchronized (this) {
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

        // Generate the prescription number using pracNo instead of clinicName
        prescriptionNumber = pracNo + todayStr + String.format("%03d", continuousCount);
        System.out.println("Prescription Number in generatepdf documentbytes: " + prescriptionNumber);
        }

        // Write the updated prescription number back to the file
        try (BufferedWriter writer = new BufferedWriter(new FileWriter(counterFile))) {
            writer.write(String.valueOf(continuousCount));  // Write the updated count back to the file
        } catch (IOException e) {
            e.printStackTrace();
        }

        } else {
            // Not a fax request: Just read from the file and increment for normal PDF generation
            File counterFile = new File(filePath);
            if (!counterFile.exists()) {
                // If the file does not exist, it means this is the first time, so start from 1
                prescriptionNumber = pracNo + todayStr + String.format("%03d", continuousCount);
            } else {
            synchronized (this) {
                try (BufferedReader reader = new BufferedReader(new FileReader(counterFile))) {
                    String lastCountStr = reader.readLine();
                    if (lastCountStr != null && !lastCountStr.isEmpty()) {
                        continuousCount = Integer.parseInt(lastCountStr) + 1; // Increment by 1
                        prescriptionNumber = pracNo + todayStr + String.format("%03d", continuousCount);
                    }
                } catch (IOException | NumberFormatException e) {
                    e.printStackTrace();
                }
            }
        }
}

// At this point, `prescriptionNumber` is either incremented (for faxing purpose) or just read from the file       

        String deliveryOption = req.getParameter("deliveryOption");
        if (deliveryOption == null) {
        deliveryOption = "";  // Set a default value if it's null
        }
        String pharmaName = req.getParameter("pharmaName");
        String pharmaAddress1 = req.getParameter("pharmaAddress1");
        String pharmaAddress2 = req.getParameter("pharmaAddress2");
        String pharmaTel = req.getParameter("pharmaTel");
        String pharmaFax = req.getParameter("pharmaFax");
        String currentDate = now.format(dateFormatter);
        String currentTime = now.format(timeFormatter);
        String patientGender = req.getParameter("patientGender");
        String patientAllergies = req.getParameter("patientAllergies");
        if (patientAllergies == null || patientAllergies.isEmpty()) {
            patientAllergies = "NA";
        }
        String age = "";
        if (patientDOB != null && !patientDOB.isEmpty()) {
            age = calculateAge(patientDOB); // Calculate age based on DOB
        }
    
        // Signature and image handling
        // String imgPath = req.getParameter("imgFile");
        // String imgBase64 = "";
        // if (imgPath != null && !imgPath.isEmpty()) {
        //     File imgFile = new File(imgPath);
        //     if (imgFile.exists()) {
        //         imgBase64 = "data:image/png;base64," + encodeImageToBase64(imgFile);
        //     }
        // }

// Get both static and drawn signatures from JSP
String imgPath = req.getParameter("imgFile");  // Static signature filename
String electronicSignature = req.getParameter("electronicSignature");  // Drawn signature in Base64

// System.out.println("DEBUG (Servlet): imgPath (static) = " + imgPath);
// System.out.println("DEBUG (Servlet): electronicSignature (drawn) = " + (electronicSignature != null ? "Exists" : "NULL"));

// Initialize imgBase64 variable
String imgBase64 = "";

// **Step 1: Use Drawn Signature If It Exists and is Valid**
if (electronicSignature != null && !electronicSignature.trim().isEmpty()) {
    if (electronicSignature.startsWith("data:image/png;base64,")) {
        electronicSignature = electronicSignature.replace("data:image/png;base64,", "");
    }

    //  Validate Base64 Content
    if (isBase64Valid(electronicSignature)) {
        imgBase64 = "data:image/png;base64," + electronicSignature;  //  Use Drawn Signature
        // System.out.println(" Using Drawn Signature (Base64, Length: " + imgBase64.length() + ")");
    } else {
        System.out.println(" ERROR: Drawn Signature Base64 is INVALID");
    }
}

// **Step 2: If No Drawn Signature, Load Static Signature**
if (imgBase64.isEmpty() && imgPath != null && !imgPath.isEmpty()) {
    File imgFile;

    // **Handle Case Where Signature is in `/tmp/`**
    if (imgPath.startsWith("/tmp/")) {
        imgFile = new File(imgPath);
        // System.out.println("Checking for drawn signature in /tmp/: " + imgFile.getAbsolutePath());
    } else {
        // **Static Signature Directory**
        String signatureDirectory = "/usr/share/oscar-emr/OscarDocument/oscar/eform/images";
        imgFile = new File(signatureDirectory, imgPath);
    }

    if (imgFile.exists()) {
        imgBase64 = "data:image/png;base64," + encodeImageToBase64(imgFile);
        // System.out.println("Using Signature from: " + imgFile.getAbsolutePath());
    } else {
        System.out.println("Signature Not Found: " + imgFile.getAbsolutePath());
    }
}

// **Final Debugging**
// System.out.println("DEBUG (Servlet): Final imgBase64 length = " + (imgBase64.isEmpty() ? "NO IMAGE" : imgBase64.length()));



// Now imgBase64 is correctly set and can be used in the HTML template


        // String logoPath = ctx.getRealPath("/images/rx_logo.png");
        // Gets absolute path of the logo from the webapps directory (complete enviornment)
        String logoPath = "/var/lib/tomcat9/webapps/clinic_data/logo/logo2.png";
        File logoFile = new File(logoPath);
        String logoBase64 = "";
        if (logoFile.exists()) {
            logoBase64 = "data:image/png;base64," + encodeImageToBase64(logoFile);
        }

        isFaxRequest = req.getParameter("__method").trim();
        // System.out.println("isFaxRequest: [" + isFaxRequest + "]");
        
        String faxInfo = ""; // Ensure faxInfo starts empty
        // System.out.println("faxInfo before condition check: [" + faxInfo + "]");

        if ("oscarRxFax".equals(isFaxRequest)) {
            // System.out.println("Condition met: Setting faxInfo for fax request.");
            faxInfo = "<h3>Prescriber Certification</h3>\n"
                + "<p>I hereby certify that:</p>\n"
                + "<ul>\n"
                + "    <li>This prescription represents the original prescription drug order.</li>\n"
                + "    <li>The pharmacy address noted above is the sole intended recipient.</li>\n"
                + "    <li>The original prescription will not be reissued.</li>\n"
                + "</ul>\n"
                + "<br/>\n"
                + "<br/>\n"
                + "Fax was sent to " + escapeHtml(pharmaName) + " on " + escapeHtml(currentDate) + " at " + escapeHtml(currentTime) + ".";
        }
        else {
            faxInfo = "";
            // System.out.println("Condition NOT met: isFaxRequest = [" + isFaxRequest + "]");
        }
        
        // System.out.println("Final faxInfo passed to template: [" + faxInfo + "]");

        logger.debug("Base64 encoded logo length: " + (logoBase64 != null ? logoBase64.length() : "not found"));
    
        // Load the HTML template as a String
        String htmlTemplate = loadHtmlTemplate();
    
        // Replace placeholders in HTML template
        String filledHtml = htmlTemplate
        .replace("{{faxInfo}}", faxInfo)
        .replace("{{prescriptions}}", prescriptionsHtml.toString())
        .replace("${clinicName}", escapeHtml(clinicName))
        .replace("${clinicAddress}", escapeHtml(clinicAddress))
        .replace("${clinicCity}", escapeHtml(clinicCity))
        .replace("${clinicProvince}", escapeHtml(clinicProvince))
        .replace("${clinicPostal}", escapeHtml(clinicPostal))
        .replace("${clinicTel}", escapeHtml(clinicTel))
        .replace("${clinicFax}", escapeHtml(clinicFax))
        .replace("${rxDate}", escapeHtml(rxDate))
        .replace("${patientName}", escapeHtml(patientName))
        .replace("${patientDOB}", escapeHtml(patientDOB))
        .replace("${age}", escapeHtml(age))
        .replace("${patientPhone}", escapeHtml(patientPhone.replace("Tel", "").trim()))
        .replace("${patientAddress}", escapeHtml(patientAddress))
        .replace("${patientCityPostal}", escapeHtml(patientCityPostal))
        .replace("${patientHIN}", escapeHtml(patientHIN))
        .replace("${sigDoctorName}", escapeHtml(sigDoctorName))
        .replace("${pracNo}", escapeHtml(pracNo))
        .replace("${rx}", escapeHtml(rx))
        .replace("${rx_no_newlines}", escapeHtml(rxNoNewlines))   
        .replace("${rxQty}", escapeHtml(rxQty))
        .replace("${rxRepeats}", escapeHtml(rxRepeats))
        .replace("${rxStartDate}", escapeHtml(rxStartDate))
        .replace("${additNotes}", escapeHtml(additNotes))
        .replace("${pharmaName}", escapeHtml(pharmaName))
        .replace("${pharmaAddress1}", escapeHtml(pharmaAddress1))
        .replace("${pharmaAddress2}", escapeHtml(pharmaAddress2))
        .replace("${pharmaTel}", escapeHtml(pharmaTel))
        .replace("${pharmaFax}", escapeHtml(pharmaFax))
        .replace("${currentDate}", escapeHtml(currentDate))
        .replace("${currentTime}", escapeHtml(currentTime))
        .replace("${imgPath}", !imgBase64.isEmpty() ? imgBase64 : "")
        .replace("${patientGender}", patientGender != null ? escapeHtml(patientGender) : "")
        .replace("${patientAllergies}", patientAllergies != null ? escapeHtml(patientAllergies) : "None")
        .replace("${deliveryOption}", escapeHtml(deliveryOption)) 
        .replace("${prescriptionNumber}", escapeHtml(prescriptionNumber))
        .replace("${prescriptionBatchId}", escapeHtml(prescriptionBatchId))
        .replace("${logo}", logoBase64.isEmpty() ? "" : logoBase64);


         // Render HTML to PDF using Flying Saucer library
        //  ByteArrayOutputStream baosPDF = new ByteArrayOutputStream();
        //  ITextRenderer renderer = new ITextRenderer();
        //  renderer.setDocumentFromString(filledHtml);
        //  renderer.layout();
        //  renderer.createPDF(baosPDF);
     
        //  logger.debug("***END in generatePDFDocumentBytes2 FrmCustomedPDFServlet.java***");
        //  return new Object[] { baosPDF, prescriptionNumber };

        // Use Chrome Headless to generate PDF instead of Flying Saucer
        File tempHtmlFile = File.createTempFile("prescription_", ".html");
        File tempPdfFile = File.createTempFile("prescription_", ".pdf");
        
        // Write filled HTML to temp file
        try (BufferedWriter writer = new BufferedWriter(new FileWriter(tempHtmlFile))) {
            writer.write(filledHtml);
        }
        
        // Build Chrome command with safe data dir
        String[] command = {
            "google-chrome",
            "--headless",
            "--no-sandbox",
            "--disable-gpu",
            "--user-data-dir=/tmp/chrome-profile", // explicitly set writable user data dir
            "--print-to-pdf=" + tempPdfFile.getAbsolutePath(),
            tempHtmlFile.getAbsolutePath()
        };
        
        // Start the process
        ProcessBuilder pb = new ProcessBuilder(command);
        pb.redirectErrorStream(true); // Merge stdout + stderr
        pb.environment().put("HOME", "/tmp");      // override default HOME
        
        Process process = pb.start();
        
        // Optional: log output for debugging
        try (BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()))) {
            String line;
            while ((line = reader.readLine()) != null) {
                System.out.println("CHROME >> " + line); // or use a logger
            }
        }
        
        int exitCode = process.waitFor();
        
        if (exitCode != 0 || !tempPdfFile.exists() || tempPdfFile.length() == 0) {
            throw new IOException("Chrome headless PDF generation failed. Exit code: " + exitCode);
        }
        

// Read generated PDF into ByteArrayOutputStream
ByteArrayOutputStream baosPDF = new ByteArrayOutputStream();
try (FileInputStream fis = new FileInputStream(tempPdfFile)) {
    byte[] buffer = new byte[4096];
    int bytesRead;
    while ((bytesRead = fis.read(buffer)) != -1) {
        baosPDF.write(buffer, 0, bytesRead);
    }
} finally {
    // Clean up temp files
    tempHtmlFile.delete();
    tempPdfFile.delete();
}

logger.debug("*** END in generatePDFDocumentBytes2 FrmCustomedPDFServlet.java (Chrome Headless) ***");
return new Object[] { baosPDF, prescriptionNumber };

        }
    

// Method to convert image file to Base64 string
private String encodeImageToBase64(File imageFile) throws IOException {
    try (FileInputStream imageInFile = new FileInputStream(imageFile)) {
        ByteArrayOutputStream buffer = new ByteArrayOutputStream();
        byte[] data = new byte[1024];
        int bytesRead;
        while ((bytesRead = imageInFile.read(data, 0, data.length)) != -1) {
            buffer.write(data, 0, bytesRead);
        }
        // Use Base64 from Apache Commons Codec
        return Base64.encodeBase64String(buffer.toByteArray());
    }
}

public boolean isBase64Valid(String base64) {
    try {
        // Remove "data:image/png;base64," prefix if it exists
        if (base64.startsWith("data:image/png;base64,")) {
            base64 = base64.replace("data:image/png;base64,", "");
        }

        // Decode using Apache Commons Codec
        byte[] decodedBytes = Base64.decodeBase64(base64);
        
        // If decoded successfully, return true
        return decodedBytes.length > 0;
    } catch (Exception e) {
        System.out.println("ERROR: Invalid Base64 Encoding");
        return false;
    }
}

// Load HTML template as in your previous code
private String loadHtmlTemplate() throws IOException {
    InputStream inputStream = getClass().getResourceAsStream("/template.html");
    if (inputStream == null) {
        throw new FileNotFoundException("HTML template not found in resources.");
    }
    
    ByteArrayOutputStream result = new ByteArrayOutputStream();
    byte[] buffer = new byte[1024];
    int length;
    while ((length = inputStream.read(buffer)) != -1) {
        result.write(buffer, 0, length);
    }
    
    return result.toString("UTF-8");
}

public boolean uploadToS3(ByteArrayOutputStream baosPDF, String s3FolderPath, String pdfFileName) {

    // Fetch credentials and config from properties file
    OscarProperties props = OscarProperties.getInstance();

    String bucketName = props.getProperty("AWS_BUCKET_NAME");
    String region = props.getProperty("AWS_REGION");
    String accessKey = props.getProperty("AWS_ACCESS_KEY");
    String secretKey = props.getProperty("AWS_SECRET_KEY");
    // System.out.println("BUCKET_NAME: " + bucketName);

    if (bucketName == null || region == null || accessKey == null || secretKey == null) {
        System.err.println("AWS properties not properly configured.");
        return false;
    }

    // Initialize AWS credentials
    AwsBasicCredentials awsCreds = AwsBasicCredentials.create(accessKey, secretKey);

    // Initialize S3 Client
    S3Client s3 = S3Client.builder()
        .region(Region.of(region))
        .credentialsProvider(StaticCredentialsProvider.create(awsCreds))
        .build();

    try {
        // Convert ByteArrayOutputStream to byte array
        byte[] pdfBytes = baosPDF.toByteArray();

        // Prepare S3 put request
        PutObjectRequest putOb = PutObjectRequest.builder()
            .bucket(bucketName)
            .key(s3FolderPath + pdfFileName)
            .contentType("application/pdf")
            .build();

        // Upload to S3
        s3.putObject(putOb, RequestBody.fromBytes(pdfBytes));

        System.out.println("PDF successfully uploaded to S3: " + s3FolderPath + pdfFileName);
        return true;  // Upload successful

    } catch (Exception e) {
        System.err.println("Error uploading PDF to S3: " + e.getMessage());
        e.printStackTrace();
        return false;  // Upload failed
    }
}



//     try {
//         // Convert ByteArrayOutputStream to byte array
//         byte[] pdfBytes = baosPDF.toByteArray();

//         // Upload to S3
//         PutObjectRequest putOb = PutObjectRequest.builder()
//             .bucket(bucketName)
//             .key(s3FolderPath + pdfFileName) // Full S3 path
//             .contentType("application/pdf")
//             .build();

//         s3.putObject(putOb, RequestBody.fromBytes(pdfBytes));

//         System.out.println("PDF successfully uploaded to S3: " + s3FolderPath + pdfFileName);
//         return true;  // Upload successful
//     } catch (Exception e) {
//         System.err.println("Error uploading PDF to S3: " + e.getMessage());
//         e.printStackTrace();
//         return false;  // Upload failed
//     }
// }


 }