local ffi = require('ffi')
local cdef = ffi.cdef

-- single line comment

--[[
long,
multi-line
comment
]]

--[=[
long,
multi-line
level comment
]=]

sq = 'string'
dq = "string again"

long_s = [[
long
multi-line
string
]]

long_s_lvl = [==[
long multi-line
leveled block
]==]

numbers = {
  3, 3.0, 3.1416, 314.16e-2, 0.31416E1,
  0xff, 0x0.1E, 0xA23p-4, 0X1.921FB54442D18P+1,
  2LL, 2ULL, 3ll, 3ull, 0x2ull -- luajit 64-bit cdata extensions
}

special = _VERSION

MY_CONSTANT = 1
MY_CONSTANT2 = 1

MyNonConstant = 3

function func_def (x, y)
  return (x^2 + y^2)^0.5
end

function mod:bar()
end

function mod.foo (value)
  return P{op='X',repr=value,index='wrap'}
end

local func_def2 = function(x) return x / 2 end
local non_func_def = function2()
local non_func_def2 = functionX()

ffi.cdef [[
  typedef char          gchar;
  typedef long          glong;
]]

ffi.cdef [=[
  typedef enum {
    GDK_SHIFT_MASK    = 1 << 0,
    GDK_LOCK_MASK     = 1 << 1,

    GDK_MODIFIER_MASK = 0x5c001fff
  } GdkModifierType;

  gchar * g_strndup(const gchar *str, gssize n);
]=]

cdef[[
int open(const char *pathname, int flags, mode_t mode);
int close(int fd);
]]

ffi.cdef('typedef char gchar;') -- single quoted string cdef
ffi.cdef("typedef char gchar;") -- double quoted string cdef
