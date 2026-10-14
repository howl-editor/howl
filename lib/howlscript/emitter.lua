-- Copyright 2026 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

-- Collects the Lua output, keeping it aligned with the source lines.
--
-- Before code from source line L is written, `at(L)` pads the output with line
-- breaks until it is on line L. It never goes backwards: code generated for a line
-- that's already passed shares the current line. So every statement starts on the
-- line it starts on in the source, and errors and tracebacks from the Lua point
-- straight into the Howlscript, with no line mapping. Padded lines get the
-- indentation of the source line, to keep the output readable.

local byte, find, match, gmatch = string.byte, string.find, string.match, string.gmatch

jit.off(true, true) -- see the note in compiler.lua

local Emitter = {}
Emitter.__index = Emitter

local function new(source)
  local indents = {}
  local nr = 1
  for line in gmatch(source .. '\n', '([^\n]*)\n') do
    indents[nr] = match(line, '^[ \t]*')
    nr = nr + 1
  end

  return setmetatable({
    buf = {},
    line = 1,
    bol = true, -- nothing but indentation written on the current line
    stmt_start = false,
    indents = indents,
  }, Emitter)
end

function Emitter:w(s)
  if s == '' then return end
  if self.stmt_start then
    self.stmt_start = false
    -- a statement starting with '(' would continue the previous one as a call
    if byte(s, 1) == 40 then
      self.buf[#self.buf + 1] = ';'
    end
  end
  self.buf[#self.buf + 1] = s

  local pos = find(s, '\n', 1, true)
  while pos do
    self.line = self.line + 1
    pos = find(s, '\n', pos + 1, true)
  end
  self.bol = byte(s, -1) == 10
end

function Emitter:at(line)
  if line and line > self.line then
    self.buf[#self.buf + 1] = string.rep('\n', line - self.line) .. (self.indents[line] or '')
    self.line = line
    self.bol = true
  end
end

-- Separates what follows from what's already on the line.
function Emitter:sp(line)
  self:at(line)
  if not self.bol then
    self.buf[#self.buf + 1] = ' '
  end
  self.bol = false
end

-- Starts a statement, on `line` if given.
function Emitter:stmt(line)
  self:sp(line)
  self.stmt_start = true
end

function Emitter:result()
  return table.concat(self.buf)
end

return {
  new = new,
}
