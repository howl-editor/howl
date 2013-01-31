-- Copyright 2006-2012 Mitchell mitchell.att.foicica.com. See LICENSE.

local M = {}

--[=[ This comment is for LuaDoc.
---
-- Lexes Scintilla documents with Lua and LPeg.
--
-- ## Overview
--
-- Lexers are the mechanism for highlighting the syntax of source code.
-- Scintilla (the editing component behind [Textadept][] and [SciTE][])
-- traditionally uses static, compiled C++ lexers which are notoriously
-- difficult to create and/or extend. On the other hand, lexers written with Lua
-- make it easy to rapidly create new lexers, extend existing ones, and embed
-- lexers within one another. They tend to be more readable than C++ lexers too.
--
-- Lexers are written using Parsing Expression Grammars, or PEGs, with the Lua
-- [LPeg library][]. The following table is taken from the LPeg documentation
-- and summarizes all you need to know about constructing basic LPeg patterns.
-- This module provides convenience functions for creating and working with
-- other more advanced patterns and concepts.
--
-- Operator             | Description
-- ---------------------|------------
-- `lpeg.P(string)`     | Matches `string` literally.
-- `lpeg.P(`_`n`_`)`    | Matches exactly _`n`_ characters.
-- `lpeg.S(string)`     | Matches any character in `string` (Set).
-- `lpeg.R("`_`xy`_`")` | Matches any character between `x` and `y` (Range).
-- `patt^`_`n`_         | Matches at least _`n`_ repetitions of `patt`.
-- `patt^-`_`n`_        | Matches at most _`n`_ repetitions of `patt`.
-- `patt1 * patt2`      | Matches `patt1` followed by `patt2`.
-- `patt1 + patt2`      | Matches `patt1` or `patt2` (ordered choice).
-- `patt1 - patt2`      | Matches `patt1` if `patt2` does not match.
-- `-patt`              | Equivalent to `("" - patt)`.
-- `#patt`              | Matches `patt` but consumes no input.
--
-- The first part of this document deals with rapidly constructing a simple
-- lexer. The next part deals with more advanced techniques, such as custom
-- coloring and embedding lexers within one another. Following that is a
-- discussion about code folding, or being able to tell Scintilla what code
-- blocks can be "folded" (hidden temporarily from view). After that,
-- instructions on how to use LPeg lexers with the aforementioned Textadept and
-- SciTE editors is listed. Finally, considerations on performance and
-- limitations are given.
--
-- [LPeg library]: http://www.inf.puc-rio.br/~roberto/lpeg/lpeg.html
-- [Textadept]: http://foicica.com/textadept
-- [SciTE]: http://scintilla.org/SciTE.html
--
-- ## Lexer Basics
--
-- All lexers are contained in the *lexers/* directory. Your new lexer will also
-- be included in this directory. Before attempting to write one from scratch
-- though, first determine if your programming language is similar to any of the
-- 80+ languages supported. If so, you may be able to copy and modify that
-- lexer, saving some time and effort. The filename of your lexer should be the
-- name of your programming language in lower case followed by a *.lua*
-- extension. For example, a new Lua lexer would have the name *lua.lua*.
--
-- Note: It is not recommended to use one-character language names like "b",
-- "c", or "d". These lexers happen to be named *b_lang.lua*, *cpp.lua*, and
-- *dmd.lua* respectively, for example.
--
-- ### New Lexer Template
--
-- There is a *lexers/template.txt* file that contains a simple template for a
-- new lexer. Feel free to use it, replacing the '?'s with the name of your
-- lexer:
--
--     -- ? LPeg lexer.
--
--     local l = lexer
--     local token, word_match = l.token, l.word_match
--     local style, color = l.style, l.color
--     local P, R, S = l.lpeg.P, l.lpeg.R, l.lpeg.S
--
--     local M = {_NAME = '?'}
--
--     -- Whitespace.
--     local ws = token(l.WHITESPACE, l.space^1)
--
--     M._rules = {
--       {'whitespace', ws},
--       {'any_char', l.any_char},
--     }
--
--     M._tokenstyles = {
--
--     }
--
--     return M
--
-- The first 4 lines of code are simply defining convenience variables you will
-- be using often. The 5th and last lines define and return the lexer object
-- used by Scintilla; they are very important and must be part of every lexer.
-- The sixth line defines what is called a "token", an essential building block
-- of a lexer. Tokens will be discussed shortly. The rest of the code defines a
-- set of grammar rules and token styles. Those will be discussed later. Note,
-- however, the `M.` prefix in front of `_rules` and `_tokenstyles`: not only do
-- these tables belong to their respective lexers, but any non-local variables
-- should be prefixed by `M.` so-as not to affect Lua's global environment. All
-- in all, this is a minimal, working lexer that can be built on.
--
-- ### Tokens
--
-- Take a moment to think about your programming language's structure. What kind
-- of key elements does it have? In the template shown earlier, one predefined
-- element all languages have is whitespace. Your language probably also has
-- elements like comments, strings, and keywords. These elements are called
-- "tokens". They are the so-called "building blocks" of lexers. Source code is
-- broken down into tokens and subsequently colored, resulting in the syntax
-- highlighting you are familiar with. It is up to you how specific you would
-- like your lexer to be when it comes to tokens. Perhaps you would like to only
-- distinguish between keywords and identifiers, or maybe you would like to also
-- recognize constants and built-in functions, methods, or libraries. The Lua
-- lexer, for example, defines 11 tokens: whitespace, comments, strings,
-- numbers, keywords, built-in functions, constants, built-in libraries,
-- identifiers, labels, and operators. Even though constants, built-in
-- functions, and built-in libraries are a subset of identifiers, it is helpful
-- to Lua programmers for the lexer to distinguish between them all. It would
-- have otherwise been perfectly acceptable to just recognize keywords and
-- identifiers.
--
-- In a lexer, tokens are composed of a token name and an LPeg pattern that
-- matches a sequence of characters recognized to be an instance of that token.
-- Tokens are created using the [`token()`](#token) function. Let us examine the
-- "whitespace" token defined in the template shown earlier:
--
--     local ws = token(l.WHITESPACE, l.space^1)
--
-- At first glance, the first argument does not appear to be a string name and
-- the second argument does not appear to be an LPeg pattern. Perhaps you were
-- expecting something like:
--
--     local ws = token('whitespace', S('\t\v\f\n\r ')^1)
--
-- The `lexer` (`l`) module actually provides a convenient list of common token
-- names and common LPeg patterns for you to use. Token names include
-- [`DEFAULT`](#DEFAULT), [`WHITESPACE`](#WHITESPACE), [`COMMENT`](#COMMENT),
-- [`STRING`](#STRING), [`NUMBER`](#NUMBER), [`KEYWORD`](#KEYWORD),
-- [`IDENTIFIER`](#IDENTIFIER), [`OPERATOR`](#OPERATOR), [`ERROR`](#ERROR),
-- [`PREPROCESSOR`](#PREPROCESSOR), [`CONSTANT`](#CONSTANT),
-- [`VARIABLE`](#VARIABLE), [`FUNCTION`](#FUNCTION), [`CLASS`](#CLASS),
-- [`TYPE`](#TYPE), [`LABEL`](#LABEL), and [`REGEX`](#REGEX). Patterns include
-- [`any`](#any), [`ascii`](#ascii), [`extend`](#extend), [`alpha`](#alpha),
-- [`digit`](#digit), [`alnum`](#alnum), [`lower`](#lower), [`upper`](#upper),
-- [`xdigit`](#xdigit), [`cntrl`](#cntrl), [`graph`](#graph), [`print`](#print),
-- [`punct`](#punct), [`space`](#space), [`newline`](#newline),
-- [`nonnewline`](#nonnewline), [`nonnewline_esc`](#nonnewline_esc),
-- [`dec_num`](#dec_num), [`hex_num`](#hex_num), [`oct_num`](#oct_num),
-- [`integer`](#integer), [`float`](#float), and [`word`](#word). However, you
-- are not limited to the token names and LPeg patterns listed. You can do
-- whatever you like. However, the advantage of using predefined token names is
-- that your lexer's tokens will inherit the universal syntax highlighting color
-- theme used by your text editor.
--
-- #### Example Tokens
--
-- So, how might other tokens like comments, strings, and keywords be defined?
-- Here are some examples.
--
-- **Comments**
--
-- Line-style comments with a prefix character(s) are easy to express with LPeg:
--
--     local shell_comment = token(l.COMMENT, '#' * l.nonnewline^0)
--     local c_line_comment = token(l.COMMENT, '//' * l.nonnewline_esc^0)
--
-- The comments above start with a '#' or "//" and go to the end of the line.
-- The second comment recognizes the next line also as a comment if the current
-- line ends with a '\' escape character.
--
-- C-style "block" comments with a start and end delimiter are also easy to
-- express:
--
--     local c_comment = token(l.COMMENT, '/*' * (l.any - '*/')^0 * P('*/')^-1)
--
-- This comment starts with a "/\*" sequence and can contain anything up to, and
-- including, an ending "\*/" sequence. The ending "\*/" is defined to be
-- optional so that an unfinished comment is still matched as a comment and
-- highlighted as you would expect.
--
-- **Strings**
--
-- It may be tempting to think that a string is not much different from the
-- block comment shown above in that both have start and end delimiters:
--
--     local dq_str = '"' * (l.any - '"')^0 * P('"')^-1
--     local sq_str = "'" * (l.any - "'")^0 * P("'")^-1
--     local simple_string = token(l.STRING, dq_str + sq_str)
--
-- However, most programming languages allow escape sequences in strings such
-- that a sequence like "\\&quot;" in a double-quoted string indicates that the
-- '&quot;' is not the end of the string. The above token would incorrectly
-- match such a string. Instead, a convenient function is provided for you:
-- [`delimited_range()`](#delimited_range).
--
--     local dq_str = l.delimited_range('"', '\\', true)
--     local sq_str = l.delimited_range("'", '\\', true)
--     local string = token(l.STRING, dq_str + sq_str)
--
-- In this case, '\' is treated as an escape character in a string sequence. The
-- `true` argument is analogous to `P('"')^-1` in that non-terminated strings
-- are highlighted as expected.
--
-- **Keywords**
--
-- Instead of matching _n_ keywords with _n_ `P('keyword_`_`n`_`')` ordered
-- choices, another convenience function, [`word_match()`](#word_match), is
-- provided. It is much easier and more efficient to write word matches like:
--
--     local keyword = token(l.KEYWORD, l.word_match{
--       'keyword_1', 'keyword_2', ..., 'keyword_n'
--     })
--
--     local case_insensitive_keyword = token(l.KEYWORD, l.word_match({
--       'KEYWORD_1', 'keyword_2', ..., 'KEYword_n'
--     }, nil, true))
--
--     local hyphened_keyword = token(l.KEYWORD, l.word_match({
--       'keyword-1', 'keyword-2', ..., 'keyword-n'
--     }, '-'))
--
-- By default, characters considered to be in keywords are in the set of
-- alphanumeric characters and underscores. The last token demonstrates how to
-- allow '-' (hyphen) characters to be in keywords as well.
--
-- **Numbers**
--
-- Most programming languages have the same format for integer and float tokens,
-- so it might be as simple as using a couple of predefined LPeg patterns:
--
--     local number = token(l.NUMBER, l.float + l.integer)
--
-- However, some languages allow postfix characters on integers.
--
--     local integer = P('-')^-1 * (l.dec_num * S('lL')^-1)
--     local number = token(l.NUMBER, l.float + l.hex_num + integer)
--
-- Your language may have other tweaks that may be necessary, but it is up to
-- you how fine-grained you want your highlighting to be. After all, it is not
-- like you are writing a compiler or interpreter!
--
-- ### Rules
--
-- Programming languages have grammars, which specify how their tokens may be
-- used structurally. For example, comments usually cannot appear within a
-- string. Grammars are broken down into rules, which are simply combinations of
-- tokens. Recall from the lexer template the `_rules` table, which defines all
-- the rules used by the lexer grammar:
--
--     M._rules = {
--       {'whitespace', ws},
--       {'any_char', l.any_char},
--     }
--
-- Each entry in a lexer's `_rules` table is composed of a rule name and its
-- associated pattern. Rule names are completely arbitrary and serve only to
-- identify and distinguish between different rules. Rule order is important: if
-- text does not match the first rule, the second rule is tried, and so on. This
-- simple grammar says to match whitespace tokens under a rule named
-- "whitespace" and anything else under a rule named "any_char".
--
-- To illustrate why rule order is important, here is an example of a simplified
-- Lua grammar:
--
--     M._rules = {
--       {'whitespace', ws},
--       {'keyword', keyword},
--       {'identifier', identifier},
--       {'string', string},
--       {'comment', comment},
--       {'number', number},
--       {'label', label},
--       {'operator', operator},
--       {'any_char', l.any_char},
--     }
--
-- Note how identifiers come after keywords. In Lua, as with most programming
-- languages, the characters allowed in keywords and identifiers are in the same
-- set (alphanumerics plus underscores). If the "identifier" rule was listed
-- before the "keyword" rule, all keywords would match identifiers and thus
-- would be incorrectly highlighted as identifiers instead of keywords. The same
-- idea applies to function, constant, etc. tokens that you may want to
-- distinguish between: their rules should come before identifiers.
--
-- Now, you may be wondering what `l.any_char` is and why the "any_char" rule
-- exists. `l.any_char` is a special, predefined token that matches one single
-- character as a `DEFAULT` token. The "any_char" rule should appear in every
-- lexer because there may be some text that does not match any of the rules you
-- defined. How is that possible? Well in Lua, for example, the '!' character is
-- meaningless outside a string or comment. Therefore, if the lexer encounters a
-- '!' in such a circumstance, it would not match any existing rules other than
-- "any_char". With "any_char", the lexer can "skip" over the "error" and
-- continue highlighting the rest of the source file correctly. Without
-- "any_char", the lexer would fail to continue. Perhaps you instead want your
-- language to highlight such "syntax errors". You would replace the "any_char"
-- rule such that the grammar looks like:
--
--     M._rules = {
--       {'whitespace', ws},
--       {'error', token(l.ERROR, l.any)},
--     }
--
-- This would identify and highlight any character not matched by an existing
-- rule as an `ERROR` token.
--
-- Even though the rules defined in the examples above contain a single token,
-- rules can consist of multiple tokens. For example, a rule for an HTML tag
-- could be composed of a tag token followed by an arbitrary number of attribute
-- tokens, allowing all tokens to be highlighted separately. The rule might look
-- something like this:
--
--     {'tag', tag_start * (ws * attributes)^0 * tag_end^-1}
--
-- ### Summary
--
-- Lexers are primarily composed of tokens and grammar rules. A number of
-- convenience patterns and functions are available for rapidly creating a
-- lexer. If you choose to use predefined token names for your tokens, you do
-- not have to define how tokens are highlighted. They will inherit the default
-- syntax highlighting color theme your editor uses.
--
-- ## Advanced Techniques
--
-- ### Styles and Styling
--
-- The most basic form of syntax highlighting is assigning different colors to
-- different tokens. Instead of highlighting with just colors, Scintilla allows
-- for more rich highlighting, or "styling", with different fonts, font sizes,
-- font attributes, and foreground and background colors, just to name a few.
-- The unit of this rich highlighting is called a "style". Styles are created
-- using the [`style()`](#style) function. By default, predefined token names
-- like `WHITESPACE`, `COMMENT`, `STRING`, etc. are associated with a particular
-- style as part of a universal color theme. These predefined styles include
-- [`style_nothing`](#style_nothing), [`style_class`](#style_class),
-- [`style_comment`](#style_comment), [`style_constant`](#style_constant),
-- [`style_definition`](#style_definition), [`style_error`](#style_error),
-- [`style_function`](#style_function), [`style_keyword`](#style_keyword),
-- [`style_label`](#style_label), [`style_number`](#style_number),
-- [`style_operator`](#style_operator), [`style_regex`](#style_regex),
-- [`style_string`](#style_string), [`style_preproc`](#style_preproc),
-- [`style_tag`](#style_tag), [`style_type`](#style_type),
-- [`style_variable`](#style_variable), [`style_whitespace`](#style_whitespace),
-- [`style_embedded`](#style_embedded), and
-- [`style_identifier`](#style_identifier). Like with predefined token names and
-- LPeg patterns, you are not limited to these predefined styles. At their core,
-- styles are just Lua tables, so you can create new ones and/or modify existing
-- ones. Each style consists of a set of attributes:
--
-- Attribute   | Description
-- ------------|------------
-- `font`      | The name of the font the style uses.
-- `size`      | The size of the font the style uses.
-- `bold`      | Whether or not the font face is bold.
-- `italic`    | Whether or not the font face is italic.
-- `underline` | Whether or not the font face is underlined.
-- `fore`      | The foreground color of the font face.
-- `back`      | The background color of the font face.
-- `eolfilled` | Does the background color extend to the end of the line?
-- `case`      | The case of the font (1 = upper, 2 = lower, 0 = normal).
-- `visible`   | Whether or not the text is visible.
-- `changeable`| Whether the text is changeable or read-only.
-- `hotspot`   | Whether or not the text is clickable.
--
-- Font colors are defined using the [`color()`](#color) function. Like with
-- token names, LPeg patterns, and styles, there is a set of predefined colors
-- in the `l.colors` table, but the color names depend on the current theme
-- being used. It is generally not a good idea to manually define colors within
-- styles in your lexer because they might not fit into a user's chosen color
-- theme. It is not even recommended to use a predefined color in a style
-- because that color may be theme-specific. Instead, the best practice is to
-- either use predefined styles or derive new color-agnostic styles from
-- predefined ones. For example, Lua "longstring" tokens use the existing
-- `style_string` style instead of defining a new one.
--
-- #### Example Styles
--
-- Defining styles is pretty straightforward. An empty style that inherits the
-- default theme settings is defined like this:
--
--     local style_nothing = l.style{}
--
-- A similar style but with a bold font face is defined like this:
--
--     local style_bold = l.style{bold = true}
--
-- If you wanted the same style, but also with an italic font face, you can
-- define the new style in terms of the old one:
--
--     local style_bold_italic = style_bold..{italic = true}
--
-- This allows you to derive new styles from predefined ones without having to
-- rewrite them. This operation leaves the old style unchanged. Thus if you
-- had a "static variable" token whose style you wanted to base off of
-- `style_variable`, it would probably look like:
--
--     local style_static_var = l.style_variable..{italic = true}
--
-- More examples of style definitions are in the color theme files in the
-- *lexers/themes/* folder.
--
-- ### Token Styles
--
-- Tokens are assigned to a particular style with the lexer's `_tokenstyles`
-- table. Recall the token definition and `_tokenstyles` table from the lexer
-- template:
--
--     local ws = token(l.WHITESPACE, l.space^1)
--
--     ...
--
--     M._tokenstyles = {
--
--     }
--
-- Why is a style not assigned to the `WHITESPACE` token? As mentioned earlier,
-- tokens that use predefined token names are automatically associated with a
-- particular style. Only tokens with custom token names need manual style
-- associations. As an example, consider a custom whitespace token:
--
--     local ws = token('custom_whitespace', l.space^1)
--
-- Assigning a style to this token looks like:
--
--     M._tokenstyles = {
--       {'custom_whitespace', l.style_whitespace}
--     }
--
-- Each entry in a lexer's `_tokenstyles` table is composed of a token's name
-- and its associated style. Unlike with `_rules`, the ordering in
-- `_tokenstyles` does not matter since entries are just associations. Do not
-- confuse token names with rule names. They are completely different entities.
-- In the example above, the "custom_whitespace" token is just being assigned
-- the existing style for `WHITESPACE` tokens. If instead you wanted to color
-- the background of whitespace a shade of grey, it might look like:
--
--     local style = l.style_whitespace..{back = l.colors.grey}
--     M._tokenstyles = {
--       {'custom_whitespace', style}
--     }
--
-- Remember it is generally not recommended to assign specific colors in styles,
-- but in this case, the color grey likely exists in all user color themes.
--
-- ### Line Lexers
--
-- By default, lexers match the arbitrary chunks of text passed to them by
-- Scintilla. These chunks may be a full document, only the visible part of a
-- document, or even just portions of lines. Some lexers need to match whole
-- lines. For example, a lexer for the output of a file "diff" needs to know if
-- the line started with a '+' or '-' and then style the entire line
-- accordingly. To indicate that your lexer matches by line, use the
-- `_LEXBYLINE` field:
--
--     M._LEXBYLINE = true
--
-- Now the input text for the lexer is a single line at a time. Keep in mind
-- that line lexers do not have the ability to look ahead at subsequent lines.
--
-- ### Embedded Lexers
--
-- Lexers can be embedded within one another very easily, requiring minimal
-- effort. In the following sections, the lexer being embedded is called the
-- "child" lexer and the lexer a child is being embedded in is called the
-- "parent". For example, consider an HTML lexer and a CSS lexer. Either lexer
-- can stand alone for styling their respective HTML and CSS files. However, CSS
-- can be embedded inside HTML. In this specific case, the CSS lexer is referred
-- to as the "child" lexer with the HTML lexer being the "parent". Now consider
-- an HTML lexer and a PHP lexer. This sounds a lot like the case with CSS, but
-- there is a subtle difference: PHP _embeds itself_ into HTML while CSS is
-- _embedded in_ HTML. This fundamental difference results in two types of
-- embedded lexers: a parent lexer that embeds other child lexers in it (like
-- HTML embedding CSS), and a child lexer that embeds itself within a parent
-- lexer (like PHP embedding itself in HTML).
--
-- #### Parent Lexer
--
-- Before you can embed a child lexer into a parent lexer, the child lexer needs
-- to be loaded inside the parent. This is done with the [`load()`](#load)
-- function. For example, loading the CSS lexer within the HTML lexer looks
-- like:
--
--     local css = l.load('css')
--
-- The next part of the embedding process is telling the parent lexer when to
-- switch over to the child lexer and when to switch back. These indications are
-- called the "start rule" and "end rule", respectively, and are just LPeg
-- patterns. Continuing with the HTML/CSS example, the transition from HTML to
-- CSS is when a "style" tag with a "type" attribute whose value is "text/css"
-- is encountered:
--
--     local css_tag = P('<style') * P(function(input, index)
--       if input:find('^[^>]+type="text/css"', index) then
--         return index
--       end
--     end)
--
-- This pattern looks for the beginning of a "style" tag and searches its
-- attribute list for the text "`type="text/css"`". (In this simplified example,
-- the Lua pattern does not consider whitespace between the '=' nor does it
-- consider that single quotes can be used instead of double quotes.) If there
-- is a match, the functional pattern returns a value instead of `nil`. In this
-- case, the value returned does not matter because we ultimately want the
-- "style" tag to be styled as an HTML tag, so the actual start rule looks like
-- this:
--
--     local css_start_rule = #css_tag * tag
--
-- Now that the parent knows when to switch to the child, it needs to know when
-- to switch back. In the case of HTML/CSS, the switch back occurs when an
-- ending "style" tag is encountered, but the tag should still be styled as an
-- HTML tag:
--
--     local css_end_rule = #P('</style>') * tag
--
-- Once the child lexer is loaded and its start and end rules are defined, you
-- can embed it in the parent using the [`embed_lexer()`](#embed_lexer)
-- function:
--
--     l.embed_lexer(M, css, css_start_rule, css_end_rule)
--
-- The first parameter is the parent lexer object to embed the child in, which
-- in this case is `M`. The other three parameters are the child lexer object
-- loaded earlier followed by its start and end rules.
--
-- #### Child Lexer
--
-- The process for instructing a child lexer to embed itself into a parent is
-- very similar to embedding a child into a parent: first, load the parent lexer
-- into the child lexer with the [`load()`](#load) function and then create
-- start and end rules for the child lexer. However, in this case, swap the
-- lexer object arguments to [`embed_lexer()`](#embed_lexer) and indicate
-- through a `_lexer` field in the child lexer that the parent should be used as
-- the primary lexer. For example, in the PHP lexer:
--
--     local html = l.load('hypertext')
--     local php_start_rule = token('php_tag', '<?php ')
--     local php_end_rule = token('php_tag', '?>')
--     l.embed_lexer(html, M, php_start_rule, php_end_rule)
--     M._lexer = html
--
-- The last line is very important. Without it, the PHP lexer's rules would be
-- used instead of the HTML lexer's rules.
--
-- ## Code Folding
--
-- When reading source code, it is occasionally helpful to temporarily hide
-- blocks of code like functions, classes, comments, etc. This concept is called
-- "folding". In the Textadept and SciTE editors for example, little indicators
-- in the editor margins appear next to code that can be folded at places called
-- "fold points". When an indicator is clicked, the code associated with it is
-- visually hidden until the indicator is clicked again. A lexer can specify
-- these fold points and what code exactly to fold.
--
-- The fold points for most languages occur on keywords or character sequences.
-- Examples of fold keywords are "if" and "end" in Lua and examples of fold
-- character sequences are '{', '}', "/\*", and "\*/" in C for code block and
-- comment delimiters, respectively. However, these fold points cannot occur
-- just anywhere. For example, fold keywords that appear within strings or
-- comments should not be recognized as fold points. Your lexer can conveniently
-- define fold points with such granularity in a `_foldsymbols` table. For
-- example, consider C:
--
--     M._foldsymbols = {
--       [l.OPERATOR] = {['{'] = 1, ['}'] = -1},
--       [l.COMMENT] = {['/*'] = 1, ['*/'] = -1},
--       _patterns = {'[{}]', '/%*', '%*/'}
--     }
--
-- The first assignment states that any '{' or '}' that the lexer recognized as
-- an `OPERATOR` token is a fold point. The integer `1` indicates the match is
-- a beginning fold point and `-1` indicates the match is an ending fold point.
-- Likewise, the second assignment states that any "/\*" or "\*/" that the lexer
-- recognizes as part of a `COMMENT` token is a fold point. Any occurences of
-- these characters outside their defined tokens (such as in a string) would not
-- be considered a fold point. Finally, every `_foldsymbols` table must have a
-- `_patterns` field that contains a list of [Lua patterns][] that match fold
-- points. If the lexer encounters text that matches one of those patterns, the
-- matched text is looked up in its token's table to determine whether or not it
-- is a fold point. In the example above, the first Lua pattern matches any '{'
-- or '}' characters. When the lexer comes across one of those characters, it
-- checks if the match is an `OPERATOR` token. If so, the match is identified as
-- a fold point. It is the same idea for the other patterns. (The '%' is in the
-- other patterns because '\*' is a special character in Lua patterns and it
-- must be escaped.) How are fold keywords specified? Here is an example for
-- Lua:
--
--     M._foldsymbols = {
--       [l.KEYWORD] = {
--         ['if'] = 1, ['do'] = 1, ['function'] = 1,
--         ['end'] = -1, ['repeat'] = 1, ['until'] = -1
--       },
--       _patterns = {'%l+'},
--     }
--
-- Any time the lexer encounters a lower case word, if that word is a `KEYWORD`
-- token and in the associated list of fold points, it is identified as a fold
-- point.
--
-- If your lexer needs to do some additional processing to determine if a fold
-- point has occurred on a match, you can assign a function that returns an
-- integer. Returning `1` or `-1` indicates the match is a fold point. Returning
-- `0` indicates it is not. For example:
--
--     local function fold_strange_token(text, pos, line, s, match)
--       if ... then
--         return 1 -- beginning fold point
--       elseif ... then
--         return -1 -- ending fold point
--       end
--       return 0
--     end
--
--     M._foldsymbols = {
--       ['strange_token'] = {['|'] = fold_strange_token},
--       _patterns = {'|'}
--     }
--
-- Any time the lexer encounters a '|' that is a "strange_token", it calls the
-- `fold_strange_token` function to determine if '|' is a fold point. These
-- kinds of functions are called with the following arguments: the text to fold,
-- the position of the start of the current line in the text to fold, the text
-- of the current line, the position in the current line the matched text starts
-- at, and the matched text itself.
--
-- [Lua patterns]: http://www.lua.org/manual/5.2/manual.html#6.4.1
--
-- ## Using Lexers
--
-- ### Textadept
--
-- Put your lexer in your *~/.textadept/lexers/* directory so it will not be
-- overwritten when upgrading Textadept. Also, lexers in this directory override
-- default lexers. Thus, a user *lua* lexer would be loaded instead of the
-- default *lua* lexer. This is convenient if you wish to tweak a default lexer
-- to your liking. Then add a [mime-type][] for your lexer if necessary.
--
-- [mime-type]: _M.textadept.mime_types.html
--
-- ### SciTE
--
-- Create a *.properties* file for your lexer and `import` it in either your
-- *SciTEUser.properties* or *SciTEGlobal.properties*. The contents of the
-- *.properties* file should contain:
--
--     file.patterns.[lexer_name]=[file_patterns]
--     lexer.$(file.patterns.[lexer_name])=[lexer_name]
--
-- where `[lexer_name]` is the name of your lexer (minus the *.lua* extension)
-- and `[file_patterns]` is a set of file extensions matched to your lexer.
--
-- Please note any styling information in *.properties* files is ignored.
-- Styling information for Lua lexers is contained in your theme file in the
-- *lexers/themes/* directory.
--
-- ## Considerations
--
-- ### Performance
--
-- There might be some slight overhead when initializing a lexer, but loading a
-- file from disk into Scintilla is usually more expensive. On modern computer
-- systems, I see no difference in speed between LPeg lexers and Scintilla's C++
-- ones. Lexers can usually be optimized for speed by re-arranging rules in the
-- `_rules` table so that the most common rules are matched first. Do keep in
-- mind the fact that order matters for similar rules.
--
-- ### Limitations
--
-- Embedded preprocessor languages like PHP are not completely embedded in their
-- parent languages in that the parent's tokens do not support start and end
-- rules. This mostly goes unnoticed, but code like
--
--     <div id="<?php echo $id; ?>">
--
-- or
--
--     <div <?php if ($odd) { echo 'class="odd"'; } ?>>
--
-- will not style correctly.
--
-- ### Troubleshooting
--
-- Errors in lexers can be tricky to debug. Lua errors are printed to
-- `io.stderr` and `_G.print()` statements in lexers are printed to `io.stdout`.
-- Running your editor from a terminal is the easiest way to see errors as they
-- occur.
--
-- ### Risks
--
-- Poorly written lexers have the ability to crash Scintilla (and thus its
-- containing application), so unsaved data might be lost. However, these
-- crashes have only been observed in early lexer development, when syntax
-- errors or pattern errors are present. Once the lexer actually starts styling
-- text (either correctly or incorrectly, it does not matter), no crashes have
-- been observed.
--
-- ### Acknowledgements
--
-- Thanks to Peter Odding for his [lexer post][] on the Lua mailing list
-- that inspired me, and thanks to Roberto Ierusalimschy for LPeg.
--
-- [lexer post]: http://lua-users.org/lists/lua-l/2007-04/msg00116.html
-- @field DEFAULT (string)
--   The token name for default tokens.
-- @field WHITESPACE (string)
--   The token name for whitespace tokens.
-- @field COMMENT (string)
--   The token name for comment tokens.
-- @field STRING (string)
--   The token name for string tokens.
-- @field NUMBER (string)
--   The token name for number tokens.
-- @field KEYWORD (string)
--   The token name for keyword tokens.
-- @field IDENTIFIER (string)
--   The token name for identifier tokens.
-- @field OPERATOR (string)
--   The token name for operator tokens.
-- @field ERROR (string)
--   The token name for error tokens.
-- @field PREPROCESSOR (string)
--   The token name for preprocessor tokens.
-- @field CONSTANT (string)
--   The token name for constant tokens.
-- @field VARIABLE (string)
--   The token name for variable tokens.
-- @field FUNCTION (string)
--   The token name for function tokens.
-- @field CLASS (string)
--   The token name for class tokens.
-- @field TYPE (string)
--   The token name for type tokens.
-- @field LABEL (string)
--   The token name for label tokens.
-- @field REGEX (string)
--   The token name for regex tokens.
-- @field any (pattern)
--   A pattern matching any single character.
-- @field ascii (pattern)
--   A pattern matching any ASCII character (`0`..`127`).
-- @field extend (pattern)
--   A pattern matching any ASCII extended character (`0`..`255`).
-- @field alpha (pattern)
--   A pattern matching any alphabetic character (`A-Z`, `a-z`).
-- @field digit (pattern)
--   A pattern matching any digit (`0-9`).
-- @field alnum (pattern)
--   A pattern matching any alphanumeric character (`A-Z`, `a-z`, `0-9`).
-- @field lower (pattern)
--   A pattern matching any lower case character (`a-z`).
-- @field upper (pattern)
--   A pattern matching any upper case character (`A-Z`).
-- @field xdigit (pattern)
--   A pattern matching any hexadecimal digit (`0-9`, `A-F`, `a-f`).
-- @field cntrl (pattern)
--   A pattern matching any control character (`0`..`31`).
-- @field graph (pattern)
--   A pattern matching any graphical character (`!` to `~`).
-- @field print (pattern)
--   A pattern matching any printable character (space to `~`).
-- @field punct (pattern)
--   A pattern matching any punctuation character not alphanumeric (`!` to `/`,
--   `:` to `@`, `[` to `'`, `{` to `~`).
-- @field space (pattern)
--   A pattern matching any whitespace character (`\t`, `\v`, `\f`, `\n`, `\r`,
--   space).
-- @field newline (pattern)
--   A pattern matching any newline characters.
-- @field nonnewline (pattern)
--   A pattern matching any non-newline character.
-- @field nonnewline_esc (pattern)
--   A pattern matching any non-newline character excluding newlines escaped
--   with '\'.
-- @field dec_num (pattern)
--   A pattern matching a decimal number.
-- @field hex_num (pattern)
--   A pattern matching a hexadecimal number.
-- @field oct_num (pattern)
--   A pattern matching an octal number.
-- @field integer (pattern)
--   A pattern matching a decimal, hexadecimal, or octal number.
-- @field float (pattern)
--   A pattern matching a floating point number.
-- @field word (pattern)
--   A pattern matching a typical word starting with a letter or underscore and
--   then any alphanumeric or underscore characters.
-- @field any_char (pattern)
--   A `DEFAULT` token matching any single character, useful in a fallback rule
--   for a grammar.
-- @field style_nothing (table)
--   The style typically used for no styling.
-- @field style_class (table)
--   The style typically used for class definitions.
-- @field style_comment (table)
--   The style typically used for code comments.
-- @field style_constant (table)
--   The style typically used for constants.
-- @field style_definition (table)
--   The style typically used for definitions.
-- @field style_error (table)
--   The style typically used for erroneous syntax.
-- @field style_function (table)
--   The style typically used for function definitions.
-- @field style_keyword (table)
--   The style typically used for language keywords.
-- @field style_label (table)
--   The style typically used for labels.
-- @field style_number (table)
--   The style typically used for numbers.
-- @field style_operator (table)
--   The style typically used for operators.
-- @field style_regex (table)
--   The style typically used for regular expression strings.
-- @field style_string (table)
--   The style typically used for strings.
-- @field style_preproc (table)
--   The style typically used for preprocessor statements.
-- @field style_tag (table)
--   The style typically used for markup tags.
-- @field style_type (table)
--   The style typically used for static types.
-- @field style_variable (table)
--   The style typically used for variables.
-- @field style_whitespace (table)
--   The style typically used for whitespace.
-- @field style_embedded (table)
--   The style typically used for embedded code.
-- @field style_identifier (table)
--   The style typically used for identifier words.
-- @field style_default (table)
--   The style all styles are based off of.
-- @field style_line_number (table)
--   The style used for all margins except fold margins.
-- @field style_bracelight (table)
--   The style used for highlighted brace characters.
-- @field style_bracebad (table)
--   The style used for unmatched brace characters.
-- @field style_controlchar (table)
--   The style used for control characters.
--   Color attributes are ignored.
-- @field style_indentguide (table)
--   The style used for indentation guides.
-- @field style_calltip (table)
--   The style used by call tips if `buffer.call_tip_use_style` is set.
--   Only the font name, size, and color attributes are used.
-- @field SC_FOLDLEVELBASE (number)
--   The initial (root) fold level.
-- @field SC_FOLDLEVELWHITEFLAG (number)
--   Flag indicating that the line is blank.
-- @field SC_FOLDLEVELHEADERFLAG (number)
--   Flag indicating the line is fold point.
-- @field SC_FOLDLEVELNUMBERMASK (number)
--   Flag used with `SCI_GETFOLDLEVEL(line)` to get the fold level of a line.
module('lexer')]=]

local lpeg = require 'lpeg'
local lpeg_P, lpeg_R, lpeg_S, lpeg_V = lpeg.P, lpeg.R, lpeg.S, lpeg.V
local lpeg_Ct, lpeg_Cc, lpeg_Cp = lpeg.Ct, lpeg.Cc, lpeg.Cp
local lpeg_match = lpeg.match

-- Adds a rule to a lexer's current ordered list of rules.
-- @param lexer The lexer to add the given rule to.
-- @param name The name associated with this rule. It is used for other lexers
--   to access this particular rule from the lexer's `_RULES` table. It does not
--   have to be the same as the name passed to `token`.
-- @param rule The LPeg pattern of the rule.
local function add_rule(lexer, id, rule)
  if not lexer._RULES then
    lexer._RULES = {}
    -- Contains an ordered list (by numerical index) of rule names. This is used
    -- in conjunction with lexer._RULES for building _TOKENRULE.
    lexer._RULEORDER = {}
  end
  lexer._RULES[id] = rule
  lexer._RULEORDER[#lexer._RULEORDER + 1] = id
end

-- Adds a new Scintilla style to Scintilla.
-- @param lexer The lexer to add the given style to.
-- @param token_name The name of the token associated with this style.
-- @param style A Scintilla style created from `style()`.
-- @see style
local function add_style(lexer, token_name, style)
  local len = lexer._STYLES.len
  if len == 32 then len = len + 8 end -- skip predefined styles
  if len >= 128 then print('Too many styles defined (128 MAX)') end
  lexer._TOKENS[token_name] = len
  lexer._STYLES[len] = style
  lexer._STYLES.len = len + 1
end

-- (Re)constructs `lexer._TOKENRULE`.
-- @param parent The parent lexer.
local function join_tokens(lexer)
  local patterns, order = lexer._RULES, lexer._RULEORDER
  local token_rule = patterns[order[1]]
  for i = 2, #order do token_rule = token_rule + patterns[order[i]] end
  lexer._TOKENRULE = token_rule
  return lexer._TOKENRULE
end

-- Adds a given lexer and any of its embedded lexers to a given grammar.
-- @param grammar The grammar to add the lexer to.
-- @param lexer The lexer to add.
local function add_lexer(grammar, lexer, token_rule)
  local token_rule = join_tokens(lexer)
  local lexer_name = lexer._NAME
  for _, child in ipairs(lexer._CHILDREN) do
    if child._CHILDREN then add_lexer(grammar, child) end
    local child_name = child._NAME
    local rules = child._EMBEDDEDRULES[lexer_name]
    local rules_token_rule = grammar['__'..child_name] or rules.token_rule
    grammar[child_name] = (-rules.end_rule * rules_token_rule)^0 *
                          rules.end_rule^-1 * lpeg_V(lexer_name)
    local embedded_child = '_'..child_name
    grammar[embedded_child] = rules.start_rule * (-rules.end_rule *
                              rules_token_rule)^0 * rules.end_rule^-1
    token_rule = lpeg_V(embedded_child) + token_rule
  end
  grammar['__'..lexer_name] = token_rule -- can contain embedded lexer rules
  grammar[lexer_name] = token_rule^0
end

-- (Re)constructs `lexer._GRAMMAR`.
-- @param lexer The parent lexer.
-- @param initial_rule The name of the rule to start lexing with. The default
--   value is `lexer._NAME`. Multilang lexers use this to start with a child
--   rule if necessary.
local function build_grammar(lexer, initial_rule)
  local children = lexer._CHILDREN
  if children then
    local lexer_name = lexer._NAME
    if not initial_rule then initial_rule = lexer_name end
    local grammar = {initial_rule}
    add_lexer(grammar, lexer)
    lexer._INITIALRULE = initial_rule
    lexer._GRAMMAR = lpeg_Ct(lpeg_P(grammar))
  else
    lexer._GRAMMAR = lpeg_Ct(join_tokens(lexer)^0)
  end
end

-- Default tokens.
-- Contains predefined token names and their associated style numbers.
-- @class table
-- @name tokens
-- @field default The default token's style (0).
-- @field whitespace The whitespace token's style (1).
-- @field comment The comment token's style (2).
-- @field string The string token's style (3).
-- @field number The number token's style (4).
-- @field keyword The keyword token's style (5).
-- @field identifier The identifier token's style (6).
-- @field operator The operator token's style (7).
-- @field error The error token's style (8).
-- @field preprocessor The preprocessor token's style (9).
-- @field constant The constant token's style (10).
-- @field variable The variable token's style (11).
-- @field function The function token's style (12).
-- @field class The class token's style (13).
-- @field type The type token's style (14).
-- @field label The label token's style (15).
-- @field regex The regex token's style (16).
local tokens = {
  default      = 0,
  whitespace   = 1,
  comment      = 2,
  string       = 3,
  number       = 4,
  keyword      = 5,
  identifier   = 6,
  operator     = 7,
  error        = 8,
  preprocessor = 9,
  constant     = 10,
  variable     = 11,
  ['function'] = 12,
  class        = 13,
  type         = 14,
  label        = 15,
  regex        = 16,
}
local string_upper = string.upper
for k, v in pairs(tokens) do M[string_upper(k)] = k end

---
-- Initializes or loads lexer *lexer_name* and returns the lexer object.
-- Scintilla calls this function to load a lexer. Parent lexers also call this
-- function to load child lexers and vice-versa.
-- @param lexer_name The name of the lexing language.
-- @return lexer object
-- @name load
function M.load(lexer_name)
  M.WHITESPACE = lexer_name..'_whitespace'
  local lexer = require(lexer_name or 'null')
  if not lexer then error('Lexer '..lexer_name..' does not exist') end
  lexer._TOKENS = tokens
  lexer._STYLES = {
    [0] = M.style_nothing,
    [1] = M.style_whitespace,
    [2] = M.style_comment,
    [3] = M.style_string,
    [4] = M.style_number,
    [5] = M.style_keyword,
    [6] = M.style_identifier,
    [7] = M.style_operator,
    [8] = M.style_error,
    [9] = M.style_preproc,
    [10] = M.style_constant,
    [11] = M.style_variable,
    [12] = M.style_function,
    [13] = M.style_class,
    [14] = M.style_type,
    [15] = M.style_label,
    [16] = M.style_regex,
    len = 17,
    -- Predefined styles.
    [32] = M.style_default,
    [33] = M.style_line_number,
    [34] = M.style_bracelight,
    [35] = M.style_bracebad,
    [36] = M.style_controlchar,
    [37] = M.style_indentguide,
    [38] = M.style_calltip,
  }
  if lexer._lexer then
    local l, _r, _s = lexer._lexer, lexer._rules, lexer._tokenstyles
    if not l._tokenstyles then l._tokenstyles = {} end
    for _, r in ipairs(_r or {}) do
      -- Prevent rule id clashes.
      l._rules[#l._rules + 1] = {lexer._NAME..'_'..r[1], r[2]}
    end
    for _, s in ipairs(_s or {}) do l._tokenstyles[#l._tokenstyles + 1] = s end
    -- Each lexer that is loaded with l.load() has its _STYLES modified through
    -- add_style(). Reset _lexer's _STYLES accordingly.
    -- For example: RHTML load's HTML (which loads CSS and Javascript). CSS's
    -- styles are added to css._STYLES and JS's styles are added to js._STYLES.
    -- HTML adds its styles to html._STYLES as well as CSS's and JS's styles.
    -- RHTML adds its styles, HTML's styles, CSS's styles, and JS's styles to
    -- rhtml._STYLES. The problem is that rhtml == _lexer == html. Therefore
    -- html._STYLES would contain duplicate styles. Compensate by setting
    -- html._STYLES to rhtml._STYLES.
    l._STYLES = lexer._STYLES
    lexer = l
  end
  if lexer._rules then
    for _, s in ipairs(lexer._tokenstyles or {}) do
      add_style(lexer, s[1], s[2])
    end
    for _, r in ipairs(lexer._rules) do add_rule(lexer, r[1], r[2]) end
    build_grammar(lexer)
  end
  add_style(lexer, lexer._NAME..'_whitespace', M.style_whitespace)
  if lexer._foldsymbols and lexer._foldsymbols._patterns then
    local patterns = lexer._foldsymbols._patterns
    for i = 1, #patterns do patterns[i] = '()('..patterns[i]..')' end
  end
  _G._LEXER = lexer
  return lexer
end

---
-- Lexes a chunk of text *text* with an initial style number of *init_style*.
-- Called by the Scintilla lexer; **do not call from Lua**. If the lexer has a
-- `_LEXBYLINE` flag set, the text is lexed one line at a time. Otherwise the
-- text is lexed as a whole.
-- @param text The text to lex.
-- @param init_style The current style. Multilang lexers use this to determine
--   which language to start lexing in.
-- @return table of token names and positions.
-- @name lex
function M.lex(text, init_style)
  local lexer = _G._LEXER
  if not lexer._LEXBYLINE then
    -- For multilang lexers, build a new grammar whose initial_rule is the
    -- current language.
    if lexer._CHILDREN then
      for style, style_num in pairs(lexer._TOKENS) do
        if style_num == init_style then
          local lexer_name = style:match('^(.+)_whitespace') or lexer._NAME
          if lexer._INITIALRULE ~= lexer_name then
            build_grammar(lexer, lexer_name)
          end
          break
        end
      end
    end
    return lpeg_match(lexer._GRAMMAR, text)
  else
    local tokens = {}
    local function append(tokens, line_tokens, offset)
      for i = 1, #line_tokens, 2 do
        tokens[#tokens + 1] = line_tokens[i]
        tokens[#tokens + 1] = line_tokens[i + 1] + offset
      end
    end
    local offset = 0
    local grammar = lexer._GRAMMAR
    for line in text:gmatch('[^\r\n]*\r?\n?') do
      local line_tokens = lpeg_match(grammar, line)
      if line_tokens then append(tokens, line_tokens, offset) end
      offset = offset + #line
      -- Use the default style to the end of the line if none was specified.
      if tokens[#tokens] ~= offset then
        tokens[#tokens + 1], tokens[#tokens + 2] = 'default', offset + 1
      end
    end
    return tokens
  end
end

local get_style_at = GetStyleAt
local get_property, get_indent_amount = GetProperty, GetIndentAmount
local FOLD_BASE = SC_FOLDLEVELBASE
local FOLD_HEADER  = SC_FOLDLEVELHEADERFLAG
local FOLD_BLANK = SC_FOLDLEVELWHITEFLAG

---
-- Folds *text*, a chunk of text starting at position *start_pos* on line number
-- *start_line* with a beginning fold level of *start_level* in the buffer.
-- Called by the Scintilla lexer; **do not call from Lua**. If the current lexer
-- has a `_fold` function or a `_foldsymbols` table, it is used to perform
-- folding. Otherwise, if a `fold.by.indentation` property is set, folding by
-- indentation is done.
-- @param text The document text to fold.
-- @param start_pos The position in the document text starts at.
-- @param start_line The line number text starts on.
-- @param start_level The fold level text starts on.
-- @return table of fold levels.
-- @name fold
function M.fold(text, start_pos, start_line, start_level)
  local folds = {}
  if text == '' then return folds end
  local lexer = _G._LEXER
  if lexer._fold then
    return lexer._fold(text, start_pos, start_line, start_level)
  elseif lexer._foldsymbols then
    local lines = {}
    for p, l in text:gmatch('()(.-)\r?\n') do lines[#lines + 1] = {p, l} end
    lines[#lines + 1] = {text:match('()([^\r\n]*)$')}
    local fold_symbols = lexer._foldsymbols
    local fold_symbols_patterns = fold_symbols._patterns
    local line_num, prev_level = start_line, start_level
    local current_level = prev_level
    for i = 1, #lines do
      local pos, line = lines[i][1], lines[i][2]
      if line ~= '' then
        for j = 1, #fold_symbols_patterns do
          for s, match in line:gmatch(fold_symbols_patterns[j]) do
            local symbols = fold_symbols[get_style_at(start_pos + pos + s - 1)]
            local l = symbols and symbols[match]
            if type(l) == 'number' then
              current_level = current_level + l
            elseif type(l) == 'function' then
              current_level = current_level + l(text, pos, line, s, match)
            end
          end
        end
        folds[line_num] = prev_level
        if current_level > prev_level then
          folds[line_num] = prev_level + FOLD_HEADER
        end
        if current_level < FOLD_BASE then current_level = FOLD_BASE end
        prev_level = current_level
      else
        folds[line_num] = prev_level + FOLD_BLANK
      end
      line_num = line_num + 1
    end
  elseif get_property('fold.by.indentation', 1) == 1 then
    -- Indentation based folding.
    local current_line, prev_level = start_line, start_level
    for _, line in text:gmatch('([\t ]*)(.-)\r?\n') do
      if line ~= '' then
        local current_level = FOLD_BASE + get_indent_amount(current_line)
        if current_level > prev_level then -- next level
          local i = current_line - 1
          while folds[i] and folds[i][2] == FOLD_BLANK do i = i - 1 end
          if folds[i] then folds[i][2] = FOLD_HEADER end -- low indent
          folds[current_line] = {current_level} -- high indent
        elseif current_level < prev_level then -- prev level
          if folds[current_line - 1] then
            folds[current_line - 1][1] = prev_level -- high indent
          end
          folds[current_line] = {current_level} -- low indent
        else -- same level
          folds[current_line] = {prev_level}
        end
        prev_level = current_level
      else
        folds[current_line] = {prev_level, FOLD_BLANK}
      end
      current_line = current_line + 1
    end
    -- Flatten.
    for line, level in pairs(folds) do
      folds[line] = level[1] + (level[2] or 0)
    end
  else
    -- No folding, reset fold levels if necessary.
    local current_line = start_line
    for _ in text:gmatch(".-\r?\n") do
      folds[current_line] = start_level
      current_line = current_line + 1
    end
  end
  return folds
end

-- The following are utility functions lexers will have access to.

-- Common patterns.
M.any = lpeg_P(1)
M.ascii = lpeg_R('\000\127')
M.extend = lpeg_R('\000\255')
M.alpha = lpeg_R('AZ', 'az')
M.digit = lpeg_R('09')
M.alnum = lpeg_R('AZ', 'az', '09')
M.lower = lpeg_R('az')
M.upper = lpeg_R('AZ')
M.xdigit = lpeg_R('09', 'AF', 'af')
M.cntrl = lpeg_R('\000\031')
M.graph = lpeg_R('!~')
M.print = lpeg_R(' ~')
M.punct = lpeg_R('!/', ':@', '[\'', '{~')
M.space = lpeg_S('\t\v\f\n\r ')

M.newline = lpeg_S('\r\n\f')^1
M.nonnewline = 1 - M.newline
M.nonnewline_esc = 1 - (M.newline + '\\') + '\\' * M.any

M.dec_num = M.digit^1
M.hex_num = '0' * lpeg_S('xX') * M.xdigit^1
M.oct_num = '0' * lpeg_R('07')^1
M.integer = lpeg_S('+-')^-1 * (M.hex_num + M.oct_num + M.dec_num)
M.float = lpeg_S('+-')^-1 *
          (M.digit^0 * '.' * M.digit^1 + M.digit^1 * '.' * M.digit^0 +
           M.digit^1) *
          lpeg_S('eE') * lpeg_S('+-')^-1 * M.digit^1
M.word = (M.alpha + '_') * (M.alnum + '_')^0

---
-- Creates and returns a token pattern with the name *name* and pattern *patt*.
-- If *name* is not a predefined token name, its style must be defined in the
-- lexer's `_tokenstyles` table.
-- @param name The name of token. If this name is not a predefined token name,
--   then a style needs to be assiciated with it in the lexer's `_tokenstyles`
--   table.
-- @param patt The LPeg pattern associated with the token.
-- @return pattern
-- @usage local ws = token(l.WHITESPACE, l.space^1)
-- @usage local annotation = token('annotation', '@' * l.word)
-- @name token
function M.token(name, patt)
  return lpeg_Cp() * lpeg_Cc(name) * patt * lpeg_Cp()
end

-- Common tokens
M.any_char = M.token(M.DEFAULT, M.any)

---
-- Table of common colors for a theme.
-- This table should be redefined in each theme.
-- @class table
-- @name colors
M.colors = {}

---
-- Creates and returns a Scintilla style from the given table of style
-- properties.
-- @param style_table A table of style properties:
--   * `font` (string) The name of the font the style uses.
--   * `size` (number) The size of the font the style uses.
--   * `bold` (bool) Whether or not the font face is bold.
--   * `italic` (bool) Whether or not the font face is italic.
--   * `underline` (bool) Whether or not the font face is underlined.
--   * `fore` (number) The foreground [`color`](#color) of the font face.
--   * `back` (number) The background [`color`](#color) of the font face.
--   * `eolfilled` (bool) Whether or not the background color extends to the end
--     of the line.
--   * `case` (number) The case of the font (1 = upper, 2 = lower, 0 = normal).
--   * `visible` (bool) Whether or not the text is visible.
--   * `changeable` (bool) Whether the text changable or read-only.
--   * `hotspot` (bool) Whether or not the text is clickable.
-- @return style table
-- @usage local style_bold_italic = style{bold = true, italic = true}
-- @usage local style_grey = style{fore = l.colors.grey}
-- @see color
-- @name style
function M.style(style_table)
  setmetatable(style_table, {
    __concat = function(t1, t2)
      local t = setmetatable({}, getmetatable(t1)) -- duplicate t1
      for k,v in pairs(t1) do t[k] = v end
      for k,v in pairs(t2) do t[k] = v end
      return t
    end
  })
  return style_table
end

---
-- Creates and returns a Scintilla color from *r*, *g*, and *b* string
-- hexadecimal color components.
-- @param r The string red hexadecimal component of the color.
-- @param g The string green hexadecimal component of the color.
-- @param b The string blue hexadecimal component of the color.
-- @return integer color for Scintilla.
-- @usage local red = color('FF', '00', '00')
-- @name color
function M.color(r, g, b) return tonumber(b..g..r, 16) end

---
-- Creates and returns a pattern that matches a range of text bounded by
-- *chars* characters.
-- This is a convenience function for matching more complicated delimited ranges
-- like strings with escape characters and balanced parentheses. *escape*
-- specifies the escape characters a range can have, *end_optional* indicates
-- whether or not unterminated ranges match, *balanced* indicates whether or not
-- to handle balanced ranges like parentheses and requires *chars* to be
-- composed of two characters, and *forbidden* is a set of characters disallowed
-- in ranges such as newlines.
-- @param chars The character(s) that bound the matched range.
-- @param escape Optional escape character. This parameter may `nil` or the
--   empty string to indicate no escape character.
-- @param end_optional Optional flag indicating whether or not an ending
--   delimiter is optional or not. If `true`, the range begun by the start
--   delimiter matches until an end delimiter or the end of the input is
--   reached.
-- @param balanced Optional flag indicating whether or not a balanced range is
--   matched, like the "%b" Lua pattern. This flag only applies if `chars`
--   consists of two different characters (e.g. "()").
-- @param forbidden Optional string of characters forbidden in a delimited
--   range. Each character is part of the set. This is particularly useful for
--   disallowing newlines in delimited ranges.
-- @return pattern
-- @usage local dq_str_noescapes = l.delimited_range('"', nil, true)
-- @usage local dq_str_escapes = l.delimited_range('"', '\\', true)
-- @usage local unbalanced_parens = l.delimited_range('()', '\\')
-- @usage local balanced_parens = l.delimited_range('()', '\\', false, true)
-- @see nested_pair
-- @name delimited_range
function M.delimited_range(chars, escape, end_optional, balanced, forbidden)
  local s = chars:sub(1, 1)
  local e = #chars == 2 and chars:sub(2, 2) or s
  local range
  local b = balanced and s or ''
  local f = forbidden or ''
  if not escape or escape == '' then
    local invalid = lpeg_S(e..f..b)
    range = M.any - invalid
  else
    local invalid = lpeg_S(e..f..b) + escape
    range = M.any - invalid + escape * M.any
  end
  if balanced and s ~= e then
    return lpeg_P{s * (range + lpeg_V(1))^0 * e}
  else
    if end_optional then e = lpeg_P(e)^-1 end
    return s * range^0 * e
  end
end

---
-- Creates and returns a pattern that matches pattern *patt* only at the
-- beginning of a line.
-- @param patt The LPeg pattern to match on the beginning of a line.
-- @return pattern
-- @usage local preproc = token(l.PREPROCESSOR, #P('#') * l.starts_line('#' *
--   l.nonnewline^0))
-- @name starts_line
function M.starts_line(patt)
  return lpeg_P(function(input, index)
    if index == 1 then return index end
    local char = input:sub(index - 1, index - 1)
    if char == '\n' or char == '\r' or char == '\f' then return index end
  end) * patt
end

---
-- Creates and returns a pattern that matches any previous non-whitespace
-- character in *s* and consumes no input.
-- @param s String character set like one passed to `lpeg.S()`.
-- @return pattern
-- @usage local regex = l.last_char_includes('+-*!%^&|=,([{') *
--   l.delimited_range('/', '\\')
-- @name last_char_includes
function M.last_char_includes(s)
  s = '['..s:gsub('[-%%%[]', '%%%1')..']'
  return lpeg_P(function(input, index)
    if index == 1 then return index end
    local i = index
    while input:sub(i - 1, i - 1):match('[ \t\r\n\f]') do i = i - 1 end
    if input:sub(i - 1, i - 1):match(s) then return index end
  end)
end

---
-- Similar to `delimited_range()`, but allows for multi-character, nested
-- delimiters *start_chars* and *end_chars*. *end_optional* indicates whether or
-- not unterminated ranges match.
-- With single-character delimiters, this function is identical to
-- `delimited_range(start_chars..end_chars, nil, end_optional, true)`.
-- @param start_chars The string starting a nested sequence.
-- @param end_chars The string ending a nested sequence.
-- @param end_optional Optional flag indicating whether or not an ending
--   delimiter is optional or not. If `true`, the range begun by the start
--   delimiter matches until an end delimiter or the end of the input is
--   reached.
-- @return pattern
-- @usage local nested_comment = l.nested_pair('/*', '*/', true)
-- @see delimited_range
-- @name nested_pair
function M.nested_pair(start_chars, end_chars, end_optional)
  local s, e = start_chars, end_optional and lpeg_P(end_chars)^-1 or end_chars
  return lpeg_P{s * (M.any - s - end_chars + lpeg_V(1))^0 * e}
end

---
-- Creates and returns a pattern that matches any word in the set *words*
-- case-sensitively, unless *case_insensitive* is `true`, with the set of word
-- characters being alphanumerics, underscores, and all of the characters in
-- *word_chars*.
-- This is a convenience function for simplifying a set of ordered choice word
-- patterns.
-- @param words A table of words.
-- @param word_chars Optional string of additional characters considered to be
--   part of a word. By default, word characters are alphanumerics and
--   underscores ("%w_" in Lua). This parameter may be `nil` or the empty string
--   to indicate no additional word characters.
-- @param case_insensitive Optional boolean flag indicating whether or not the
--   word match is case-insensitive. The default is `false`.
-- @return pattern
-- @usage local keyword = token(l.KEYWORD, word_match{'foo', 'bar', 'baz'})
-- @usage local keyword = token(l.KEYWORD, word_match({'foo-bar', 'foo-baz',
--   'bar-foo', 'bar-baz', 'baz-foo', 'baz-bar'}, '-', true))
-- @name word_match
function M.word_match(words, word_chars, case_insensitive)
  local word_list = {}
  for _, word in ipairs(words) do
    word_list[case_insensitive and word:lower() or word] = true
  end
  local chars = '%w_'
  -- escape 'magic' characters
  -- TODO: append chars to the end so ^_ can be passed for not including '_'s
  if word_chars then chars = chars..word_chars:gsub('([%^%]%-])', '%%%1') end
  return lpeg_P(function(input, index)
      local s, e, word = input:find('^(['..chars..']+)', index)
      if word then
        if case_insensitive then word = word:lower() end
        return word_list[word] and e + 1 or nil
      end
    end)
end

---
-- Embeds *child* lexer in *parent* with *start_rule* and *end_rule*, patterns
-- that signal the beginning and end of the embedded lexer, respectively.
-- @param parent The parent lexer.
-- @param child The child lexer.
-- @param start_rule The pattern that signals the beginning of the embedded
--   lexer.
-- @param end_rule The pattern that signals the end of the embedded lexer.
-- @usage l.embed_lexer(M, css, css_start_rule, css_end_rule)
-- @usage l.embed_lexer(html, M, php_start_rule, php_end_rule)
-- @usage l.embed_lexer(html, ruby, ruby_start_rule, ruby_end_rule)
-- @name embed_lexer
function M.embed_lexer(parent, child, start_rule, end_rule)
  -- Add child rules.
  if not child._EMBEDDEDRULES then child._EMBEDDEDRULES = {} end
  if not child._RULES then -- creating a child lexer to be embedded
    if not child._rules then error('Cannot embed language with no rules') end
    for _, r in ipairs(child._rules) do add_rule(child, r[1], r[2]) end
  end
  child._EMBEDDEDRULES[parent._NAME] = {
    ['start_rule'] = start_rule,
    token_rule = join_tokens(child),
    ['end_rule'] = end_rule
  }
  if not parent._CHILDREN then parent._CHILDREN = {} end
  local children = parent._CHILDREN
  children[#children + 1] = child
  -- Add child styles.
  if not parent._tokenstyles then parent._tokenstyles = {} end
  local tokenstyles = parent._tokenstyles
  tokenstyles[#tokenstyles + 1] = {child._NAME..'_whitespace',
                                   M.style_whitespace}
  for _, style in ipairs(child._tokenstyles or {}) do
    tokenstyles[#tokenstyles + 1] = style
  end
end

-- Determines if the previous line is a comment.
-- This is used for determining if the current comment line is a fold point.
-- @param prefix The prefix string defining a comment.
-- @param text The text passed to a fold function.
-- @param pos The pos passed to a fold function.
-- @param line The line passed to a fold function.
-- @param s The s passed to a fold function.
local function prev_line_is_comment(prefix, text, pos, line, s)
  local start = line:find('%S')
  if start < s and not line:find(prefix, start, true) then return false end
  local p = pos - 1
  if text:sub(p, p) == '\n' then
    p = p - 1
    if text:sub(p, p) == '\r' then p = p - 1 end
    if text:sub(p, p) ~= '\n' then
      while p > 1 and text:sub(p - 1, p - 1) ~= '\n' do p = p - 1 end
      while text:sub(p, p):find('^[\t ]$') do p = p + 1 end
      return text:sub(p, p + #prefix - 1) == prefix
    end
  end
  return false
end

-- Determines if the next line is a comment.
-- This is used for determining if the current comment line is a fold point.
-- @param prefix The prefix string defining a comment.
-- @param text The text passed to a fold function.
-- @param pos The pos passed to a fold function.
-- @param line The line passed to a fold function.
-- @param s The s passed to a fold function.
local function next_line_is_comment(prefix, text, pos, line, s)
  local p = text:find('\n', pos + s)
  if p then
    p = p + 1
    while text:sub(p, p):find('^[\t ]$') do p = p + 1 end
    return text:sub(p, p + #prefix - 1) == prefix
  end
  return false
end

---
-- Returns a fold function, to be used within the lexer's `_foldsymbols` table,
-- that folds consecutive line comments beginning with string *prefix*.
-- @param prefix The prefix string defining a line comment.
-- @usage [l.COMMENT] = {['--'] = l.fold_line_comments('--')}
-- @usage [l.COMMENT] = {['//'] = l.fold_line_comments('//')}
-- @name fold_line_comments
function M.fold_line_comments(prefix)
  return function(text, pos, line, s)
    if get_property('fold.line.comments', 0) == 0 then return 0 end
    if s > 1 and line:match('^%s*()') < s then return 0 end
    local prev_line_comment = prev_line_is_comment(prefix, text, pos, line, s)
    local next_line_comment = next_line_is_comment(prefix, text, pos, line, s)
    if not prev_line_comment and next_line_comment then return 1 end
    if prev_line_comment and not next_line_comment then return -1 end
    return 0
  end
end

---
-- Individual lexer fields.
-- @field _NAME The string name of the lexer in lowercase.
-- @field _rules An ordered list of rules for a lexer grammar.
--   Each rule is a table containing an arbitrary rule name and the LPeg pattern
--   associated with the rule. The order of rules is important as rules are
--   matched sequentially. Ensure there is a fallback rule in case the lexer
--   encounters any unexpected input, usually using the predefined `l.any_char`
--   token.
--   Child lexers should not use this table to access and/or modify their
--   parent's rules and vice-versa. Use the `_RULES` table instead.
-- @field _tokenstyles A list of styles associated with non-predefined token
--   names.
--   Each token style is a table containing the name of the token (not a rule
--   containing the token) and the style associated with the token. The order of
--   token styles is not important.
--   It is recommended to use predefined styles or color-agnostic styles derived
--   from predefined styles to ensure compatibility with user color themes.
-- @field _foldsymbols A table of recognized fold points for the lexer.
--   Keys are token names with table values defining fold points. Those table
--   values have string keys of keywords or characters that indicate a fold
--   point whose values are integers. A value of `1` indicates a beginning fold
--   point and a value of `-1` indicates an ending fold point. Values can also
--   be functions that return `1`, `-1`, or `0` (indicating no fold point) for
--   keys which need additional processing.
--   There is also a required `_pattern` key whose value is a table containing
--   Lua pattern strings that match all fold points (the string keys contained
--   in token name table values). When the lexer encounters text that matches
--   one of those patterns, the matched text is looked up in its token's table
--   to determine whether or not it is a fold point.
-- @field _fold If this function exists in the lexer, it is called for folding
--   the document instead of using `_foldsymbols` or indentation.
-- @field _lexer For child lexers embedding themselves into a parent lexer, this
--   field should be set to the parent lexer object in order for the parent's
--   rules to be used instead of the child's.
-- @field _RULES A map of rule name keys with their associated LPeg pattern
--   values for the lexer.
--   This is constructed from the lexer's `_rules` table and accessible to other
--   lexers for embedded lexer applications like modifying parent or child
--   rules.
-- @field _LEXBYLINE Indicates the lexer matches text by whole lines instead of
--    arbitrary chunks.
--    The default value is `false`. Line lexers cannot look ahead to subsequent
--    lines.
-- @class table
-- @name lexer
local lexer

-- Registered functions and constants.

---
-- Returns the string style name and style number at position *pos* in the
-- buffer.
-- @param pos The position to get the style for.
-- @return style name
-- @return style number
-- @class function
-- @name get_style_at
M.get_style_at = GetStyleAt

---
-- Returns the integer property value associated with string property *key*, or
-- *default*.
-- @param key The property key.
-- @param default Optional integer value to return if key is not set.
-- @return integer property value
-- @class function
-- @name get_property
M.get_property = GetProperty

---
-- Returns the fold level for line number *line_number*.
-- This level already has `SC_FOLDLEVELBASE` added to it, so you do not need to
-- add it yourself.
-- @param line_number The line number to get the fold level of.
-- @return integer fold level
-- @class function
-- @name get_fold_level
M.get_fold_level = GetFoldLevel

---
-- Returns the amount of indentation the text on line number *line_number* has.
-- @param line_number The line number to get the indent amount of.
-- @return integer indent amount
-- @class function
-- @name get_indent_amount
M.get_indent_amount = GetIndentAmount

M.SC_FOLDLEVELBASE = SC_FOLDLEVELBASE
M.SC_FOLDLEVELWHITEFLAG = SC_FOLDLEVELWHITEFLAG
M.SC_FOLDLEVELHEADERFLAG = SC_FOLDLEVELHEADERFLAG
M.SC_FOLDLEVELNUMBERMASK = SC_FOLDLEVELNUMBERMASK

return M
