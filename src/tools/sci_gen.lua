#! /usr/bin/env lua

--[[
(C) 2012 Nils Nordman <nino at nordman.org>

Generates a Lua interface for Scintilla using the latter's interface file.
]]

local iface, target = ...

if not iface or not target then
  error('Usage: <interface-file> <target-file>')
end

local name_replacements = {
  start = 'start_pos',
  ['end']  = 'end_pos',
}

local outdata_types = {
  stringresult = 1,
  textrange = 1,
  findtext = 1,
}

local function adjust_name(name)
  if not name then return name end
  name = name:gsub('%l%u', function(match)
    return match:gsub('%u', function(upper) return '_' .. upper:lower() end)
  end):lower()
  return name_replacements[name] or name
end

local function scan(iface)
  local constants = {}
  local methods = {}
  local cur_doc = {}
  for line in io.lines(iface) do
    local doc = line:match('^%s*#%s*(.+)%s*$')
    if doc then
      cur_doc[#cur_doc + 1] = doc
    elseif line:match('^%s*$') then
      cur_doc = {}
    else
      local op, rest = line:match('^(%w+)%s(.+)$')
      if op == 'val' then
        local key, value = rest:match('(%S+)=(%S+)')
        if key then
          constants[#constants + 1] = { name = key, value = value }
        end
      elseif op == 'fun' or op == 'set' or op == 'get' then
        local ret, name, number, p_string = rest:match('(%S+)%s(%S+)=(%d+)%(([^)]+)%)')
        if ret then
          local params = {}
          local t, n = p_string:match('(%w+)%s+(%w+),')
          if t then params.first = { what = t, name = adjust_name(n) } end
          t, n = p_string:match('(%w+)%s+(%w+)$')
          if t then params.second = { what = t, name = adjust_name(n) } end

          methods[#methods + 1] = {
            name = adjust_name(name),
            ret = ret,
            number = number,
            params = params,
            doc = cur_doc
          }

          -- Recreate the SCI_* constants as well
          constants[#constants + 1] = { name = 'SCI_' .. name:upper(), value = number }

        end
      elseif op == 'evt' then
        name, number = rest:match('%w+%s(%S+)=(%d+)')
        if name then
          constants[#constants + 1] = { name = 'SCN_' .. name:upper(), value = number }
        end
      end
    end
  end
  return constants, methods
end

local function write_outdata_method(m, out)
  local p = m.params
  local what = p.second.what
  local call_p = { p.first and p.first.name }

  if what == 'textrange' then
    call_p = { 'start_pos', 'end_pos' }
  elseif what == 'findtext' then
    call_p = { 'start_pos', 'end_pos', 'text' }
  end

  out:write('function sci:' .. m.name .. '(')
  out:write(table.concat(call_p, ', '))
  out:write(')\n')
  out:write('  return self:send_with_' .. what .. '(' .. m.number )
  if #call_p > 0 then
    out:write(', ', table.concat(call_p, ', '))
  end
  out:write(')\n')
  out:write('end\n')
end

local function return_with_cast(expr, ret_type)
  if ret_type == 'void' then return expr
  elseif ret_type == 'bool' then return 'return 0 ~= ' .. expr
  else return 'return tonumber(' .. expr .. ')' end
end

local function write_plain_method(m, out)
  local p = m.params
  out:write('function sci:' .. m.name .. '(')
  if p.first then out:write(p.first.name) end
  if p.second then
    if p.first then out:write(', ') end
    out:write(p.second.name)
  end
  out:write(')\n')
  inv = 'self:send(' .. m.number .. ', '

  if p.first then inv = inv .. p.first.name .. ', '
  else inv = inv .. '0, ' end

  if p.second then inv = inv .. p.second.name
  else inv = inv .. '0' end

  inv = inv .. ')'

  out:write('  ' .. return_with_cast(inv, m.ret) .. '\n')
  out:write('end\n')
end

local function write_method(m, out)
  local p = m.params
  if #m.doc then
    for i, comment in ipairs(m.doc) do
      out:write('-- ' .. comment .. '\n')
    end
  end

  if p.second and outdata_types[p.second.what] then
    write_outdata_method(m, out)
  else
    write_plain_method(m, out)
  end

  out:write('\n')
end

local function update(target, constants, methods)
  local lines = {}
  for line in io.lines(target) do lines[#lines + 1] = line end
  local t = assert(io.open(target, 'w'))
  local in_auto = false
  for i, line in ipairs(lines) do
    if in_auto then
      if line:match('!! End auto') then
        t:write(line, '\n')
        in_auto = false
      end
    else
      t:write(line, '\n')
      if line:match('!! Begin auto') then
        t:write('\n')
        in_auto = true

        for i, v in ipairs(constants) do
          if not v.name:match('^SCE') then
            t:write(v.name .. ' = ' .. v.value .. '\n')
          end
        end

        t:write('\n')

        for _, m in ipairs(methods) do
          write_method(m, t)
        end
      end
    end
  end
  t:close()
end

print('Scanning ' .. iface .. '..')
local constants, methods = scan(iface)

print('Updating ' .. target .. '..')
update(target, constants, methods)
