-- Syntax check: lua5.1 Dev/check.lua *.lua UI/*.lua  (Dev/ never ships)
-- Also flags a top-level local used above its definition: Lua reads it as a
-- (nil) global there, which only fails in game.
local bad = 0
for _, f in ipairs(arg) do
  local fn, err = loadfile(f)
  if not fn then print(err); bad = bad + 1 end
  -- Code only: block comments, line comments and strings blanked.
  local lines, inBlock = {}, false
  for l in io.lines(f) do
    if inBlock then
      if l:find("%]%]") then inBlock = false end
      l = ""
    elseif l:find("^%s*%-%-%[%[") then
      inBlock = not l:find("%]%]"); l = ""
    end
    lines[#lines + 1] = l:gsub('"[^"]*"', '""'):gsub("'[^']*'", "''"):gsub("%-%-.*", "")
  end
  for i, l in ipairs(lines) do
    local name = l:match("^local function ([%w_]+)") or l:match("^local ([%w_]+)%s*=")
    if name then
      for j = 1, i - 1 do
        local code = " " .. lines[j]
        if code:find("[^%w_.:]" .. name .. "%f[^%w_]") and not code:find("^ local%s") then
          print(("%s:%d: '%s' used before its definition on line %d"):format(f, j, name, i)); bad = bad + 1
          break
        end
      end
    end
  end
end
print(#arg .. " files, " .. bad .. " problems")
os.exit(bad == 0 and 0 or 1)
