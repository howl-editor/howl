-- Copyright 2026 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

-- Lexical scopes, as the compiler walks the AST. A scope holds the locals declared
-- in it, and the names that `export` makes global.

jit.off(true, true) -- see the note in compiler.lua

local Scope = {}
Scope.__index = Scope

local function new(parent)
  return setmetatable({
    parent = parent,
    names = {},
    exported = {},
    export_all = false,
  }, Scope)
end

function Scope:declare(name, line)
  self.names[name] = { line = line }
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

-- Whether assigning to `name`, when no local of that name is visible, assigns a
-- global. `export name` holds for nested scopes too, while `export *` only covers
-- the scope it's in.
function Scope:is_exported(name)
  if self.export_all then return true end
  local scope = self
  while scope do
    if scope.exported[name] then return true end
    scope = scope.parent
  end
  return false
end

-- Whether an assignment to `name` declares a new local.
function Scope:is_fresh(name)
  return not self:lookup(name) and not self:is_exported(name)
end

return {
  new = new,
}
