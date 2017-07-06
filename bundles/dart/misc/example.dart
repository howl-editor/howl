// Dart - dartlang.org

/* differnt style of comment
 *

 end of comment */

// import
import 'package:subpackage/file.dart';

// basic function
void main() {
  // numbers
  int x = 1;
  num y = 2;
  double z = 3;
  double z = 1.42e5;
  int hex = 0xf0f0ABCD;
  bool flag = true;
  bool flag2 = false;
  Empty obj = null;

  // strings
  String s = 'hello\'quote';
  String s = "hello\"quote";
  var multi_line = '''
  line one 'can have quotes' or even double quotes ''
  line two
  ''';
  var multi_line2 = """
  this one has "double quotes" and double double ""
  line two
  """;
  var raw_string = r'raw string' ;

  // modifiers const and final
  const pi = 3.14;
  const int pi = 3.14; // can accept type
  final int pi = 3.14;

  // lists and maps
  var list = [1, 2, 3];
  var map = {
    'key': 'value',   // string key
    'k2': 'value2',
    2: 'value3',      // numeric key
  }

  // symbols
  var s = #symbola;
  var s = #symbolb;

  // instantiation - classes are generally CapitalizedWord
  var obj = new SomeClass();

  // named parameters
  var obj = new SomeClass(
    key1: value1,
    key2: 'hello',
    key3: 3.14,
  );

  // generics specialized using <>
  List<Color> obj = new GenericClass<Specilization>();

  // control structures
  if (condition) {
    // do x
  }
  else if (condition2) {
    // do y
  }
  else {
    // do z
  }

  for (var i=0; i<10; i++) {
    // loop
  }

  while (condition) {
    // do something
    continue;
    break;
  }

  do {
    // something
  } while (condition);

  // asserts
  assert(some_condition(), 'error');

  // exceptions
  try {
    throw new SpecificException();
  } on SpecificException {
    // handle
  } on Exception catch (e) {
    // handle
  } catch (e) {
    // handle
  }

  // operators
  ternary = cond ? iftrue : iffalse;

  // leading underscore types
  _PrivateType function() {
    return;
  }
}

// enum
enum Color {
  red,
  green,
  blue
}

// class definition
class MySubClass extends SomeBaseClass implements Interface{

  // method
  ReturnType methodname(int arg1) {
    super.methodname();
    return new ReturnType(arg1);
  }

  // static method
  static void methodname() {
  }

  // operator overrides
  MySubClass operator +(a, b) {
    return a - b;
  }
}
