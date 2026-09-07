@echo off
rem Build and stage one WDK 7.1 target. Each CI step starts a fresh cmd.exe,
rem because setenv.bat is not safe to call repeatedly in one command process.
setlocal
set "REQUESTED_CPU=%~1"
set "TARGET=%~2"
set "ARTIFACT=%~3"
set "ROOT=%~dp0.."
if "%DDKROOT%"=="" goto noddk
if "%REQUESTED_CPU%"=="x86" set "OUTARCH=i386"
if "%REQUESTED_CPU%"=="x64" set "OUTARCH=amd64"
if "%OUTARCH%"=="" goto usage
if "%TARGET%"=="" goto usage
if "%ARTIFACT%"=="" goto usage
if not exist "%ROOT%\artifact" mkdir "%ROOT%\artifact"
if errorlevel 1 goto fail

call "%DDKROOT%\bin\setenv.bat" %DDKROOT% fre %REQUESTED_CPU% %TARGET% no_oacr
if errorlevel 1 goto fail
rem WDK 7.1 decorates this as fre_<target>_<cpu>; sources accepts project flavours.
set "BUILD_ALT_DIR=fre"
cd /d "%ROOT%"
if errorlevel 1 goto fail
call scripts\make-usbport-lib-wdk.cmd %REQUESTED_CPU%
if errorlevel 1 goto fail
cd /d "%ROOT%\src"
build -ceZ
set "BUILD_RC=%ERRORLEVEL%"
if exist "buildfre.log" copy /y "buildfre.log" "%ROOT%\artifact\%ARTIFACT%-build.log" >nul
if exist "buildfre.err" copy /y "buildfre.err" "%ROOT%\artifact\%ARTIFACT%-build.err" >nul
if not "%BUILD_RC%"=="0" goto builderror
if not exist "objfre\%OUTARCH%\xhci98.sys" goto nooutput

if exist "%ROOT%\artifact\%ARTIFACT%" rmdir /s /q "%ROOT%\artifact\%ARTIFACT%"
mkdir "%ROOT%\artifact\%ARTIFACT%"
if errorlevel 1 goto fail
copy /y "objfre\%OUTARCH%\xhci98.sys" "%ROOT%\artifact\%ARTIFACT%\xhci98.sys" >nul
if errorlevel 1 goto fail
copy /y "%ROOT%\src\xhci98.inf" "%ROOT%\artifact\%ARTIFACT%\xhci98.inf" >nul
if errorlevel 1 goto fail
if exist "buildfre.log" copy /y "buildfre.log" "%ROOT%\artifact\%ARTIFACT%\build.log" >nul
if exist "buildfre.err" copy /y "buildfre.err" "%ROOT%\artifact\%ARTIFACT%\build.err" >nul
endlocal
exit /b 0

:usage
echo ERROR: usage: build-wdk71-target.cmd ^<x86^|x64^> ^<WXP^|WNET^|WLH^|WIN7^> ^<artifact-name^>
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
:builderror
echo.
echo ===== buildfre.err =====
if exist "buildfre.err" type "buildfre.err"
echo.
echo ===== buildfre.log =====
if exist "buildfre.log" type "buildfre.log"
endlocal
exit /b %BUILD_RC%
