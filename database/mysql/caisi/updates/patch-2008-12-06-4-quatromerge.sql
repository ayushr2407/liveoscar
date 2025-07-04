LOCK TABLES `property` WRITE;
INSERT INTO `property` VALUES('ENABLE_ACCOUNT_LOCKING', 'yes', 1, '262074', '2008-10-07 11:28:21');
INSERT INTO `property` VALUES('USER_LOCK_MAX_DURATION', '15', 2, '1111', '2008-07-30 01:01:01');
INSERT INTO `property` VALUES('LOGIN_MAX_FAILED_TIMES', '3', 3, '262117', '2008-10-07 11:35:32');
INSERT INTO `property` VALUES('PROGRAM_OCCUPANCY_STARTTIME', '21:03', 4, '262104', '2008-09-09 14:49:55');
INSERT INTO `property` VALUES('PROGRAM_OCCUPANCY_PREVIOUSDAY', 'no', 5, '1111', '2008-08-20 19:28:57');
INSERT INTO `property` VALUES('AUTO_DISCHARGE_REASON_CODE', '50', 6, '262078', '2008-09-16 22:08:43');
UNLOCK TABLES;

delete from secObjectName where objectName = '_admin';
delete from secObjectName where objectName = '_admin.systemMessage';
delete from secObjectName where objectName = '_admin.lookup';
delete from secObjectName where objectName = '_admin.mergeClient';
delete from secObjectName where objectName = '_admin.org';
delete from secObjectName where objectName = '_admin.role';
delete from secObjectName where objectName = '_admin.unlockUser';
delete from secObjectName where objectName = '_client';
delete from secObjectName where objectName = '_clientAdmission';
delete from secObjectName where objectName = '_clientCase';
delete from secObjectName where objectName = '_clientComplaint';
delete from secObjectName where objectName = '_clientConsent';
delete from secObjectName where objectName = '_clientDischarge';
delete from secObjectName where objectName = '_clientDocument';
delete from secObjectName where objectName = '_clientHealthSafety';
delete from secObjectName where objectName = '_clientHistory';
delete from secObjectName where objectName = '_clientIntake';
delete from secObjectName where objectName = '_clientPrintLabel';
delete from secObjectName where objectName = '_clientRefer';
delete from secObjectName where objectName = '_clientRestriction';
delete from secObjectName where objectName = '_clientTasks';
delete from secObjectName where objectName = '_facility';
delete from secObjectName where objectName = '_facility.bed';
delete from secObjectName where objectName = '_facility.edit';
delete from secObjectName where objectName = '_facility.message';
delete from secObjectName where objectName = '_facility.program';
delete from secObjectName where objectName = '_program';
delete from secObjectName where objectName = '_program.clients';
delete from secObjectName where objectName = '_program.incident';
delete from secObjectName where objectName = '_program.queue';
delete from secObjectName where objectName = '_program.queueReject';
delete from secObjectName where objectName = '_program.serviceRestrictions';
delete from secObjectName where objectName = '_program.staff';
delete from secObjectName where objectName = '_programEdit';
delete from secObjectName where objectName = '_programEdit.serviceRestrictions';
delete from secObjectName where objectName = '_reports';

