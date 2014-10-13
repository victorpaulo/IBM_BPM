CREATE PROCEDURE bpmadmin.LSW_ERASE_TEMP_GROUPS()
    LANGUAGE SQL

  -- This procedure deletes all temporary groups that are no longer referenced by a task. --

  BEGIN
  
    DECLARE groupId DECIMAL(12,0);
    DECLARE sqlCmd VARCHAR(500);
    DECLARE at_end DECIMAL(1,0);
    DECLARE not_found CONDITION for SQLSTATE '02000';
    DECLARE CONTINUE HANDLER for not_found SET at_end = 1;

    BEGIN
        DECLARE groupsToDelete CURSOR FOR stmt1;
        SET sqlCmd = 'SELECT DISTINCT G.GROUP_ID FROM bpmadmin.LSW_USR_GRP_XREF G WHERE G. GROUP_TYPE = 2 AND NOT EXISTS ( SELECT T.GROUP_ID FROM bpmadmin.LSW_TASK T WHERE T.GROUP_ID = G.GROUP_ID UNION ALL SELECT T.GROUP_ID FROM bpmadmin.LSW_TASK T WHERE T.GROUP_ID = - G.GROUP_ID )';
        PREPARE stmt1 FROM sqlCmd;

        OPEN groupsToDelete;
        DELETE_GROUP_LOOP:
        LOOP
            SET at_end = 0;
            FETCH groupsToDelete INTO groupId;
            IF (at_end = 1) THEN
                LEAVE DELETE_GROUP_LOOP;
            END IF;
            
            DELETE FROM bpmadmin.LSW_USR_GRP_MEM_XREF WHERE GROUP_ID = groupId;
            DELETE FROM bpmadmin.LSW_GRP_GRP_MEM_EXPLODED_XREF WHERE GROUP_ID = groupId OR CONTAINER_GROUP_ID = groupId;
            DELETE FROM bpmadmin.LSW_GRP_GRP_MEM_XREF WHERE GROUP_ID = groupId OR CONTAINER_GROUP_ID = groupId;
            DELETE FROM bpmadmin.LSW_USR_GRP_XREF WHERE GROUP_ID = groupId;
			
        END LOOP;
        CLOSE groupsToDelete;
    END;
  
  END

GO

CREATE PROCEDURE bpmadmin.LSW_HOUSE_KEEPING(IN modeHK DECIMAL(12,0))
    LANGUAGE SQL

MAIN:
BEGIN

DECLARE statuses VARCHAR(64);
DECLARE sqlCmd VARCHAR(4000);
DECLARE flgStatusNotExist CHAR(1);
DECLARE flgDelete CHAR(1);
DECLARE rootTaskId DECIMAL(12,0);
DECLARE taskId DECIMAL(12,0);
DECLARE taskStatus VARCHAR(2);

DECLARE at_end DECIMAL(1,0);
DECLARE not_found CONDITION for SQLSTATE '02000';
DECLARE CONTINUE HANDLER for not_found SET at_end = 1;

IF (modeHK = 1) THEN

  -- Delete orphaned and DELETED task attachments --
  DELETE FROM bpmadmin.LSW_TASK_FILE WHERE TASK_ID IN (SELECT TASK_ID FROM bpmadmin.LSW_TASK WHERE STATUS IN ('91','92'));
  DELETE FROM bpmadmin.LSW_FILE WHERE FILE_ID NOT IN (SELECT FILE_ID FROM bpmadmin.LSW_TASK_FILE) OR FILE_ID NOT IN (SELECT FILE_ID FROM bpmadmin.LSW_TASK, bpmadmin.LSW_TASK_FILE WHERE bpmadmin.LSW_TASK.TASK_ID = bpmadmin.LSW_TASK_FILE.TASK_ID);
  DELETE FROM bpmadmin.LSW_TASK_FILE WHERE FILE_ID NOT IN (SELECT FILE_ID FROM bpmadmin.LSW_FILE) OR TASK_ID NOT IN (SELECT bpmadmin.LSW_TASK.TASK_ID FROM bpmadmin.LSW_TASK, bpmadmin.LSW_TASK_FILE WHERE bpmadmin.LSW_TASK.TASK_ID = bpmadmin.LSW_TASK_FILE.TASK_ID);

  -- Delete orphaned task-scoped temporary groups --
  CALL bpmadmin.LSW_ERASE_TEMP_GROUPS();

