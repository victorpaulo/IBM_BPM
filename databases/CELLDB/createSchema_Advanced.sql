-- BEGIN COPYRIGHT
-- *************************************************************************
--
--  Licensed Materials - Property of IBM
--  5725-C94, 5725-C95, 5725-C96
--  (C) Copyright IBM Corporation 2004, 2014. All Rights Reserved.
--  US Government Users Restricted Rights- Use, duplication or disclosure
--  restricted by GSA ADP Schedule Contract with IBM Corp.
--
-- *************************************************************************
-- END COPYRIGHT

------------------------------------------------------------------------
-- The code assumes an implicit schema, i.e. the tables
-- and views have to be created in a collection that has
-- the name of the user connected to use the product.
-- You may want to create the collection using:
--     db2 create collection <username>
-- before applying this script
------------------------------------------------------------------------
-- 1. Process this script in the DB2 command line processor
-- Example:
--            db2 connect to <dbname> user <user name> using <user password>
--            db2 -tf createTable_AppScheduler.sql

-- create the schema

CREATE TABLE bpmadmin.WSCH_TASK
(
  TASKID             BIGINT                NOT NULL ,
  VERSION            VARCHAR(5)            NOT NULL ,
  ROW_VERSION        INTEGER               NOT NULL ,
  TASKTYPE           INTEGER               NOT NULL ,
  TASKSUSPENDED      SMALLINT              NOT NULL ,
  CANCELLED          SMALLINT              NOT NULL ,
  NEXTFIRETIME       BIGINT                NOT NULL ,
  STARTBYINTERVAL    VARCHAR(254)                   ,
  STARTBYTIME        BIGINT                         ,
  VALIDFROMTIME      BIGINT                         ,
  VALIDTOTIME        BIGINT                         ,
  REPEATINTERVAL     VARCHAR(254)                   ,
  MAXREPEATS         INTEGER               NOT NULL ,
  REPEATSLEFT        INTEGER               NOT NULL ,
  TASKINFO           BLOB(102400) LOGGED NOT COMPACT ,
  NAME               VARCHAR(254)          NOT NULL ,
  AUTOPURGE          INTEGER               NOT NULL ,
  FAILUREACTION      INTEGER                        ,
  MAXATTEMPTS        INTEGER                        ,
  QOS                INTEGER                        ,
  PARTITIONID        INTEGER                        ,
  OWNERTOKEN         VARCHAR(200)          NOT NULL ,
  CREATETIME         BIGINT                NOT NULL
) ;

ALTER TABLE bpmadmin.WSCH_TASK ADD PRIMARY KEY (TASKID);

CREATE INDEX bpmadmin.WSCH_TASK_IDX1 ON bpmadmin.WSCH_TASK
(
  TASKID, OWNERTOKEN
) ;

CREATE INDEX bpmadmin.WSCH_TASK_IDX2 ON bpmadmin.WSCH_TASK
(
  NEXTFIRETIME ASC ,
  REPEATSLEFT ,
  PARTITIONID
) CLUSTER;

CREATE TABLE bpmadmin.WSCH_TREG
(
  REGKEY             VARCHAR(254)          NOT NULL ,
  REGVALUE           VARCHAR(254)
) ;

ALTER TABLE bpmadmin.WSCH_TREG ADD PRIMARY KEY (REGKEY);

CREATE TABLE bpmadmin.WSCH_LMGR
(
  LEASENAME          VARCHAR(254)          NOT NULL ,
  LEASEOWNER         VARCHAR(254)          NOT NULL ,
  LEASE_EXPIRE_TIME  BIGINT                         ,
  DISABLED           VARCHAR(5)
) ;

ALTER TABLE bpmadmin.WSCH_LMGR ADD PRIMARY KEY (LEASENAME);

CREATE TABLE bpmadmin.WSCH_LMPR
(
  LEASENAME          VARCHAR(254)          NOT NULL ,
  NAME               VARCHAR(254)          NOT NULL ,
  VALUE              VARCHAR(254)          NOT NULL
) ;

