@REM BEGIN COPYRIGHT
@REM *************************************************************************
@REM 
@REM  Licensed Materials - Property of IBM
@REM  5725-C94, 5725-C95, 5725-C96
@REM  (C) Copyright IBM Corporation 2013. All Rights Reserved.
@REM  US Government Users Restricted Rights- Use, duplication or disclosure
@REM  restricted by GSA ADP Schedule Contract with IBM Corp.
@REM 
@REM *************************************************************************
@REM END COPYRIGHT
@echo off
setlocal

db2cmd /c /w /i db2 -stf "%~dp0\dropDatabase.sql"
set RC=%ERRORLEVEL%

endlocal & exit /b %RC%
