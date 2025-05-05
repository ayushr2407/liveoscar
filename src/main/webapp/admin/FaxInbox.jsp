<%@ page import="java.net.*, java.io.*, org.json.JSONObject, org.json.JSONArray" %>
   <%@ page import="org.oscarehr.fax.util.FaxConfigUtil" %>
   <%@ page import="org.oscarehr.common.model.FaxConfig" %>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
    <title>SRFax Fax Inbox</title>
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
    </style>
</head>
<body>
    <h1>Fax Inbox</h1>
<%
    FaxConfig activeConfig = FaxConfigUtil.getActiveFaxConfig();
    if (activeConfig == null) {
        out.println("<p>Error: No active fax configuration found. Please set up a fax configuration first.</p>");
        return;
    }
    String accessId = activeConfig.getFaxUser();
    String accessPwd = activeConfig.getFaxPasswd();
    String srFaxApiUrl = "https://www.srfax.com/SRF_SecWebSvc.php";
    String action = "Get_Fax_Inbox";

    // Create the connection
    URL url = new URL(srFaxApiUrl);
    HttpURLConnection conn = (HttpURLConnection) url.openConnection();
    conn.setRequestMethod("POST");
    conn.setDoOutput(true);

    // Set parameters for the request
    String urlParameters = "action=" + URLEncoder.encode(action, "UTF-8") +
                           "&access_id=" + URLEncoder.encode(accessId, "UTF-8") +
                           "&access_pwd=" + URLEncoder.encode(accessPwd, "UTF-8") +
                           "&sResponseFormat=JSON";

    // Send POST request
    try (DataOutputStream wr = new DataOutputStream(conn.getOutputStream())) {
        wr.writeBytes(urlParameters);
        wr.flush();
    }

    // Get response from the API
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
        JSONArray faxList = jsonResponse.getJSONArray("Result");
        int faxCount = faxList.length();

        out.println("<table><thead><tr><th>No.</th><th>Date Received</th><th>Filename</th><th>View</th></tr></thead><tbody>");

        for (int i = 0; i < faxCount; i++) {
            JSONObject fax = faxList.getJSONObject(i);
            String fileName = fax.optString("FileName", "Unknown Filename");
            String dateReceived = fax.optString("DateQueued", "Unknown Date");

%>
            <tr>
                <td class="center"><%= i + 1 %></td>
                <td><%= dateReceived %></td>
                <td><%= fileName %></td>
                <td><a href="<%= request.getContextPath() %>/admin/retrieveFax.jsp?fileName=<%= URLEncoder.encode(fileName, "UTF-8") %>" target="_blank">View</a></td>
            </tr>
<%
        }
        out.println("</tbody></table>");
    } else {
        out.println("<p>Error fetching received faxes: " + jsonResponse.getString("Result") + "</p>");
    }
%>

</body>
</html>
