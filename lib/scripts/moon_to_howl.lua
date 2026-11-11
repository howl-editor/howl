-- Copyright 2026 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)
--
-- Converts MoonScript files to Howlscript, printing the result or writing it to
-- a .howl file in place of the .moon. Warnings, and errors compiling the result,
-- go to stderr.
--
-- Normally invoked via bin/howl-convert; directly it is
--
--   ./src/howl --run lib/scripts/moon_to_howl.lua [-w] [--spec] [--howl] <file>...

local convert = require('howlscript.convert')
local howlscript = require('howlscript')

local function read(path)
  local fh, err = io.open(path, 'rb')
  if not fh then return nil, err end
  local text = fh:read('*a')
  fh:close()
  return text
end

local function shell_quote(s)
  return "'" .. s:gsub("'", "'\\''") .. "'"
end

-- the year a file was first added, following renames
local function first_year(path)
  local p = io.popen('git log --follow --diff-filter=A --format=%ad --date=format:%Y -- '
    .. shell_quote(path) .. ' 2>/dev/null')
  local years = p:read('*a')
  p:close()
  return tonumber(years:match('(%d+)%s*$'))
end

local function is_tracked(path)
  return os.execute('git ls-files --error-unmatch -- ' .. shell_quote(path) .. ' >/dev/null 2>&1') == 0
end

local write, all_specs, howl_files = false, false, false
local files = {}
for _, arg in ipairs({ ... }) do
  if arg == '-w' or arg == '--write' then
    write = true
  elseif arg == '--spec' then
    all_specs = true
  elseif arg == '--howl' then
    howl_files = true
  else
    files[#files + 1] = arg
  end
end

local status = 0
local year = tonumber(os.date('%Y'))

for _, path in ipairs(files) do
  local src, err = read(path)
  if not src then
    io.stderr:write(('howl-convert: %s\n'):format(err))
    status = 1
  else
    local opts = { spec = all_specs or path:match('_spec%.moon$') ~= nil }
    if howl_files then
      opts.copyright = { year = year, first_year = first_year(path) or year }
    end
    local text, warnings = convert.convert(src, opts)
    local out_path = path:gsub('%.moon$', '') .. '.howl'
    if not text then
      io.stderr:write(('%s: %s\n'):format(path, warnings))
      status = 1
    else
      for _, w in ipairs(warnings) do
        io.stderr:write(('%s:%d: warning: %s\n'):format(path, w.line, w.message))
        status = 1
      end
      local lua, compile_err = howlscript.to_lua(text, { chunkname = '@' .. out_path })
      if not lua then
        io.stderr:write(compile_err .. '\n')
        status = 1
      end
      if write then
        local fh = assert(io.open(out_path, 'wb'))
        fh:write(text)
        fh:close()
        if is_tracked(path) then
          os.execute('git rm -q -- ' .. shell_quote(path))
        else
          os.remove(path)
        end
      else
        if #files > 1 then io.write(('-- >>> %s\n'):format(path)) end
        io.write(text)
      end
    end
  end
end

os.exit(status)
