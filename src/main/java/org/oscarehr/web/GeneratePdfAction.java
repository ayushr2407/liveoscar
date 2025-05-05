package org.oscarehr.web;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.apache.struts.action.*;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.interactive.form.PDAcroForm;
import org.apache.pdfbox.pdmodel.interactive.form.PDField;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import java.io.File;
import java.util.Map;

public class GeneratePdfAction extends Action {

    private static final String PDF_RELATIVE_PATH = "/WEB-INF/forms/";

    public static class PdfRequest {
        public String pdfName;
        public Map<String, String> fields;
    }

    @Override
    public ActionForward execute(ActionMapping mapping, ActionForm form,
                                 HttpServletRequest request, HttpServletResponse response) throws Exception {

        // Parse incoming JSON to PdfRequest object
        ObjectMapper objectMapper = new ObjectMapper();
        PdfRequest pdfRequest = objectMapper.readValue(request.getInputStream(), PdfRequest.class);

        // Resolve actual file path securely
        String absolutePath = getServlet().getServletContext().getRealPath(PDF_RELATIVE_PATH + pdfRequest.pdfName);
        File template = new File(absolutePath);

        if (!template.exists()) {
            response.setStatus(HttpServletResponse.SC_NOT_FOUND);
            response.getWriter().write("PDF template not found.");
            return null;
        }

        // Load the PDF and fill the form
        try (PDDocument document = PDDocument.load(template)) {
            PDAcroForm acroForm = document.getDocumentCatalog().getAcroForm();

            if (acroForm != null && pdfRequest.fields != null) {
                for (Map.Entry<String, String> entry : pdfRequest.fields.entrySet()) {
                    PDField field = acroForm.getField(entry.getKey());
                    if (field != null) {
                        field.setValue(entry.getValue());
                    }
                }
                // acroForm.flatten(); // Optional: makes fields read-only
            }

            // Stream PDF as response
            response.setContentType("application/pdf");
            response.setHeader("Content-Disposition", "inline; filename=\"" + pdfRequest.pdfName + "\"");
            document.save(response.getOutputStream());
        }

        return null; // no ActionForward — direct stream
    }
}
