-- Syntax check: lua5.1 Dev/check.lua *.lua  (Dev/ never ships)
local bad = 0
for _, f in ipairs(arg) do
  local fn, err = loadfile(f)
  if not fn then print(err); bad = bad + 1 end
end
print(#arg .. " files, " .. bad .. " with syntax errors")
os.exit(bad == 0 and 0 or 1)
