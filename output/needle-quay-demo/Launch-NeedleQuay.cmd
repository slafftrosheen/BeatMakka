@echo off
setlocal
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0Launch-NeedleQuay.ps1" %*
set "launchResult=%ERRORLEVEL%"
if not "%launchResult%"=="0" (
    echo.
    echo Needle Quay could not launch. See the error above.
    pause
)
exit /b %launchResult%
