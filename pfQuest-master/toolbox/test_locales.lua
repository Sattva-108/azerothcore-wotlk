#!/usr/bin/lua
-- Test script to check locale data in AzerothCore

package.path = package.path .. ';./lua-sql-mysql/src/?.lua'
luasql = require("luasql.mysql")

-- Database connection
local env = luasql.mysql()
local con = env:connect("acore_world", "acore", "acore", "127.0.0.1", 3306)

if con then
  print("Connected to database!")

  -- Check available locales in creature_template_locale
  print("\n=== Checking creature_template_locale ===")
  local query = con:execute("SELECT DISTINCT locale FROM creature_template_locale LIMIT 10")
  if query then
    local row = query:fetch({})
    while row do
      print("Found locale:", row[1])
      row = query:fetch({})
    end
    query:close()
  else
    print("No creature_template_locale table or data")
  end

  -- Check count of creatures with locale data
  print("\n=== Checking creature locale counts ===")
  local query2 = con:execute("SELECT locale, COUNT(*) as count FROM creature_template_locale GROUP BY locale")
  if query2 then
    local row = query2:fetch({})
    while row do
      print("Locale:", row[1], "Count:", row[2])
      row = query2:fetch({})
    end
    query2:close()
  end

  -- Check sample creature names
  print("\n=== Sample creature names ===")
  local query3 = con:execute("SELECT c.entry, c.name, cl.Name, cl.locale FROM creature_template c LEFT JOIN creature_template_locale cl ON cl.ID = c.entry WHERE cl.locale IS NOT NULL LIMIT 5")
  if query3 then
    local row = query3:fetch({})
    while row do
      print(string.format("ID: %s, Original: %s, Localized: %s, Locale: %s", row[1], row[2], row[3] or "NULL", row[4] or "NULL"))
      row = query3:fetch({})
    end
    query3:close()
  end

  con:close()
else
  print("Failed to connect to database!")
end

env:close()
