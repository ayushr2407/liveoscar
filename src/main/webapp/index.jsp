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
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet" />
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;600&display=swap" rel="stylesheet" />
    <html:base/>
    <title><%= props.getProperty("logintitle", "") != "" ? props.getProperty("logintitle", "") : "OSCAR Login" %></title>
    <%-- <title>OAT Clinic</title> --%>

    <style>
    body, html {
      height: 100%;
      margin: 0;
      font-family: 'Inter', sans-serif;
      background-color: #e0f4f8;
    }
 
    .login-container {
      display: flex;
      height: 100vh;
    }
 
    .form-section {
      flex: 1;
      background-color: #f9fafb;
      display: flex;
      justify-content: center;
      align-items: center;
      padding: 2rem;
    }
 
    .form-box {
      width: 100%;
      max-width: 360px;
    }
 
    .form-box h3 {
      margin-bottom: 1rem;
      font-weight: 600;
    }
 
    .form-control {
      border-radius: 8px;
      height: 45px;
    }
 
    .form-group {
      position: relative;
      margin-bottom: 1.2rem;
    }
 
    .form-group i {
      position: absolute;
      top: 13px;
      left: 15px;
      color: #888;
    }
 
    .form-group input {
      padding-left: 40px;
    }
 
    .btn-gradient {
  background: linear-gradient(90deg, #4facfe, #00f2fe, #4facfe);
  background-size: 400% 400%;
  border: none;
  border-radius: 8px;
  height: 45px;
  color: white;
  font-weight: 500;
  transition: 0.3s;
  animation: gradientFlow 8s ease infinite;
}
 
@keyframes gradientFlow {
  0% {
    background-position: 0% 50%;
  }
  50% {
    background-position: 100% 50%;
  }
  100% {
    background-position: 0% 50%;
  }
}
 
    .btn-gradient:hover {
      opacity: 0.9;
    }
 
    .error-message {
      color: #e63946;
      font-size: 0.85rem;
      padding-top: 5px;
      display: none;
    }
 
    .support-link {
      margin-top: 1rem;
      font-size: 0.9rem;
      text-align: center;
    }
 
    .right-section {
      flex: 1;
      background: url('https://images.unsplash.com/photo-1666214280391-8ff5bd3c0bf0') center center/cover no-repeat;
      position: relative;
    }
 
    .quote {
      position: absolute;
      bottom: 20px;
      right: 20px;
      color: white;
      font-size: 0.9rem;
      font-style: italic;
      text-shadow: 0 1px 3px rgba(0,0,0,0.6);
      text-align: right;
    }
 
    @media (max-width: 768px) {
      .right-section {
        display: none;
      }
    }
  </style>


</head>
<body onload="setfocus();checkMe();">
 
<div class="login-container">
  <!-- Left Form Section -->
  <div class="form-section">
    <div class="form-box">
      <img class="mb-4" src="/clinic_data/logo/login-logo.png" alt="Clinic Logo" style="max-width: 180px;">
      <h3>Login to continue</h3>
      <div><%=ssoLoginMessage%></div>
 
      <html:form action="login" style="width: 100%;" onsubmit="return validateForm(event);">
 
        <!-- Username -->
        <div class="form-group">
          <i class="fas fa-user"></i>
          <input type="text" id="username" name="username" class="form-control" autocomplete="off" placeholder="Username" />
          <span class="error-message" id="username-error">Username is required</span>
          <c:if test="${not empty usernameError}">
            <span class="error-message" id="username-error" style="display: block;">${usernameError}</span>
          </c:if>
        </div>
 
        <!-- Password -->
        <div class="form-group">
          <i class="fas fa-lock"></i>
          <input type="password" id="password2" name="password" class="form-control" placeholder="Password" />
          <span class="error-message" id="password-error">Password is required</span>
          <c:if test="${not empty passwordError}">
            <span class="error-message" id="password-error" style="display: block;">${passwordError}</span>
          </c:if>
        </div>
 
        <!-- PIN -->
        <div class="form-group">
          <i class="fas fa-key"></i>
          <input type="tel" id="pin2" name="pin2" class="form-control" autocomplete="off" placeholder="PIN" inputmode="numeric" oninput="maskMe(event);" onchange="checkMe();" />
          <span class="error-message" id="pin-error">PIN is required</span>
          <c:if test="${not empty pinError}">
            <span class="error-message" id="pin-error" style="display: block;">${pinError}</span>
          </c:if>
        </div>
 
        <input type="hidden" id="pin" name="pin" value="">
 
        <% if(oneIdEnabled && !oauth2Enabled) { %>
        <a href="<%=econsultUrl %>/SAML2/login?oscarReturnURL=<%=URLEncoder.encode(oscarUrl.toString() + "/ssoLogin.do", "UTF-8") + "?loginStart="%>" id="oneIdLogin" class="btn btn-outline-secondary w-100 mb-3">ONE ID Login</a>
        <% } %>
 
        <% if(oneIdEnabled && oauth2Enabled) { %>
        <a href="<%=request.getContextPath() %>/eho/login2.jsp" id="oneIdLoginOauth" class="btn btn-outline-secondary w-100 mb-3">ONE ID Login</a>
        <% } %>
 
        <button type="submit" name="submit" class="btn btn-gradient w-100 mb-3">Login</button>
 
        <div class="support-link">
          Having trouble logging in? 
          <a href="mailto:support@medidoze.com">Contact Support</a>
        </div>
      </html:form>
    </div>
  </div>
 
  <!-- Right Image Section -->
  <div class="right-section">
    <div class="quote">
      "Start your shift with purpose. Power up patient care."
    </div>
  </div>
</div>

<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
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

// original
    // var mask = true;
    // function maskMe() {
    //     if (!mask) {
    //         document.getElementById('pin').value = document.getElementById('pin2').value;
    //         return;
    //     }
    //     var key = event.keyCode || event.charCode;
    //     if (key == 8) {
    //         let str = document.getElementById('pin').value;
    //         str = str.substring(0, str.length - 1);
    //         document.getElementById('pin').value = str;
    //     } else {
    //         document.getElementById('pin').value += document.getElementById('pin2').value.slice(-1);
    //         document.getElementById('pin2').value = document.getElementById('pin2').value.replace(/./g, "*");
    //     }
    // }


//     var mask = true;

// function maskMe(event) {
//     var pinInput = document.getElementById('pin'); // Hidden input field (sent in form)
//     var pinMaskedInput = document.getElementById('pin2'); // Visible masked input
    
//     if (!mask) {
//         pinInput.value = pinMaskedInput.value; // Directly copy if masking is off
//         return;
//     }

//     // Ensure that the hidden pin always contains the full value
//     pinInput.value = pinMaskedInput.value.replace(/\D/g, ""); // Remove non-numeric values

//     // Handle backspace separately
//     if (event.inputType === "deleteContentBackward") {
//         pinInput.value = pinInput.value.slice(0, -1);
//     }

//     // Use a small delay to ensure full input is captured before masking
//     setTimeout(() => {
//         pinMaskedInput.value = "*".repeat(pinInput.value.length);
//     }, 50);
// }

// var mask = true;

// function maskMe(event) {
//     var pinInput = document.getElementById('pin'); // Hidden input field (sent in form)
//     var pinMaskedInput = document.getElementById('pin2'); // Visible masked input

//     if (!mask) {
//         pinInput.value = pinMaskedInput.value; // Directly copy if masking is off
//         return;
//     }

//     // Handle backspace separately
//     if (event.inputType === "deleteContentBackward") {
//         pinInput.value = pinInput.value.slice(0, -1);
//     } else {
//         pinInput.value += event.data; // Append the new character to `pin`
//     }

//     // Instantly mask the visible input to prevent interruptions
//     pinMaskedInput.value = "*".repeat(pinInput.value.length);
// }


var mask = true;

function maskMe(event) {
    var pinInput = document.getElementById('pin'); // Hidden field (stores actual PIN)
    var pinMaskedInput = document.getElementById('pin2'); // Visible masked input

    // If mask is off, allow normal input
    if (!mask) {
        pinInput.value = pinMaskedInput.value;
        return;
    }

    // Ensure valid event data (handles undefined cases)
    let newChar = event.data || ""; // Prevents "null" issue on deletion

    // Handle backspace correctly
    if (event.inputType === "deleteContentBackward") {
        pinInput.value = pinInput.value.slice(0, -1); // Remove last digit
    } else if (newChar.match(/[0-9]/)) { // Ensure only numbers are added
        pinInput.value += newChar;
    }

    // Mask input with asterisks
    setTimeout(() => {
        pinMaskedInput.value = "*".repeat(pinInput.value.length);
    }, 0);
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
