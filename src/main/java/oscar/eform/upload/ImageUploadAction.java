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


package oscar.eform.upload;

// import java.util.List;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.OutputStream;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.apache.struts.action.Action;
import org.apache.struts.action.ActionForm;
import org.apache.struts.action.ActionForward;
import org.apache.struts.action.ActionMapping;
import org.apache.struts.upload.FormFile;
import org.oscarehr.common.dao.UserPropertyDAO;
import org.oscarehr.common.model.UserProperty;
import org.oscarehr.managers.SecurityInfoManager;
import org.oscarehr.util.LoggedInInfo;
import org.oscarehr.util.MiscUtils;
import org.oscarehr.util.SpringUtils;

import oscar.OscarProperties;

public class ImageUploadAction extends Action {
    
	private SecurityInfoManager securityInfoManager = SpringUtils.getBean(SecurityInfoManager.class);

    public ActionForward execute(ActionMapping mapping, ActionForm form, 
                             HttpServletRequest request, HttpServletResponse response) throws Exception {

    if (!securityInfoManager.hasPrivilege(LoggedInInfo.getLoggedInInfoFromSession(request), "_eform", "w", null)) {
        throw new SecurityException("missing required security object (_eform)");
    }

    String method = request.getParameter("method");
    if ("uploadProviderImage".equals(method)) {
        return uploadProviderImage(mapping, form, request, response);
    } else if ("removeProviderImage".equals(method)) {
        return removeProviderImage(mapping, form, request, response);
    }

    return mapping.findForward("success");
}

    public ActionForward uploadProviderImage(ActionMapping mapping, ActionForm form,
            HttpServletRequest request, HttpServletResponse response) {

            ImageUploadForm fm = (ImageUploadForm) form;
            FormFile image = fm.getImage();  // Single file upload

            if (image == null || image.getFileSize() == 0) {
            request.setAttribute("error", "No file selected.");
            return mapping.findForward("failure");
            }

            String providerNo = LoggedInInfo.getLoggedInInfoFromSession(request).getLoggedInProviderNo();
            UserPropertyDAO userPropertyDAO = SpringUtils.getBean(UserPropertyDAO.class);

            try {
            // Generate unique filename
            String signatureName = "consult_sig_" + providerNo + "_" + System.currentTimeMillis() + ".png";
            OutputStream fos = getEFormImageOutputStream(signatureName);
            fos.write(image.getFileData());
            fos.close();

            // Save new signature entry in DB
            UserProperty property = new UserProperty();
            property.setName(UserProperty.PROVIDER_CONSULT_SIGNATURE);
            property.setProviderNo(providerNo);
            property.setValue(signatureName);
            userPropertyDAO.saveSignature(property);

            } catch (Exception e) {
            MiscUtils.getLogger().error("Error saving image: ", e);
            return mapping.findForward("failure");
            }

            return mapping.findForward("consultSignatureSuccess");
    }


public ActionForward removeProviderImage(ActionMapping mapping, ActionForm form, 
                                         HttpServletRequest request, HttpServletResponse response) {
    
    String providerNo = LoggedInInfo.getLoggedInInfoFromSession(request).getLoggedInProviderNo();
    String imagePath = request.getParameter("imageToDelete");

    UserPropertyDAO userPropertyDAO = SpringUtils.getBean(UserPropertyDAO.class);
    
    if (imagePath != null && !imagePath.isEmpty()) {
        try {
            // Delete file from storage
            File sigFile = new File(OscarProperties.getInstance().getProperty("eform_image") + "/" + imagePath);
            if (sigFile.exists()) {
                sigFile.delete();
            }

            // Remove from DB
            userPropertyDAO.deleteSignature(providerNo, imagePath);
        } catch (Exception e) {
            MiscUtils.getLogger().error("Error", e);
        }
    }

    return mapping.findForward("consultSignatureSuccess");
}

	
    // public ActionForward execute(ActionMapping mapping, ActionForm form, HttpServletRequest request, HttpServletResponse response) {
    	
    // 	if(!securityInfoManager.hasPrivilege(LoggedInInfo.getLoggedInInfoFromSession(request), "_eform", "w", null)) {
	// 		throw new SecurityException("missing required security object (_eform)");
	// 	}
		