CREATE INDEX bpmadmin.WSCH_LMPR_IDX1 ON bpmadmin.WSCH_LMPR
(
  LEASENAME, NAME
) ;

-- *******************************************
-- Create dynamic artifact repository tables
-- for DB2
-- *******************************************

-- *******************************************
-- Create the BYTESTORE table
--    Use by the product components
--      Business Rules, Selector and customization
--
--    Columns
--      TIMESTAMP1          timestamp of last update
--      INITIALBYTES BLOB   holds the serialized SCA component model (EMF)
--                          including generated Business Rule classes
-- *******************************************

CREATE TABLE bpmadmin.BYTESTORE
  (ARTIFACTTNS VARCHAR(250) NOT NULL,
   ARTIFACTNAME VARCHAR(200) NOT NULL,
   ARTIFACTTYPE VARCHAR(50) NOT NULL,
   INITIALBYTES BLOB(30000),
   TIMESTAMP1 BIGINT NOT NULL,
   FILENAME VARCHAR(250),
   BACKINGCLASS VARCHAR(250),
   CHARENCODING VARCHAR(50),
   APPNAME VARCHAR(200),
   COMPONENTTNS VARCHAR(250),
   COMPONENTNAME VARCHAR(200),
   SCAMODULENAME VARCHAR(200),
   SCACOMPONENTNAME VARCHAR(200));

ALTER TABLE bpmadmin.BYTESTORE
  ADD CONSTRAINT PK_BYTESTORE PRIMARY KEY (ARTIFACTTYPE, ARTIFACTTNS, ARTIFACTNAME);

CREATE INDEX bpmadmin.BYTESTORE_INDEX1 ON bpmadmin.BYTESTORE (
      COMPONENTTNS,
      COMPONENTNAME);

CREATE INDEX bpmadmin.BYTESTORE_INDEX2 ON bpmadmin.BYTESTORE (
      ARTIFACTTYPE,
      COMPONENTTNS,
      COMPONENTNAME);


-- *******************************************
-- Create the BYTESTOREOVERFLOW table
--    Use by the product components
--      Business Rules, Selector and customization
--
--    Extension of BYTESTORE table, used if serialized object does not fit there.
--    Column
--      SEQUENCENUMBER  order of the chunks
--      BYTES BLOB      holds chunks of serialized SCA component model (EMF)
--
-- *******************************************

CREATE TABLE bpmadmin.BYTESTOREOVERFLOW
  (ARTIFACTTYPE VARCHAR(50) NOT NULL,
   ARTIFACTTNS VARCHAR(250) NOT NULL,
   ARTIFACTNAME VARCHAR(200) NOT NULL,
   SEQUENCENUMBER INTEGER NOT NULL,
   BYTES BLOB(30000));

ALTER TABLE bpmadmin.BYTESTOREOVERFLOW
  ADD CONSTRAINT PK_BYTESTOREOVERFL PRIMARY KEY (ARTIFACTTYPE, ARTIFACTTNS, ARTIFACTNAME, SEQUENCENUMBER);


-- *******************************************
-- Create the APPTIMESTAMP table
--    Use by the product components
--      Business Rules, Selector and customization
--
--    Column
--      TIMESTAMP1 used to keep cache up-to-date and nodes in sync
--
-- *******************************************

CREATE TABLE bpmadmin.APPTIMESTAMP
  (APPNAME VARCHAR(200) NOT NULL,
   TIMESTAMP1 BIGINT NOT NULL);

ALTER TABLE bpmadmin.APPTIMESTAMP
  ADD CONSTRAINT PK_APPTIMESTAMP PRIMARY KEY (APPNAME);

-- *******************************************
-- Create the CUSTPROPERTIES table
-- *******************************************

CREATE TABLE bpmadmin.CUSTPROPERTIES
  (PROPERTYID VARCHAR (128) NOT NULL,
   ARTIFACTTNS VARCHAR(250) NOT NULL,
   ARTIFACTNAME VARCHAR(200) NOT NULL,
   ARTIFACTTYPE VARCHAR(50) NOT NULL,
   PNAME VARCHAR(250) NOT NULL,
   PVALUE VARCHAR(250) NOT NULL,
   PTYPE VARCHAR (16) NOT NULL);