LOCK TABLES `secObjectName` WRITE;
INSERT INTO `secObjectName` VALUES('_admin', 'Administration', 0, 'Administration on Menu and Home Page');
INSERT INTO `secObjectName` VALUES('_admin.systemMessage', 'Admin - System Message', 0, 'Administration System Message');
INSERT INTO `secObjectName` VALUES('_admin.lookup', 'Admin - Lookup Tables', 0, 'Administration Lookup Tables Maintenance');
INSERT INTO `secObjectName` VALUES('_admin.mergeClient', 'Admin - Merge Client', 0, 'Administration Merge Client');
INSERT INTO `secObjectName` VALUES('_admin.org', 'Admin - Org Chart', 0, 'Administration SMIS Org Chart');
INSERT INTO `secObjectName` VALUES('_admin.role', 'Admin - Role Management', 0, 'Administration Role Management');
INSERT INTO `secObjectName` VALUES('_admin.unlockUser', 'Admin - Unlock User', 0, 'Administration Unlock User');
INSERT INTO `secObjectName` VALUES('_admin.user', 'Admin - User Management', 0, 'Administration User Management');
INSERT INTO `secObjectName` VALUES('_client', 'Client  Management', 0, 'Client on Menu and Icon on Home page');
INSERT INTO `secObjectName` VALUES('_clientAdmission', 'Client - Admission', 1, 'Client - Admission');
INSERT INTO `secObjectName` VALUES('_clientCase', 'Client - Case', 1, 'Client - Case tab');
INSERT INTO `secObjectName` VALUES('_clientComplaint', 'Client - Complaint', 1, 'Client - Complaint tab');
INSERT INTO `secObjectName` VALUES('_clientConsent', 'Client - Consent', 1, 'Client - Consent tab');
INSERT INTO `secObjectName` VALUES('_clientDischarge', 'Client - Discharge', 1, 'Client - Discharge tab');
INSERT INTO `secObjectName` VALUES('_clientDocument', 'Client - Document Attachment', 1, 'Client - Document tab');
INSERT INTO `secObjectName` VALUES('_clientHealthSafety', 'Client - Health and Safety', 0, 'Client - Health Safety Edit Button');
INSERT INTO `secObjectName` VALUES('_clientHistory', 'Client - History', 1, 'Client - History tab');
INSERT INTO `secObjectName` VALUES('_clientIntake', 'Client - Intake', 1, 'Client - Intake tab');
INSERT INTO `secObjectName` VALUES('_clientPrintLabel', 'Client - Print Label', 1, 'Client - Print Label tab');
INSERT INTO `secObjectName` VALUES('_clientRefer', 'Client - Refer', 1, 'Client - Referral tab');
INSERT INTO `secObjectName` VALUES('_clientRestriction', 'Client - Restriction', 1, 'Client - Service Restriction tab');
INSERT INTO `secObjectName` VALUES('_clientTasks', 'Client - Tasks', 1, 'Client - Task tab');
INSERT INTO `secObjectName` VALUES('_facility', 'Facility Management', 0, 'Facility First Page');
INSERT INTO `secObjectName` VALUES('_facility.bed', 'Facility - Manage Bed', 0, 'Facility Bed tab');
INSERT INTO `secObjectName` VALUES('_facility.edit', 'Facility - Edit Facility', 0, NULL);
INSERT INTO `secObjectName` VALUES('_facility.message', 'Facility - Message', 0, 'Facility Message tab');
INSERT INTO `secObjectName` VALUES('_facility.program', 'Facility - Program', 0, 'Facility Program tab');
INSERT INTO `secObjectName` VALUES('_program', 'Program Management', 0, NULL);
INSERT INTO `secObjectName` VALUES('_program.clients', 'Program - Clients', 0, 'Program - Client tab');
INSERT INTO `secObjectName` VALUES('_program.incident', 'Program - Incident', 0, 'Program - Incident tab');
INSERT INTO `secObjectName` VALUES('_program.queue', 'Program - Queue', 0, 'Program - Queue tab');
INSERT INTO `secObjectName` VALUES('_program.queueReject', 'Program - Queue - Reject', 0, 'Program - Queue - Reject');
INSERT INTO `secObjectName` VALUES('_program.serviceRestrictions', 'Program - Service Restriction List', 0, 'Program - Service Restriction');
INSERT INTO `secObjectName` VALUES('_program.staff', 'Program - Staff List', 0, NULL);
INSERT INTO `secObjectName` VALUES('_programEdit', 'Program - Edit', 0, 'Program - General tab');
INSERT INTO `secObjectName` VALUES('_programEdit.serviceRestrictions', 'Program - Service Restriction', 0, 'Program - service restriction tab');
INSERT INTO `secObjectName` VALUES('_reports', 'Reports ', 0, NULL);
UNLOCK TABLES;


