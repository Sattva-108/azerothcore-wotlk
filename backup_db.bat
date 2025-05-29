@echo off
echo Creating backup of db folder...

REM Create timestamp
for /f "tokens=2-4 delims=/ " %%a in ('date /t') do (set mydate=%%c-%%a-%%b)
for /f "tokens=1-2 delims=/:" %%a in ('time /t') do (set mytime=%%a%%b)
set datetime=%mydate%_%mytime%

REM Create backup
xcopy "C:\Users\user\Desktop\azerothcore-wotlk\pfQuest-master\db" "C:\Users\user\Desktop\azerothcore-wotlk\pfQuest-master\db-backup-%datetime%" /E /I /H /Y

echo Backup created: db-backup-%datetime%
echo.
echo IMPORTANT: Only modify files in db/ folder manually!
echo Don't let codemcp overwrite your changes!
pause
