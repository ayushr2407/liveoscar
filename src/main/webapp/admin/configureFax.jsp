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


<%@ taglib uri="/WEB-INF/security.tld" prefix="security"%>
<%
    String roleName$ = (String)session.getAttribute("userrole") + "," + (String) session.getAttribute("user");
    boolean authed = true;
%>
<security:oscarSec roleName="<%=roleName$%>" objectName="_admin" rights="r" reverse="<%=true%>">
    <% authed = false; %>
    <% response.sendRedirect("../securityError.jsp?type=_admin"); %>
</security:oscarSec>
<%
if (!authed) {
    return;
}
%>

<!DOCTYPE html>
<html>
<head>
    <title>SR Fax Configuration</title>
    <script src="<%=request.getContextPath() %>/js/jquery-1.12.3.js"></script>
    <link rel="stylesheet" href="<%=request.getContextPath() %>/css/bootstrap.min.css">
<style>
    body { 
        padding: 10px; 
    }
    .container-fluid { 
        max-width: 1200px;
        margin: 0 auto;
        padding-left: 15px;
        padding-right: 15px;
    }
    .card { 
        box-shadow: 0 4px 8px rgba(0,0,0,0.1);
        margin-bottom: 20px;
    }
    .card-body {
        padding: 15px;
    }
    .form-group {
        margin-bottom: 1rem;
    }
    .form-group label {
        display: block;
        margin-bottom: 0.5rem;
    }
    .form-check {
        padding-left: 0;
    }
    .text-right {
        text-align: right;
    }
    .table { 
        margin-top: 15px; 
        font-size: 0.9em;
    }
    .table th, .table td {
        padding: 0.5rem;
    }
    .btn-sm {
        padding: 0.25rem 0.5rem;
        font-size: 0.875rem;
    }
    @media (min-width: 768px) {
        .row {
            display: flex;
            flex-wrap: wrap;
        }
        .col-md-6 {
            flex: 0 0 50%;
            max-width: 50%;
            padding-right: 15px;
            padding-left: 15px;
        }
    }
    @media (max-width: 767px) {
        .text-right {
            text-align: left !important;
        }
    }
</style>
</head>
<body>
<div class="container-fluid">
    <div class="card">
        <div class="card-body">
            <h4 class="card-title">SR Fax Configuration</h4>
            <div id="msg" class="alert" style="display: none;"></div>
            
            <form id="configFrm" method="post">
                <input type="hidden" name="method" value="configure"/>
                
                <div class="row">
                    <div class="col-md-6">
                        <div class="form-group">
                            <label for="faxUser">Account ID</label>
                            <input type="text" class="form-control" id="faxUser" name="faxUser" required/>
                        </div>
                    </div>
                    <div class="col-md-6">
                        <div class="form-group">
                            <label for="faxPasswd">Password</label>
                            <input type="password" class="form-control" id="faxPasswd" name="faxPassword" required/>
                        </div>
                    </div>
                </div>
                <div class="row">
                    <div class="col-md-6">
                        <div class="form-group">
                            <label for="faxNumber">Fax Number</label>
                            <input type="text" class="form-control" id="faxNumber" name="faxNumber" required pattern="\d{10}" title="Please enter a 10-digit fax number"/>
                        </div>
                    </div>
                    <div class="col-md-6">
                        <div class="form-group">
                            <label for="senderEmail">Email</label>
                            <input type="email" class="form-control" id="senderEmail" name="senderEmail" required/>
                        </div>
                    </div>
                </div>
                <div class="row">
                    <div class="col-md-6">
                        <div class="form-check">
                            <input type="checkbox" class="form-check-input" id="isActive" name="isActive">
                            <label class="form-check-label" for="isActive">Set as Active</label>
                        </div>
                    </div>
                    <div class="col-md-6 text-right">
                        <button type="submit" class="btn btn-primary">Save</button>
                    </div>
                </div>
            </form>
        </div>
    </div>

    <div class="card mt-4">
        <div class="card-body">
            <h4 class="card-title">Saved Configurations</h4>
            <table id="configTable" class="table table-striped">
                <thead>
                    <tr>
                        <th>Account ID</th>
                        <th>Fax Number</th>
                        <th>Email</th>
                        <th>Status</th>
                        <th>Action</th>
                    </tr>
                </thead>
                <tbody>
                    <!-- This will be populated by JavaScript -->
                </tbody>
            </table>
        </div>
    </div>
