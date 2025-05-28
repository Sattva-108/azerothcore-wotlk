@echo off
echo ===============================================
echo pfQuest Final Extraction - No Debug Limits
echo ===============================================
echo.

echo Analyzing current output...
C:\Lua51\lua5.1.exe analyze_output.lua
echo.

echo Running full extraction (this may take 5-10 minutes)...
echo Processing ALL creatures (no 1000 limit)
echo Processing ALL items (no 500 limit)
echo Debug prints removed
echo.

C:\Lua51\lua5.1.exe extractor.lua

echo.
echo ===============================================
echo Extraction completed!
echo ===============================================
echo.

echo Analyzing final output...
C:\Lua51\lua5.1.exe analyze_output.lua

echo.
echo Check output/ folder for results:
echo - units-wotlk.lua should contain coordinates for thousands of creatures
echo - objects-wotlk.lua should contain coordinates for game objects
echo - All other files should be complete
echo.

pause
