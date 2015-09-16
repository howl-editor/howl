#! /usr/bin/coffee
# Lots of examples copied from http://coffeescript.org/

# Functions
square = (x) -> x * x
fill = (container, liquid = "coffee") ->
  "Filling the #{container} with #{1 / 2}..."

awardMedals = (first, second, others...) ->
  gold = first

String::dasherize = ->
  this.replace /_/g, "-"

# Arrays and hashes
song = ["do", "re", "mi", "fa", "so"]
singers = {Jagger: "Rock", Elvis: "Roll"}

bitlist = [
  1, 0, 1
  0, 0, 1
  1, 1, 0
]

kids =
  brother:
    name: "Max"
    age:  11
  sister:
    name: "Ida"
    age:  9

# some keywords displayed
if happy and knowsIt? # existential operator
  clapsHands()
  chaChaCha()
else
  showIt()

date = if friday then sue else jill
foods = ['broccoli', 'spinach', 'chocolate']
eat food for food in foods when food isnt 'chocolate'

yearsOld = max: 10, ida: 9, tim: 11
ages = for child, age of yearsOld
  "#{child} is #{age}"

switch day
  when "Mon" then go work
  when "Fri", "Sat"
    if day is bingoDay
      go bingo
  when "Sun" then go church
  else go work

try
  nonexistent / undefined
catch error
  "And the error is ... #{error}"
finally
  'wat?'

# Strings

print inspect "My name is #{@name}"

text = "Every literary critic believes he will
        outwit history and have the last word"

non_interpolated = 'foo #{bar} zed'

html = """
       <strong class="string within multistring">
         cup of #{@coffeescript}
       </strong>
       """

single_block_string = '''
       <strong class='string within multistring'>
         cup of coffeescript
       </strong>
       '''

# comments

###
SkinnyMochaHalfCaffScript Compiler v1.0
Released under the MIT License
###

# regexes

/foo+/
apply /foo+/i

escaped_del = /^https?:\/\//i

///
dlld
dk #{'sl'}
next
///

multi_regex = /// ^ (
  ?: [-=]>             # function
   | #{1 + 2}+          #interpolated
   | [-+*/%<>&|^!?=]=  # compound assign / compare
   | \.{2,3}           # range or splat
) ///

# not regex

i = 3 / 2
i = (3 / 2) + (2 / 1)
i = (foo / 2) + (2 / 1)

# Classes

class ClassName
  constructor: (@name, bar) ->
    @bar = bar

  move: (meters) ->
    alert @name + " moved #{meters}m."

class Snake extends Animal
  move: ->
    alert "Slithering..."
    super 5

sam = new Snake "Sammy the Python"

# embedded javascript
hi = `function() {
  return [document.title, "Hello JavaScript"].join(": ");
}`

# constants

foo.MY_CONSTANT

foo.Bar # not a constant

# all keywords - should all be lexed properly
new, delete, typeof, in, instanceof
return, throw, break, continue, debugger
if, else, switch, for, while, do, try, catch, finally
class, extends, super

undefined, then, unless, until, loop, of, by, when
and, or, isnt, is, not, yes, no, on, off

# reserved words are lexed as errors

function foo() {}

# but not when they are fields
envelope.message.private = true
