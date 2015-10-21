#! /usr/bin/env python

# Comments use '#'

# Lists

empty_list = []

# Builtin Identifiers

builtins = [ArithmeticError, AssertionError, AttributeError,
BaseException, BufferError, BytesWarning, DeprecationWarning,
EOFError, Ellipsis, EnvironmentError, Exception, False,
FloatingPointError, FutureWarning, GeneratorExit, IOError,
ImportError, ImportWarning, IndentationError, IndexError, KeyError,
KeyboardInterrupt, LookupError, MemoryError, NameError, None,
NotImplemented, NotImplementedError, OSError, OverflowError,
PendingDeprecationWarning, ReferenceError, RuntimeError, RuntimeWarning,
StandardError, StopIteration, SyntaxError, SyntaxWarning, SystemError,
SystemExit, TabError, True, TypeError, UnboundLocalError,
UnicodeDecodeError, UnicodeEncodeError, UnicodeError,
UnicodeTranslateError, UnicodeWarning, UserWarning, ValueError,
Warning, ZeroDivisionError, __debug__, __doc__, __import__,
__name__, __package__, abs, all, any, apply, basestring, bin,
bool, buffer, bytearray, bytes, callable, chr, classmethod, cmp,
coerce, compile, complex, copyright, credits, delattr, dict,
dir, divmod, enumerate, eval, execfile, exit, file, filter,
float, format, frozenset, getattr, globals, hasattr, hash, help,
hex, id, input, int, intern, isinstance, issubclass, iter,
len, license, list, locals, long, map, max, memoryview, min,
next, object, oct, open, ord, pow, property, quit,
range, raw_input, reduce, reload, repr, reversed, round, set,
setattr, slice, sorted, staticmethod, str, sum, super, tuple,
type, unichr, unicode, vars, xrange, zip]

# Identifiers
if False:
  idents = [a, b, cde, fgh1, _blah, _foo_abc013, UPPER_CASE, Mixed8347df_]


# Integers

ints = [1, 2, 3, 4, 5, 38474, 13313]
longs = [1L, 30l, 347388472349449848L]

# Floats

floats = [1.0, 2.0, 3.456, 3.234e123, 1342343e199394]

# Complex

complex = [1j, 2j, 3 + 4j, 7.18384 + 43.3847j]

# Strings

sq_strings = ['single', 'quoted', 'encloses "double" quotes', 'backlash escapes \' ']
dq_strings = ["single", "quoted", "encloses 'single' quotes", "backlash escapes \" "]

triple_sq_string = '''can span
multiple lines easily
single 'quotes' ok - no escaping needed
double "quotes" ok too!
'''

triple_dq_strings = """can span
multiple lines easily
single 'quotes' ok - no escaping needed
double "quotes" ok too!
"""

adjacent_strings_auto_concat = "hello " "world"
same_as_above = "hello""world"
raw_string = r'abc\d'

simple_f_string = f'abc{de}fgh{ij}klm'
conv_f_string = f'ab{cd!s}ef'
complicated_triple_f_string = f'''abc{a+'!':a=+#0{abc},.{prec}b}def'''
brace_f_string = f'{value:abc{f() + g()}}abc'
spaced_f_string = f'{a + b}abc'
f_string_spec = f'{v!r}'
another_braced_f_string = f'{v:a4c{abc}}abc'
f_string_with_bang = f'{v!=0}'

if False:
  # Dictionaries
  d = {a: b, c: d, "s": 1234 }

  # Sets
  s = {a, b, c}

  # String conversions
  s = `a`
  s = `arbitrary + expression() - here`

  # Function calls

  call_function()
  call_another_function(arg1, arg2, arg3, 133, 'hello')
  pass_keyword_args(arg1, kwarg1=123, kwarg2="efg")

  # Function definitions

  def func():
    pass

  def func():
    "any bare string here is a doc string"
    pass

  def func2(arg1, arg2):
    pass

  def func3(kwarg1='default', kwarg2=100, kwarg3=another_default):
    pass

  def func5(arg1, *positional_args, **keyword_args):
    pass

  def single_line(): pass

  @decor1
  def decorated():
    pass

  @decor2('arg')
  def decorated():
    pass

  @stacked
  @decorators
  @are_ok
  def decorated():
    pass

  # Operators

  def operators():
    # https://docs.python.org/2/reference/expressions.html#evaluation-order has a good list

    # logical
    a and b or c and not d

    # parenthesis
    (a or b) and (c or d)

    # basic math
    a + b
    a - b
    a * b
    a / b
    a // b
    a % b
    a ** b

    # identity
    a is b
    a is not b

    # comparison
    a < b
    a > b
    a <= b
    a >= b
    a != b
    a <> b
    a == b

    # chained
    a < b <= c

    # containment
    a in b

    # indexing and slicing
    a[b]
    a[b:c]
    a[b:c:d]

    # bitwise
    ~a
    a << b
    a >> b
    a & b
    a | b
    a ^ b

# Statements
if False:
  # assignment
  a = b

  assert e, e2

  # augmented
  a += b
  a -= b
  a *= b
  a /= b
  a //= b
  a %= b
  a **= b
  a >>= b
  a <<= b
  a &= b
  a |= b
  a ^= b

  pass

  del a

  print a

  def f():
    return a

  def g():
    yield a

  try:
    raise e
  except E as a:
    b()
  except:
    c()
  else:
    d()

  for a in aa:
    if c:
      continue
    elif d:
      e()
    else:
      break
  else:
    g()

  with a as b:
    c()

  import a
  import a.b
  from a.b import c, d

  print a

  global g1, g2

  exec "print 1"

  f = lambda a: a + 1

# Class Definition
if False:
  class Name(base1, base2):
    class_attr = a
    def method(self):
      pass

    def __special__(self):
      pass