ELSEIF (modeHK > 1) THEN

  -- Define what task statuses we are interested in --
  SET statuses = '';
  IF (modeHK >= 2) THEN
    SET statuses = '''91'',''92''';
  END IF;
  IF (modeHK >= 3) THEN
    SET statuses = statuses || ',''21''';
  END IF;
  IF (modeHK >= 4) THEN
    SET statuses = statuses || ',''31'',''32''';
  END IF;

  DECLARE GLOBAL TEMPORARY TABLE TEMP_DELETE_TASK (
  TASK_ID DECIMAL(12,0) NOT NULL
  ) NOT LOGGED WITH REPLACE;

  BEGIN
  -- Go through each root task id --
  DECLARE curAllRootTasks CURSOR FOR stmt1;
  SET sqlCmd = 'SELECT DISTINCT ORIG_TASK_ID FROM bpmadmin.LSW_TASK';
  PREPARE stmt1 FROM sqlCmd;
  OPEN curAllRootTasks;
  MAIN_LOOP:
  LOOP
    SET at_end = 0;
    FETCH curAllRootTasks INTO rootTaskId;
    IF (at_end = 1) THEN
      LEAVE MAIN_LOOP;
    END IF;

    -- Check each task belonging to the current root task group. If ALL tasks in this group belong to --
    -- the statuses we are interested in, then we can remove these tasks --
    SET flgDelete = 'T';
    BEGIN
    DECLARE curRootTask CURSOR FOR stmt2;
    SET sqlCmd = 'SELECT TASK_ID, STATUS FROM bpmadmin.LSW_TASK WHERE ORIG_TASK_ID = ?';
    PREPARE stmt2 FROM sqlCmd;
    OPEN curRootTask USING rootTaskId;
    ROOT_TASK_LOOP:
    LOOP
      SET at_end = 0;
      FETCH curRootTask INTO taskId, taskStatus;
      IF (at_end = 1) THEN
        LEAVE ROOT_TASK_LOOP;
      END IF;

      SET flgStatusNotExist = 'F';
      BEGIN
      DECLARE curStatusNotExist CURSOR FOR stmt3;
      SET sqlCmd = 'SELECT ''T'' FROM SYSIBM.SYSDUMMY1 WHERE ? NOT IN (' || statuses || ')';
      PREPARE stmt3 FROM sqlCmd;
      OPEN curStatusNotExist USING taskStatus;
      FETCH curStatusNotExist INTO flgStatusNotExist;
      CLOSE curStatusNotExist;
      END;

      IF (flgStatusNotExist = 'T') THEN
        SET flgDelete = 'F';
        LEAVE ROOT_TASK_LOOP;
      END IF;

      INSERT INTO SESSION.TEMP_DELETE_TASK VALUES (taskId);

    END LOOP;

    CLOSE curRootTask;

    IF (flgDelete = 'T') THEN
      BEGIN
      DECLARE curDeleteTask CURSOR FOR stmt4;
      SET sqlCmd = 'SELECT TASK_ID FROM SESSION.TEMP_DELETE_TASK';
      PREPARE stmt4 FROM sqlCmd;
      OPEN curDeleteTask;
      SET at_end = 0;
      DELETE_TASK_LOOP:
      LOOP
        SET at_end = 0;
        FETCH curDeleteTask INTO taskId;
        IF (at_end = 1) THEN
          LEAVE DELETE_TASK_LOOP;
        END IF;
	DELETE FROM bpmadmin.LSW_TASK_NARR WHERE TASK_ID = taskId;
	DELETE FROM bpmadmin.LSW_TASK_FILE WHERE TASK_ID = taskId;
	DELETE FROM bpmadmin.LSW_TASK_ADDR WHERE TASK_ID = taskId;
	DELETE FROM bpmadmin.LSW_TASK_EXECUTION_CONTEXT WHERE TASK_ID = taskId;
	DELETE FROM bpmadmin.LSW_TASK WHERE TASK_ID = taskId;
      END LOOP;
      CLOSE curDeleteTask;
      END;
    END IF;

    DELETE FROM SESSION.TEMP_DELETE_TASK;

    END;

  END LOOP;

  CLOSE curAllRootTasks;

  END;

  DROP TABLE SESSION.TEMP_DELETE_TASK;

  -- Delete all attachment files that are not referenced by any task --
  DELETE FROM bpmadmin.LSW_FILE WHERE FILE_ID NOT IN (SELECT FILE_ID FROM bpmadmin.LSW_TASK_FILE);

  -- Delete orphaned task-scoped temporary groups --
  CALL bpmadmin.LSW_ERASE_TEMP_GROUPS();
  
