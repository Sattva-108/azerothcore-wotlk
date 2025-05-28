print("Testing Lua execution...")
print("Current working directory: " .. (io.popen("cd"):read() or "unknown"))
os.exit(0)
