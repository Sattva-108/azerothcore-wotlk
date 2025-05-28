-- Copy generated files to db folder
local lfs = require("lfs")

local function copy_file(source, dest)
    local infile = io.open(source, "rb")
    if not infile then
        print("Error: Could not open source file: " .. source)
        return false
    end

    local outfile = io.open(dest, "wb")
    if not outfile then
        print("Error: Could not create destination file: " .. dest)
        infile:close()
        return false
    end

    local data = infile:read("*all")
    outfile:write(data)

    infile:close()
    outfile:close()

    print("Copied: " .. source .. " -> " .. dest)
    return true
end

local function copy_directory(source_dir, dest_dir)
    for file in lfs.dir(source_dir) do
        if file ~= "." and file ~= ".." then
            local source_path = source_dir .. "/" .. file
            local dest_path = dest_dir .. "/" .. file

            local attr = lfs.attributes(source_path)
            if attr.mode == "directory" then
                -- Create directory if it doesn't exist
                lfs.mkdir(dest_path)
                copy_directory(source_path, dest_path)
            else
                copy_file(source_path, dest_path)
            end
        end
    end
end

print("Copying files from toolbox/output to db/...")
copy_directory("output", "../db")
print("Copy completed!")
