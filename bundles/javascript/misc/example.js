// Some example JavaScript syntax, a lot of it borrowed from Wikipedia
// http://en.wikipedia.org/wiki/JavaScript_syntax

const TEST_FILE = 'yes';

a = b + c // comment at end of line

/* this is a long,
   multi-line comment */

(d + e).foo() /* long comment at end of line */

// numbers
345;    // an "integer", although there is only one numeric type in JavaScript
34.5;   // a floating-point number
3.45e2; // another floating-point, equivalent to 345
0377;   // an octal integer equal to 255
0xFF;   // a hexadecimal integer equal to 255, digits represented by the ...
0Xfa;    // ... letters A-F may be upper or lowercase
Nan Infinity; // special number representations

// some special literal representations
undefined;
null;
true;
false;

// strings
"hello!" && 'hi there!';
"esc\"aped" && 'esc\'aped';
`this is a multi-line template string,
with a string ${variable} inlined.`;

// Capitalized identifiers are treated as types
new String('foo');

// arrays
var arr = [];
arr[1] = 'foo';

// hashes
dog = {
  color: "brown",
  "size": "large"
};
dog["color"]; // results in "brown"
dog.color;    // also results in "brown"

// regular expressions
/ab{3}c/;
/ab{3}\/dc/; // with escaped terminator
/ab{3}/gim; // with flags

// regexes used in various contexts
if (/[0-9]/.test('6')) alert('Digit');
invoke(/[0-9]/, /abc/);
invoke(/[0-9]/, on_res(/abc/));

// not regexes below
var foo = 2 / 2;
var bar = 2 / 2 / 3;
var zed = 2 / 2 / other_var;
var frob = var1 / var2 / other_var;

// function declarations
var add = new Function('x', 'y', 'return x+y');
var sum = function(a, b) { return a + b; }
MyType.field = function(a, b) { return a + b; }
function add2(x, y) {
    return x + y;
}
var f = function* (a, b) { yield* 123; }
function* g(c) { yield c; }
var
  foo = 1,
  my_func = function() {};

// aync await
async function () {
  await Promise.resolve(true);
}

// modules
import foo from './foo';
export default 'a';

// class
class Foo extends Bar {
  constructor () {
    super();
  }
}
