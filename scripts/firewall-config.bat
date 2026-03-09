@echo off

set FLAG=C:\firewall_done.flag
set LOG=C:\firewall_status.txt

:: If already executed, exit
if exist %FLAG% exit /b

:: Check Administrator privileges
net session >nul 2>&1
if %errorlevel% neq 0 (
 powershell -Command "Start-Process '%~f0' -Verb RunAs"
 exit /b
)

echo ===== Firewall Script Start %date% %time% ===== >> %LOG%

netsh advfirewall set allprofiles state off >> %LOG% 2>&1

netsh advfirewall show allprofiles | find "OFF" >nul

if %errorlevel%==0 (
 echo SUCCESS: Firewall disabled >> %LOG%
) else (
 echo FAILED: Firewall still enabled >> %LOG%
)

echo done > %FLAG%

echo ===== Script End ===== >> %LOG%