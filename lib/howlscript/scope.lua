-- Copyright 2026 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

-- Lexical scopes, as the compiler walks the AST. A scope holds the locals declared
-- in it.

jit.off(true, true) -- see the note in compiler.lua

local Scope = {}
Scope.__index = Scope

local function new(parent)
  return setmetatable({
    parent = parent,
    names = {},
  }, Scope)
end

function Scope:declare(name, line)
  local decl = { line = line }
  self.names[name] = decl
  return decl
end

-- The declaration of the local `name` visible from this scope, if any.
function Scope:lookup(name)
  local scope = self
  while scope do
    local decl = scope.names[name]
    if decl then return decl end
    scope = scope.parent
  end
end

-- Whether an assignment to `name` declares a new local: whenever no local of that
-- name is visible, as globals are only assigned through _G.
function Scope:is_fresh(name)
  return not self:lookup(name)
end

return {
  new = new,
}
