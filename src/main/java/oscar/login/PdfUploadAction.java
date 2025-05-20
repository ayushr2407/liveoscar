package oscar.login;

import java.io.File;
import java.util.List;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.apache.commons.fileupload.FileItem;
import org.apache.commons.fileupload.disk.DiskFileItemFactory;
import org.apache.commons.fileupload.servlet.ServletFileUpload;

import org.apache.struts.action.Action;
import org.apache.struts.action.ActionForm;
import org.apache.struts.action.ActionForward;
import org.apache.struts.action.ActionMapping;

public class PdfUploadAction extends Action {

    // Target location to save the PDFs
    private static final String SAVE_DIRECTORY = "/usr/share/oscar-emr/OscarDocument/oscar/document";

    @Override
    public ActionForward execute(ActionMapping mapping, ActionForm form,
                                 HttpServletRequest request, HttpServletResponse response) {
        try {
            if (!ServletFileUpload.isMultipartContent(request)) {
                response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                response.getWriter().write("Error: form must be multipart/form-data");
                return null;
            }

            // Set up file upload handling
            DiskFileItemFactory factory = new DiskFileItemFactory();
            ServletFileUpload upload = new ServletFileUpload(factory);
            upload.setFileSizeMax(25 * 1024 * 1024); // 10 MB limit
            upload.setSizeMax(30 * 1024 * 1024);

            List<FileItem> items = upload.parseRequest(request);

            for (FileItem item : items) {
                if (!item.isFormField()) {
                    String filename = new File(item.getName()).getName();
                    File saveDir = new File(SAVE_DIRECTORY);
                    if (!saveDir.exists()) saveDir.mkdirs();

                    File savedFile = new File(saveDir, filename);
                    item.write(savedFile);

                    response.setStatus(HttpServletResponse.SC_OK);
                    response.getWriter().write("PDF uploaded successfully as: " + filename);
                    return null;
                }
            }

            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            response.getWriter().write("Error: no file part found in request");
        } catch (Exception e) {
            try {
                response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
                response.getWriter().write("Error while uploading: " + e.getMessage());
            } catch (Exception ignored) {}
        }

        return null;
    }
}
