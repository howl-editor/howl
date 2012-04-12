------------------------------------------------------------------------------
--
--  LGI GObject.Type facilities.
--
--  Copyright (c) 2010, 2011 Pavel Holejsovsky
--  Licensed under the MIT license:
--  http://www.opensource.org/licenses/mit-license.php
--
------------------------------------------------------------------------------

local assert, pairs, ipairs = assert, pairs, ipairs
local core = require 'lgi.core'
local repo = core.repo

-- Add synthetic GObject.Type, containing well-known GType constants
-- and grouping some type_xxx methods.
local Type = { STRV = 'GStrv', ARRAY = 'GArray', BYTE_ARRAY = 'GByteArray',
	       PTR_ARRAY = 'GPtrArray', HASH_TABLE = 'GHashTable',
	       ERROR = 'GError', GTYPE = 'GType' }
repo.GObject._struct = { Type = Type }
for _, name in pairs { 'name', 'qname', 'from_name', 'parent', 'depth',
		       'next_base', 'is_a', 'children', 'interfaces',
		       'query', 'fundamental_next', 'fundamental'} do
   Type[name] = repo.GObject['type_' .. name]
end
for num, name in ipairs { 'NONE', 'INTERFACE', 'CHAR', 'UCHAR', 'BOOLEAN',
			  'INT', 'UINT', 'LONG', 'ULONG', 'INT64', 'UINT64',
			  'ENUM', 'FLAGS', 'FLOAT', 'DOUBLE', 'STRING',
			  'POINTER', 'BOXED', 'PARAM', 'OBJECT', 'VARIANT' } do
   Type[name] = Type.name(num * 4)
end

-- Map of basic typeinfo tags to GType.
local type_tag_map = {
   gboolean = Type.BOOLEAN, gint8 = Type.CHAR, guint8 = Type.UCHAR,
   gint16 = Type.INT, guint16 = Type.UINT,
   gint32 = Type.INT, guint32 = Type.UINT,
   gint64 = Type.INT64, guint64 = Type.UINT64,
   gunichar = Type.UINT, gfloat = Type.FLOAT, gdouble = Type.DOUBLE,
   GType = Type.GTYPE, utf8 = Type.STRING, filename = Type.STRING,
   ghash = Type.HASH_TABLE, glist = Type.POINTER, gslist = Type.POINTER,
   error = Type.ERROR }

-- Gets GType corresponding to specified typeinfo.
function Type.from_typeinfo(ti)
   local gtype = type_tag_map[ti.tag]
   if not gtype then
      if ti.tag == 'interface' then
	 gtype = Type.name(ti.interface.gtype)
      elseif ti.tag == 'array' then
	 local atype = ti.array_type
	 if atype == 'c' then
	    gtype = Type.POINTER
	    -- Check for Strv.
	    local etag = ti.params[1].tag
	    if ((etag == 'utf8' or etag == 'filename')
		and ti.is_zero_terminated) then
	       gtype = Type.STRV
	    end
	 else
	    gtype = ({ array = Type.ARRAY, byte_array = Type.BYTE_ARRAY,
		       ptr_array = Type.PTR_ARRAY })[atype]
	 end
      end
   end
   return gtype
end