ALTER TABLE bpmadmin.CUSTPROPERTIES
  ADD CONSTRAINT PK_CUSTPROP PRIMARY KEY (PROPERTYID);

CREATE INDEX bpmadmin.CUSTPROP_INDEX1 ON bpmadmin.CUSTPROPERTIES (
      ARTIFACTTYPE,
      ARTIFACTTNS);

CREATE INDEX bpmadmin.CUSTPROP_INDEX2 ON bpmadmin.CUSTPROPERTIES (
      ARTIFACTTYPE,
      ARTIFACTNAME);

CREATE INDEX bpmadmin.CUSTPROP_INDEX3 ON bpmadmin.CUSTPROPERTIES (
      ARTIFACTTYPE,
      ARTIFACTTNS,
      ARTIFACTNAME);

CREATE INDEX bpmadmin.CUSTPROP_INDEX4 ON bpmadmin.CUSTPROPERTIES (
      ARTIFACTTYPE,
      PNAME);

CREATE INDEX bpmadmin.CUSTPROP_INDEX5 ON bpmadmin.CUSTPROPERTIES (
      ARTIFACTTYPE,
      ARTIFACTTNS,
      PNAME);

      CREATE TABLE bpmadmin.D2D_ITEM (
          ID VARCHAR(255) NOT NULL,
          STATE VARCHAR(20) NOT NULL,
          ITEM_LEVEL INT NOT NULL,
          MODULE_NAME VARCHAR(255),
          APPLICATION_NAME VARCHAR(255),
          VERSION VARCHAR(30),
          WPS_VERSION VARCHAR(10),
          NEW_APP_NAME VARCHAR(255),
          PRIMARY KEY (ID));

      CREATE TABLE bpmadmin.D2D_PROGRESS (
          ITEM_ID VARCHAR(255) NOT NULL,
          PROGRESS INTEGER,
          PROGRESS_MSG VARCHAR(255),
          PROGRESS_ERROR_CODE  VARCHAR(255),
          PRIMARY KEY (ITEM_ID));

      CREATE TABLE bpmadmin.D2D_CONTENT (
          ITEM_ID VARCHAR(255) NOT NULL,
          PI	BLOB(100M),
          PRIMARY KEY (ITEM_ID));

      CREATE TABLE bpmadmin.D2D_METADATA(
          ITEM_ID VARCHAR(255) NOT NULL,
          NAME VARCHAR(255) NOT NULL,
          VALUE VARCHAR(255) );

      CREATE TABLE bpmadmin.D2D_LOCK(
          ITEM_LOCK CHARACTER(1),
          LASTUPDATE TIMESTAMP);

      INSERT INTO bpmadmin.D2D_LOCK VALUES ('X', NULL);

      CREATE TABLE bpmadmin.D2D_MESSAGE(
          ITEM_ID VARCHAR(255) NOT NULL,
          SEQ INT NOT NULL,
          ID	VARCHAR(63),
          DESCRIPTION VARCHAR(1024),
          AFFECTED_RESOURCE VARCHAR(255),
          LOCATION VARCHAR(63),
          FOLDER VARCHAR(255),
          CHR VARCHAR(63),
          TAG	VARCHAR(63),
          SEVERITY VARCHAR(15),
          TIME TIMESTAMP,
          PRIMARY KEY (ITEM_ID, SEQ));

-- ###############################################
-- WARNING
-- Do not perform any committable statements in this file
-- as they will be rolled back in the case where the user
-- drops the W_ tables and expects the system to bootstrap
-- the tables again but did not drop the sequences.  When
-- the CREATE SEQUENCE statements fail, the transation will
-- be rolled back along with any committable work.
-----------------------------------------------------------
----Create tables ,primary keys & indexes for  triplestore
-------------------------------------------------------------

CREATE TABLE bpmadmin.w_lit_double (
    id INTEGER NOT NULL,
    litval DOUBLE )
 IN USERSPACE1;

