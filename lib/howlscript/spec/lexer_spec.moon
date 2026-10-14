lexer = require 'howlscript.lexer'

describe 'howlscript.lexer', ->
  -- the tokens as {type, value} pairs, without the final eof
  lex = (src) ->
    [{t.t, t.v} for t in *lexer.lex(src) when t.t != 'eof']

  token = (src, nr = 1) -> lexer.lex(src)[nr]

  lex_error = (src) ->
    ok, err = pcall lexer.lex, src
    assert.is_false ok
    err

  it 'lexes names, keywords and numbers', ->
    assert.same {
      {'keyword', 'if'}, {'name', 'foo'}, {'keyword', 'and'}, {'name', 'bar_2'}
    }, lex 'if foo and bar_2'
    assert.same {{'number', '12'}, {'number', '0.5'}, {'number', '.5'}, {'number', '3e10'}}, lex '12 0.5 .5 3e10'
    assert.same {{'number', '0xff'}, {'number', '0x1p4'}}, lex '0xff 0x1p4'
    assert.same {{'number', '10ULL'}, {'number', '7LL'}, {'number', '2i'}}, lex '10ULL 7LL 2i'

  it 'lexes Lua-only keywords as names', ->
    assert.same {{'name', 'end'}, {'name', 'function'}, {'name', 'goto'}}, lex 'end function goto'

  it 'does not take the dot of .. into a number', ->
    assert.same {{'number', '1'}, {'op', '..'}, {'name', 'x'}}, lex '1..x'

  it 'reports malformed numbers', ->
    assert.equals 1, lex_error('12abc').col

  it 'lexes operators, longest first', ->
    assert.same {
      {'op', '...'}, {'op', '..='}, {'op', '..'}, {'op', '=='}, {'op', '!='}, {'op', '->'},
      {'op', '=>'}, {'op', '@@'}, {'op', '@'}, {'op', '+='}, {'op', '++'}
    }, lex '... ..= .. == != -> => @@ @ += ++'

  it 'lexes `or=` and `and=` as update operators', ->
    assert.same {{'name', 'x'}, {'op', 'or='}, {'number', '1'}}, lex 'x or= 1'
    assert.same {{'name', 'x'}, {'op', 'and='}, {'name', 'y'}}, lex 'x and= y'
    assert.same {{'name', 'a'}, {'keyword', 'or'}, {'op', '=='}, {'name', 'b'}}, lex 'a or==b'

  describe '--', ->
    it 'is the decrement operator when touching a name or ]', ->
      assert.same {{'name', 'x'}, {'op', '--'}}, lex 'x--'
      assert.same {{'name', 't'}, {'op', '['}, {'number', '1'}, {'op', ']'}, {'op', '--'}}, lex 't[1]--'

    it 'starts a comment otherwise', ->
      assert.same {{'name', 'x'}}, lex 'x -- a comment'
      assert.same {{'name', 'x'}}, lex 'x\n-- a comment'
      assert.same {{'keyword', 'nil'}}, lex 'nil--'
      assert.same {}, lex '-- only a comment'

  describe 'strings', ->
    it 'keeps single quoted strings as is', ->
      t = token "'a\\'b'"
      assert.equals "'", t.q
      assert.same {"a\\'b"}, t.parts

    it 'splits double quoted strings into text and interpolations', ->
      t = token '"a #{x + 1} b"'
      assert.equals '"', t.q
      assert.equals 'a ', t.parts[1]
      assert.same {{'name', 'x'}, {'op', '+'}, {'number', '1'}, {'eof'}}, [{p.t, p.v} for p in *t.parts[2].tokens]
      assert.equals ' b', t.parts[3]

    it 'handles quotes and braces inside interpolations', ->
      t = token [["#{f('}')} #{ {1}[1] }"]]
      assert.equals 3, #t.parts
      assert.equals ' ', t.parts[2]
      assert.same {'op', '}'}, {t.parts[3].tokens[3].t, t.parts[3].tokens[3].v}

    it 'escapes raw line breaks in quoted strings, keeping the lines', ->
      toks = lexer.lex "x = 'a\nb' y"
      assert.equals "a\\\nb", toks[3].parts[1]
      assert.equals 1, toks[3].line
      assert.equals 2, toks[4].line
      assert.is_false toks[4].first

    it 'keeps long strings, with their brackets', ->
      t = token '[==[ a ]] b ]==]'
      assert.equals '[', t.q
      assert.same {'[==[ a ]] b ]==]'}, t.parts

    it 'counts lines in long strings', ->
      toks = lexer.lex "[[a\nb\nc]] x"
      assert.equals 3, toks[2].line

    it 'reports unterminated strings and interpolations', ->
      assert.equals 5, lex_error('x = "abc').col
      err = lex_error '"a #{x'
      assert.match err.message, 'unterminated string interpolation'
      assert.equals 4, err.col

    it 'reports empty interpolations', ->
      assert.match tostring(lex_error('"#{}"')), 'empty string interpolation'

    it 'handles multibyte text', ->
      t = token [['åäö #{x}']]
      assert.same {'åäö #{x}'}, t.parts
      assert.same {{'name', 'x'}}, lex "-- åäö\nx"

  describe 'positions and spacing', ->
    it 'records line, column and whether a token is first on its line', ->
      toks = lexer.lex 'a = 1\n  b(c)'
      assert.same {1, 1, true}, {toks[1].line, toks[1].col, toks[1].first}
      assert.same {2, 3, true}, {toks[4].line, toks[4].col, toks[4].first}
      assert.is_false toks[5].first

    it 'records the indentation of each token`s line, counting a tab as 4', ->
      toks = lexer.lex 'a\n  b c\n\tx'
      assert.same {0, 2, 2, 4}, [t.indent for t in *toks[1, 4]]

    it 'ignores blank and comment lines for indentation', ->
      toks = lexer.lex 'a\n\n    -- c\n  b'
      assert.equals 2, toks[2].indent
      assert.is_true toks[2].first

    it 'records whether whitespace comes before and after a token', ->
      toks = lexer.lex "a:b c: d r'x'"
      colon1, colon2 = toks[2], toks[5]
      assert.same {false, false}, {colon1.sb, colon1.sa}
      assert.same {false, true}, {colon2.sb, colon2.sa}
      assert.is_false toks[8].sb -- the string touching r

  describe 'errors', ->
    it 'rejects \\ with a hint to use :', ->
      err = lex_error 'obj\\method!'
      assert.equals 4, err.col
      assert.match err.message, "use ':'"

    it 'rejects ! with a hint to call with ()', ->
      assert.match lex_error('f!').message, "call with '%(%)'"

    it 'rejects names reserved for the compiler', ->
      assert.match lex_error('__hs_x = 1').message, 'reserved'

    it 'rejects unexpected characters, naming them in full', ->
      assert.match lex_error('x = a & b').message, "unexpected character '&'"
      assert.match lex_error('x = ä').message, "unexpected character 'ä'"
