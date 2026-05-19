@echo off
setlocal

REM Run one final assignment query from Windows Command Prompt.
REM This keeps both the console and the MySQL connection in UTF-8, which is
REM required for Greek KEN/ICD text to display correctly.
REM Usage:
REM   run_query_windows.bat Q01
REM   run_query_windows.bat Q06 root

chcp 65001 >nul

set QUERY=%1
set MYSQL_USER=%2
if "%MYSQL_USER%"=="" set MYSQL_USER=root

if "%QUERY%"=="" (
  echo ERROR: Give a query name, for example Q01 or Q06.
  exit /b 1
)

if not exist "sql\%QUERY%.sql" (
  echo ERROR: sql\%QUERY%.sql was not found.
  echo Run this script from the Ygeiopolis-healthcare-system repository root.
  exit /b 1
)

mysql --default-character-set=utf8mb4 -t -u %MYSQL_USER% -p < "sql\%QUERY%.sql"