ALTER TABLE bpmadmin.w_lit_double ADD PRIMARY KEY (id);

CREATE INDEX bpmadmin.idx_obj_dbl ON bpmadmin.w_lit_double (litval);

CREATE TABLE bpmadmin.w_lit_float (
    id INTEGER NOT NULL,
    litval REAL )
 IN USERSPACE1;

ALTER TABLE bpmadmin.w_lit_float ADD PRIMARY KEY (id);

CREATE INDEX bpmadmin.idx_obj_flt ON bpmadmin.w_lit_float (litval);

CREATE TABLE bpmadmin.w_lit_long (
    id INTEGER NOT NULL,
    litval BIGINT )
 IN USERSPACE1;

ALTER TABLE bpmadmin.w_lit_long ADD PRIMARY KEY (id);

CREATE INDEX bpmadmin.idx_obj_long ON bpmadmin.w_lit_long (litval);


CREATE TABLE bpmadmin.w_obj_lit_any (
    id INTEGER NOT NULL,
    large LONG VARCHAR FOR BIT DATA,
    hash VARCHAR(40),
    type_uri VARCHAR(254) NOT NULL )
 IN USERSPACE1;

ALTER TABLE bpmadmin.w_obj_lit_any ADD PRIMARY KEY (id);

CREATE INDEX bpmadmin.idx_obj_any ON bpmadmin.w_obj_lit_any (type_uri);


CREATE TABLE bpmadmin.w_obj_lit_date (
    id INTEGER NOT NULL,
    litval TIMESTAMP )
 IN USERSPACE1;

ALTER TABLE bpmadmin.w_obj_lit_date ADD PRIMARY KEY (id);

CREATE INDEX bpmadmin.idx_obj_date ON bpmadmin.w_obj_lit_date (litval);


CREATE TABLE bpmadmin.w_obj_lit_datetime (
    id INTEGER NOT NULL,
    litval TIMESTAMP )
 IN USERSPACE1;


ALTER TABLE bpmadmin.w_obj_lit_datetime ADD PRIMARY KEY (id);

CREATE INDEX bpmadmin.idx_obj_time ON bpmadmin.w_obj_lit_datetime (litval);


CREATE TABLE bpmadmin.w_obj_lit_string (
    id INTEGER NOT NULL,
    large LONG VARCHAR FOR BIT DATA,
    litval VARCHAR(1024),
    hash VARCHAR(40))
 IN USERSPACE1;

ALTER TABLE bpmadmin.w_obj_lit_string ADD PRIMARY KEY (id);

CREATE INDEX bpmadmin.idx_obj_str ON bpmadmin.w_obj_lit_string (hash);


CREATE TABLE bpmadmin.w_namespace (
    id INTEGER NOT NULL,
    namespace VARCHAR(254) NOT NULL )
 IN USERSPACE1;

ALTER TABLE bpmadmin.w_namespace ADD PRIMARY KEY (id);

CREATE UNIQUE INDEX bpmadmin.idx_namespace ON bpmadmin.w_namespace (namespace ASC);


CREATE TABLE bpmadmin.w_uri (
    id INTEGER NOT NULL,
    uri VARCHAR(254) NOT NULL,
    namespace_id INTEGER NOT NULL )
 IN USERSPACE1;

ALTER TABLE bpmadmin.w_uri ADD PRIMARY KEY (id);

CREATE UNIQUE INDEX bpmadmin.idx_uri ON bpmadmin.w_uri (uri ASC);
CREATE UNIQUE INDEX bpmadmin.idx_uri_by_ns ON bpmadmin.w_uri (namespace_id, id);


CREATE TABLE bpmadmin.w_statement (
    id INTEGER NOT NULL,
    version_from INTEGER NOT NULL,
    version_to INTEGER NOT NULL,
    subj_id INTEGER NOT NULL,
    pred_id INTEGER NOT NULL,
    obj_id INTEGER NOT NULL,
    obj_typ_cd INTEGER NOT NULL,
    partition_id INTEGER NOT NULL)
 IN USERSPACE1;

