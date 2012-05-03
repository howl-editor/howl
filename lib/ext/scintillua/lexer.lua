-- Copyright 2006-2012 Mitchell mitchell.att.foicica.com. See LICENSE.

local M = {}

--[[ This comment is for LuaDoc.
---
-- Performs lexing of Scintilla documents.
module('lexer')]]

-- Markdown:
-- ## Overview
--
-- Dynamic lexers are more flexible than Scintilla's static ones. They are often
-- more readable as well. This document provides all the information necessary
-- in order to write a new lexer. For illustrative purposes, a Lua lexer will be
-- created. Lexers are written using Parsing Expression Grammars or PEGs with
-- the Lua [LPeg library][LPeg]. Please familiarize yourself with LPeg's
-- documentation before proceeding.
--
-- [LPeg]: http://www.inf.puc-rio.br/~roberto/lpeg/lpeg.html
--
-- ## Writing a Dynamic Lexer
--
-- Rather than writing a lexer from scratch, first see if your language is
-- similar to any of the 80+ languages supported. If so, you can copy and modify
-- that lexer, saving some time and effort.
--
-- ### Introduction
--
-- All lexers are contained in the `lexers/` directory. To begin, create a Lua
-- script with the name of your lexer and open it for editing.
--
--     $> cd lexers
--     $> textadept lua.lua
--
-- Inside the file, the lexer should look like the following:
--
--     -- Lua LPeg lexer
--
--     local l = lexer
--     local token, word_match = l.token, l.word_match
--     local P, R, S, V = lpeg.P, lpeg.R, lpeg.S, lpeg.V
--
--     local M = { _NAME = 'lua' }
--
--     -- Lexer code goes here.
--
--     return M
--
-- where the value of `_NAME` should be replaced with your lexer's name.
--
-- Like most Lua modules, the lexer module will store all of its data in a table
-- `M` so as not to clutter the global namespace with lexer-specific patterns
-- and variables. Therefore, remember to use the prefix `M` when declaring and
-- using non-local variables. Also, do not forget the `return M` at the end.
--
-- The local variables above give easy access to the many useful functions
-- available for creating lexers.
--
-- ### Lexer Language Structure
--
-- It is important to spend some time considering the structure of the language
-- you are creating the lexer for. What kinds of tokens does it have? Comments,
-- strings, keywords, etc.? Lua has 9 tokens: whitespace, comments, strings,
-- numbers, keywords, functions, constants, identifiers, and operators.
--
-- ### Tokens
--
-- In a lexer, tokens are comprised of a token type followed by an LPeg pattern.
-- They are created using the [`token()`](#token) function. The `lexer` (`l`)
-- module provides a number of default token types:
--
-- * `DEFAULT`
-- * `WHITESPACE`
-- * `COMMENT`
-- * `STRING`
-- * `NUMBER`
-- * `KEYWORD`
-- * `IDENTIFIER`
-- * `OPERATOR`
-- * `ERROR`
-- * `PREPROCESSOR`
-- * `CONSTANT`
-- * `VARIABLE`
-- * `FUNCTION`
-- * `CLASS`
-- * `TYPE`
-- * `LABEL`
-- * `REGEX`
--
-- Please note you are not limited to just these token types; you can create
-- your own. If you create your own, you will have to specify how they are
-- colored. The procedure is discussed later.
--
-- A whitespace token typically looks like:
--
--     local ws = token(l.WHITESPACE, S('\t\v\f\n\r ')^1)
--
-- It is difficult to remember that a space character is either a `\t`, `\v`,
-- `\f`, `\n`, `\r`, or ` `. The `lexer` module also provides you with a
-- shortcut for this and many other character sequences. They are:
--
-- * `any`
--   Matches any single character.
-- * `ascii`
--   Matches any ASCII character (`0`..`127`).
-- * `extend`
--   Matches any ASCII extended character (`0`..`255`).
-- * `alpha`
--   Matches any alphabetic character (`A-Z`, `a-z`).
-- * `digit`
--   Matches any digit (`0-9`).
-- * `alnum`
--   Matches any alphanumeric character (`A-Z`, `a-z`, `0-9`).
-- * `lower`
--   Matches any lowercase character (`a-z`).
-- * `upper`
--   Matches any uppercase character (`A-Z`).
-- * `xdigit`
--   Matches any hexadecimal digit (`0-9`, `A-F`, `a-f`).
-- * `cntrl`
--   Matches any control character (`0`..`31`).
-- * `graph`
--   Matches any graphical character (`!` to `~`).
-- * `print`
--   Matches any printable character (space to `~`).
-- * `punct`
--   Matches any punctuation character not alphanumeric (`!` to `/`, `:` to `@`,
--   `[` to `'`, `{` to `~`).
-- * `space`
--   Matches any whitespace character (`\t`, `\v`, `\f`, `\n`, `\r`, space).
-- * `newline`
--   Matches any newline characters.
-- * `nonnewline`
--   Matches any non-newline character.
-- * `nonnewline_esc`
--   Matches any non-newline character excluding newlines escaped with `\\`.
-- * `dec_num`
--   Matches a decimal number.
-- * `hex_num`
--   Matches a hexadecimal number.
-- * `oct_num`
--   Matches an octal number.
-- * `integer`
--   Matches a decimal, hexadecimal, or octal number.
-- * `float`
--   Matches a floating point number.
-- * `word`
--   Matches a typical word starting with a letter or underscore and then any
--   alphanumeric or underscore characters.
--
-- The above whitespace token can be rewritten more simply as:
--
--     local ws = token(l.WHITESPACE, l.space^1)
--
-- The next Lua token is a comment. Short comments beginning with `--` are easy
-- to express with LPeg:
--
--     local line_comment = '--' * l.nonnewline^0
--
-- On the other hand, long comments are more difficult to express because they
-- have levels. See the [Lua Reference Manual][lexical_conventions] for more
-- information. As a result, a functional pattern is necessary:
--
--     local longstring = #('[[' + ('[' * P('=')^0 * '[')) *
--       P(function(input, index)
--         local level = input:match('^%[(=*)%[', index)
--         if level then
--           local _, stop = input:find(']'..level..']', index, true)
--           return stop and stop + 1 or #input + 1
--         end
--       end)
--     local block_comment = '--' * longstring
--
-- The token for a comment is then:
--
--     local comment = token(l.COMMENT, line_comment + block_comment)
--
-- [lexical_conventions]: http://www.lua.org/manual/5.2/manual.html#3.1
--
-- It is worth noting that while token names are arbitrary, you are encouraged
-- to use the ones listed in the [`tokens`](#tokens) table because a standard
-- color theme is applied to them. If you wish to create a unique token, no
-- problem. You can specify how it will be displayed later on.
--
-- Lua strings should be easy to express because they are just characters
-- surrounded by `'` or `"` characters, right? Not quite. Lua strings contain
-- escape sequences (`\`*`char`*) so a `\'` sequence in a single-quoted string
-- does not indicate the end of a string and must be handled appropriately.
-- Fortunately, this is a common occurance in many programming languages, so a
-- convenient function is provided: [`delimited_range()`](#delimited_range).
--
--     local sq_str = l.delimited_range("'", '\\', true)
--     local dq_str = l.delimited_range('"', '\\', true)
--
-- Lua also has multi-line strings, but they have the same format as block
-- comments. All strings can all be combined into a token:
--
--     local string = token(l.STRING, sq_str + dq_str + longstring)
--
-- Numbers are easy in Lua using `lexer`'s predefined patterns.
--
--     local lua_integer = P('-')^-1 * (l.hex_num + l.dec_num)
--     local number = token(l.NUMBER, l.float + lua_integer)
--
-- Keep in mind that the predefined patterns may not be completely accurate for
-- your language, so you may have to create your own variants. In the above
-- case, Lua integers do not have octal sequences, so the `l.integer` pattern is
-- not used.
--
-- Depending on the number of keywords for a particular language, a simple
-- `P(keyword1) + P(keyword2) + ... + P(keywordN)` pattern can get quite large.
-- In fact, LPeg has a limit on pattern size. Also, if the keywords are not case
-- sensitive, additional complexity arises, so a better approach is necessary.
-- Once again, `lexer` has a shortcut function: [`word_match()`](#word_match).
--
--     local keyword = token(l.KEYWORD, word_match {
--       'and', 'break', 'do', 'else', 'elseif', 'end', 'false', 'for',
--       'function', 'goto', 'if', 'in', 'local', 'nil', 'not', 'or', 'repeat',
--       'return', 'then', 'true', 'until', 'while'
--     })
--
-- If keywords were case-insensitive, an additional parameter would be specified
-- in the call to [`word_match()`](#word_match); no other action is needed.
--
-- Lua functions and constants are specified like keywords:
--
--     local func = token(l.FUNCTION, word_match {
--       'assert', 'collectgarbage', 'dofile', 'error', 'getmetatable',
--       'ipairs', 'load', 'loadfile', 'next', 'pairs', 'pcall', 'print',
--       'rawequal', 'rawget', 'rawlen', 'rawset', 'require', 'setmetatable',
--       'tonumber', 'tostring', 'type', 'xpcall'
--     })
--
--     local constant = token(l.CONSTANT, word_match {
--       '_G', '_VERSION'
--     })
--
-- Like most programming languages, Lua allows the usual characters in
-- identifier names (variables, functions, etc.) so the usual `l.word` can be
-- used:
--
--     local identifier = token(l.IDENTIFIER, l.word)
--
-- Lua has labels too:
--
--     local label = token(l.LABEL, '::' * l.word * '::')
--
-- Finally, an operator character is one of the following:
--
--     local operator = token(l.OPERATOR, '~=' + S('+-*/%^#=<>;:,.{}[]()'))
--
-- ### Rules
--
-- Rules are just a combination of tokens. In Lua, all rules consist of a
-- single token, but other languages may have two or more tokens in a rule.
-- For example, an HTML tag consists of an element token followed by an
-- optional set of attribute tokens. This allows each part of the tag to be
-- colored distinctly.
--
-- The set of rules that comprises Lua is specified in a `M._rules` table for
-- the lexer.
--
--     M._rules = {
--       { 'whitespace', ws },
--       { 'keyword', keyword },
--       { 'function', func },
--       { 'constant', constant },
--       { 'identifier', identifier },
--       { 'string', string },
--       { 'comment', comment },
--       { 'number', number },
--       { 'label', label },
--       { 'operator', operator },
--       { 'any_char', l.any_char },
--     }
--
-- Each entry is a rule name and its associated pattern. Please note that the
-- names of the rules can be completely different than the names of the tokens
-- contained within them.
--
-- The order of the rules is important because of the nature of LPeg. LPeg tries
-- to apply the first rule to the current position in the text it is matching.
-- If there is a match, it colors that section appropriately and moves on. If
-- there is not a match, it tries the next rule, and so on. Suppose instead that
-- the `identifier` rule was before the `keyword` rule. It can be seen that all
-- keywords satisfy the requirements for being an identifier, so any keywords
-- would be incorrectly colored as identifiers. This is why `identifier` is
-- where it is in the `M._rules` table.
--
-- You might be wondering what that `any_char` is doing at the bottom of
-- `M._rules`. Its purpose is to match anything not accounted for in the above
-- rules. For example, suppose the `!` character is in the input text. It will
-- not be matched by any of the first 9 rules, so without `any_char`, the text
-- would not match at all, and no coloring would occur. `any_char` matches one
-- single character and moves on. It may be colored red (indicating a syntax
-- error) if desired because it is a token, not just a pattern.
--
-- ### Summary
--
-- The above method of defining tokens and rules is sufficient for a majority of
-- lexers. The `lexer` module provides many useful patterns and functions for
-- constructing a working lexer quickly and efficiently. In most cases, the
-- amount of knowledge of LPeg required to write a lexer is minimal.
--
-- As long as you used the default token types provided by `lexer`, you do not
-- have to specify any coloring (or styling) information in the lexer; it is
-- taken care of by the user's color theme.
--
-- The rest of this document is devoted to more complex lexer techniques.
--
-- ### Styling Tokens
--
-- The term for coloring text is styling. Just like with predefined LPeg
-- patterns in `lexer`, predefined styles are available.
--
-- * `style_nothing`
--   Typically used for whitespace.
-- * `style_class`
--   Typically used for class definitions.
-- * `style_comment`
--   Typically used for code comments.
-- * `style_constant`
--   Typically used for constants.
-- * `style_definition`
--   Typically used for definitions.
-- * `style_error`
--   Typically used for erroneous syntax.
-- * `style_function`
--   Typically used for function definitions.
-- * `style_keyword`
--   Typically used for language keywords.
-- * `style_label`
--   Typically used for labels.
-- * `style_number`
--   Typically used for numbers.
-- * `style_operator`
--   Typically used for operators.
-- * `style_regex`
--   Typically used for regular expression strings.
-- * `style_string`
--   Typically used for strings.
-- * `style_preproc`
--   Typically used for preprocessor statements.
-- * `style_tag`
--   Typically used for markup tags.
-- * `style_type`
--   Typically used for static types.
-- * `style_variable`
--   Typically used for variables.
-- * `style_embedded`
--   Typically used for embedded code.
-- * `style_identifier`
--   Typically used for identifier words.
--
-- Each style consists of a set of attributes:
--
-- + `font`: The style's font name.
-- + `size`: The style's font size.
-- + `bold`: Flag indicating whether or not the font is boldface.
-- + `italic`: Flag indicating whether or not the font is italic.
-- + `underline`: Flag indicating whether or not the font is underlined.
-- + `fore`: The color of the font face.
-- + `back`: The color of the font background.
-- + `eolfilled`: Flag indicating whether or not to color the end of the line.
-- + `characterset`: The character set of the font.
-- + `case`: The case of the font. 1 for upper case, 2 for lower case, 0 for
--   normal case.
-- + `visible`: Flag indicating whether or not the text is visible.
-- + `changable`: Flag indicating whether or not the text is read-only.
-- + `hotspot`: Flag indicating whether or not the style is clickable.
--
-- Styles are created with [`style()`](#style). For example:
--
--     -- style with default theme settings
--     local style_nothing = l.style { }
--
--     -- style with bold text with default theme font
--     local style_bold = l.style { bold = true }
--
--     -- style with bold italic text with default theme font
--     local style_bold_italic = l.style { bold = true, italic = true }
--
-- The `style_bold_italic` style can be rewritten in terms of `style_bold`:
--
--     local style_bold_italic = style_bold..{ italic = true }
--
-- In this way you can build on previously defined styles without having to
-- rewrite them. Note the previous style is left unchanged.
--
-- Style colors are different than the #rrggbb RGB notation you may be familiar
-- with. Instead, create a color using [`color()`](#color).
--
--     local red = l.color('FF', '00', '00')
--     local green = l.color('00', 'FF', '00')
--     local blue = l.color('00', '00', 'FF')
--
-- The default set of colors varies depending on the color theme used. Please
-- see the current theme for more information.
--
-- Finally, styles are assigned to tokens via a `M._tokenstyles` table in the
-- lexer. Styles do not have to be assigned to the default tokens; it is done
-- automatically. You only have to assign styles for tokens you create. For
-- example:
--
--     local lua = token('lua', P('lua'))
--
--     -- ... other patterns and tokens ...
--
--     M._tokenstyles = {
--       { 'lua', l.style_keyword },
--     }
--
-- Each entry is the token name the style is for and the style itself. The order
-- of styles in `M._tokenstyles` does not matter.
--
-- For examples of how styles are created, please see the theme files in the
-- `lexers/themes/` folder.
--
-- ### Line Lexer
--
-- Sometimes it is advantageous to lex input text line by line rather than a
-- chunk at a time. This occurs particularly in diff, patch, or make files. Put
--
--     M._LEXBYLINE = true
--
-- somewhere in your lexer in order to do this.
--
-- ### Embedded Lexers
--
-- A particular advantage that dynamic lexers have over static ones is that
-- lexers can be embedded within one another very easily, requiring minimal
-- effort. There are two kinds of embedded lexers: a parent lexer that embeds
-- other child lexers in it, and a child lexer that embeds itself within a
-- parent lexer.
--
-- #### Parent Lexer with Children
--
-- An example of this kind of lexer is HTML with embedded CSS and Javascript.
-- After creating the parent lexer, load the children lexers in it using
-- [`lexer.load()`](#load). For example:
--
--     local css = l.load('css')
--
-- There needs to be a transition from the parent HTML lexer to the child CSS
-- lexer. This is something of the form `<style type="text/css">`. Similarly,
-- the transition from child to parent is `</style>`.
--
--     local css_start_rule = #(P('<') * P('style') * P(function(input, index)
--       if input:find('^[^>]+type%s*=%s*(["\'])text/css%1', index) then
--         return index
--       end
--     end)) * tag
--     local css_end_rule = #(P('</') * P('style') * ws^0 * P('>')) * tag
--
-- where `tag` and `ws` have been previously defined in the HTML lexer.
--
-- Now the CSS lexer can be embedded using [`embed_lexer()`](#embed_lexer):
--
--     l.embed_lexer(M, css, css_start_rule, css_end_rule)
--
-- Remember `M` is the parent HTML lexer object. The lexer object is needed by
-- [`embed_lexer()`](#embed_lexer).
--
-- The same procedure can be done for Javascript.
--
--     local js = l.load('javascript')
--
--     local js_start_rule = #(P('<') * P('script') * P(function(input, index)
--       if input:find('^[^>]+type%s*=%s*(["\'])text/javascript%1', index) then
--         return index
--       end
--     end)) * tag
--     local js_end_rule = #('</' * P('script') * ws^0 * '>') * tag
--     l.embed_lexer(M, js, js_start_rule, js_end_rule)
--
-- #### Child Lexer Within Parent
--
-- An example of this kind of lexer is PHP embedded in HTML. After creating the
-- child lexer, load the parent lexer. As an example:
--
--     local html = l.load('hypertext')
--
-- Since HTML should be the main lexer, (PHP is just a preprocessing language),
-- the following statement changes the main lexer from PHP to HTML:
--
--     M._lexer = html
--
-- Like in the previous section, transitions from HTML to PHP and back are
-- specified:
--
--     local php_start_rule = token('php_tag', '<?' * ('php' * l.space)^-1)
--     local php_end_rule = token('php_tag', '?>')
--
-- And PHP is embedded:
--
--     l.embed_lexer(html, M, php_start_rule, php_end_rule)
--
-- ### Code Folding
--
-- It is sometimes convenient to "fold", or not show blocks of text. These
-- blocks can be functions, classes, comments, etc. A folder iterates over each
-- line of input text and assigns a fold level to it. Certain lines can be
-- specified as fold points that fold subsequent lines with a higher fold level.
--
-- #### Simple Code Folding
--
-- To specify the fold points of your lexer's language, create a
-- `M._foldsymbols` table of the following form:
--
--     M._foldsymbols = {
--       _patterns = { 'patt1', 'patt2', ... },
--       token1 = { ['fold_on'] = 1, ['stop_on'] = -1 },
--       token2 = { ['fold_on'] = 1, ['stop_on'] = -1 },
--       token3 = { ['fold_on'] = 1, ['stop_on'] = -1 }
--       ...
--     }
--
-- + `_patterns`: Lua patterns that match a fold or stop point.
-- + `token`_`N`_: The name of a token a fold or stop point must be part of.
-- + _`fold_on`_: Text in a token that matches a fold point.
-- + _`stop_on`_: Text in a token that matches a stop point.
--
-- Fold points must ultimately have a value of 1 and stop points must ultimately
-- have a value of -1 so the value in the table could be a function as long as
-- it returns 1, -1, or 0. Any functions are passed the following arguments:
--
-- + `text`: The text to fold.
-- + `pos`: The position in `text` of the start of the current line.
-- + `line`: The actual text of the current line.
-- + `s`: The position in `line` the matched text starts at.
-- + `match`: The matched text itself.
--
-- Lua folding would be implemented as follows:
--
--     M._foldsymbols = {
--       _patterns = { '%l+', '[%({%)}%[%]]' },
--       [l.KEYWORD] = {
--         ['if'] = 1, ['do'] = 1, ['function'] = 1, ['end'] = -1,
--         ['repeat'] = 1, ['until'] = -1
--       },
--       [l.COMMENT] = { ['['] = 1, [']'] = -1 },
--       [l.OPERATOR] = { ['('] = 1, ['{'] = 1, [')'] = -1, ['}'] = -1 }
--     }
--
-- `_patterns` matches lower-case words and any brace character. These are the
-- fold and stop points in Lua. If a lower-case word happens to be a `keyword`
-- token and that word is `if`, `do`, `function`, or `repeat`, the line
-- containing it is a fold point. If the word is `end` or `until`, the line is a
-- stop point. Any unmatched parenthesis or braces counted as operators are also
-- fold points. Finally, unmatched brackets in comments are fold points in order
-- to fold long (multi-line) comments.
--
-- #### Advanced Code Folding
--
-- If you need more granularity than `M._foldsymbols`, you can define your own
-- fold function:
--
--     function M._fold(text, start_pos, start_line, start_level)
--
--     end
--
-- + `text`: The text to fold.
-- + `start_pos`: Current position in the buffer of the text (used for obtaining
--   style information from the document).
-- + `start_line`: The line number the text starts at.
-- + `start_level`: The fold level of the text at `start_line`.
--
-- The function must return a table whose indices are line numbers and whose
-- values are tables containing the fold level and optionally a fold flag.
--
-- The following Scintilla fold flags are available:
--
-- * `SC_FOLDLEVELBASE`
--   The initial (root) fold level.
-- * `SC_FOLDLEVELWHITEFLAG`
--   Flag indicating that the line is blank.
-- * `SC_FOLDLEVELHEADERFLAG`
--   Flag indicating the line is fold point.
-- * `SC_FOLDLEVELNUMBERMASK`
--   Flag used with `SCI_GETFOLDLEVEL(line)` to get the fold level of a line.
--
-- Have your fold function interate over each line, setting fold levels. You can
-- use the [`get_style_at()`](#get_style_at), [`get_property()`](#get_property),
-- [`get_fold_level()`](#get_fold_level), and
-- [`get_indent_amount()`](#get_indent_amount) functions as necessary to
-- determine the fold level for each line. The following example sets fold
-- points by changes in indentation.
--
--     function M._fold(text, start_pos, start_line, start_level)
--       local folds = {}
--       local current_line = start_line
--       local prev_level = start_level
--       for indent, line in text:gmatch('([\t ]*)(.-)\r?\n') do
--         if line ~= '' then
--           local current_level = l.get_indent_amount(current_line)
--           if current_level > prev_level then -- next level
--             local i = current_line - 1
--             while folds[i] and folds[i][2] == l.SC_FOLDLEVELWHITEFLAG do
--               i = i - 1
--             end
--             if folds[i] then
--               folds[i][2] = l.SC_FOLDLEVELHEADERFLAG -- low indent
--             end
--             folds[current_line] = { current_level } -- high indent
--           elseif current_level < prev_level then -- prev level
--             if folds[current_line - 1] then
--               folds[current_line - 1][1] = prev_level -- high indent
--             end
--             folds[current_line] = { current_level } -- low indent
--           else -- same level
--             folds[current_line] = { prev_level }
--           end
--           prev_level = current_level
--         else
--           folds[current_line] = { prev_level, l.SC_FOLDLEVELWHITEFLAG }
--         end
--         current_line = current_line + 1
--       end
--       return folds
--     end
--
-- SciTE users note: do not use `get_property` for getting fold options from a
-- `.properties` file because SciTE is not set up to forward them to your lexer.
-- Instead, you can provide options that can be set at the top of the lexer.
--
-- ### Using with SciTE
--
-- Create a `.properties` file for your lexer and `import` it in either your
-- `SciTEUser.properties` or `SciTEGlobal.properties`. The contents of the
-- `.properties` file should contain:
--
--     file.patterns.[lexer_name]=[file_patterns]
--     lexer.$(file.patterns.[lexer_name])=[lexer_name]
--
-- where [lexer\_name] is the name of your lexer (minus the `.lua` extension)
-- and [file\_patterns] is a set of file extensions matched to your lexer.
--
-- Please note any styling information in `.properties` files is ignored.
--
-- ### Using with Textadept
--
-- Put your lexer in your [`~/.textadept/`][user]`lexers/` directory. That way
-- your lexer will not be overwritten when upgrading. Also, lexers in this
-- directory override default lexers. (A user `lua` lexer would be loaded
-- instead of the default `lua` lexer. This is convenient if you wish to tweak
-- a default lexer to your liking.) Do not forget to add a
-- [mime-type](textadept.mime_types.html) for your lexer.
--
-- [user]: http://caladbolg.net/luadoc/textadept/manual/5_FolderStructure.html
--
-- ### Optimization
--
-- Lexers can usually be optimized for speed by re-arranging tokens so that the
-- most common ones are recognized first. Keep in mind the issue that was raised
-- earlier: if you put similar tokens like `identifier`s before `keyword`s, the
-- latter will not be styled correctly.
--
-- ### Troubleshooting
--
-- Errors in lexers can be tricky to debug. Lua errors are printed to STDERR
-- and `_G.print()` statements in lexers are printed to STDOUT.
--
-- ### Limitations
--
-- True embedded preprocessor language highlighting is not available. For most
-- cases this will not be noticed, but code like
--
--     <div id="<?php echo $id; ?>">
--
-- or
--
--     <div <?php if ($odd) { echo 'class="odd"'; } ?>>
--
-- will not highlight correctly.
--
-- ### Performance
--
-- There might be some slight overhead when initializing a lexer, but loading a
-- file from disk into Scintilla is usually more expensive.
--
-- On modern computer systems, I see no difference in speed between LPeg lexers
-- and Scintilla's C++ ones.
--
-- ### Risks
--
-- Poorly written lexers have the ability to crash Scintilla, so unsaved data
-- might be lost. However, these crashes have only been observed in early lexer
-- development, when syntax errors or pattern errors are present. Once the lexer
-- actually starts styling text (either correctly or incorrectly; it does not
-- matter), no crashes have occurred.
--
-- ### Acknowledgements
--
-- Thanks to Peter Odding for his [lexer post][post] on the Lua mailing list
-- that inspired me, and of course thanks to Roberto Ierusalimschy for LPeg.
--
-- [post]: http://lua-users.org/lists/lua-l/2007-04/msg00116.html

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
---
-- List of rule names with associated LPeg patterns for a specific lexer.
-- It is accessible to other lexers for embedded lexer applications.
-- @class table
-- @name _RULES
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
-- @param style A Scintilla style created from style().
-- @see style
local function add_style(lexer, token_name, style)
  local len = lexer._STYLES.len
  if len == 32 then len = len + 8 end -- skip predefined styles
  if len >= 128 then print('Too many styles defined (128 MAX)') end
  lexer._TOKENS[token_name] = len
  lexer._STYLES[len] = style
  lexer._STYLES.len = len + 1
end

-- (Re)constructs lexer._TOKENRULE.
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

-- (Re)constructs lexer._GRAMMAR.
-- @param lexer The parent lexer.
-- @param initial_rule The name of the rule to start lexing with. The default
--   value is `lexer._NAME`. Multilang lexers use this to start with a child
--   rule if necessary.
local function build_grammar(lexer, initial_rule)
  local children = lexer._CHILDREN
  if children then
    local lexer_name = lexer._NAME
    if not initial_rule then initial_rule = lexer_name end
    local grammar = { initial_rule }
    add_lexer(grammar, lexer)
    lexer._INITIALRULE = initial_rule
    lexer._GRAMMAR = lpeg_Ct(lpeg_P(grammar))
  else
    lexer._GRAMMAR = lpeg_Ct(join_tokens(lexer)^0)
  end
end

-- Default tokens.
-- Contains token identifiers and associated style numbers.
-- @class table
-- @name tokens
-- @field default The default type (0).
-- @field whitespace The whitespace type (1).
-- @field comment The comment type (2).
-- @field string The string type (3).
-- @field number The number type (4).
-- @field keyword The keyword type (5).
-- @field identifier The identifier type (6).
-- @field operator The operator type (7).
-- @field error The error type (8).
-- @field preprocessor The preprocessor type (9).
-- @field constant The constant type (10).
-- @field variable The variable type (11).
-- @field function The function type (12).
-- @field class The class type (13).
-- @field type The type type (14).
-- @field label The label type (15).
-- @field regex The regex type (16).
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
-- Initializes the specified lexer.
-- @param lexer_name The name of the lexing language.
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
      l._rules[#l._rules + 1] = { lexer._NAME..'_'..r[1], r[2] }
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
-- Lexes the given text.
-- Called by LexLPeg.cxx; do not call from Lua.
-- If the lexer has a _LEXBYLINE flag set, the text is lexed one line at a time.
-- Otherwise the text is lexed as a whole.
-- @param text The text to lex.
-- @param init_style The current style. Multilang lexers use this to determine
--   which language to start lexing in.
-- @name lex
function M.lex(text, init_style)
  local lexer = _G._LEXER
  if not lexer._GRAMMAR then return {} end
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
      for _, token in ipairs(line_tokens) do
        token[2] = token[2] + offset
        tokens[#tokens + 1] = token
      end
    end
    local offset = 0
    local grammar = lexer._GRAMMAR
    for line in text:gmatch('[^\r\n]*\r?\n?') do
      local line_tokens = lpeg_match(grammar, line)
      if line_tokens then append(tokens, line_tokens, offset) end
      offset = offset + #line
      -- Use the default style to the end of the line if none was specified.
      if tokens[#tokens][2] ~= offset then
        tokens[#tokens + 1] = { 'default', offset + 1 }
      end
    end
    return tokens
  end
end

local GetProperty = GetProperty
local FOLD_BASE = SC_FOLDLEVELBASE
local FOLD_HEADER  = SC_FOLDLEVELHEADERFLAG
local FOLD_BLANK = SC_FOLDLEVELWHITEFLAG

---
-- Folds the given text.
-- Called by LexLPeg.cxx; do not call from Lua.
-- If the current lexer has no _fold function, folding by indentation is
-- performed if the 'fold.by.indentation' property is set.
-- @param text The document text to fold.
-- @param start_pos The position in the document text starts at.
-- @param start_line The line number text starts on.
-- @param start_level The fold level text starts on.
-- @return Table of fold levels.
-- @name fold
function M.fold(text, start_pos, start_line, start_level)
  local folds = {}
  if text == '' then return folds end
  local lexer = _G._LEXER
  if lexer._fold then
    return lexer._fold(text, start_pos, start_line, start_level)
  elseif lexer._foldsymbols then
    local lines = {}
    for p, l in text:gmatch('()(.-)\r?\n') do lines[#lines + 1] = { p, l } end
    lines[#lines + 1] = { text:match('()([^\r\n]*)$') }
    local fold_symbols = lexer._foldsymbols
    local get_style_at = GetStyleAt
    local line_num, prev_level = start_line, start_level
    local current_level = prev_level
    for i = 1, #lines do
      local pos, line = lines[i][1], lines[i][2]
      if line ~= '' then
        for _, patt in ipairs(fold_symbols._patterns) do
          for s, match in line:gmatch(patt) do
            local symbols = fold_symbols[get_style_at(start_pos + pos + s - 1)]
            local l = symbols and symbols[match]
            if type(l) == 'number' then
              current_level = current_level + l
            elseif type(l) == 'function' then
              current_level = current_level + l(text, pos, line, s, match)
            end
          end
        end
        folds[line_num] = { prev_level }
        if current_level > prev_level then folds[line_num][2] = FOLD_HEADER end
        if current_level < FOLD_BASE then current_level = FOLD_BASE end
        prev_level = current_level
      else
        folds[line_num] = { prev_level, FOLD_BLANK }
      end
      line_num = line_num + 1
    end
  elseif GetProperty('fold.by.indentation', 1) == 1 then
    local get_indent_amount = GetIndentAmount
    -- Indentation based folding.
    local current_line, prev_level = start_line, start_level
    for _, line in text:gmatch('([\t ]*)(.-)\r?\n') do
      if line ~= '' then
        local current_level = FOLD_BASE + get_indent_amount(current_line)
        if current_level > prev_level then -- next level
          local i = current_line - 1
          while folds[i] and folds[i][2] == FOLD_BLANK do i = i - 1 end
          if folds[i] then folds[i][2] = FOLD_HEADER end -- low indent
          folds[current_line] = { current_level } -- high indent
        elseif current_level < prev_level then -- prev level
          if folds[current_line - 1] then
            folds[current_line - 1][1] = prev_level -- high indent
          end
          folds[current_line] = { current_level } -- low indent
        else -- same level
          folds[current_line] = { prev_level }
        end
        prev_level = current_level
      else
        folds[current_line] = { prev_level, FOLD_BLANK }
      end
      current_line = current_line + 1
    end
  else
    -- No folding, reset fold levels if necessary.
    local current_line = start_line
    for _ in text:gmatch(".-\r?\n") do
      folds[current_line] = { start_level }
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
-- Creates an LPeg capture table index with the name and position of the token.
-- @param name The name of token. If this name is not in `l.tokens` then you
--   will have to specify a style for it in `lexer._tokenstyles`.
-- @param patt The LPeg pattern associated with the token.
-- @usage local ws = token(l.WHITESPACE, l.space^1)
-- @usage php_start_rule = token('php_tag', '<?' * ('php' * l.space)^-1)
-- @name token
function M.token(name, patt)
  if not name then print('noname') end
  return lpeg_Ct(lpeg_Cc(name) * patt * lpeg_Cp())
end

-- common tokens
M.any_char = M.token('default', M.any)

---
-- Table of common colors for a theme.
-- This table should be redefined in each theme.
-- @class table
-- @name colors
M.colors = {}

---
-- Creates a Scintilla style from a table of style properties.
-- @param style_table A table of style properties.
-- Style properties available:
--     * font [string]
--     * size [integer]
--     * bold [boolean]
--     * italic [boolean]
--     * underline [boolean]
--     * fore [integer] (Use value returned by [`color()`](#color))
--     * back [integer] (Use value returned by [`color()`](#color))
--     * eolfilled [boolean]
--     * characterset [?]
--     * case [integer]
--     * visible [boolean]
--     * changeable [boolean]
--     * hotspot [boolean]
-- @usage local bold_italic = style { bold = true, italic = true }
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
-- Creates a Scintilla color.
-- @param r The string red component of the hexadecimal color.
-- @param g The string green component of the color.
-- @param b The string blue component of the color.
-- @usage local red = color('FF', '00', '00')
-- @name color
function M.color(r, g, b) return tonumber(b..g..r, 16) end

---
-- Creates an LPeg pattern that matches a range of characters delimitted by a
-- specific character(s).
-- This can be used to match a string, parenthesis, etc.
-- @param chars The character(s) that bound the matched range.
-- @param escape Optional escape character. This parameter may be omitted, nil,
--   or the empty string.
-- @param end_optional Optional flag indicating whether or not an ending
--   delimiter is optional or not. If true, the range begun by the start
--   delimiter matches until an end delimiter or the end of the input is
--   reached.
-- @param balanced Optional flag indicating whether or not a balanced range is
--   matched, like `%b` in Lua's `string.find`. This flag only applies if
--   `chars` consists of two different characters (e.g. '()').
-- @param forbidden Optional string of characters forbidden in a delimited
--   range. Each character is part of the set.
-- @usage local sq_str_noescapes = delimited_range("'")
-- @usage local sq_str_escapes = delimited_range("'", '\\', true)
-- @usage local unbalanced_parens = delimited_range('()', '\\', true)
-- @usage local balanced_parens = delimited_range('()', '\\', true, true)
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
    return lpeg_P{ s * (range + lpeg_V(1))^0 * e }
  else
    if end_optional then e = lpeg_P(e)^-1 end
    return s * range^0 * e
  end
end

---
-- Creates an LPeg pattern from a given pattern that matches the beginning of a
-- line and returns it.
-- @param patt The LPeg pattern to match at the beginning of a line.
-- @usage local preproc = token(l.PREPROCESSOR, #P('#') * l.starts_line('#' *
--   l.nonnewline^0))
-- @name starts_line
function M.starts_line(patt)
  return lpeg_P(function(input, idx)
    if idx == 1 then return idx end
    local char = input:sub(idx - 1, idx - 1)
    if char == '\n' or char == '\r' or char == '\f' then return idx end
  end) * patt
end

---
-- Similar to `delimited_range()`, but allows for multi-character delimitters.
-- This is useful for lexers with tokens such as nested block comments. With
-- single-character delimiters, this function is identical to
-- `delimited_range(start_chars..end_chars, nil, end_optional, true)`.
-- @param start_chars The string starting a nested sequence.
-- @param end_chars The string ending a nested sequence.
-- @param end_optional Optional flag indicating whether or not an ending
--   delimiter is optional or not. If true, the range begun by the start
--   delimiter matches until an end delimiter or the end of the input is
--   reached.
-- @usage local nested_comment = l.nested_pair('/*', '*/', true)
-- @name nested_pair
function M.nested_pair(start_chars, end_chars, end_optional)
  local s, e = start_chars, end_optional and lpeg_P(end_chars)^-1 or end_chars
  return lpeg_P{ s * (M.any - s - end_chars + lpeg_V(1))^0 * e }
end

---
-- Creates an LPeg pattern that matches a set of words.
-- @param words A table of words.
-- @param word_chars Optional string of additional characters considered to be
--   part of a word (default is `%w_`).
-- @param case_insensitive Optional boolean flag indicating whether the word
--   match is case-insensitive.
-- @usage local keyword = token(l.KEYWORD, word_match { 'foo', 'bar', 'baz' })
-- @usage local keyword = token(l.KEYWORD, word_match({ 'foo-bar', 'foo-baz',
--   'bar-foo', 'bar-baz', 'baz-foo', 'baz-bar' }, '-', true))
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
-- Embeds a child lexer language in a parent one.
-- @param parent The parent lexer.
-- @param child The child lexer.
-- @param start_rule The token that signals the beginning of the embedded
--   lexer.
-- @param end_rule The token that signals the end of the embedded lexer.
-- @usage embed_lexer(M, css, css_start_rule, css_end_rule)
-- @usage embed_lexer(html, M, php_start_rule, php_end_rule)
-- @usage embed_lexer(html, ruby, ruby_start_rule, rule_end_rule)
-- @name embed_lexer
function M.embed_lexer(parent, child, start_rule, end_rule)
  -- Add child rules.
  if not child._EMBEDDEDRULES then
---
-- Set of rules for an embedded lexer.
-- For a parent lexer name, contains child's `start_rule`, `token_rule`, and
-- `end_rule` patterns.
-- @class table
-- @name _EMBEDDEDRULES
    child._EMBEDDEDRULES = {}
  end
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
  tokenstyles[#tokenstyles + 1] = { child._NAME..'_whitespace',
                                    M.style_whitespace }
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
-- Returns a fold function that folds consecutive line comments.
-- This function should be used inside the lexer's `_foldsymbols` table.
-- @param prefix The prefix string defining a line comment.
-- @usage [l.COMMENT] = { ['--'] = l.fold_line_comments('--') }
-- @usage [l.COMMENT] = { ['//'] = l.fold_line_comments('//') }
-- @name fold_line_comments
function M.fold_line_comments(prefix)
  return function(text, pos, line, s)
    if GetProperty('fold.line.comments', 0) == 0 then return 0 end
    if s > 1 and line:match('^%s*()') < s then return 0 end
    local prev_line_comment = prev_line_is_comment(prefix, text, pos, line, s)
    local next_line_comment = next_line_is_comment(prefix, text, pos, line, s)
    if not prev_line_comment and next_line_comment then return 1 end
    if prev_line_comment and not next_line_comment then return -1 end
    return 0
  end
end

-- Registered functions and constants.

---
-- Returns the string style name and style number at a given position.
-- @param pos The position to get the style for.
-- @class function
-- @name get_style_at
M.get_style_at = GetStyleAt

---
-- Returns an integer property value for a given key.
-- @param key The property key.
-- @param default Optional integer value to return if key is not set.
-- @class function
-- @name get_property
M.get_property = GetProperty

---
-- Returns the fold level for a given line.
-- This level already has `SC_FOLDLEVELBASE` added to it, so you do not need to
-- add it yourself.
-- @param line_number The line number to get the fold level of.
-- @class function
-- @name get_fold_level
M.get_fold_level = GetFoldLevel

---
-- Returns the indent amount of text for a given line.
-- @param line The line number to get the indent amount of.
-- @class function
-- @name get_indent_amount
M.get_indent_amount = GetIndentAmount

M.SC_FOLDLEVELBASE = SC_FOLDLEVELBASE
M.SC_FOLDLEVELWHITEFLAG = SC_FOLDLEVELWHITEFLAG
M.SC_FOLDLEVELHEADERFLAG = SC_FOLDLEVELHEADERFLAG
M.SC_FOLDLEVELNUMBERMASK = SC_FOLDLEVELNUMBERMASK

return M
