@echo off
REM Create junction link for pfQuest addon
REM This links the addon folder to WoW addons directory

echo Creating junction link for pfQuest addon...
echo Source: C:\Users\user\Desktop\azerothcore-wotlk\pfQuest-master
echo Target: E:\3.3.5\interface\addons\pfQuest-wotlk

REM Remove existing link if it exists
if exist "E:\3.3.5\interface\addons\pfQuest-wotlk" (
    echo Removing existing link...
    rmdir "E:\3.3.5\interface\addons\pfQuest-wotlk"
)

REM Create junction link
mklink /J "E:\3.3.5\interface\addons\pfQuest-wotlk" "C:\Users\user\Desktop\azerothcore-wotlk\pfQuest-master"

if %errorlevel% equ 0 (
    echo SUCCESS: Junction link created!
    echo Game will see addon at: E:\3.3.5\interface\addons\pfQuest-wotlk
    echo But files are actually in: C:\Users\user\Desktop\azerothcore-wotlk\pfQuest-master
) else (
    echo ERROR: Failed to create junction link
    echo Make sure you run this as Administrator
)

pause
