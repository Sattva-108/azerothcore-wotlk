#!/usr/bin/lua

-- Script to create missing base files for pfQuest WotLK
-- Creates empty vanilla base files needed for proper addon loading

local output_dir = "output/"
local locales = {"enUS", "deDE", "frFR", "esES", "koKR", "ptBR", "ruRU", "zhCN", "zhTW"}

-- Function to write file
function write_file(filename, content)
    local file = io.open(filename, "w")
    if file then
        file:write(content)
        file:close()
        print("Created: " .. filename)
        return true
    else
        print("ERROR: Could not create " .. filename)
        return false
    end
end

print("=== Creating missing base files for pfQuest WotLK ===")

-- 1. Create main base files (vanilla data)
local main_files = {
    {file = "areatrigger.lua", var = "pfDB[\"areatrigger\"][\"data\"]", content = "{}"},
    {file = "items.lua", var = "pfDB[\"items\"][\"data\"]", content = "{}"},
    {file = "meta.lua", var = "pfDB[\"meta\"]", content = "{\n  [\"chests\"] = {},\n  [\"flight\"] = {},\n  [\"herbs\"] = {},\n  [\"mines\"] = {},\n  [\"rares\"] = {},\n}"},
    {file = "minimap.lua", var = "pfDB[\"minimap\"]", content = "{}"},
    {file = "objects.lua", var = "pfDB[\"objects\"][\"data\"]", content = "{}"},
    {file = "quests.lua", var = "pfDB[\"quests\"][\"data\"]", content = "{}"},
    {file = "quests-itemreq.lua", var = "pfDB[\"quests-itemreq\"][\"data\"]", content = "{}"},
    {file = "refloot.lua", var = "pfDB[\"refloot\"][\"data\"]", content = "{}"},
    {file = "units.lua", var = "pfDB[\"units\"][\"data\"]", content = "{}"},
    {file = "zones.lua", var = "pfDB[\"zones\"][\"data\"]", content = "{}"}
}

print("\n1. Creating main base files...")
for _, item in ipairs(main_files) do
    local content = item.var .. " = " .. item.content .. "\n"
    write_file(output_dir .. item.file, content)
end

-- 2. Create locale base files
print("\n2. Creating locale base files...")
for _, locale in ipairs(locales) do
    -- Create locale directory
    os.execute("mkdir \"" .. output_dir .. locale .. "\" 2>nul")

    local locale_files = {
        {file = "items.lua", var = "pfDB[\"items\"][\"" .. locale .. "\"]", content = "{}"},
        {file = "objects.lua", var = "pfDB[\"objects\"][\"" .. locale .. "\"]", content = "{}"},
        {file = "professions.lua", var = "pfDB[\"professions\"][\"" .. locale .. "\"]", content = "{}"},
        {file = "quests.lua", var = "pfDB[\"quests\"][\"" .. locale .. "\"]", content = "{}"},
        {file = "units.lua", var = "pfDB[\"units\"][\"" .. locale .. "\"]", content = "{}"},
        {file = "zones.lua", var = "pfDB[\"zones\"][\"" .. locale .. "\"]", content = "{}"}
    }

    for _, item in ipairs(locale_files) do
        local content = item.var .. " = " .. item.content .. "\n"
        write_file(output_dir .. locale .. "/" .. item.file, content)
    end
end

-- 3. Create correct init.lua (empty structure)
print("\n3. Creating corrected init.lua...")
local init_content = [[pfDB = {
  ["areatrigger"] = {},
  ["items"] = {},
  ["meta"] = {},
  ["meta-wotlk"] = {},
  ["minimap"] = {},
  ["minimap-wotlk"] = {},
  ["objects"] = {},
  ["professions"] = {},
  ["quests"] = {},
  ["quests-itemreq"] = {},
  ["refloot"] = {},
  ["units"] = {},
  ["zones"] = {},
}
]]

write_file(output_dir .. "init.lua", init_content)

print("\n=== Summary ===")
print("✅ Created 10 main base files")
print("✅ Created " .. (#locales * 6) .. " locale files (" .. #locales .. " locales × 6 files)")
print("✅ Fixed init.lua structure")
print("\nTotal files created: " .. (10 + (#locales * 6) + 1))
print("\n🎯 pfQuest WotLK database is now ready for addon loading!")
print("Files structure matches the expected format from working db/ directory.")
