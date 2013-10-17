------------------------------------------------------------------------------
--
--  LGI Gtk3 override module.
--
--  Copyright (c) 2010, 2011 Pavel Holejsovsky
--  Licensed under the MIT license:
--  http://www.opensource.org/licenses/mit-license.php
--
------------------------------------------------------------------------------

local select, type, pairs, ipairs, unpack, setmetatable, error, next, rawget
   = select, type, pairs, ipairs, unpack, setmetatable, error, next, rawget
local lgi = require 'lgi'
local core = require 'lgi.core'
local Gtk = lgi.Gtk
local Gdk = lgi.Gdk
local GObject = lgi.GObject
local cairo = lgi.cairo

local log = lgi.log.domain('lgi.Gtk')

-- Initialize GTK.
Gtk.disable_setlocale()
assert(Gtk.init_check())

-- Gtk.Allocation is just an alias to Gdk.Rectangle.
Gtk.Allocation = Gdk.Rectangle

-------------------------------- Gtk.Widget overrides.
Gtk.Widget._attribute = {
   width = { get = Gtk.Widget.get_allocated_width },
   height = { get = Gtk.Widget.get_allocated_height },
   events = {},
   style = {},
}

-- Add widget attributes for some get/set method combinations not covered by
-- native widget properties.
for _, name in pairs { 'allocation', 'direction', 'settings', 'realized',
		       'mapped', 'display', 'screen', 'window', 'root_window',
		       'has_window', 'style_context' } do
   if not Gtk.Widget._property[name] then
      local attr = { get = Gtk.Widget['get_' .. name],
		     set = Gtk.Widget['set_' .. name] }
      if next(attr) then
	 Gtk.Widget._attribute[name] = attr
      end
   end
end

function Gtk.Widget._attribute.width:set(width)
   self.width_request = width
end

function Gtk.Widget._attribute.height:set(height)
   self.height_request = height
end

-- gtk_widget_intersect is missing an (out caller-allocates) annotation
if core.gi.Gtk.Widget.methods.intersect.args[2].direction == 'in' then
   local real_intersect = Gtk.Widget.intersect
   function Gtk.Widget._method:intersect(area)
      local intersection = Gdk.Rectangle()
      local notempty = real_intersect(self, area, intersection)
      return notempty and intersection or nil
   end
end

function Gtk.Widget._attribute.events:get()
   return Gdk.EventMask[self:get_events()]
end

function Gtk.Widget._attribute.events:set(events)
   self:set_events(Gdk.EventMask(events))
end

-- Accessing style properties is preferrably done by accessing 'style'
-- property.  In case that caller wants deprecated 'style' property, it
-- must be accessed by '_property_style' name.
local widget_style_mt = {}
function widget_style_mt:__index(name)
   name = name:gsub('_', '-')
   local pspec = self._widget._class:find_style_property(name)
   if not pspec then
      error(("%s: no style property `%s'"):format(
	       self._widget.type._name, name:gsub('%-', '_')), 2)
   end
   local value = GObject.Value(pspec.value_type)
   self._widget:style_get_property(name, value)
   return value.value
end
function Gtk.Widget._attribute.style:get()
   return setmetatable({ _widget = self }, widget_style_mt)
end

-- Get/Set widget from Gdk.Window
function Gdk.Window:get_widget()
   return core.object.new(self:get_user_data(), false)
end
function Gdk.Window:set_widget(widget)
   self:set_user_data(widget)
end
Gdk.Window._attribute = rawget(Gdk.Window, '_attribute') or {}
Gdk.Window._attribute.widget = {
   set = Gdk.Window.set_widget,
   get = Gdk.Window.get_widget,
}

-------------------------------- Gtk.Buildable overrides.
Gtk.Buildable._attribute = { id = {}, child = {} }

-- Create custom 'id' property, mapped to buildable name.
function Gtk.Buildable._attribute.id:set(id)
   core.object.env(self).id = id
end
function Gtk.Buildable._attribute.id:get()
   return core.object.env(self).id
end

-- Custom 'child' property, which returns widget in the subhierarchy
-- with specified id.
local buildable_child_mt = {}
function buildable_child_mt:__index(id)
   return self._buildable.id == id and self._buildable or nil
