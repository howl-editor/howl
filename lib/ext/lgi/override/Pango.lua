------------------------------------------------------------------------------
--
--  LGI Pango override module.
--
--  Copyright (c) 2012 Pavel Holejsovsky
--  Licensed under the MIT license:
--  http://www.opensource.org/licenses/mit-license.php
--
------------------------------------------------------------------------------

local pairs = pairs
local lgi = require 'lgi'
local Pango = lgi.Pango

-- Provide defines which are not present in the GIR
local _ = Pango.SCALE
for name, value in pairs {
   SCALE_XX_SMALL = 1 / (1.2 * 1.2 * 1.2),
   SCALE_X_SMALL = 1 / (1.2 * 1.2),
   SCALE_SMALL = 1 / 1.2,
   SCALE_MEDIUM = 1,
   SCALE_LARGE = 1.2,
   SCALE_X_LARGE = 1.2 * 1.2,
   SCALE_XX_LARGE = 1.2 * 1.2 * 1.2,
} do
   if not Pango[name] then
      Pango._constant[name] = value
   end
end
