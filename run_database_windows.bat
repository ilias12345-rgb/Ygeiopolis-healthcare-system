@echo off
setlocal

REM Run this file from the repository root on Windows Command Prompt.
REM Usage:
REM   run_database_windows.bat
REM   run_database_windows.bat my_mysql_user

set MYSQL_USER=%1
if "%MYSQL_USER%"=="" set MYSQL_USER=root

if not exist "sql\install.sql" (
  echo ERROR: sql\install.sql was not found.
  echo Run this script from the Ygeiopolis-healthcare-system repository root.
  exit /b 1
)

if not exist "data\generated\doctor.csv" (
  echo ERROR: data\generated\doctor.csv was not found.
  echo The final repository must include CSV data under data\reference and data\generated.
  exit /b 1
)

echo Normalizing CSV line endings for MySQL LOAD DATA...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; Get-ChildItem -Path 'data' -Recurse -Filter '*.csv' | ForEach-Object { $p=$_.FullName; $text=[System.IO.File]::ReadAllText($p); $text=$text -replace \"`r`n\", \"`n\" -replace \"`r\", \"`n\"; [System.IO.File]::WriteAllText($p, $text, [System.Text.UTF8Encoding]::new($false)) }"
if errorlevel 1 exit /b 1

echo Enabling MySQL local_infile...
mysql -u %MYSQL_USER% -e "SET GLOBAL local_infile = 1;"
if errorlevel 1 exit /b 1

echo Checking local_infile...
mysql -u %MYSQL_USER% -e "SHOW GLOBAL VARIABLES LIKE 'local_infile';"
if errorlevel 1 exit /b 1

echo Installing schema...
mysql -u %MYSQL_USER% < sql\install.sql
if errorlevel 1 exit /b 1

echo Loading included CSV data...
mysql --local-infile=1 -u %MYSQL_USER% < sql\load.sql
if errorlevel 1 exit /b 1

echo Running validation...
mysql -u %MYSQL_USER% < sql\validation.sql
if errorlevel 1 exit /b 1

echo Done. The Ygeiopolis database was installed, loaded, and validated.