END IF;

END

GO

CREATE PROCEDURE bpmadmin.LSW_ERASE_BPD_INST_NO_GROUP(IN bpdInstanceId DECIMAL(12,0))
    LANGUAGE SQL

  -- This procedure deletes a BPD instance and its dependent entries. It does NOT delete temporary groups. --

MAIN:
  BEGIN
    DELETE FROM bpmadmin.LSW_BPD_INSTANCE_DOC_PROPS WHERE DOC_ID IN (SELECT DOC_ID FROM bpmadmin.LSW_BPD_INSTANCE_DOCUMENTS WHERE BPD_INSTANCE_ID = bpdInstanceId);

    DELETE FROM bpmadmin.LSW_BPD_INSTANCE_DOCUMENTS WHERE BPD_INSTANCE_ID = bpdInstanceId;
    
    DELETE FROM bpmadmin.LSW_BPD_INSTANCE_VARIABLES WHERE BPD_INSTANCE_ID = bpdInstanceId;

    DELETE FROM bpmadmin.LSW_BPD_INSTANCE_DATA WHERE BPD_INSTANCE_ID = bpdInstanceId;
    
    DELETE FROM bpmadmin.LSW_BPD_INSTANCE_CORRELATION WHERE BPD_INSTANCE_ID = bpdInstanceId;
    
    DELETE FROM bpmadmin.LSW_BPD_INSTANCE_EXT_DATA WHERE BPD_INSTANCE_ID = bpdInstanceId;

    DELETE FROM bpmadmin.LSW_BPD_NOTIFICATION WHERE BPD_INSTANCE_ID = bpdInstanceId;

    DELETE FROM bpmadmin.LSW_RUNTIME_ERROR WHERE BPD_INSTANCE_ID = bpdInstanceId;

    DELETE FROM bpmadmin.LSW_BPD_INSTANCE WHERE BPD_INSTANCE_ID = bpdInstanceId;

    DELETE FROM bpmadmin.LSW_INST_MSG_INCL WHERE BPD_INSTANCE_ID = bpdInstanceId;

    DELETE FROM bpmadmin.LSW_INST_MSG_EXCL WHERE BPD_INSTANCE_ID = bpdInstanceId;
    
    DELETE FROM bpmadmin.LSW_BPD_ACTIVITY_INSTANCE WHERE BPD_INSTANCE_ID = bpdInstanceId;
	
  END

GO

CREATE PROCEDURE bpmadmin.LSW_ERASE_BPD_INSTANCE(IN bpdInstanceId DECIMAL(12,0))
    LANGUAGE SQL
    
    -- This procedure deletes a BPD instance and its dependent entries, including temporary groups. --

MAIN:
  BEGIN
    
    -- Delete the BPD instance itself --
    CALL bpmadmin.LSW_ERASE_BPD_INST_NO_GROUP(bpdInstanceId);
	
    -- Cleanup: Delete orphaned task-scoped temporary groups --
    CALL bpmadmin.LSW_ERASE_TEMP_GROUPS();
    
  END

