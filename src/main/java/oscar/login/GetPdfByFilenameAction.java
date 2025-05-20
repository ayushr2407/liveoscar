package oscar.login;

import com.lowagie.text.Document;
import com.lowagie.text.pdf.PdfCopy;
import com.lowagie.text.pdf.PdfReader;
import org.apache.struts.action.Action;
import org.apache.struts.action.ActionForm;
import org.apache.struts.action.ActionForward;
import org.apache.struts.action.ActionMapping;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.*;
import java.util.Base64;


public class GetPdfByFilenameAction extends Action {

    private static final String DOCUMENT_PATH = "/usr/share/oscar-emr/OscarDocument/oscar/document/";

    @Override
public ActionForward execute(ActionMapping mapping, ActionForm form,
                             HttpServletRequest request, HttpServletResponse response) throws Exception {

    String[] filenames = request.getParameterValues("filename");

    if (filenames == null || filenames.length == 0) {
        response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
        response.getWriter().write("Missing 'filename' parameter(s).");
        return null;
    }

    byte[] pdfBytes;

    if (filenames.length == 1) {
        // Single file case
        String filename = filenames[0];
        File file = new File(DOCUMENT_PATH + filename);

        if (!file.exists() || !file.isFile()) {
            response.setStatus(HttpServletResponse.SC_NOT_FOUND);
            response.getWriter().write("File not found: " + filename);
            return null;
        }

        try (FileInputStream fis = new FileInputStream(file);
             ByteArrayOutputStream baos = new ByteArrayOutputStream()) {
            byte[] buffer = new byte[8192];
            int len;
            while ((len = fis.read(buffer)) != -1) {
                baos.write(buffer, 0, len);
            }
            pdfBytes = baos.toByteArray();
        }

    } else {
        // Multiple files merge case
        ByteArrayOutputStream mergedPdfStream = new ByteArrayOutputStream();
        Document mergedDoc = new Document();
        PdfCopy copy = new PdfCopy(mergedDoc, mergedPdfStream);
        mergedDoc.open();

        boolean atLeastOneFile = false;

        for (String filename : filenames) {
            if (filename == null || filename.trim().isEmpty()) continue;

            File file = new File(DOCUMENT_PATH + filename);
            if (!file.exists() || !file.isFile()) continue;

            PdfReader reader = new PdfReader(new FileInputStream(file));
            int pages = reader.getNumberOfPages();

            for (int i = 1; i <= pages; i++) {
                copy.addPage(copy.getImportedPage(reader, i));
            }
            reader.close();
            atLeastOneFile = true;
        }

        mergedDoc.close();

        if (!atLeastOneFile) {
            response.setStatus(HttpServletResponse.SC_NOT_FOUND);
            response.getWriter().write("None of the requested files were found.");
            return null;
        }

        pdfBytes = mergedPdfStream.toByteArray();
    }

    // Encode PDF bytes to base64
    String base64Pdf = Base64.getEncoder().encodeToString(pdfBytes);

    // Return as JSON
    String jsonResponse = "{\"base64_pdf\":\"" + base64Pdf + "\"}";
    response.setContentType("application/json");
    response.setCharacterEncoding("UTF-8");
    response.getWriter().write(jsonResponse);

    return null;
}
}
