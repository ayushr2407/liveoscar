<%@ page import="java.net.*, java.io.*, java.util.Base64, org.json.JSONObject" %>
   <%@ page import="org.oscarehr.fax.util.FaxConfigUtil" %>
   <%@ page import="org.oscarehr.common.model.FaxConfig" %>
<%@ page language="java" contentType="text/html" pageEncoding="UTF-8"%>

<%
    try {
        // Get the fax file name from the request parameter
        String fileName = request.getParameter("fileName");
        if (fileName == null || fileName.isEmpty()) {
            throw new Exception("Fax file name is missing in the request parameters.");
        }

       FaxConfig activeConfig = FaxConfigUtil.getActiveFaxConfig();
        if (activeConfig == null) {
            throw new Exception("No active fax configuration found. Please set up a fax configuration first.");
        }

        String accessId = activeConfig.getFaxUser();
        String accessPwd = activeConfig.getFaxPasswd();
        String action = "Retrieve_Fax";
        String direction = "IN";  // Use "IN" for received faxes

        // Create the connection to SRFax API
        URL url = new URL("https://www.srfax.com/SRF_SecWebSvc.php");
        HttpURLConnection conn = (HttpURLConnection) url.openConnection();
        conn.setRequestMethod("POST");
        conn.setDoOutput(true);

        // Prepare the POST parameters
        String urlParameters = "action=" + URLEncoder.encode(action, "UTF-8") +
                               "&access_id=" + URLEncoder.encode(accessId, "UTF-8") +
                               "&access_pwd=" + URLEncoder.encode(accessPwd, "UTF-8") +
                               "&sFaxFileName=" + URLEncoder.encode(fileName, "UTF-8") +
                               "&sDirection=" + URLEncoder.encode(direction, "UTF-8") +
                               "&sFaxFormat=PDF";

        // Send the POST request
        try (DataOutputStream wr = new DataOutputStream(conn.getOutputStream())) {
            wr.writeBytes(urlParameters);
            wr.flush();
        }

        // Read the response from SRFax API
        StringBuilder apiResponse = new StringBuilder();
        try (BufferedReader in = new BufferedReader(new InputStreamReader(conn.getInputStream()))) {
            String inputLine;
            while ((inputLine = in.readLine()) != null) {
                apiResponse.append(inputLine);
            }
        }

        // Parse the JSON response
        JSONObject jsonResponse = new JSONObject(apiResponse.toString());
        String status = jsonResponse.getString("Status");

        if ("Success".equals(status)) {
            // Retrieve the Base64-encoded PDF content
            String base64FaxContent = jsonResponse.getString("Result");

            // Sanitize the Base64 string by removing invalid characters (e.g., newlines or extra spaces)
            base64FaxContent = base64FaxContent.replaceAll("[^A-Za-z0-9+/=]", "");

            if (base64FaxContent == null || base64FaxContent.isEmpty()) {
                out.println("<p>Error: No fax content received from SRFax.</p>");
            } else {
                try {
                    // Convert the Base64-encoded content to a byte array
                    byte[] pdfContent = Base64.getDecoder().decode(base64FaxContent);

                    if (pdfContent.length == 0) {
                        out.println("<p>Error: Decoded PDF content is empty.</p>");
                    } else {
                        // Set the response headers for the PDF file
                        response.setContentType("application/pdf");
                        response.setContentLength(pdfContent.length);
                        response.setHeader("Content-Disposition", "inline; filename=\"fax.pdf\"");

                        // Write the PDF content to the response output stream
                        try (ServletOutputStream outputStream = response.getOutputStream()) {
                            outputStream.write(pdfContent);
                            outputStream.flush();
                        }
                    }
                } catch (IllegalArgumentException e) {
                    out.println("<p>Error: Failed to decode Base64 content. Exception: " + e.getMessage() + "</p>");
                }
            }
        } else {
            // Handle the error if the fax retrieval fails
            out.println("<p>Error retrieving fax: " + jsonResponse.getString("Result") + "</p>");
        }
    } catch (Exception e) {
        // Print the exception message and stack trace for debugging
        out.println("<p>Exception: " + e.getMessage() + "</p>");
        e.printStackTrace(new PrintWriter(out));
    }
%>
