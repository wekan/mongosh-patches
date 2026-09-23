@echo off
setlocal
if "%~1"=="" goto menu
if /I "%~1"=="release-all" goto package
if /I "%~1"=="release-all-missing" goto package
if /I "%~1"=="win64" goto package
if /I "%~1"=="win-arm64" goto package
if /I "%~1"=="win32" goto package
echo Usage: build.bat win64^|win-arm64^|win32
exit /b 2
:package
where bash >nul 2>nul || (echo Git Bash is required.& exit /b 1)
bash "%~dp0build.sh" %*
exit /b %errorlevel%
:menu
echo 1^) Package Windows x64
echo 2^) Package Windows ARM64
echo 3^) Package Windows x86
echo 4^) Release All
echo 5^) Release All Missing
set /p choice=Selection: 
if "%choice%"=="1" call "%~f0" win64
if "%choice%"=="2" call "%~f0" win-arm64
if "%choice%"=="3" call "%~f0" win32
if "%choice%"=="4" call "%~f0" release-all
if "%choice%"=="5" call "%~f0" release-all-missing
exit /b %errorlevel%
