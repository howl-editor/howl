#![allow(unused)]

extern crate

// an old fashion single line comment

/*
a multi-line
comment
*/

/*
a
/*
nested
*/
multiline
comment
*/

as
const
crate
extern
for
impl
in
move
mut
ref
return
Self
static
super
trait
unsafe
where
while

abstract
alignof
become
box
do
final
macro
offsetof
override
priv
proc
pure
sizeof
typeof
unsized
virtual
yield

union
'static

type Label = String;

mod a {
    pub fn foo() { self::bar() }

    fn bar() {}
}

mod b {
    pub fn foo() { super::a::foo() }
}

enum MyEnum {
    Variant1(i8,i16,i32,i64),
    Variant2(u8,u16,u32,u64),
    Variant3
}

struct MyStruct {
    field1: bool,
    field2: char,
    field3: str
}

struct NamedTuple(f32,f64,isize,usize);

fn main() {
    use std::Vec;
    let literal_chars = ['a', '\n', '\0', '§', '\u{00e9}'];
    let literal_strings = ["normal  \"string\"", r#"raw "string""#, r##"another "raw" #"string"#"##];
    let literal_ascii_char = b'H';
    let literal_ascii_str = br#"raw ascii "string""#
    let literal_decimal = 1234_5678i32;
    let literal_hex = 0xabcdef_0123456789u64;
    let literal_octal = 0o4567_0123__u32;
    let literal_binary = 0b1001____0110u16;
    let literal_float = 1_23.45E+67f64;
    let v = vec!{123, 456};
    macro_rules! macro_name { () => () };
    macro_name!();

    let b: bool = match Some(3i32) {
        Some(_) => true,
        None => false,
    };

    loop { break; continue; }

    let i: i32 = if true { 3 } else { 4 };

}