ALTER TABLE bpmadmin.w_statement ADD PRIMARY KEY (id);

CREATE INDEX bpmadmin.idx_smt_by_sbj ON bpmadmin.w_statement (subj_id, version_from, version_to);
CREATE INDEX bpmadmin.idx_smt_by_fvr ON bpmadmin.w_statement (version_from);
CREATE INDEX bpmadmin.idx_sbj_by_prp ON bpmadmin.w_statement (pred_id, obj_id);
CREATE INDEX bpmadmin.idx_smt_by_val ON bpmadmin.w_statement (obj_id, subj_id);
CREATE INDEX bpmadmin.idx_val_by_prp ON bpmadmin.w_statement (subj_id, pred_id);


CREATE TABLE bpmadmin.w_version (
    username VARCHAR(64) NOT NULL,
    change_time TIMESTAMP NOT NULL,
    cl_gid VARCHAR(36),
    cl_lid VARCHAR(10),
    schema_ns_id INTEGER,
    schema_rev INTEGER,
    id INTEGER NOT NULL,
    partition_id INTEGER NOT NULL )
 IN USERSPACE1;

ALTER TABLE bpmadmin.w_version ADD PRIMARY KEY (id, partition_id);

CREATE INDEX bpmadmin.idx_ver_schema ON bpmadmin.w_version (schema_ns_id);

CREATE TABLE bpmadmin.w_artifact_blob (
 id VARCHAR(254) NOT NULL,
 content BLOB(1G),
 deleted SMALLINT,
 PRIMARY KEY(id))
IN USERSPACE1;

---------------------------------------------------------------------------------
-----Create Foreign keys on trplestore tables
---------------------------------------------------------------------------------

