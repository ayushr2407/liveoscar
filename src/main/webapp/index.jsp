<%--

    Copyright (c) 2001-2002. Department of Family Medicine, McMaster University. All Rights Reserved.
    This software is published under the GPL GNU General Public License.
    This program is free software; you can redistribute it and/or
    modify it under the terms of the GNU General Public License
    as published by the Free Software Foundation; either version 2
    of the License, or (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

    This software was written for the
    Department of Family Medicine
    McMaster University
    Hamilton
    Ontario, Canada

--%>

<%@page import="org.oscarehr.common.service.AcceptableUseAgreementManager"%>
<%@page import="oscar.OscarProperties, javax.servlet.http.Cookie, oscar.oscarSecurity.CookieSecurity, oscar.login.UAgentInfo" %>
<%@ page import="java.net.URLEncoder"%>
<%@ taglib uri="/WEB-INF/struts-bean.tld" prefix="bean" %>
<%@ taglib uri="/WEB-INF/struts-html.tld" prefix="html" %>
<%@ taglib uri="/WEB-INF/struts-logic.tld" prefix="logic" %>
<%@ taglib uri="/WEB-INF/caisi-tag.tld" prefix="caisi" %>
<caisi:isModuleLoad moduleName="ticklerplus"><%
    if (session.getValue("user") != null) {
        response.sendRedirect("provider/providercontrol.jsp");
    }
%></caisi:isModuleLoad><%
OscarProperties props = OscarProperties.getInstance();

// Clear old cookies
Cookie prvCookie = new Cookie(CookieSecurity.providerCookie, "");
prvCookie.setPath("/");
response.addCookie(prvCookie);

String econsultUrl = props.getProperty("backendEconsultUrl");

// Initialize browser info variables
String userAgent = request.getHeader("User-Agent");
String httpAccept = request.getHeader("Accept");
UAgentInfo detector = new UAgentInfo(userAgent, httpAccept);

if (request.getParameter("full") != null) {
    session.setAttribute("fullSite","true");
}

if (detector.detectSmartphone() && detector.detectWebkit()  && session.getAttribute("fullSite") == null) {
    session.setAttribute("mobileOptimized", "true");
} else {
    session.removeAttribute("mobileOptimized");
}
Boolean isMobileOptimized = session.getAttribute("mobileOptimized") != null;

String hostPath = request.getScheme() + "://" + request.getHeader("Host") +  ":" + request.getLocalPort();
String loginUrl = hostPath + request.getContextPath();

StringBuffer oscarUrl = request.getRequestURL();
int urlLength = oscarUrl.length() - request.getServletPath().length();
oscarUrl.setLength(urlLength);

boolean oneIdEnabled = "true".equalsIgnoreCase(OscarProperties.getInstance().getProperty("oneid.enabled","false"));
boolean oauth2Enabled= "true".equalsIgnoreCase(OscarProperties.getInstance().getProperty("oneid.oauth2.enabled","false")); 

String ssoLoginMessage = "";
if (request.getParameter("email") != null) {
    ssoLoginMessage = "Hello " + request.getParameter("email") + "<br>Please login with your OSCAR credentials to link your accounts.";
}
else if (request.getParameter("errorMessage") != null) {
    ssoLoginMessage = request.getParameter("errorMessage");
}
%>

<html:html locale="true">
<head>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <%-- <link rel="shortcut icon" href="images/Oscar.ico" /> --%>
    <link rel="icon" type="image/png" href="/clinic_data/logo/logo2.png" />
    <link href="https://stackpath.bootstrapcdn.com/bootstrap/4.3.1/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/5.15.3/css/all.min.css" rel="stylesheet">
    <html:base/>
    <title><%= props.getProperty("logintitle", "") != "" ? props.getProperty("logintitle", "") : "OSCAR Login" %></title>
    <%-- <title>OAT Clinic</title> --%>

    <style>
    body, html {
            margin: 0;
            padding: 0;
            height: 100%;
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background-color: #c8f0f5;  /* Changed to black */
        }
        .form-action {
    display: flex;
    flex-direction: column;
    align-items: center;
    width: 100%;
}

.support-link {
    margin-top: 10px;
    font-size: 14px;
    text-align: center;
    color: black;
}

.support-link-text {
    color: black;
    text-decoration: none;
}

.support-link-text:hover {
    text-decoration: underline;
}


        .background {
            height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
        }

        .login-container {
        background: white;
        border-radius: 20px;
        box-shadow: 0 10px 30px rgba(0, 0, 0, 0.1);
        overflow: hidden;
        width: 80%;
        max-width: 1000px;
        display: flex;
    }

    .left-container {
        flex: 1;
        padding: 40px;
        display: flex;
        flex-direction: column;
        align-items: flex-start;
        justify-content: flex-start;
    }

    .logo {
        width: 150px;
        margin-bottom: 20px;
        margin-left: 10%;  /* Align with form fields */
    }

    h2 {
        color: #333;
        font-size: 24px;
        margin-bottom: 30px;
        font-weight: 300;
        margin-left: 10%;  /* Align with form fields */
    }

    form {
        width: 80%;
        max-width: 400px;
        margin: 0 auto;
    }


        .right-container {
            flex: 1;
    background: url('images/Background_login.jpg') center/cover no-repeat;
            position: relative;
        }

        .right-container::before {
            content: '';
            position: absolute;
            top: 0;
            left: 0;
            right: 0;
            bottom: 0;
            background: linear-gradient(135deg, rgba(0, 174, 239, 0.7), rgba(0, 174, 239, 0.8));
        }

        .logo {
            width: 150px;
            margin-bottom: 20px;
        }

    

        .form-group {
            margin-bottom: 20px;
            position: relative;
            width: 100%;
            margin-bottom: 25px;
        }

        .form-group input {
            width: 100%;
            padding: 12px 15px 12px 40px;
            border: 1px solid #e0e0e0;
            border-radius: 5px;
            font-size: 16px;
            transition: all 0.3s ease;
        }

        .form-group input:focus {
            border-color: #00AEEF;
            box-shadow: 0 0 0 2px rgba(0, 174, 239, 0.2);
        }

        .form-group i {
            position: absolute;
            left: 15px;
            top: 50%;
            transform: translateY(-50%);
            color: #7f8c8d;
        }

        .btn-primary {
            width: 100%;
            padding: 12px;
            background-color: #00AEEF;
            color: white;
            border: none;
            border-radius: 5px;
            font-size: 18px;
            cursor: pointer;
            transition: background-color 0.3s ease;
        }

        .btn-primary:hover {
            background-color: #0089BC;
        }
        .error-message {
    color: red;
    font-size: 12px;
    position: absolute;
    display: none;
}
    </style>
</head>
<body onload="setfocus();checkMe();">
    <div class="background">
        <div class="login-container">
            <div class="left-container">
            <img class="logo" src="/clinic_data/logo/login-logo.png" alt="Clinic Logo">
                  <%-- <img class="logo" src="images/OSCAR-LOGO.gif" alt="OAT Clinic Logo"> --%>
                <h2>Login to continue</h2>
                <div><%=ssoLoginMessage%></div>
                <html:form action="login" style="width: 100%;" onsubmit="return validateForm(event);">
    <div class="form-group">
        <i class="fas fa-user"></i>
        <input type="text" id="username" name="username" autocomplete="off" placeholder="Username">
        <span class="error-message" id="username-error">Username is required</span>
    </div>
    <div class="form-group">
        
        <i class="fas fa-lock"></i>
        <input type="password" id="password2" name="password" placeholder="Password">
        <%-- <i class="fas fa-eye icon-eye-open" onclick="showPwd('password2');"></i> --%>
        <span class="error-message" id="password-error">Password is required</span>
    </div>
    <div class="form-group">
        <i class="fas fa-key"></i>
        <input type="text" id="pin2" name="pin2" autocomplete="off" placeholder="PIN" onkeyup="maskMe();" onchange="checkMe();">
        <%-- <i class="fas fa-eye icon-eye-open" onclick="toggleMask();"></i> --%>
        <span class="error-message" id="pin-error">PIN is required</span>
    </div>
    <input type="hidden" id="pin" name="pin" value="">
    <% if(oneIdEnabled && !oauth2Enabled) { %>
        <a href="<%=econsultUrl %>/SAML2/login?oscarReturnURL=<%=URLEncoder.encode(oscarUrl.toString() + "/ssoLogin.do", "UTF-8") + "?loginStart="%>" id="oneIdLogin" class="oneIDLogin" onclick="addStartTime()">ONE ID Login</a>
    <% } %>
    <% if(oneIdEnabled && oauth2Enabled) { %>
        <a href="<%=request.getContextPath() %>/eho/login2.jsp" id="oneIdLoginOauth" class="oneIDLogin">ONE ID Login</a>
    <% } %>
   <div class="form-action">
    <button type="submit" name="submit" class="btn-primary">Login</button>
    <div class="support-link">
        Having trouble logging in? 
        <a href="mailto:support@medidoze.com" class="support-link-text">
        support@bimble.pro
            <%-- Contact Support --%>
        </a>
    </div>
</div>
</html:form>
            </div>
            <div class="right-container">
                <!-- Background image container -->
            </div>
        </div>
    </div>

    <div class="container" style="border-radius: 25px; margin-top: 25px; padding: 14px;">
        <div id="auaText" class="span3" style="display:none;">
            <h3><bean:message key="provider.login.title.confidentiality"/></h3>
            <p><%=AcceptableUseAgreementManager.getAUAText()%></p> 
        </div>
        <div id="liscence" class="span3" style="display:none;">
            <p><bean:message key="loginApplication.leftRmk2"/></p>
        </div>
        <span class="span4 offset4 text-right">
            <small>
                <bean:message key="loginApplication.gplLink"/> <a href="javascript:void(0);" onclick="showHideItem('liscence');"><bean:message key="global.showhide"/></a><br>
                <% if (AcceptableUseAgreementManager.hasAUA()){ %>
                    <bean:message key="global.aua"/> &nbsp; <a href="javascript:void(0);" onclick="showHideItem('auaText');"><bean:message key="global.showhide"/></a><br>
                <% } %>
                OSCAR <%=OscarProperties.getBuildTag()%>:<%= OscarProperties.getBuildDate() %>
            </small>&nbsp;&nbsp;
        </span>
    </div>

    <script>

function validateForm(event) {
        // Fetch input values
        const username = document.getElementById('username').value.trim();
        const password = document.getElementById('password2').value.trim();
        const pin = document.getElementById('pin2').value.trim();

        // Error flags
        let isValid = true;

        // Validate Username
        if (username === "") {
            document.getElementById('username-error').style.display = "block";
            isValid = false;
        } else {
            document.getElementById('username-error').style.display = "none";
        }

        // Validate Password
        if (password === "") {
            document.getElementById('password-error').style.display = "block";
            isValid = false;
        } else {
            document.getElementById('password-error').style.display = "none";
        }

        // Validate PIN
        if (pin === "") {
            document.getElementById('pin-error').style.display = "block";
            isValid = false;
        } else {
            document.getElementById('pin-error').style.display = "none";
        }

        // If all fields are valid
        if (!isValid) {
            event.preventDefault();  // Prevent form submission if there are errors
        }

        return isValid; // Return the validation result
    }

    function showPwd(id) {
        var field = document.getElementById(id);
        if (field.type === 'password') {
            field.type = 'text';
        } else {
            field.type = 'password';
        }
    }

    var mask = true;
    function maskMe() {
        if (!mask) {
            document.getElementById('pin').value = document.getElementById('pin2').value;
            return;
        }
        var key = event.keyCode || event.charCode;
        if (key == 8) {
            let str = document.getElementById('pin').value;
            str = str.substring(0, str.length - 1);
            document.getElementById('pin').value = str;
        } else {
            document.getElementById('pin').value += document.getElementById('pin2').value.slice(-1);
            document.getElementById('pin2').value = document.getElementById('pin2').value.replace(/./g, "*");
        }
    }

    function toggleMask() {
        if (document.getElementById('pin2').value.slice(0, 1) != "*") {
            document.getElementById('pin2').value = document.getElementById('pin').value.replace(/./g, "*");
            mask = true;
        } else {
            document.getElementById('pin2').value = document.getElementById('pin').value;
            mask = false;
        }
    }

    function setfocus() {
        document.getElementById('username').focus();
    }

    function checkMe() {
        if (document.getElementById('pin2').value == "") {
            document.getElementById('pin').value = "";
        }
    }

    function showHideItem(id) {
        var item = document.getElementById(id);
        if (item.style.display === 'none') {
            item.style.display = 'block';
        } else {
            item.style.display = 'none';
        }
    }

    function addStartTime() {
        document.getElementById("oneIdLogin").href += (Math.round(new Date().getTime() / 1000).toString());
    }
    </script>
</body>
</html:html>
