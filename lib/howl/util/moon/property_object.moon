-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

-- A subclass's __base inherits from its parent's through __index, so a plain
-- lookup finds the parent's table and writing to it would clobber the parent's
-- properties (and those of any sibling subclass). Give each class a table of
-- its own, chained to the inherited one so parent properties still resolve.
class_properties = (base) ->
  props = rawget base, '__properties'
  unless props
    inherited = base.__properties
    props = inherited and setmetatable({}, {__index: inherited}) or {}
    rawset base, '__properties', props
  props

-- Metas need the same separation, but they're applied by iterating with pairs,
-- which doesn't follow __index - so inherited entries are copied in instead.
meta_methods = (base) ->
  metas = rawget base, '__metas'
  unless metas
    metas = {}
    inherited = base.__metas
    if inherited
      metas[k] = v for k, v in pairs inherited
    rawset base, '__metas', metas
  metas

delegate = (target, key) ->
  return nil unless target
  val = target[key]
  return val unless callable val
  return (self, ...) ->
    val(target, ...)

__index = (key) =>
  base = getmetatable self
  prop = base.__properties[key]
  return prop.get self if prop and prop.get
  v = base[key]
  return v if v
  target = base.__delegate_target
  target and delegate target, key

__newindex = (key, value) =>
  base = getmetatable self
  prop = base.__properties[key]
  if prop
    if prop.set
      prop.set self, value
    else
      error 'Attempt to set read-only property "' .. key .. '"', 1
  else
    rawset self, key, value

class PropertyObject
  new: (delegate_target) =>
    base = getmetatable self
    class_properties base
    rawset base, '__delegate_target', delegate_target if delegate_target
    base.__index = __index
    base.__newindex = __newindex
    for k, v in pairs meta_methods base
      rawset base, k, v

  property: (cls, tbl) ->
    properties = class_properties cls.__base
    properties[k] = v for k,v in pairs tbl

  meta: (cls, tbl) ->
    metas = meta_methods cls.__base
    metas[k] = v for k,v in pairs tbl

return PropertyObject
