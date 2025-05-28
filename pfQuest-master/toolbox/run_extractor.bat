@echo off
echo Starting pfQuest extraction...
echo Using Lua 5.1 at: C:\Lua51\lua5.1.exe
echo Working directory: %CD%
echo.

C:\Lua51\lua5.1.exe extractor.lua

echo.
echo Extraction completed. Check the output above for results.
pause
