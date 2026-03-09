@echo off
REM Clear log file at start
echo. > C:\install_log.txt
echo ===== START ===== >> C:\install_log.txt
REM Connect to network share
net use \\192.168.0.121\software /user:CHRIST\Administrator CHRIST@12345 >> C:\install_log.txt 2>&1
REM Test access
dir \\192.168.0.121\software >> C:\test_access.txt 2>&1
REM Exit if installer not found
if not exist "\\192.168.0.121\software\sqlite3.exe" (
    echo ERROR: sqlite3.exe not found on share >> C:\install_log.txt
    goto cleanup
)
REM Check if SQLite3 already exists
if exist "C:\Program Files\SQLite\sqlite3.exe" (
    echo SQLite3 is already installed. >> C:\install_log.txt
    REM Show popup dialog asking for confirmation
    powershell -sta -command "Add-Type -AssemblyName System.Windows.Forms; $result = [System.Windows.Forms.MessageBox]::Show('SQLite3 is already installed. Do you want to remove and reinstall?', 'SQLite3 Installer', [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Question); if ($result -eq 'Yes') { exit 0 } else { exit 1 }"
    if errorlevel 1 (
        echo User chose to skip reinstall. >> C:\install_log.txt
        goto cleanup
    )
    echo User confirmed. Removing old installation... >> C:\install_log.txt
    rmdir /s /q "C:\Program Files\SQLite"
)
REM Create install directory
echo Installing SQLite3... >> C:\install_log.txt
mkdir "C:\Program Files\SQLite" >> C:\install_log.txt 2>&1
REM Copy sqlite3.exe from network share
copy "\\192.168.0.121\software\sqlite3.exe" "C:\Program Files\SQLite\sqlite3.exe" >> C:\install_log.txt 2>&1
REM Verify installation
echo Checking installation... >> C:\install_log.txt
if exist "C:\Program Files\SQLite\sqlite3.exe" (
    echo SUCCESS >> C:\install_log.txt
) else (
    echo FAILED >> C:\install_log.txt
    goto cleanup
)
REM Add SQLite3 to system PATH
echo Adding SQLite3 to system PATH... >> C:\install_log.txt
powershell -command "[System.Environment]::SetEnvironmentVariable('Path', [System.Environment]::GetEnvironmentVariable('Path','Machine') + ';C:\Program Files\SQLite', 'Machine')"
REM Create Desktop shortcut
echo Creating desktop shortcut... >> C:\install_log.txt
set "target=C:\Program Files\SQLite\sqlite3.exe"
set "desktop_shortcut=%PUBLIC%\Desktop\SQLite3.lnk"
powershell -command "$s=(New-Object -COM WScript.Shell).CreateShortcut('%desktop_shortcut%');$s.TargetPath='%target%';$s.Description='SQLite3 Command Line Tool';$s.Save()"
REM Create Start Menu shortcut (makes it appear in Windows Search)
echo Creating Start Menu shortcut... >> C:\install_log.txt
set "startmenu=%ProgramData%\Microsoft\Windows\Start Menu\Programs\SQLite3.lnk"
powershell -command "$s=(New-Object -COM WScript.Shell).CreateShortcut('%startmenu%');$s.TargetPath='%target%';$s.Description='SQLite3 Command Line Tool';$s.Save()"
echo ===== DONE ===== >> C:\install_log.txt
:cleanup
REM Disconnect network share
net use \\192.168.0.121\software /delete >> C:\install_log.txt 2>&1
exit
