#! /usr/bin/env ruby

=begin
Embedded doc
that spans multiple lines
=end

BEGIN {
  puts [1,2,3].inject(:+)
}

END { [:foo, :bar].map(&:to_s) }

MY_CONSTANT = 'yowser!'
$global = :symbol
$/ = '\r' # what a great naming scheme
other_symbols = [:@_action_has_layout, :$global]
local = 2

# string madness
r = 'sq string'
%q/sq again/ and %q#sq again# and %q|esca\|ed| and true
%q(paired) and %q{paired} and %q[yes paired]
# string end

r = "dq string"
r = "Interpolation: #{[1,2,3].inject(:+)} #@ends #$here sir"
# string end
%Q/dq again/ and %Q|dq again| and %Q#esca\#ed# and %Q|inter#{'pol' + :at.to_s}ed|
%Q(paired) and %Q{paired} and %Q[yes paired]
# string end
interpolation = 'foo'
r = %{
  and dq again
  with #{interpolation}
  ends here
}
# string end
r = "Double interpolation: #{ "Why why oh #{1 + 2} why" } is twice as fun?"
# string end
r = "but this is just a # sign"

# regex
/foo(\w+)/ and  %r|(foo\|bar)| or %r'\d+#{local}\w+' and %r|'"\d+magic\p{L}| and /with 東京都 flags/im
puts %r[PAIR #{local} ME!]

# not regex
i = 3 / 2
i = (3 / 2) + (2 / 1)
i = (foo / 2) + (2 / 1)
i = (foo / bar) + (bar / foo)

# but these are arithmetic expressions containing division
foo = 4 / 2 * 3
r = foo / 23 * 7

# but this is a method invoked with a regex
puts(/\d*/)

# commands
puts `ls -l #{'/bin/ls'}`
# command end
puts %x| echo #{'same quotes!'}|
# command end
puts %x{ echo #{MY_CONSTANT} }

# crazy number representations
[
  0_123, -123, 1_234, 123.45, 12.32_1, 1.2e-3, 1.234E1,
  0xffff, 0x23_32, 0o252, 0b01011, 0b10_10, 0377, ?a,
  ?\C-a, ?\M-a, ?\M-\C-a
]

# hashes
{
  :foo => 'bar',
  'bar' => 'foo',
}

# 1.9 style symbol keys
{
  foo: 'bar',
  bar: 'foo',
}

word_list = %w(
  foo/bar/urk/**.rb
  next
)

word_list = %w{foo/bar/urk/**.rb paths} or %w|never reached| or %w[ditto]

def yes?
end

def no!; end

module AbstractController; class Base; end; end

class Foo < AbstractController::Base
  @@class_var = 42

  def initialize(bar, foo)
    @bar = bar
    @fooish = foo + 23
    self.class.where_class_is_not_keyword!
  end
end

# OMG heredocs!
action = :go
$boy = 'fred'

print <<HEREDOC # bare heredoc
Oh boy
here we #{action.to_s + " #$boy"}
hold tight!
HEREDOC

puts <<"DQ".upcase.to_sym # heredoc with arbitrary code attached
Now with quotes, at half the price! #{action} forth and buy!
#{MY_CONSTANT}
DQ

print <<'SQ' # single quoted, yay
  Don't you dare to #{interpolate} me!
  Thanks SQ
SQ

print <<`EOC` # comment about executing commands
  echo All systems #{action.to_s + 'ne'}
EOC

print <<-INDENT
  foo
  bare
  INDENT

# from 2.3
print <<~SQUIGGLY
  trim
  me
  SQUIGGLY

# stackable heredoc with interpolations in interpolations?
# - yes of course.. sigh.. but let's just do some approximation
print <<"foo", <<"bar"
  I said #{ "all #{action}" }.
foo
  Ok #$boy ?
bar

puts ['All', 'legal', 'Ruby.'].join '. '
[other_symbols, r]
