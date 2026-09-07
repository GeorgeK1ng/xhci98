@echo off
rem Build and stage one WDK 7.1 target. Each CI step starts a fresh cmd.exe,
rem because setenv.bat is not safe to call repeatedly in one command process.
setlocal
set "CPU=%~1"
set "TARGET=%~2"
set "ARTIFACT=%~3"
set "ROOT=%~dp0.."
if "%DDKROOT%"=="" goto noddk
if "%CPU%"=="x86" set "OUTARCH=i386"
if "%CPU%"=="x64" set "OUTARCH=amd64"
if "%OUTARCH%"=="" goto usage
if "%TARGET%"=="" goto usage
if "%ARTIFACT%"=="" goto usage

call "%DDKROOT%\bin\setenv.bat" %DDKROOT% fre %CPU% %TARGET% no_oacr
if errorlevel 1 goto fail
rem WDK 7.1 decorates this as fre_<target>_<cpu>; sources accepts project flavours.
set "BUILD_ALT_DIR=fre"
cd /d "%ROOT%"
if errorlevel 1 goto fail
call scripts\make-usbport-lib-wdk.cmd %CPU%
if errorlevel 1 goto fail
cd /d "%ROOT%\src"
build -ceZ
if errorlevel 1 goto fail
if not exist "objfre\%OUTARCH%\xhci98.sys" goto nooutput

if exist "%ROOT%\artifact\%ARTIFACT%" rmdir /s /q "%ROOT%\artifact\%ARTIFACT%"
mkdir "%ROOT%\artifact\%ARTIFACT%"
if errorlevel 1 goto fail
copy /y "objfre\%OUTARCH%\xhci98.sys" "%ROOT%\artifact\%ARTIFACT%\xhci98.sys" >nul
if errorlevel 1 goto fail
copy /y "%ROOT%\src\xhci98.inf" "%ROOT%\artifact\%ARTIFACT%\xhci98.inf" >nul
if errorlevel 1 goto fail
endlocal
exit /b 0

:usage
echo ERROR: usage: build-wdk71-target.cmd ^<x86^|x64^> ^<WXP^|WNET^> ^<artifact-name^>
endlocal
exit /b 2
:noddk
echo ERROR: DDKROOT is not set.
endlocal
exit /b 1
:nooutput
echo ERROR: expected objfre\%OUTARCH%\xhci98.sys was not built.
:fail
endlocal
exit /b 1