ALTER TABLE bpmadmin.w_uri
    ADD CONSTRAINT w_uri_fk_namesp FOREIGN KEY
        (namespace_id)
    REFERENCES bpmadmin.w_namespace
        (id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    ENFORCED
    ENABLE QUERY OPTIMIZATION;


ALTER TABLE bpmadmin.w_version
    ADD CONSTRAINT w_ver_fk_namesp FOREIGN KEY
        (schema_ns_id)
    REFERENCES bpmadmin.w_namespace
        (id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    ENFORCED
    ENABLE QUERY OPTIMIZATION;

-- The CREATE SEQUENCE statements are at the bottom here so that
-- developers can drop their tables and have them recreated on restart
-- without having to drop sequences also. This is because the DB2
-- Control Center does not provide a way to drop sequences.


CREATE SEQUENCE bpmadmin.seq_w_lit_double_id
 AS INTEGER START WITH 0 INCREMENT BY 1
 NO MAXVALUE MINVALUE 1
NO CYCLE CACHE 20 ORDER;

CREATE SEQUENCE bpmadmin.seq_w_lit_float_id
AS INTEGER START WITH 0 INCREMENT BY 1
 NO MAXVALUE MINVALUE 1
NO CYCLE CACHE 20 ORDER;

CREATE SEQUENCE bpmadmin.seq_w_lit_long_id
AS INTEGER START WITH 0 INCREMENT BY 1
NO MAXVALUE MINVALUE 1
NO CYCLE CACHE 20 ORDER;

CREATE SEQUENCE bpmadmin.seq_w_namespace_id
AS INTEGER START WITH 0 INCREMENT BY 1
NO MAXVALUE MINVALUE 1
NO CYCLE CACHE 20 ORDER;

CREATE SEQUENCE bpmadmin.seq_w_obj_lit_any_id
AS INTEGER START WITH 0 INCREMENT BY 1
NO MAXVALUE MINVALUE 1
NO CYCLE CACHE 20 ORDER;

CREATE SEQUENCE bpmadmin.seq_w_obj_lit_date_id
AS INTEGER START WITH 0 INCREMENT BY 1
NO MAXVALUE MINVALUE 1
NO CYCLE CACHE 20 ORDER;

CREATE SEQUENCE bpmadmin.seq_w_obj_lit_datetime_id
AS INTEGER START WITH 0 INCREMENT BY 1
NO MAXVALUE MINVALUE 1
NO CYCLE CACHE 20 ORDER;

CREATE SEQUENCE bpmadmin.seq_w_obj_lit_string_id
AS INTEGER START WITH 0 INCREMENT BY 1
NO MAXVALUE MINVALUE 1
NO CYCLE CACHE 20 ORDER;

CREATE SEQUENCE bpmadmin.seq_w_statement_id
AS INTEGER START WITH 0 INCREMENT BY 1
NO MAXVALUE MINVALUE 1
NO CYCLE CACHE 20 ORDER;

CREATE SEQUENCE bpmadmin.seq_w_uri_id
AS INTEGER START WITH 0 INCREMENT BY 1
NO MAXVALUE MINVALUE 1
NO CYCLE CACHE 20 ORDER;

CREATE TABLE bpmadmin.w_locale (
    id INTEGER NOT NULL,
    locale VARCHAR(8) NOT NULL)
 IN USERSPACE1;

ALTER TABLE bpmadmin.w_locale ADD PRIMARY KEY (id);

ALTER TABLE bpmadmin.w_locale ADD CONSTRAINT unique_locale UNIQUE(locale);

INSERT INTO bpmadmin.w_locale VALUES (1000, '');
INSERT INTO bpmadmin.w_locale VALUES (1001, 'en');
INSERT INTO bpmadmin.w_locale VALUES (1002, 'en-us');
INSERT INTO bpmadmin.w_locale VALUES (1003, 'en-uk');
INSERT INTO bpmadmin.w_locale VALUES (1004, 'en-gb');
INSERT INTO bpmadmin.w_locale VALUES (1032, 'cs');
INSERT INTO bpmadmin.w_locale VALUES (1064, 'es');
INSERT INTO bpmadmin.w_locale VALUES (1096, 'de');
INSERT INTO bpmadmin.w_locale VALUES (1128, 'de-de');
INSERT INTO bpmadmin.w_locale VALUES (1129, 'fr');
INSERT INTO bpmadmin.w_locale VALUES (1160, 'fr-ca-sk');
INSERT INTO bpmadmin.w_locale VALUES (1161, 'hu');
INSERT INTO bpmadmin.w_locale VALUES (1192, 'it');
INSERT INTO bpmadmin.w_locale VALUES (1224, 'ja');
INSERT INTO bpmadmin.w_locale VALUES (1256, 'ko');
INSERT INTO bpmadmin.w_locale VALUES (1288, 'pl');
INSERT INTO bpmadmin.w_locale VALUES (1320, 'pt-br');
INSERT INTO bpmadmin.w_locale VALUES (1352, 'ru');
INSERT INTO bpmadmin.w_locale VALUES (1384, 'zh');
INSERT INTO bpmadmin.w_locale VALUES (1416, 'zh-tw');
INSERT INTO bpmadmin.w_locale VALUES (1448, 'el');

-- Pattern tables for query optimization

CREATE TABLE bpmadmin.w_subj_pred_index (
    subj_id INTEGER NOT NULL REFERENCES bpmadmin.w_uri (id),
    predicate_map VARCHAR (1024) FOR BIT DATA,
    version_from INTEGER NOT NULL,
    version_to INTEGER NOT NULL,
    partition_id INTEGER NOT NULL REFERENCES bpmadmin.w_uri (id),
    PRIMARY KEY (subj_id, version_from, version_to, partition_id)
);

CREATE TABLE bpmadmin.w_subj_obj_index (
    subj_id INTEGER NOT NULL REFERENCES bpmadmin.w_uri (id),
    object_map VARCHAR (1024) FOR BIT DATA,
    obj_typ_cd INTEGER NOT NULL,
    version_from INTEGER NOT NULL,
    version_to INTEGER NOT NULL,
    partition_id INTEGER NOT NULL REFERENCES bpmadmin.w_uri (id),
    PRIMARY KEY (subj_id, obj_typ_cd, version_from, version_to, partition_id)
);

CREATE TABLE bpmadmin.w_pred_subj_index (
    pred_id INTEGER NOT NULL REFERENCES bpmadmin.w_uri (id),
    subject_map VARCHAR (1024) FOR BIT DATA,
    version_from INTEGER NOT NULL,
    version_to INTEGER NOT NULL,
    partition_id INTEGER NOT NULL REFERENCES bpmadmin.w_uri (id),
    PRIMARY KEY (pred_id, version_from, version_to, partition_id)
);

CREATE TABLE bpmadmin.w_pred_obj_index (
    pred_id INTEGER NOT NULL REFERENCES bpmadmin.w_uri (id),
    object_map VARCHAR (1024) FOR BIT DATA,
    obj_typ_cd INTEGER NOT NULL,
    version_from INTEGER NOT NULL,
    version_to INTEGER NOT NULL,
    partition_id INTEGER NOT NULL REFERENCES bpmadmin.w_uri (id),
    PRIMARY KEY (pred_id, obj_typ_cd, version_from, version_to, partition_id)
);

CREATE TABLE bpmadmin.w_obj_subj_index (
    obj_id INTEGER NOT NULL,
    obj_typ_cd INTEGER NOT NULL,
    subject_map VARCHAR (1024) FOR BIT DATA,
    version_from INTEGER NOT NULL,
    version_to INTEGER NOT NULL,
    partition_id INTEGER NOT NULL REFERENCES bpmadmin.w_uri (id),
    PRIMARY KEY (obj_id, obj_typ_cd, version_from, version_to, partition_id)
);

CREATE TABLE bpmadmin.w_obj_pred_index (
    obj_id INTEGER NOT NULL,
    obj_typ_cd INTEGER NOT NULL,
    predicate_map VARCHAR (1024) FOR BIT DATA,
    version_from INTEGER NOT NULL,
    version_to INTEGER NOT NULL,
    partition_id INTEGER NOT NULL REFERENCES bpmadmin.w_uri (id),
    PRIMARY KEY (obj_id, obj_typ_cd, version_from, version_to, partition_id)
);




CREATE TABLE bpmadmin.w_dbversion (
    subsystem VARCHAR(8) NOT NULL,
    cur_version INTEGER NOT NULL )
 IN USERSPACE1;

ALTER TABLE bpmadmin.w_dbversion ADD PRIMARY KEY (subsystem);

CREATE TABLE bpmadmin.mediation_tickets (
    targetTicketID varchar(255) not null,
    ticketEntry BLOB,
    version varchar(255) not null,
    primary key (targetTicketID));

CREATE TABLE bpmadmin.RELN_METADATA_T(RELATIONSHIP_NAME VARCHAR(255) NOT NULL, VERSION VARCHAR(10) NOT NULL);
CREATE UNIQUE INDEX bpmadmin.RMT_RELN_NAME_I ON bpmadmin.RELN_METADATA_T (RELATIONSHIP_NAME);



CREATE TABLE bpmadmin.RELN_VIEW_META_T ( VIEW_NAME VARCHAR(255) NOT NULL,
                RELATIONSHIP_NAME VARCHAR(255) NOT NULL,
                ROLE_NAME VARCHAR(255) NOT NULL,
                VERSION VARCHAR(10) NOT NULL
                );
CREATE UNIQUE INDEX bpmadmin.RELN_VIEW_I ON bpmadmin.RELN_VIEW_META_T (RELATIONSHIP_NAME, ROLE_NAME);

-- DB2UDB V8.2 schema for Message Logger Mediation

  CREATE TABLE bpmadmin.MSGLOG
    (TIMESTAMP TIMESTAMP NOT NULL,
     MESSAGEID VARCHAR(36) NOT NULL,
     MEDIATIONNAME VARCHAR(256) NOT NULL,
     MODULENAME VARCHAR(256),
     MESSAGE CLOB(100000K),
     VERSION VARCHAR(10))
     ;

  ALTER TABLE bpmadmin.MSGLOG
  ADD CONSTRAINT PK_MSGLOG PRIMARY KEY (TIMESTAMP, MESSAGEID, MEDIATIONNAME)
  ;


