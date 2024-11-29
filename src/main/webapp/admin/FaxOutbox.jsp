<%@ page import="java.net.*, java.io.*, org.json.JSONObject, org.json.JSONArray" %>
<%@ page import="org.oscarehr.fax.util.FaxConfigUtil" %>
<%@ page import="org.oscarehr.common.model.FaxConfig" %>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
    <title>SRFax Fax Outbox</title>
    <style>
        table {
            width: 100%;
            border-collapse: collapse;
        }
        table, th, td {
            border: 1px solid black;
        }
        th, td {
            padding: 8px;
            text-align: left;
        }
        th {
            background-color: #f2f2f2;
        }
        .center {
            text-align: center;
        }
        .pagination {
            text-align: center;
            margin: 20px 0;
        }
        .pagination a {
            margin: 0 5px;
            text-decoration: none;
        }
    </style>
</head>
<body>
    <h1>Fax Outbox</h1>

<%
    int currentPage = 1;
    int faxesPerPage = 10;

    if (request.getParameter("page") != null) {
        currentPage = Integer.parseInt(request.getParameter("page"));
    }

    FaxConfig activeConfig = FaxConfigUtil.getActiveFaxConfig();
    if (activeConfig == null) {
        out.println("<p>Error: No active fax configuration found. Please set up a fax configuration first.</p>");
        return;
    }
    String accessId = activeConfig.getFaxUser();
    String accessPwd = activeConfig.getFaxPasswd();
    String srFaxApiUrl = "https://www.srfax.com/SRF_SecWebSvc.php";
    String action = "Get_Fax_Outbox";

// Create the connection to SRFax API
URL url = new URL(srFaxApiUrl);
HttpURLConnection conn = (HttpURLConnection) url.openConnection();
conn.setRequestMethod("POST");
conn.setDoOutput(true);

// Prepare the POST parameters
String urlParameters = "action=" + URLEncoder.encode(action, "UTF-8") +
                       "&access_id=" + URLEncoder.encode(accessId, "UTF-8") +
                       "&access_pwd=" + URLEncoder.encode(accessPwd, "UTF-8");

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
        JSONArray allFaxes = jsonResponse.getJSONArray("Result");
        int totalFaxes = allFaxes.length();
        int totalPages = (int) Math.ceil((double) totalFaxes / faxesPerPage);

        // Calculate start and end index for the current page
        int startIndex = (currentPage - 1) * faxesPerPage;
        int endIndex = Math.min(startIndex + faxesPerPage, totalFaxes);

        out.println("<table><thead><tr><th>No.</th><th>Date Sent</th><th>Fax Number</th><th>View</th></tr></thead><tbody>");

for (int i = startIndex; i < endIndex; i++) {
    JSONObject fax = allFaxes.getJSONObject(i);
    String toFaxNumber = fax.optString("ToFaxNumber", "Unknown Fax Number");
    String dateSent = fax.optString("DateSent", "Unknown Date");
    String fileName = fax.optString("FileName", "");

%>
    <tr>
        <td class="center"><%= i + 1 %></td>
        <td><%= dateSent %></td>
        <td><%= toFaxNumber %></td>
        <td><a href="<%= request.getContextPath() %>/admin/retrieveSentFax.jsp?fileName=<%= URLEncoder.encode(fileName, "UTF-8") %>" target="_blank">View</a></td>
    </tr>
<%
}

        out.println("</tbody></table>");

        // Pagination controls
        out.println("<div class='pagination'>");
        if (currentPage > 1) {
            out.println("<a href='?page=" + (currentPage - 1) + "'>Previous</a>");
        }
        
        // Show a limited number of page links
        int startPage = Math.max(1, currentPage - 2);
        int endPage = Math.min(totalPages, currentPage + 2);
        
        if (startPage > 1) {
            out.println("<a href='?page=1'>1</a>");
            if (startPage > 2) {
                out.println("<span>...</span>");
            }
        }
        
        for (int i = startPage; i <= endPage; i++) {
            if (i == currentPage) {
                out.println("<strong>" + i + "</strong>");
            } else {
                out.println("<a href='?page=" + i + "'>" + i + "</a>");
            }
        }
        
        if (endPage < totalPages) {
            if (endPage < totalPages - 1) {
                out.println("<span>...</span>");
            }
            out.println("<a href='?page=" + totalPages + "'>" + totalPages + "</a>");
        }
        
        if (currentPage < totalPages) {
            out.println("<a href='?page=" + (currentPage + 1) + "'>Next</a>");
        }
        out.println("</div>");
    } else {
        out.println("<p>Error fetching sent faxes: " + jsonResponse.getString("Result") + "</p>");
    }
%>

</body>
</html>
</html>