end
function Gtk.Buildable._attribute.child:get()
   return setmetatable({ _buildable = self }, buildable_child_mt)
end

-------------------------------- Gtk.Container overrides.
Gtk.Container._attribute = {}

-- Extand add() functionality to allow adding child properties.
function Gtk.Container:add(widget, props)
   if type(widget) == 'table' then
      props = widget
      widget = widget[1]
   end
   Gtk.Container._method.add(self, widget)
   if props then
      local properties = self.property[widget]
      for name, value in pairs(props) do
	 if type(name) == 'string' then
	    properties[name] = value
	 end
      end
   end
end

-- Map 'add' method also to '_container_add', so that ctor can use it
-- for adding widgets from the array part.
Gtk.Container._container_add = Gtk.Container.add

-- Accessing child properties is preferrably done by accessing
-- 'property' attribute.
Gtk.Container._attribute.property = {}
local container_property_item_mt = {}
function container_property_item_mt:__index(name)
   name = name:gsub('_', '-')
   local pspec = self._container._class:find_child_property(name)
   if not pspec then
      error(("%s: no child property `%s'"):format(
	       self._container.type._name, name:gsub('%-', '_')), 2)
   end
   local value = GObject.Value(pspec.value_type)
   self._container:child_get_property(self._child, name, value)
   return value.value
end
function container_property_item_mt:__newindex(name, val)
   name = name:gsub('_', '-')
   local pspec = self._container._class:find_child_property(name)
   if not pspec then
      error(("%s: no child property `%s'"):format(
	       self._container.type._name, name:gsub('%-', '_')), 2)
   end
   local value = GObject.Value(pspec.value_type, val)
   self._container:child_set_property(self._child, name, value)
end
local container_property_mt = {}
function container_property_mt:__index(child)
   if type(child) == 'string' then child = self._container.child[child] end
   return setmetatable({ _container = self._container, _child = child },
		       container_property_item_mt)
end
function Gtk.Container._attribute.property:get()
   return setmetatable({ _container = self }, container_property_mt)
end

-- Override 'child' attribute; writing allows adding child with
-- children properties (similarly as add() override), reading provides
-- table which can lookup subchildren by Gtk.Buildable.id.
Gtk.Container._attribute.child = {}
local container_child_mt = {}
function container_child_mt:__index(id)
   local found = (core.object.env(self._container).id == id
	       and self._container)
   if not found then
      for _, child in ipairs(self) do
	 found = child.child[id]
	 if found then break end
      end
   end
   return found or nil
end
function Gtk.Container._attribute.child:get()
   local children = self:get_children()
   children._container = self
   return setmetatable(children, container_child_mt)
end
function Gtk.Container._attribute.child:set(widget)
   self:add(widget)
end

-------------------------------- Gtk.Builder overrides.
Gtk.Builder._attribute = {}

-- Override add_from_ family of functions, their C-signatures are
-- completely braindead.
local function builder_fix_return(res, e1, e2)
   if res and res ~= 0 then return true end
   return false, e1, e2
end
function Gtk.Builder:add_from_file(filename)
   return builder_fix_return(Gtk.Builder._method.add_from_file(self, filename))
end
function Gtk.Builder:add_objects_from_file(filename, object_ids)
   return builder_fix_return(Gtk.Builder._method.add_objects_from_file(
				self, filename, object_ids))
end
function Gtk.Builder:add_from_string(string, len)
   if not len or len == -1 then len = #string end
   return builder_fix_return(Gtk.Builder._method.add_from_string(
				self, string, len))
end
function Gtk.Builder:add_objects_from_string(string, len, object_ids)
   if not len or len == -1 then len = #string end
   return builder_fix_return(Gtk.Builder._method.add_objects_from_string(
				self, string, len, object_ids))
end

-- Wrapping get_object() using 'objects' attribute.
Gtk.Builder._attribute.objects = {}
local builder_objects_mt = {}
function builder_objects_mt:__index(name)
   return self._builder:get_object(name)