GO

CREATE PROCEDURE bpmadmin.LSW_ERASE_TASK_NO_GROUP(IN taskId DECIMAL(12,0))
    LANGUAGE SQL

  -- This procedure deletes a task and its dependent entries. It does NOT delete temporary groups that were created for this task. --

  BEGIN

    DELETE FROM bpmadmin.LSW_TASK_ADDR WHERE TASK_ID = taskId;

    DELETE FROM bpmadmin.LSW_TASK_EXECUTION_CONTEXT WHERE TASK_ID = taskId;

    DELETE FROM bpmadmin.LSW_TASK_NARR WHERE TASK_ID = taskId;

    DELETE FROM bpmadmin.LSW_TASK_FILE WHERE TASK_ID = taskId;

    DELETE FROM bpmadmin.LSW_TASK_IPF_DATA WHERE TASK_ID = taskId;
    
    DELETE FROM bpmadmin.LSW_TASK_EXTACT_DATA WHERE TASK_ID = taskId;
    
    DELETE FROM bpmadmin.LSW_TASK WHERE TASK_ID = taskId;

  END

GO

CREATE PROCEDURE bpmadmin.LSW_ERASE_TASK(IN taskId DECIMAL(12,0))
    LANGUAGE SQL

  -- This procedure deletes a task and its dependent entries, including temporary groups that were created for this task. --

  BEGIN

    -- Delete the task itself --
    CALL bpmadmin.LSW_ERASE_TASK_NO_GROUP(taskId);

    -- Cleanup: Delete orphaned task-scoped temporary groups --
    CALL bpmadmin.LSW_ERASE_TEMP_GROUPS();

  END

GO

CREATE PROCEDURE bpmadmin.LSW_BPD_INST_DELETE_NO_GROUP(IN bpdInstanceId DECIMAL(12,0))

  -- This procedure deletes a BPD instance and its dependent entries, as well as tasks that are part of this instance. It does NOT delete temporary groups. --

MAIN:
  BEGIN

    DECLARE taskId DECIMAL(12,0);
    DECLARE sqlCmd VARCHAR(4000);
    DECLARE at_end DECIMAL(1,0);
    DECLARE not_found CONDITION for SQLSTATE '02000';
    DECLARE CONTINUE HANDLER for not_found SET at_end = 1;

    BEGIN
        DECLARE tasksToDelete CURSOR FOR stmt1;
        SET sqlCmd = 'SELECT TASK_ID FROM bpmadmin.LSW_TASK WHERE BPD_INSTANCE_ID = ?';
        PREPARE stmt1 FROM sqlCmd;

        OPEN tasksToDelete USING bpdInstanceId;
        DELETE_TASK_LOOP:
        LOOP
            SET at_end = 0;
            FETCH tasksToDelete INTO taskId;
            IF (at_end = 1) THEN
                LEAVE DELETE_TASK_LOOP;
            END IF;
            CALL bpmadmin.LSW_ERASE_TASK_NO_GROUP(taskId);
        END LOOP;
        CLOSE tasksToDelete;
    END;
    CALL bpmadmin.LSW_ERASE_BPD_INST_NO_GROUP(bpdInstanceId);
  END
GO

CREATE PROCEDURE bpmadmin.LSW_BPD_INSTANCE_DELETE(IN bpdInstanceId DECIMAL(12,0))

  -- This procedure deletes a BPD instance and its dependent entries, as well as tasks that are part of this instance and temporary groups. --

MAIN:
  BEGIN

    -- Delete the BPD instance itself --
    CALL bpmadmin.LSW_BPD_INST_DELETE_NO_GROUP(bpdInstanceId);
    
    -- Cleanup: Delete orphaned task-scoped temporary groups --
    CALL bpmadmin.LSW_ERASE_TEMP_GROUPS();
    
  END
GO

