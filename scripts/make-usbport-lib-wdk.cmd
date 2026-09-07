@echo off
rem Build the private USBPORT import library with the active WDK compiler.
rem The caller must first enter the desired x86 or amd64 WDK environment.
setlocal
set "ARCH=%~1"
set "ROOT=%~dp0.."
set "TMP=%TEMP%\xhci98-usbport-%RANDOM%"
if /i "%ARCH%"=="x86" goto x86
if /i "%ARCH%"=="x64" goto x64
echo ERROR: expected x86 or x64.
exit /b 2
:x86
set "MACHINE=X86"
goto build
:x64
set "MACHINE=X64"
:build
mkdir "%TMP%" >nul 2>&1
cl /nologo /c /W3 /Fo"%TMP%\stub.obj" "%ROOT%\scripts\usbport-lib\usbport-stub.c"
if errorlevel 1 goto fail
link /nologo /dll /noentry /nodefaultlib /machine:%MACHINE% /def:"%ROOT%\scripts\usbport-lib\usbport-stub.def" "%TMP%\stub.obj" /out:"%TMP%\usbport.sys" /implib:"%TMP%\usbport.lib"
if errorlevel 1 goto fail
copy /y "%TMP%\usbport.lib" "%ROOT%\src\usbport.lib" >nul
if errorlevel 1 goto fail
rmdir /s /q "%TMP%"
endlocal
exit /b 0
:fail
echo ERROR: could not create the %ARCH% USBPORT import library.
rmdir /s /q "%TMP%" >nul 2>&1
endlocal
exit /b 1
