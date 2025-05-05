package oscar.form.pdfservlet;

import java.net.URL;
import java.time.Duration;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import software.amazon.awssdk.auth.credentials.StaticCredentialsProvider;
import software.amazon.awssdk.auth.credentials.AwsBasicCredentials;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.s3.presigner.S3Presigner;
import software.amazon.awssdk.services.s3.presigner.model.GetObjectPresignRequest;
import software.amazon.awssdk.services.s3.model.GetObjectRequest;
import oscar.OscarProperties;

public class SecurePdfServlet extends HttpServlet {


    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException {

        try {
            // Get the file path stored in the database
            String filePath = request.getParameter("file");
            if (filePath == null || filePath.isEmpty()) {
                response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Invalid file path.");
                return;
            }

             // Fetch credentials and config from properties file
             OscarProperties props = OscarProperties.getInstance();

             String BUCKET_NAME = props.getProperty("AWS_BUCKET_NAME");
             String REGION = props.getProperty("AWS_REGION");
             String ACCESS_KEY = props.getProperty("AWS_ACCESS_KEY");
             String SECRET_KEY = props.getProperty("AWS_SECRET_KEY");

            //  System.out.println("BUCKET_NAME: " + BUCKET_NAME);
            //  System.out.println("REGION: " + REGION);
            //  System.out.println("ACCESS_KEY: " + ACCESS_KEY);
            //  System.out.println("SECRET_KEY: " + SECRET_KEY);
 
             if (BUCKET_NAME == null || REGION == null || ACCESS_KEY == null || SECRET_KEY == null) {
                 response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR,
                                    "AWS properties not properly configured.");
                 return;
             }

            // Initialize AWS credentials
            AwsBasicCredentials awsCreds = AwsBasicCredentials.create(ACCESS_KEY, SECRET_KEY);

            // Create S3 Presigner
            try (S3Presigner presigner = S3Presigner.builder()
                    .region(Region.of(REGION))
                    .credentialsProvider(StaticCredentialsProvider.create(awsCreds))
                    .build()) {

                // Generate a request to fetch the file from S3
                GetObjectRequest getObjectRequest = GetObjectRequest.builder()
                        .bucket(BUCKET_NAME)
                        .key(filePath)
                        .responseContentType("application/pdf")
                        .build();

                // Create a pre-signed URL valid for 10 minutes
                GetObjectPresignRequest presignRequest = GetObjectPresignRequest.builder()
                        .signatureDuration(Duration.ofMinutes(60))
                        .getObjectRequest(getObjectRequest)
                        .build();

                URL presignedUrl = presigner.presignGetObject(presignRequest).url();

                // Redirect the user to the pre-signed URL
                response.sendRedirect(presignedUrl.toString());
            }

        } catch (Exception e) {
            e.printStackTrace();
            try {
                response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Error generating pre-signed URL.");
            } catch (Exception ignored) {}
        }
    }
}



// import java.io.File;
// import java.io.FileInputStream;
// import java.io.IOException;
// import javax.servlet.ServletException;
// import javax.servlet.ServletOutputStream;
// import javax.servlet.http.HttpServlet;
// import javax.servlet.http.HttpServletRequest;
// import javax.servlet.http.HttpServletResponse;
// import javax.servlet.http.HttpSession;

// public class SecurePdfServlet extends HttpServlet {

//     private static final String DOCUMENT_DIR = "/usr/share/oscar-emr/OscarDocument/oscar/document/";

//     @Override
//     protected void doGet(HttpServletRequest request, HttpServletResponse response)
//             throws ServletException, IOException {

//         // Check if user is authenticated
//         HttpSession session = request.getSession(false);
//         if (session == null || session.getAttribute("user") == null) {
//             response.sendError(HttpServletResponse.SC_UNAUTHORIZED, "Unauthorized access.");
//             return;
//         }

//         // Get the requested file
//         String fileName = request.getParameter("file");
//         if (fileName == null || fileName.contains("..") || fileName.contains("/")) {
//             response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Invalid file name.");
//             return;
//         }

//         File file = new File(DOCUMENT_DIR + fileName);
//         if (!file.exists()) {
//             response.sendError(HttpServletResponse.SC_NOT_FOUND, "File not found.");
//             return;
//         }

//         // Set response headers for PDF
//         response.setContentType("application/pdf");
//         response.setHeader("Content-Disposition", "inline; filename=" + fileName);
//         response.setContentLength((int) file.length());

//         // Stream the PDF file
//         try (FileInputStream fis = new FileInputStream(file);
//              ServletOutputStream out = response.getOutputStream()) {

//             byte[] buffer = new byte[4096];
//             int bytesRead;
//             while ((bytesRead = fis.read(buffer)) != -1) {
//                 out.write(buffer, 0, bytesRead);
//             }
//         }
//     }
// }