CREATE PROCEDURE bpmadmin.LSW_TASK_CLOSE (IN userId DECIMAL(12,0), IN taskId DECIMAL(12,0), OUT returnStatus DECIMAL(12,0))
    LANGUAGE SQL

MAIN:
BEGIN

DECLARE taskUserId DECIMAL(12,0);
DECLARE taskGroupId DECIMAL(12,0);
DECLARE taskStatus VARCHAR(2);
DECLARE taskProcessRef DECIMAL(12,0);
DECLARE taskExecutionStatus DECIMAL(12,0);

DECLARE flgCanClose CHAR;

DECLARE at_end DECIMAL(1,0);
DECLARE not_found CONDITION for SQLSTATE '02000';
DECLARE CONTINUE HANDLER for not_found SET at_end = 1;

SET returnStatus = -1;

SELECT USER_ID,GROUP_ID,STATUS,START_PROCESS_REF,EXECUTION_STATUS
	   INTO taskUserId,taskGroupId,taskStatus,taskProcessRef,taskExecutionStatus
	   FROM bpmadmin.LSW_TASK
	   WHERE TASK_ID = taskId;
IF (at_end = 1) THEN
  LEAVE MAIN;
END IF;

-- See if we can close this task --
SET flgCanClose = 'F';
IF (SUBSTR(taskStatus, 1, 1) <> '3') THEN
  IF (taskProcessRef IS NULL) THEN
    SET flgCanClose = 'T';
  ELSE
    IF ((taskExecutionStatus = 1) OR (taskExecutionStatus = 4)) THEN
      SET flgCanClose = 'T';
    END IF;
  END IF;

  -- See if we own this task --
  IF (userId <> taskUserId) THEN
    SET flgCanClose = 'F';
  END IF;
END IF;

-- OK, so now close this task --
IF (flgCanClose = 'T') THEN
  UPDATE bpmadmin.LSW_TASK SET STATUS = '32', CLOSE_DATETIME = CURRENT TIMESTAMP - CURRENT TIMEZONE, CLOSE_BY = userId, EXECUTION_STATUS = 1
  		 WHERE TASK_ID = taskId;
  SET returnStatus = 0;
END IF;

END

GO

CREATE PROCEDURE bpmadmin.LSW_TASK_DELETE(IN userId DECIMAL(12,0), IN taskId DECIMAL(12,0), OUT returnStatus DECIMAL(12,0))
    LANGUAGE SQL

MAIN:
BEGIN

DECLARE taskUserId DECIMAL(12,0);
DECLARE taskGroupId DECIMAL(12,0);
DECLARE taskStatus VARCHAR(2);
DECLARE taskProcessRef DECIMAL(12,0);
DECLARE taskExecutionStatus DECIMAL(12,0);

DECLARE flgCanDelete CHAR;

DECLARE at_end DECIMAL(1,0);
DECLARE not_found CONDITION for SQLSTATE '02000';
DECLARE CONTINUE HANDLER for not_found SET at_end = 1;

SET returnStatus = -1;

SELECT USER_ID,GROUP_ID,STATUS,START_PROCESS_REF,EXECUTION_STATUS
	   INTO taskUserId,taskGroupId,taskStatus,taskProcessRef,taskExecutionStatus
	   FROM bpmadmin.LSW_TASK
	   WHERE TASK_ID = taskId;
IF (at_end = 1) THEN
  LEAVE MAIN;
END IF;

-- See if we can delete this task --
SET flgCanDelete = 'F';
IF ((SUBSTR(taskStatus, 1, 1) = '2') OR (SUBSTR(taskStatus, 1, 1) = '3')) THEN
  IF (taskProcessRef IS NULL) THEN
    SET flgCanDelete = 'T';
  ELSE
    IF ((taskExecutionStatus = 1) OR (taskExecutionStatus = 4)) THEN
      SET flgCanDelete = 'T';
    END IF;
  END IF;

  -- See if we own this task --
  IF (userId <> taskUserId) THEN
    SET flgCanDelete = 'F';
  END IF;
END IF;

