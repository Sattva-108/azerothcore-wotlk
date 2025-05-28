#!/bin/bash

echo "=== Setting up pfquest database for extractor ==="

# Step 1: Create pfquest database
echo "1. Creating pfquest database..."
mysql -u acore -pacore < create_pfquest_db.sql

if [ $? -ne 0 ]; then
    echo "ERROR: Failed to create pfquest database"
    exit 1
fi

echo "SUCCESS: pfquest database created"

# Step 2: Load DBC tables into pfquest database
echo "2. Loading DBC tables into pfquest database..."
mysql -u acore -pacore pfquest < client-data.sql

if [ $? -eq 0 ]; then
    echo "SUCCESS: All DBC tables loaded into pfquest database!"
    echo ""
    echo "Tables available:"
    echo "- AreaTrigger_wotlk"
    echo "- WorldMapArea_wotlk"
    echo "- WorldMapOverlay_wotlk"
    echo "- FactionTemplate_wotlk"
    echo "- Lock_wotlk"
    echo "- SkillLine_wotlk"
    echo "- AreaTable_wotlk"
    echo ""
    echo "You can now run: lua extractor.lua"
else
    echo "ERROR: Failed to load client-data.sql into pfquest database"
    echo "Check client-data.sql for syntax errors"
    exit 1
fi
