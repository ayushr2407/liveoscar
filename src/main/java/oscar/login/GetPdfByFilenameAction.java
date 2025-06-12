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

public class GetPdfByFilenameAction extends Action {

    private static final String DOCUMENT_PATH = "/usr/share/oscar-emr/OscarDocument/oscar/document/";

    @Override
    public ActionForward execute(ActionMapping mapping, ActionForm form,
                                 HttpServletRequest request, HttpServletResponse response) throws Exception {

        String[] parFilenames = request.getParameterValues("par_filenames");
        String[] otherFilenames = request.getParameterValues("other_filenames");

        if ((parFilenames == null || parFilenames.length == 0) &&
            (otherFilenames == null || otherFilenames.length == 0)) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            response.getWriter().write("Missing 'par_filenames' or 'other_filenames' parameters.");
            return null;
        }

        // Prioritize PAR filenames, else use OTHER
        String[] filenames = (parFilenames != null && parFilenames.length > 0) ? parFilenames : otherFilenames;
        String filenameLabel = (parFilenames != null && parFilenames.length > 0) ? "par_pdf" : "other_docs_pdf";

        // --- If only one filename, stream the file directly (preserve metadata, AcroForm, etc) ---
        if (filenames.length == 1) {
            File file = new File(DOCUMENT_PATH + filenames[0]);
            if (!file.exists() || !file.isFile()) {
                response.setStatus(HttpServletResponse.SC_NOT_FOUND);
                response.getWriter().write("File not found: " + filenames[0]);
                return null;
            }
            System.out.println("[Oscar] Streaming PAR/Single PDF directly: " + filenames[0] + ", size: " + file.length() + " bytes");
            response.setContentType("application/pdf");
            response.setHeader("Content-Disposition", "attachment; filename=\"" + filenames[0] + "\"");
            try (InputStream in = new FileInputStream(file);
                 OutputStream out = response.getOutputStream()) {
                byte[] buffer = new byte[8192];
                int bytesRead;
                while ((bytesRead = in.read(buffer)) != -1) {
                    out.write(buffer, 0, bytesRead);
                }
                out.flush();
            }
            return null;
        }
        System.out.println("[Oscar] Merging multiple PDFs: " + String.join(", ", filenames));

        // --- If multiple files, merge as before ---
        byte[] mergedPdfBytes = mergePdfs(filenames);

        if (mergedPdfBytes == null) {
            response.setStatus(HttpServletResponse.SC_NOT_FOUND);
            response.getWriter().write("No valid PDF files found to merge.");
            return null;
        }

        System.out.println("[Oscar] Returning merged PDF: " + filenameLabel + ".pdf, size: " + mergedPdfBytes.length + " bytes");


        response.setContentType("application/pdf");
        response.setHeader("Content-Disposition", "attachment; filename=\"" + filenameLabel + ".pdf\"");
        OutputStream out = response.getOutputStream();
        out.write(mergedPdfBytes);
        out.flush();
        out.close();

        return null;
    }

    private byte[] mergePdfs(String[] filenames) {
        if (filenames == null || filenames.length == 0) {
            return null;
        }

        try {
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
                return null;
            }

            return mergedPdfStream.toByteArray();

        } catch (Exception e) {
            e.printStackTrace();
            return null;
        }
    }
}
