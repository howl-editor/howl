------------------------------------------------------------------------------
--
--  LGI GLib root override module.
--
--  Copyright (c) 2012 Pavel Holejsovsky
--  Licensed under the MIT license:
--  http://www.opensource.org/licenses/mit-license.php
--
------------------------------------------------------------------------------

local select, type, pairs = select, type, pairs
local core = require 'lgi.core'
local GLib = core.repo.GLib

GLib._constant = GLib._constant or {}
GLib._constant.SOURCE_CONTINUE = true
GLib._constant.SOURCE_REMOVE = false
