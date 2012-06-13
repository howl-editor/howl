local n, v = "serpent", 0.12 -- (C) 2012 Paul Kulchenko; MIT License
local c, d = "Paul Kulchenko", "Serializer and pretty printer of Lua data types"
local snum = {[tostring(1/0)]='1/0 --[[math.huge]]',[tostring(-1/0)]='-1/0 --[[-math.huge]]',[tostring(0/0)]='0/0'}
local badtype = {thread = true, userdata = true}
local keyword, globals, G = {}, {}, (_G or _ENV)
for _,k in ipairs({'and', 'break', 'do', 'else', 'elseif', 'end', 'false',
  'for', 'function', 'goto', 'if', 'in', 'local', 'nil', 'not', 'or', 'repeat',
  'return', 'then', 'true', 'until', 'while'}) do keyword[k] = true end
for k,v in pairs(G) do globals[v] = k end -- build func to name mapping
for _,g in ipairs({'coroutine', 'debug', 'io', 'math', 'string', 'table', 'os'}) do
  for k,v in pairs(G[g]) do globals[v] = g..'.'..k end end

local function s(t, opts)
  local name, indent, fatal = opts['name'], opts['indent'], opts['fatal']
  local sparse, nocode, custom = opts['sparse'], opts['nocode'], opts['custom']
  local huge, space = not opts['nohuge'], (opts['compact'] and '' or ' ')
  local seen, sref = {}, {}
  local function gensym(val) return tostring(val):gsub("[^%w]","") end
  local function safestr(s) return type(s) == "number" and (huge and snum[tostring(s)] or s)
    or type(s) ~= "string" and tostring(s) -- escape NEWLINE/010 and EOF/026
    or ("%q"):format(s):gsub("\010","n"):gsub("\026","\\026") end
  local function comment(s) return opts['comment'] and ' --[['..tostring(s)..']]' or '' end
  local function globerr(s) return globals[s] and globals[s]..comment(s) or not fatal
    and safestr(tostring(s))..' --[[err]]' or error("Can't serialize "..tostring(s)) end
  local function safename(path, name) -- generates foo.bar, foo[3], or foo['b a r']
    local n = name == nil and '' or name
    local plain = type(n) == "string" and n:match("^[%l%u_][%w_]*$") and not keyword[n]
    local safe = plain and n or '['..safestr(n)..']'
    return (path or '')..(plain and path and '.' or '')..safe, safe
  end
  local function alphanumsort(o, n)
    local maxn = tonumber(n) or 12
    local function padnum(d) return ("%0"..maxn.."d"):format(d) end
    table.sort(o, function(a,b)
      return tostring(a):gsub("%d+",padnum) < tostring(b):gsub("%d+",padnum) end)
  end
  local function val2str(t, name, indent, path, plainindex, level)
    local ttype, level = type(t), (level or 0)
    local spath, sname = safename(path, name)
    local tag = plainindex and
      ((type(name) == "number") and '' or name..space..'='..space) or
      (name ~= nil and sname..space..'='..space or '')
    if seen[t] then
      table.insert(sref, spath..space..'='..space..seen[t])
      return tag..'nil --[[ref]]'
    elseif badtype[ttype] then return tag..globerr(t)
    elseif ttype == 'function' then
      seen[t] = spath
      local ok, res = pcall(string.dump, t)
      local func = ok and (nocode and "function()error('dummy')end" or
        "loadstring("..safestr(res)..",'@serialized')"..comment(t))
      return tag..(func or globerr(t))
    elseif ttype == "table" then
      seen[t] = spath
      if next(t) == nil then return tag..'{}'..comment(t) end -- table empty
      local maxn, o, out = #t, {}, {}
      for key = 1, maxn do -- first array part
        if t[key] or not sparse then table.insert(o, key) end end
      for key in pairs(t) do -- then hash part (skip array keys up to maxn)
        if type(key) ~= "number" or key > maxn then table.insert(o, key) end end
      if opts['sortkeys'] then alphanumsort(o, opts['sortkeys']) end
      for n, key in ipairs(o) do
        local value, ktype, plainindex = t[key], type(key), n <= maxn and not sparse
        if badtype[ktype] then plainindex, key = true, '['..globerr(key)..']' end
        if ktype == 'table' or ktype == 'function' then
          if not seen[key] and not globals[key] then
            table.insert(sref, 'local '..val2str(key,gensym(key),indent)) end
          table.insert(sref, seen[t]..'['..(seen[key] or globals[key] or gensym(key))
            ..']'..space..'='..space..(seen[value] or val2str(value,nil,indent)))
        else table.insert(out,val2str(value,key,indent,spath,plainindex,level+1)) end
      end
      local prefix = string.rep(indent or '', level)
      local head = indent and '{\n'..prefix..indent or '{'
      local body = table.concat(out, ','..(indent and '\n'..prefix..indent or space))
      local tail = indent and "\n"..prefix..'}' or '}'
      return (custom and custom(tag,head,body,tail) or tag..head..body..tail)..comment(t)
    else return tag..safestr(t) end -- handle all other types
  end
  local sepr = indent and "\n" or ";"..space
  local body = val2str(t, name, indent) -- this call also populates sref
  local tail = #sref>0 and table.concat(sref, sepr)..sepr or ''
  return not name and body or "do local "..body..sepr..tail.."return "..name..sepr.."end"
end

local function merge(a, b) if b then for k,v in pairs(b) do a[k] = v end end; return a; end
return { _NAME = n, _COPYRIGHT = c, _DESCRIPTION = d, _VERSION = v, serialize = s,
  dump = function(a, opts) return s(a, merge({name = '_', compact = true, sparse = true}, opts)) end,
  line = function(a, opts) return s(a, merge({sortkeys = true, comment = true}, opts)) end,
  block = function(a, opts) return s(a, merge({indent = '  ', sortkeys = true, comment = true}, opts)) end }