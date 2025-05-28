#!/bin/bash

# Load client-data.sql into MySQL database
echo "Loading client-data.sql into acore_world database..."

# Check if client-data.sql exists
if [ ! -f "client-data.sql" ]; then
    echo "Error: client-data.sql not found!"
    exit 1
fi

# Load the SQL file
mysql -u acore -pacore acore_world < client-data.sql

if [ $? -eq 0 ]; then
    echo "SUCCESS: client-data.sql loaded successfully!"
    echo "Tables created: Lock_wotlk, AreaTable_wotlk, FactionTemplate_wotlk, etc."
else
    echo "ERROR: Failed to load client-data.sql"
    exit 1
fi

echo "You can now run: lua extractor.lua"