end
function Gtk.Builder._attribute.objects:get()
   return setmetatable({ _builder = self }, builder_objects_mt)
end

-- Implementation of connect_signals() method.
function Gtk.Builder._method:connect_signals(handlers)
   local unconnected
   self:connect_signals_full(
      function(builder, object, signal, handler, connect_object, flags)
	 signal = 'on_' .. signal:gsub('%-', '_')
	 local target = handlers[handler]
	 if not target then
	    unconnected = unconnected or {}
	    unconnected[#unconnected + 1] = handler
	    log.warning("%s: failed to connect to `%s' handler",
			signal, handler)
	    return
	 end
	 local fun
	 if connect_object then
	    fun = function(_, ...) return target(connect_object, ...) end
	 else
	    fun = target
	 end
	 object[signal]:connect(fun, nil, flags.AFTER)
      end)
   return unconnected
end

-------------------------------- Gtk.TextTagTable overrides.
Gtk.TextTagTable._attribute = { tag = {} }

local text_tag_table_tag_mt = {}
function text_tag_table_tag_mt:__index(id)
   return self._table:lookup(id)
end
function Gtk.TextTagTable._attribute.tag:get()
   return setmetatable({ _table = self }, text_tag_table_tag_mt)
end

-- Map adding of tags in constructor array part to add() method.
Gtk.TextTagTable._container_add = Gtk.TextTagTable.add

-------------------------------- Gtk.TreeModel and relatives.
Gtk.TreeModel._attribute = {}

local tree_model_item_mt = {}
function tree_model_item_mt:__index(column)
   return self._model:get_value(self._iter, column - 1).value
end
function tree_model_item_mt:__newindex(column, val)
   column = column - 1
   local value = GObject.Value(self._model:get_column_type(column), val)
   self._model:set_value(self._iter, column, value)
end

-- Map access of lines to iterators by directly indexing treemodel
-- instance values with iterators.
local tree_model_element = Gtk.TreeModel._element
function Gtk.TreeModel:_element(model, key)
   if Gtk.TreeIter:is_type_of(key) then
      return key, '_iter'
   elseif Gtk.TreePath:is_type_of(key) then
      return model:get_iter(key), '_iter'
   end
   return tree_model_element(self, model, key)
end
function Gtk.TreeModel:_access_iter(model, iter, ...)
   if select('#', ...) > 0 then
      model:set(iter, ...)
   else
      -- Return proxy table allowing getting/setting individual columns.
      return setmetatable({ _model = model, _iter = iter }, tree_model_item_mt)
   end
end

local function treemodel_prepare_values(model, values)
   local cols, vals = {}, {}
   for column, value in pairs(values) do
      column = column - 1
      cols[#cols + 1] = column
      vals[#vals + 1] = GObject.Value(model:get_column_type(column), value)
   end
   return cols, vals
end
function Gtk.TreeModel:set(iter, values)
   -- Set all values provided by the table
   if Gtk.TreePath:is_type_of(iter) then iter = self:get_iter(iter) end
   self:set_values(iter, treemodel_prepare_values(self, values))
end

-- Implement iteration protocol for model.
function Gtk.TreeModel:next(iter)
   if not iter or type(iter) == 'table' then
      -- Start iteration.
      iter = self:iter_children(iter and iter[1])
   else
      -- Continue to the next child.
      if not self:iter_next(iter) then iter = nil end
   end
   return iter, iter and Gtk.TreeModel:_access_iter(self, iter)
end
function Gtk.TreeModel:pairs(parent)
   return Gtk.TreeModel.next, self, parent and { parent }
end

-- Redirect 'set' method to our one inherited from TreeModel, it is
-- the preferred one.  Rename the original to set_values().
Gtk.ListStore._method.set_values = Gtk.ListStore.set
Gtk.ListStore._method.set = nil

-- Allow insert() and append() to handle also 'with_values' case.
function Gtk.ListStore:insert(position, values)
   local iter
   if not values then
      iter = Gtk.ListStore._method.insert(self, position)
   else
      iter = Gtk.ListStore._method.insert_with_valuesv(
	 self, position, treemodel_prepare_values(self, values))
   end
   return iter
end
if not Gtk.ListStore._method.insert_with_values then
   Gtk.ListStore._method.insert_with_values =
      Gtk.ListStore._method.insert_with_valuesv
end
function Gtk.ListStore:append(values)
   local iter
   if not values then
      iter = Gtk.ListStore._method.append(self)
   else
      iter = Gtk.ListStore._method.insert_with_values(
	 self, -1, treemodel_prepare_values(self, values))
   end
   return iter
end

-- Similar treatment for treestore.
Gtk.TreeStore._method.set_values = Gtk.TreeStore.set
Gtk.TreeStore._method.set = nil
function Gtk.TreeStore:insert(parent, position, values)
   local iter
   if not values then
      iter = Gtk.TreeStore._method.insert(self, parent, position)
   else
      iter = Gtk.TreeStore._method.insert_with_values(
	 self, parent, position, treemodel_prepare_values(self, values))
   end
   return iter
end
function Gtk.TreeStore:append(parent, values)
   local iter
   if not values then
      iter = Gtk.TreeStore._method.append(self, parent)
   else
      iter = Gtk.TreeStore._method.insert_with_values(
	 self, parent, -1, treemodel_prepare_values(self, values))
   end
   return iter
end

-- Add missing constants, defined as anonymous enums in C headers, which
-- is not supported by GIR yet.
Gtk.TreeSortable.DEFAULT_SORT_COLUMN_ID = -1
Gtk.TreeSortable.UNSORTED_SORT_COLUMN_ID = -2

-------------------------------- Gtk.TreeView and support.
-- Array part in constructor specifies columns to add.
Gtk.TreeView._container_add = Gtk.TreeView.append_column

-- Allow looking up tree column as child of the tree.
Gtk.TreeView._attribute = {
   child = { set = Gtk.TreeView._parent._attribute.child.set }
}
local treeview_child_mt = {}
function treeview_child_mt:__index(id)
   if self._view.id == id then return self._view end
   for _, column in ipairs(self._view:get_columns()) do
      local child = column.child[id]
      if child then return child end
   end
end
function Gtk.TreeView._attribute.child:get()
   return setmetatable({ _view = self }, treeview_child_mt)
end

-- Sets attributes for specified cell.
function Gtk.CellLayout:set(cell, data)
   if type(data) == 'table' then
      for attr, column in pairs(data) do
	 self:add_attribute(cell, attr, column - 1)
      end
   else
      self:set_cell_data_func(cell, data)
   end
end

-- Adds new cellrenderer with full definition into the column.
function Gtk.CellLayout:add(def)
   if def.align == 'start' then
      self:pack_start(def[1], def.expand)
   else
      self:pack_end(def[1], def.expand)
   end

   -- Set attributes.
   self:set(def[1], def[2])
   if def.data_func then self:set_cell_data_func(def[1], def.data_func) end
end

-- Unfortunately, CellView is interface often implemented by descendants
-- of Gtk.Container, so we cannot reuse generic _container_add here,
-- because it is already occupied by implementing container's ctor.  So
-- instead add attribute 'cells' which can be assigned the list of cell
-- data definitions.
Gtk.CellLayout._attribute = { cells = {}, child = {} }
function Gtk.CellLayout._attribute.cells:set(cells)
   for _, data in ipairs(cells) do Gtk.CellLayout.add(self, data) end
end

-- Allow lookuing up rendereres by assigned id.
Gtk.CellRenderer._attribute = { id = Gtk.Buildable._attribute.id }
local celllayout_child_mt = {}
function celllayout_child_mt:__index(id)
   if id == self._layout.id then return self._layout end
   for _, renderer in ipairs(self._layout:get_cells()) do
      if renderer.id == id then return renderer end
   end
end
function Gtk.CellLayout._attribute.child:get()
   return setmetatable({ _layout = self }, celllayout_child_mt)
end

Gtk.TreeViewColumn._container_add = Gtk.TreeViewColumn.add

-------------------------------- Gtk.Action and relatives
function Gtk.ActionGroup:add(action)
   if type(action) == 'table' then
      if action.accelerator then
	 -- Add with an accelerator.
	 self:add_action_with_accel(action[1], action.accelerator)
	 return action[1]
      end

      -- Go through all actions in the table and add them.
      local first_radio
      for i = 1, #action do
	 local added = self:add(action[i])
	 if Gtk.RadioAction:is_type_of(added) then
	    if not first_radio then
	       first_radio = added
	    else
	       added:join_group(first_radio)
	    end
	 end
      end
      -- Install callback for on_activate.
      if first_radio and action.on_change then
	 local on_change = action.on_change
	 function first_radio:on_changed(current) on_change(current) end
      end
   else
      -- Add plain action.
      self:add_action(action)
      return action
   end
end
Gtk.ActionGroup._container_add = Gtk.ActionGroup.add

Gtk.ActionGroup._attribute = { action = {} }
local action_group_mt = {}
function action_group_mt:__index(name)
   return self._group:get_action(name)
end
function Gtk.ActionGroup._attribute.action:get()
   return setmetatable({ _group = self }, action_group_mt)
end

-------------------------------- Gtk.Assistant
Gtk.Assistant._attribute = { property = {} }

function Gtk.Assistant._method:add(child)
   if type(child) == 'table' then
      local widget = child[1]
      self:append_page(widget)
      for name, value in pairs(child) do
	 if type(name) == 'string' then
	    self['set_page_' .. name](self, widget, value)
	 end
      end
   else
      self:append_page(widget)
   end
end
Gtk.Assistant._container_add = Gtk.Assistant.add

local assistant_property_mt = {}
function assistant_property_mt:__newindex(property_name, value)
   self._assistant['set_page_' .. property_name](
      self._assistant, self._page, value)
end
function assistant_property_mt:__index(property_name)
   return self._assistant['get_page_' .. property_name](
      self._assistant, self._page)
end
local assistant_properties_mt = {}
function assistant_properties_mt:__index(page)
   if type(page) == 'string' then page = self._assistant.child[page] end
   return setmetatable({ _assistant = self._assistant, _page = page },
		       assistant_property_mt)
end
function Gtk.Assistant._attribute.property:get()
   return setmetatable({ _assistant = self }, assistant_properties_mt)
end

-------------------------------- Gtk.Dialog
Gtk.Dialog._attribute = { buttons = {} }

function Gtk.Dialog._attribute.buttons:set(buttons)
   for _, button in ipairs(buttons) do
      self:add_button(button[1], button[2])
   end
end

-------------------------------- Gtk.InfoBar
Gtk.InfoBar._attribute = { buttons = Gtk.Dialog._attribute.buttons }

-------------------------------- Gtk.Menu
if not Gtk.Menu.popup then
   Gtk.Menu._method.popup = Gtk.Menu.popup_for_device
end

-------------------------------- Gtk.MenuItem
Gtk.MenuItem._attribute = { child = {} }
function Gtk.MenuItem._attribute.child:get()
   local children = Gtk.Container._attribute.child.get(self)
   children[#children + 1] = Gtk.MenuItem.get_submenu(self)
   return children
end

-------------------------------- Gtk.EntryCompletion

-- Workaround for bug in GTK+; text_column accessors don't do an extra
-- needed work which is done properly in
-- gtk_entry_completion_{set/get}_text_column
Gtk.EntryCompletion._attribute = {
   text_column = { get = Gtk.EntryCompletion.get_text_column,
		   set = Gtk.EntryCompletion.set_text_column }
}

-------------------------------- Gtk.PrintSettings
Gtk._constant = Gtk._constant or {}
Gtk._constant.PRINT_OUTPUT_FILE_FORMAT = 'output-file-format'
Gtk._constant.PRINT_OUTPUT_URI = 'output-uri'

-- Gtk-cairo integration helpers.
cairo.Context._method.should_draw_window = Gtk.cairo_should_draw_window

--------------------------------- Gtk-2 workarounds
if tonumber(Gtk._version) < 3.0 then
   -- Get rid of Gtk.Bin internal 'child' field, which gets in the way
   -- of 'child' attribute mechanism introduced in this override.
   local _ = Gtk.Bin.child
   Gtk.Bin._field.child = nil
end