-- OK, so now delete this task --
IF (flgCanDelete = 'T') THEN
  IF (SUBSTR(taskStatus,1,1) = '2') THEN
    UPDATE bpmadmin.LSW_TASK SET STATUS = '92'
  		 WHERE TASK_ID = taskId;
  ELSE
    UPDATE bpmadmin.LSW_TASK SET STATUS = '91'
  		 WHERE TASK_ID = taskId;
  END IF;
  SET returnStatus = 0;
END IF;

END
GO

CREATE PROCEDURE  bpmadmin.BPM_SET_LOB_INLINE_LENGTH(IN tableName char(50), IN columnName char(50), IN inlineLength DECIMAL(12,0))
    LANGUAGE SQL
BEGIN
        DECLARE txt VARCHAR(32000);
        DECLARE EXIT HANDLER FOR SQLSTATE '42837'
        BEGIN
                --do nothing
        END;
        SET txt = 'ALTER TABLE ' || tableName || 'ALTER COLUMN ' || columnName || 'SET INLINE LENGTH ' || digits(inlineLength);
        EXECUTE IMMEDIATE txt;
END
GO

CALL  bpmadmin.BPM_SET_LOB_INLINE_LENGTH('bpmadmin.BPM_BPD_SOAPHEADER', 'DATA', 16384)
GO
CALL  bpmadmin.BPM_SET_LOB_INLINE_LENGTH('bpmadmin.LSW_PERF_DATA_TRANSFER', 'DATA', 16384)
GO
CALL  bpmadmin.BPM_SET_LOB_INLINE_LENGTH('bpmadmin.LSW_TASK_EXECUTION_CONTEXT', 'EXECUTION_CONTEXT', 30720)
GO
CALL  bpmadmin.BPM_SET_LOB_INLINE_LENGTH('bpmadmin.LSW_SAVED_SEARCHES', 'QUERY', 4096)
GO
CALL  bpmadmin.BPM_SET_LOB_INLINE_LENGTH('bpmadmin.LSW_BPD_INSTANCE_DATA', 'DATA', 30720)
GO
CALL  bpmadmin.BPM_SET_LOB_INLINE_LENGTH('bpmadmin.LSW_BPD_NOTIFICATION', 'DATA', 16384)
GO
CALL  bpmadmin.BPM_SET_LOB_INLINE_LENGTH('bpmadmin.LSW_BPD_NOTIFICATION', 'ERROR', 4096)
GO
CALL  bpmadmin.BPM_SET_LOB_INLINE_LENGTH('bpmadmin.LSW_BPD_NOTIFICATION', 'ERROR_STACK_TRACE', 4096)
GO
CALL  bpmadmin.BPM_SET_LOB_INLINE_LENGTH('bpmadmin.LSW_SNAPSHOT', 'CHANGE_DATA', 16384)
GO
CALL  bpmadmin.BPM_SET_LOB_INLINE_LENGTH('bpmadmin.LSW_SNAPSHOT', 'DESCRIPTION', 4096)
GO
CALL  bpmadmin.BPM_SET_LOB_INLINE_LENGTH('bpmadmin.LSW_EM_TASK', 'TASK_ARGUMENTS', 16384)
GO
CALL  bpmadmin.BPM_SET_LOB_INLINE_LENGTH('bpmadmin.LSW_DUR_MSG_RECEIVED', 'VALUES_DATA', 4096)
GO
CALL  bpmadmin.BPM_SET_LOB_INLINE_LENGTH('bpmadmin.LSW_DUR_MSG_RECEIVED', 'CORRELATION_BLOB', 4096)
GO
CALL  bpmadmin.BPM_SET_LOB_INLINE_LENGTH('bpmadmin.LSW_TASK_NARR', 'NARRATIVE', 1024)
GO
CALL  bpmadmin.BPM_SET_LOB_INLINE_LENGTH('bpmadmin.LSW_TASK_NARR', 'NARRATIVE_RAW', 1024)
GO							

DROP PROCEDURE bpmadmin.BPM_SET_LOB_INLINE_LENGTH
GO
