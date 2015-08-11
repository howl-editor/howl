-- Copyright 2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

howl.aux.lpeg_lexer ->

  coffeescript = sequence {
    line_start,
    #any('\t', P(' ')^4),
    sub_lex_match_time('coffeescript', scan_through_indented!)
  }

  compose 'markdown', coffeescript