</div>
    <script>
    $(document).ready(function() {

		 $("#faxNumber").on("input", function() {
        this.value = this.value.replace(/\D/g, '').slice(0, 10);
    });
        // Load existing configurations
        loadConfigurations();

        $("#configFrm").on("submit", function(e) {
            e.preventDefault();
            var url = "<%=request.getContextPath() %>/admin/ManageFax.do?method=configure";
            var data = $(this).serialize();

            $.ajax({
                url: url,
                method: 'POST',
                data: data,
                dataType: "json",
                success: function(data) {
                    if (data.success) {
                        showMessage("Configuration saved!", "success");
                        loadConfigurations();
                        $("#configFrm")[0].reset();
                    } else {
                        showMessage("Error saving configuration: " + data.error, "danger");
                    }
                },
                error: function(jqXHR, textStatus, errorThrown) {
                    showMessage("Error communicating with the server: " + textStatus, "danger");
                }
            });
        });

        function loadConfigurations() {
    $.ajax({
        url: "<%=request.getContextPath() %>/admin/ManageFax.do?method=getAllConfigurations",
        method: 'GET',
        dataType: "json",
        success: function(data) {
            if (data.success) {
                var tbody = $('#configTable tbody');
                tbody.empty();
                // Reverse the array to show the latest configuration first
                data.configurations.reverse().forEach(function(config) {
                    var row = $('<tr>');
                    row.append($('<td>').text(config.faxUser));
                    row.append($('<td>').text(config.faxNumber));
                    row.append($('<td>').text(config.senderEmail));
                    row.append($('<td>').text(config.active ? 'Active' : 'Inactive'));
                    var actionCell = $('<td>');
                    actionCell.append($('<button>').text('Delete').addClass('btn btn-sm btn-danger').click(function() {
                        deleteConfiguration(config.id);
                    }));
                    row.append(actionCell);
                    tbody.append(row);
                });
            } else {
                showMessage("Error loading configurations: " + data.error, "danger");
            }
        },
        error: function(jqXHR, textStatus, errorThrown) {
            showMessage("Error loading configurations: " + textStatus, "danger");
        }
    });
}

        function deleteConfiguration(id) {
            if (confirm('Are you sure you want to delete this configuration?')) {
                $.ajax({
                    url: "<%=request.getContextPath() %>/admin/ManageFax.do?method=deleteConfiguration",
                    method: 'POST',
                    data: { id: id },
                    dataType: "json",
                    success: function(data) {
                        if (data.success) {
                            showMessage("Configuration deleted successfully!", "success");
                            loadConfigurations();
                        } else {
                            showMessage("Error deleting configuration: " + data.error, "danger");
                        }
                    },
                    error: function(jqXHR, textStatus, errorThrown) {
                        showMessage("Error deleting configuration: " + textStatus, "danger");
                    }
                });
            }
        }

        function showMessage(message, type) {
            $("#msg").removeClass().addClass("alert alert-" + type).text(message).show().delay(3000).fadeOut();
        }
    });
    </script>
</body>
</html>


<%-- <%@ taglib uri="/WEB-INF/security.tld" prefix="security"%>
<%
    String roleName$ = (String)session.getAttribute("userrole") + "," + (String) session.getAttribute("user");
    boolean authed = true;
%>
<security:oscarSec roleName="<%=roleName$%>" objectName="_admin" rights="r" reverse="<%=true%>">
    <% authed = false; %>
    <% response.sendRedirect("../securityError.jsp?type=_admin"); %>
</security:oscarSec>
<%
if (!authed) {
    return;
}
%>


<!DOCTYPE html>
<html>
<head>
    <title>Fax Configuration</title>
    <script src="<%=request.getContextPath() %>/js/jquery-1.12.3.js"></script>
