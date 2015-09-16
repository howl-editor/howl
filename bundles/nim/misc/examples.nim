# Comment

# User defined types

type MyType
type MyExportedType*  ## '*' means it is exported
type
  MyOtherType = enum red, blue, green
  ObjectType = object
    fieldA: int
    fieldB: seq[int]
  RefObject = ref ObjectType
  ExportedType* = tuple [name: string, age: int]

# Pragmas

{. pragma .}
{. anotherPragma: "value" .}

# User defined constants, various literals

const
  EmptySeq = @[]
  Integers = @[123, 0xFA03BB3, 123'i32, 456'u64]
  Floats = @[1.23, 1.56e300, 1.48e-300]
  Strings = @["hello", "world", "abc", "def"]

when defined(some_compile_time_symbol):
  echo "something at compile time"

proc someBuiltinTypes(a: int8, b: string, c: seq[uint64]) = a + b

proc functionName*(arg1: T1, arg2: T2): ReturnType =
  var local = 1
  var
    a = 2
    b = 3

  let unchangeable = a + b

  if arg1 > 1:
    return arg1 + arg2
  else:
    return arg1 - arg2

  yield something

  try:
    attempt():
  except SomeError:
    echo "Some error"
  except:
    echo "Unknown error"
    raise
  finally:
    revert()

  return something

method methodName(self: ObjectType) = self.fieldA

proc variousOperators() =
  a = b + c - d * f / g
  custom_operators = a ++ b -* c

proc addGeneric [T](a, b: T) = a + b

# Backticks to use operator as name
proc `<>` (x, y: string): bool = x != y

template someTmpl(x, y: expr): expr {.immediate.} =
  not (x == y)

macro ignore(s: string): stmt = discard

var a = true