	// 	if (request.getParameter("method") != null && request.getParameter("method").equals("uploadProviderImage")) {
    // 	    return uploadProviderImage(mapping, form, request, response);
    //     } else if (request.getParameter("method") != null && request.getParameter("method").equals("removeProviderImage")) {
    //         return removeProviderImage(mapping, form, request, response);
    //     }
    	
    //      ImageUploadForm fm = (ImageUploadForm) form;
    //      FormFile image = fm.getImage();
    //      try {
    //          byte[] imagebytes = image.getFileData();
    //          OutputStream fos = ImageUploadAction.getEFormImageOutputStream(image.getFileName());
    //          fos.write(imagebytes);
    //      } catch (Exception e) { MiscUtils.getLogger().error("Error", e); }
    //      return mapping.findForward("success");
    // }

    public static OutputStream getEFormImageOutputStream(String imageFileName) throws IOException {
        String filepath = OscarProperties.getInstance().getProperty("eform_image") + "/" + imageFileName;
        File imageFile = new File(filepath);

        File imageFolder = getImageFolder();
        if (!imageFolder.exists() && !imageFolder.mkdirs()) {
            throw new IOException("Could not create directory " + imageFolder.getAbsolutePath());
        }

        return new FileOutputStream(imageFile);
    }

    public static File getImageFolder() throws IOException {
        File imageFolder = new File(OscarProperties.getInstance().getProperty("eform_image") + "/");
        if (!imageFolder.exists() && !imageFolder.mkdirs()) throw new IOException("Could not create directory " + imageFolder.getAbsolutePath() + " check permissions and ensure the correct eform_image property is set in the properties file");
        return imageFolder;
    }

    // public ActionForward uploadProviderImage(ActionMapping mapping, ActionForm form, HttpServletRequest request, HttpServletResponse response) {

    //     ImageUploadForm fm = (ImageUploadForm) form;
    //     FormFile image = fm.getImage();
    //     String providerNo = LoggedInInfo.getLoggedInInfoFromSession(request).getLoggedInProviderNo();
    //     String signatureName = "consult_sig_" + providerNo + ".png";
    //     try {
    //         byte[] imagebytes = image.getFileData();
    //         OutputStream fos = ImageUploadAction.getEFormImageOutputStream(signatureName);
    //         fos.write(imagebytes);
    //     } catch (Exception e) { MiscUtils.getLogger().error("Error", e); }
        
    //     UserPropertyDAO userPropertyDAO = SpringUtils.getBean(UserPropertyDAO.class);
    //     UserProperty property = userPropertyDAO.getProp(providerNo,UserProperty.PROVIDER_CONSULT_SIGNATURE);
    //     if (property == null) {
    //         property = new UserProperty();
    //         property.setName(UserProperty.PROVIDER_CONSULT_SIGNATURE);
    //         property.setProviderNo(providerNo);
    //         property.setValue(signatureName);
    //         userPropertyDAO.saveProp(property);
    //     }
    //     return mapping.findForward("consultSignatureSuccess");
    // }
    // public ActionForward removeProviderImage(ActionMapping mapping, ActionForm form, HttpServletRequest request, HttpServletResponse response) {
        
    //     String providerNo = LoggedInInfo.getLoggedInInfoFromSession(request).getLoggedInProviderNo();
        
    //     UserPropertyDAO userPropertyDAO = SpringUtils.getBean(UserPropertyDAO.class);
    //     UserProperty property = userPropertyDAO.getProp(providerNo,UserProperty.PROVIDER_CONSULT_SIGNATURE);
        
    //     if (property != null) {
    //         try {
    //             String signatureName = property.getValue();
    //             File sigFile = new File(OscarProperties.getInstance().getProperty("eform_image") + "/" + signatureName);
    //             if (sigFile.exists()) {
    //                 sigFile.delete();
    //             }

    //             userPropertyDAO.delete(property);
    //         } catch (Exception e) { MiscUtils.getLogger().error("Error", e); }

    //     }
    //     return mapping.findForward("consultSignatureSuccess");
    // }
}
