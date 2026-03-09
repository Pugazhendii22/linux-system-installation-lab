@echo off
REM Clear log file at start
echo. > C:\install_log.txt
echo ===== START ===== >> C:\install_log.txt
REM Connect to network share
net use \\192.168.0.121\software /user:CHRIST\Administrator CHRIST@12345 >> C:\install_log.txt 2>&1
REM Test access
dir \\192.168.0.121\software >> C:\test_access.txt 2>&1
REM Exit if installer not found
if not exist "\\192.168.0.121\software\codeblocks-25.03mingw-setup.exe" (
    echo ERROR: Installer not found >> C:\install_log.txt
    goto cleanup
)
REM Check if Code::Blocks already exists
if exist "C:\Program Files\CodeBlocks\codeblocks.exe" (
    echo Code::Blocks is already installed. >> C:\install_log.txt
    REM Show popup dialog asking for confirmation
    powershell -sta -command "Add-Type -AssemblyName System.Windows.Forms; $result = [System.Windows.Forms.MessageBox]::Show('Code::Blocks is already installed. Do you want to uninstall and reinstall?', 'Code::Blocks Installer', [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question); if ($result -eq 'Yes') { exit 0 } else { exit 1 }"
    if errorlevel 1 (
        echo User chose to skip reinstall. >> C:\install_log.txt
        goto cleanup
    )
    echo User confirmed. Uninstalling... >> C:\install_log.txt
    if exist "C:\Program Files\CodeBlocks\uninstall.exe" (
        start /wait "" "C:\Program Files\CodeBlocks\uninstall.exe" /S
    ) else (
        rmdir /s /q "C:\Program Files\CodeBlocks"
    )
)
REM Install Code::Blocks silently
echo Installing Code::Blocks... >> C:\install_log.txt
start /wait "" "\\192.168.0.121\software\codeblocks-25.03mingw-setup.exe" /S
REM Verify installation
echo Checking installation... >> C:\install_log.txt
if exist "C:\Program Files\CodeBlocks\codeblocks.exe" (
    echo SUCCESS >> C:\install_log.txt
) else (
    echo FAILED >> C:\install_log.txt
    goto cleanup
)
REM Create Desktop shortcut
echo Creating desktop shortcut... >> C:\install_log.txt
set "target=C:\Program Files\CodeBlocks\codeblocks.exe"
set "desktop_shortcut=%PUBLIC%\Desktop\Code::Blocks.lnk"
powershell -command "$s=(New-Object -COM WScript.Shell).CreateShortcut('%desktop_shortcut%');$s.TargetPath='%target%';$s.Description='Code::Blocks IDE';$s.Save()"
REM Create Start Menu shortcut (makes it appear in Windows Search)
echo Creating Start Menu shortcut... >> C:\install_log.txt
set "startmenu=%ProgramData%\Microsoft\Windows\Start Menu\Programs\Code::Blocks.lnk"
powershell -command "$s=(New-Object -COM WScript.Shell).CreateShortcut('%startmenu%');$s.TargetPath='%target%';$s.Description='Code::Blocks IDE';$s.Save()"
echo ===== DONE ===== >> C:\install_log.txt
:cleanup
REM Disconnect network share
net use \\192.168.0.121\software /delete >> C:\install_log.txt 2>&1
exit
