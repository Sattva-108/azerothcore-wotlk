-- Simple database test
package.path = package.path .. ';./lua-sql-mysql/src/?.lua'
luasql = require("luasql.mysql")

print("Testing database connection...")

local env = luasql.mysql()
if not env then
    error("Failed to create MySQL environment")
end

local mysql, err = env:connect("acore_world", "acore", "acore", "127.0.0.1", 3306)
if not mysql then
    error("Database connection failed: " .. (err or "unknown error"))
end

print("Connection successful!")

-- Test creature count
local query = mysql:execute('SELECT COUNT(*) as total FROM creature_template')
local result = {}
query:fetch(result, "a")
print("Total creatures in database: " .. (result.total or "unknown"))

-- Test first few creatures
print("\nFirst 5 creatures:")
local creature_query = mysql:execute('SELECT entry, name FROM creature_template ORDER BY entry LIMIT 5')
local creature = {}
while creature_query:fetch(creature, "a") do
    print("  " .. creature.entry .. ": " .. creature.name)
end

mysql:close()
env:close()
print("Test completed successfully!")