LOCK TABLES `secObjPrivilege` WRITE;
INSERT INTO `secObjPrivilege` VALUES('smisadmin', '_admin', 'w', 0, '999998');
INSERT INTO `secObjPrivilege` VALUES('smisadmin', '_admin.lookup', 'w', 0, '999998');
INSERT INTO `secObjPrivilege` VALUES('smisadmin', '_admin.mergeClient', 'w', 0, '999998');
INSERT INTO `secObjPrivilege` VALUES('smisadmin', '_admin.org', 'w', 0, '999998');
INSERT INTO `secObjPrivilege` VALUES('smisadmin', '_admin.role', 'w', 0, '999998');
INSERT INTO `secObjPrivilege` VALUES('smisadmin', '_admin.systemMessage', 'w', 0, '999998');
INSERT INTO `secObjPrivilege` VALUES('smisadmin', '_admin.unlockUser', 'w', 0, '999998');
INSERT INTO `secObjPrivilege` VALUES('smisadmin', '_admin.user', 'w', 0, '999998');
INSERT INTO `secObjPrivilege` VALUES('smisadmin', '_client', 'x', 0, '999998');
INSERT INTO `secObjPrivilege` VALUES('smisadmin', '_clientAdmission', 'x', 0, '999998');
INSERT INTO `secObjPrivilege` VALUES('smisadmin', '_clientCase', 'w', 0, '999998');
INSERT INTO `secObjPrivilege` VALUES('smisadmin', '_clientComplaint', 'w', 0, '999998');
INSERT INTO `secObjPrivilege` VALUES('smisadmin', '_clientConsent', 'w', 0, '999998');
INSERT INTO `secObjPrivilege` VALUES('smisadmin', '_clientDischarge', 'w', 0, '999998');
INSERT INTO `secObjPrivilege` VALUES('smisadmin', '_clientDocument', 'w', 0, '999998');
INSERT INTO `secObjPrivilege` VALUES('smisadmin', '_clientHealthSafety', 'w', 0, '999998');
INSERT INTO `secObjPrivilege` VALUES('smisadmin', '_clientHistory', 'w', 0, '999998');
INSERT INTO `secObjPrivilege` VALUES('smisadmin', '_clientIntake', 'w', 0, '999998');
INSERT INTO `secObjPrivilege` VALUES('smisadmin', '_clientPrintLabel', 'w', 0, '999998');
INSERT INTO `secObjPrivilege` VALUES('smisadmin', '_clientRefer', 'w', 0, '999998');
INSERT INTO `secObjPrivilege` VALUES('smisadmin', '_clientRestriction', 'w', 0, '999998');
INSERT INTO `secObjPrivilege` VALUES('smisadmin', '_clientTasks', 'w', 0, '999998');
INSERT INTO `secObjPrivilege` VALUES('smisadmin', '_facility', 'w', 0, '999998');
INSERT INTO `secObjPrivilege` VALUES('smisadmin', '_facility.bed', 'w', 0, '999998');
INSERT INTO `secObjPrivilege` VALUES('smisadmin', '_facility.edit', 'w', 0, '999998');
INSERT INTO `secObjPrivilege` VALUES('smisadmin', '_facility.message', 'w', 0, '999998');
INSERT INTO `secObjPrivilege` VALUES('smisadmin', '_facility.program', 'w', 0, '999998');
INSERT INTO `secObjPrivilege` VALUES('smisadmin', '_program', 'w', 0, '999998');
INSERT INTO `secObjPrivilege` VALUES('smisadmin', '_program.clients', 'w', 0, '999998');
INSERT INTO `secObjPrivilege` VALUES('smisadmin', '_program.incident', 'w', 0, '999998');
INSERT INTO `secObjPrivilege` VALUES('smisadmin', '_program.queue', 'w', 0, '999998');
INSERT INTO `secObjPrivilege` VALUES('smisadmin', '_program.queueReject', 'w', 0, '999998');
INSERT INTO `secObjPrivilege` VALUES('smisadmin', '_program.serviceRestrictions', 'w', 0, '999998');
INSERT INTO `secObjPrivilege` VALUES('smisadmin', '_program.staff', 'w', 0, '999998');
INSERT INTO `secObjPrivilege` VALUES('smisadmin', '_programEdit', 'w', 0, '999998');
INSERT INTO `secObjPrivilege` VALUES('smisadmin', '_programEdit.serviceRestrictions', 'w', 0, '999998');
INSERT INTO `secObjPrivilege` VALUES('smisadmin', '_reports', 'x', 0, '999998');
UNLOCK TABLES;

LOCK TABLES `secRole` WRITE;
INSERT INTO `secRole` VALUES(null,'smisadmin', 'QuatroShelter System Administrator', 1, 0.000000000000000e+000, NULL, NULL);
UNLOCK TABLES;

LOCK TABLES `secUserRole` WRITE;
INSERT INTO `secUserRole` VALUES(null,'999998', 'smisadmin', 'R1', 1, NULL, NULL);
UNLOCK TABLES;

SET FOREIGN_KEY_CHECKS = 0;
SET FOREIGN_KEY_CHECKS = 1;
