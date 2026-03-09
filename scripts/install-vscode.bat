@echo off
REM Clear log file at start
echo. > C:\install_log.txt
echo ===== START ===== >> C:\install_log.txt

REM Connect to network share
net use \\192.168.0.121\software /user:CHRIST\Administrator CHRIST@12345 >> C:\install_log.txt 2>&1

REM Test access
dir \\192.168.0.121\software >> C:\test_access.txt 2>&1

REM Exit if installer not found
if not exist "\\192.168.0.121\software\vscode.exe" (
    echo ERROR: Installer not found >> C:\install_log.txt
    goto cleanup
)

REM Check if VS Code already exists
if exist "C:\Program Files\Microsoft VS Code\Code.exe" (
    echo VS Code is already installed. >> C:\install_log.txt

    REM Show popup dialog asking for confirmation
    powershell -sta -command "Add-Type -AssemblyName System.Windows.Forms; $result = [System.Windows.Forms.MessageBox]::Show('VS Code is already installed. Do you want to uninstall and reinstall?', 'VS Code Installer', [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question); if ($result -eq 'Yes') { exit 0 } else { exit 1 }"

    if errorlevel 1 (
        echo User chose to skip reinstall. >> C:\install_log.txt
        goto cleanup
    )

    echo User confirmed. Uninstalling... >> C:\install_log.txt
    if exist "C:\Program Files\Microsoft VS Code\unins000.exe" (
        start /wait "" "C:\Program Files\Microsoft VS Code\unins000.exe" /VERYSILENT /SUPPRESSMSGBOXES
    ) else (
        rmdir /s /q "C:\Program Files\Microsoft VS Code"
    )
)

REM Install VS Code silently
echo Installing VS Code... >> C:\install_log.txt
start /wait "" "\\192.168.0.121\software\vscode.exe" /VERYSILENT /SUPPRESSMSGBOXES /NORESTART /MERGETASKS="!runcode,addcontextmenufiles,addcontextmenufolders,associatewithfiles,addtopath"

REM Verify installation
echo Checking installation... >> C:\install_log.txt
if exist "C:\Program Files\Microsoft VS Code\Code.exe" (
    echo SUCCESS >> C:\install_log.txt
) else (
    echo FAILED >> C:\install_log.txt
    goto cleanup
)

REM Create desktop shortcut
set "target=C:\Program Files\Microsoft VS Code\Code.exe"
set "shortcut=%PUBLIC%\Desktop\Visual Studio Code.lnk"
powershell -command "$s=(New-Object -COM WScript.Shell).CreateShortcut('%shortcut%');$s.TargetPath='%target%';$s.Save()"

echo ===== DONE ===== >> C:\install_log.txt

:cleanup
REM Disconnect network share
net use \\192.168.0.121\software /delete >> C:\install_log.txt 2>&1
exit /b