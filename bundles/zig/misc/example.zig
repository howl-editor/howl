// keywords
align allowzero and anyframe asm async await break
callconv catch comptime const continue defer else
enum errdefer error export extern fn for if
inline noalias orelse or packed promise pub resume
return linksection struct suspend switch test
threadlocal try union unreachable usingnamespace var
volatile while

// special words
true false null undefined

// built-in functons
@addWithOverflow @alignCast @alignOf @as @asyncCall
@atomicLoad @atomicRmw @atomicStore @bitCast @bitOffsetOf
@bitReverse @bitSizeOf @boolToInt @breakpoint
@byteOffsetOf @byteSwap @call @cDefine @ceil @cImport
@cInclude @clz @cmpxchgStrong @cmpxchgWeak @compileError
@compileLog @cos @ctz @cUndef @divExact @divFloor
@divTrunc @embedFile @enumToInt @errorName
@errorReturnTrace @errorToInt @errSetCast @exp2 @export
@exp @fabs @fence @fieldParentPtr @field @floatCast
@floatToInt @floor @frameAddress @frameSize @frame
@Frame @hasDecl @hasField @import @intCast @intToEnum
@intToError @intToFloat @intToPtr @log10 @log2 @log
@memcpy @memset @mod @mulAdd @mulWithOverflow @OpaqueType
@panic @popCount @ptrCast @ptrToInt @rem @returnAddress
@round @setAlignStack @setCold @setEvalBranchQuota
@setFloatMode @setRuntimeSafety @shlExact @shlWithOverflow
@shrExact @shuffle @sin @sizeOf @splat @sqrt
@subWithOverflow @tagName @TagType @This @truncate
@trunc @typeInfo @typeName @TypeOf @Type @unionInit
@Vector

// types
anyerror bool c_int c_longdouble c_longlong c_long
comptime_float comptime_int c_short c_uint c_ulonglong
c_ulong c_ushort c_void f128 f16 f32 f64 isize
noreturn type usize void

// arbitrary bit precision from 0 to 65535
i0 i1 i2 i3 ... i8 i16 i32 i64 i128 ... i65535
u0 u1 u2 u3 ... u8 u16 u32 u64 u128 ... u65535

// hello.zig
const std = @import("std");

pub fn main() !void {
    const stdout = &std.io.getStdOut().outStream().stream;
    try stdout.print("Hello, {}!\n", .{"world"});
}

// values
const assert = @import("std").debug.assert;
const std = @import("std");

// exported value
export const Unit = enum(u32) {
    Hundred = 100,
    Thousand = 1000,
    Million = 1000000,
};

pub fn main() void {
    // integer literals
    const decimal_int = 98222;
    const hex_int = 0xff;
    const another_hex_int = 0xFF;
    const octal_int = 0o755;
    const binary_int = 0b11110000;

    // floating-point literals
    const floating_point = 123.0E+77;
    const another_float = 123.0;
    const yet_another = 123.0e+77;
    const hex_floating_point = 0x103.70p-5;
    const another_hex_float = 0x103.70;
    const yet_another_hex_float = 0x103.70P-5;

    // boolean
    const t = true;
    const f = false;

    // string literals
    const bytes = "hello";
    assert(@TypeOf(bytes) == *const [5:0]u8);
    assert(bytes.len == 5);
    assert(bytes[1] == 'e');
    assert(bytes[5] == 0);
    assert('e' == '\x65');
    assert('\u{1f4a9}' == 128169);
    assert('💯' == 128175);
    assert(mem.eql(u8, "hello", "h\x65llo"));

    // multi-line string literals
    const hello_world_in_c =
        \\#include <stdio.h>
        \\
        \\int main(int argc, char **argv) {
        \\    printf("hello world\n");
        \\    return 0;
        \\}
    ;

    // array literal
    const message = [_]u8{ 'h', 'e', 'l', 'l', 'o' };

    // optional
    var optional_value: ?[]const u8 = null;

    // error union
    var number_or_error: anyerror!i32 = error.ArgNotFound;

    // anonymous struct literal
    const Point = struct {x: i32, y: i32};
    var pt: Point = .{
        .x = 13,
        .y = 67,
    };

    // enums
    const Suit = enum {
        Clubs,
        Spades,
        Diamonds,
        Hearts,

        pub fn isClubs(self: Suit) bool {
            return self == Suit.Clubs;
        }
    };
    const Number = packed enum(u8) {
        one,
        two,
        three,
    };

    // anonymous union literals
    const Number = union {
        int: i32,
        float: f64,
    };

    // switches
    const a: u64 = 10;
    const zz: u64 = 103;

    const b = switch (a) {
        1, 2, 3 => 0,
        5...100 => 1,
        101 => blk: {
            const c: u64 = 5;
            break :blk c * 2 + 1;
        },
        zz => zz,
        comptime blk: {
            const d: u32 = 5;
            const e: u32 = 100;
            break :blk d + e;
        } => 107,
        else => 9,
    };

    // for
    const items = [_]i32 { 4, 5, 3, 4, 0 };
    var sum: i32 = 0;

    for (items) |value| {
        if (value == 0) {
            continue;
        }
        sum += value;
    }
    assert(sum == 16);
    for (items[0..1]) |value| {
        sum += value;
    }
    assert(sum == 20);

    var sum2: i32 = 0;
    for (items) |value, i| {
        assert(@TypeOf(i) == usize);
        sum2 += @intCast(i32, i);
    }
}
