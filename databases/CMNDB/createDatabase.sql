-- BEGIN COPYRIGHT
-- *************************************************************************
-- 
--  Licensed Materials - Property of IBM
--  5725-C94, 5725-C95, 5725-C96
--  (C) Copyright IBM Corporation 2010, 2014. All Rights Reserved.
--  US Government Users Restricted Rights- Use, duplication or disclosure
--  restricted by GSA ADP Schedule Contract with IBM Corp.
-- 
-- *************************************************************************
-- END COPYRIGHT

-- create the database:
create database CMNDB automatic storage yes  using codeset UTF-8 territory US pagesize 32768;

-- connect to the created database:
connect to CMNDB;

-- A user temporary tablespace is required to support stored procedures in BPM.
CREATE USER TEMPORARY TABLESPACE USRTMPSPC1;

-- The following grant is used for databases without enhanced security.
-- For more information, review the Info Center for Enhancing Security for DB2.
grant dbadm on database to user bpmadmin;
UPDATE DB CFG FOR CMNDB USING LOGFILSIZ 16384 DEFERRED;
UPDATE DB CFG FOR CMNDB USING LOGSECOND 64 DEFERRED;

connect reset;
