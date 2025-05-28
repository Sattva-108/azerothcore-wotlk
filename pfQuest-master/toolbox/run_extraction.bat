@echo off
echo ===============================================
echo pfQuest Extractor for AzerothCore WotLK
echo ===============================================
echo.

echo Step 1: Loading DBC data into database...
lua load_dbc.lua
if errorlevel 1 (
    echo ERROR: Failed to load DBC data
    echo.
    goto :end
)

echo.
echo Step 2: Running pfQuest extractor...
lua extractor.lua
if errorlevel 1 (
    echo ERROR: Failed to run extractor
    echo.
    goto :end
)

echo.
echo ===============================================
echo SUCCESS: pfQuest extraction completed!
echo ===============================================
echo.
echo Output files created in: output/
echo - areatrigger-wotlk.lua
echo - units-wotlk.lua
echo - objects-wotlk.lua
echo - items-wotlk.lua
echo - quests-wotlk.lua
echo - meta-wotlk.lua
echo - minimap-wotlk.lua
echo - zones-wotlk.lua
echo - localization files in enUS/ folder
echo.

:end