</head>
<body>
    <h2>Fax Configuration</h2>
    <div id="msg" class="alert"></div>
    
    <form id="configFrm" method="post">
        <input type="hidden" name="method" value="configure"/>
        
        <label for="faxUser">Account ID</label>
        <input type="text" id="faxUser" name="faxUser" required/>

        <label for="faxPasswd">Password</label>
        <input type="password" id="faxPasswd" name="faxPassword" required/>

        <label for="faxNumber">Fax Number</label>
        <input type="text" id="faxNumber" name="faxNumber" required/>

        <label for="senderEmail">Email</label>
        <input type="email" id="senderEmail" name="senderEmail" required/>

        <input type="submit" value="Save"/>
    </form>

<script>
$(document).ready(function() {
    // Load existing configurations
    loadConfigurations();

    $("#configFrm").on("submit", function(e) {
        e.preventDefault();
        var url = "<%=request.getContextPath() %>/admin/ManageFax.do?method=configure";
        var data = $(this).serialize();

        $.ajax({
            url: url,
            method: 'POST',
            data: data,
            dataType: "json",
            success: function(data) {
                if (data.success) {
                    $("#msg").html("Configuration saved!");
                    $('.alert').removeClass('alert-error').addClass('alert-success');
                    loadConfigurations(); // Reload configurations after saving
                } else {
                    $("#msg").html("There was a problem saving your configuration. Check the logs for further details.");
                    $('.alert').removeClass('alert-success').addClass('alert-error');
                }
            },
            error: function(jqXHR, textStatus, errorThrown) {
                console.error("AJAX error:", textStatus, errorThrown);
                $("#msg").html("Error communicating with the server. Status: " + textStatus + ", Error: " + errorThrown);
                $('.alert').removeClass('alert-success').addClass('alert-error');
            }
        });
    });

    // Function to load configurations
    function loadConfigurations() {
        $.ajax({
            url: "<%=request.getContextPath() %>/admin/ManageFax.do?method=getAllConfigurations",
            method: 'GET',
            dataType: "json",
            success: function(data) {
                if (data.success) {
                    var tbody = $('#configTable tbody');
                    tbody.empty();
                    data.configurations.forEach(function(config) {
                        var row = $('<tr>');
                        row.append($('<td>').text(config.faxUser));
                        row.append($('<td>').text(config.faxNumber));
                        row.append($('<td>').text(config.senderEmail));
                        var deleteButton = $('<button>').text('Delete').addClass('btn btn-danger btn-sm').click(function() {
                            deleteConfiguration(config.id);
                        });
                        row.append($('<td>').append(deleteButton));
                        tbody.append(row);
                    });
                } else {
                    $("#msg").html("Error loading configurations: " + data.error);
                    $('.alert').removeClass('alert-success').addClass('alert-error');
                }
            },
            error: function(jqXHR, textStatus, errorThrown) {
                $("#msg").html("Error loading configurations. Status: " + textStatus + ", Error: " + errorThrown);
                $('.alert').removeClass('alert-success').addClass('alert-error');
            }
        });
    }

    // Function to delete a configuration
    function deleteConfiguration(id) {
        if (confirm('Are you sure you want to delete this configuration?')) {
            $.ajax({
                url: "<%=request.getContextPath() %>/admin/ManageFax.do?method=deleteConfiguration",
                method: 'POST',
                data: { id: id },
                dataType: "json",
                success: function(data) {
                    if (data.success) {
                        $("#msg").html("Configuration deleted successfully!");
                        $('.alert').removeClass('alert-error').addClass('alert-success');
                        loadConfigurations(); // Reload configurations after deleting
                    } else {
                        $("#msg").html("Error deleting configuration: " + data.error);
                        $('.alert').removeClass('alert-success').addClass('alert-error');
                    }
                },
                error: function(jqXHR, textStatus, errorThrown) {
                    $("#msg").html("Error deleting configuration. Status: " + textStatus + ", Error: " + errorThrown);
                    $('.alert').removeClass('alert-success').addClass('alert-error');
                }
            });
        }
    }
});
</script> --%>

