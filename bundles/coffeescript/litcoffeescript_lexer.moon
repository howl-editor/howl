-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

howl.aux.lpeg_lexer ->

  coffeescript = sequence {
    line_start,
    #any('\t', P(' ')^4),
    sub_lex_match_time('coffeescript', scan_through_indented!)
  }

  compose 'markdown', coffeescript
