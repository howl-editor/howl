{
  ada:
    extensions: { 'ada', 'adb', 'ads' }
    short_comment_prefix: '--'

  antlr:
    extensions: 'g'
    short_comment_prefix: '//'

  awk:
    extensions: 'awk'
    shebangs: 'awk$'
    short_comment_prefix: '#'

  bash:
    extensions: { 'bash', 'bashrc', 'bash_profile', 'configure', 'csh', 'sh', 'zsh' }
    shebangs: {'/sh$', '/bash$' }
    short_comment_prefix: '#'

  batch:
    extensions: { 'bat', 'cmd' }
    short_comment_prefix: 'REM'

  bibtex:
    extensions: 'bib'

  caml:
    extensions: { 'caml', 'ml', 'mli', 'mll', 'mly' }

  cmake:
    extensions: { 'cmake', 'ctest' }
    patterns: { '.cmake.in$', '.ctest.in$' }

  coffeescript:
    extensions: 'coffee'
    short_comment_prefix: '#'

  csharp:
    extensions: 'cs'
    short_comment_prefix: '//'

  css: { extensions: 'css' }

  cpp:
    extensions: { 'c', 'cc', 'cpp', 'cxx', 'c++', 'h', 'hh', 'hpp', 'hxx', 'h++' }
    short_comment_prefix: '//'

  dlang:
    extensions: 'd'
    short_comment_prefix: '//'

  desktop:
    extensions: 'desktop'
    short_comment_prefix: '#'

  diff:
    extensions: { 'diff', 'patch' }
    patterns: { '%.git/COMMIT_EDITMSG$' }

  dot:
    extensions: { 'dot', 'gv' }
    short_comment_prefix: '//'

  eiffel:
    extensions: { 'e', 'eif' }
    short_comment_prefix: '--'

  erlang:
    extensions: { 'erl', 'hrl' }
    short_comment_prefix: '%'

  fsharp:
    extensions: 'fs'
    short_comment_prefix: '//'

  forth:
    extensions: { 'f', 'forth', 'frt', 'fth' }
    short_comment_prefix: '\\'

  fortran:
    extensions: { 'for', 'fort', 'fpp', 'f77', 'f90', 'f95', 'f03', 'f08' }
    short_comment_prefix: '!'

  gettext:
    extensions: { 'po', 'pot' }
    short_comment_prefix: '#'

  gnuplot:
    extensions: { 'dem', 'plt' }
    short_comment_prefix: '#'

  go:
    extensions: 'go'
    short_comment_prefix: '//'

  groovy:
    extensions: { 'groovy', 'gvy' }
    short_comment_prefix: '//'

  haskell:
    extensions: 'hs'
    short_comment_prefix: '--'

  hypertext:
    extensions: { 'htm', 'html', 'shtm', 'shtml', 'xhtml' }

  ini:
    extensions: { 'cfg', 'cnf', 'inf', 'ini', 'reg' }
    short_comment_prefix: ';'

  io:
    extensions: 'io'
    short_comment_prefix: '//'

  java:
    extensions: { 'java', 'bsh' }
    short_comment_prefix: '//'

  javascript:
    extensions: { 'js', 'jsfl' }
    short_comment_prefix: '//'

  jsp:
    extensions: 'jsp'

  json:
    extensions: 'json'

  lisp:
    extensions: { 'cl', 'el', 'lisp', 'lsp' }
    short_comment_prefix: ';'

  latex:
    extensions: { 'bbl', 'dtx', 'ins', 'ltx', 'tex', 'sty' }
    short_comment_prefix: '%'

  makefile:
    extensions: { 'iface', 'mak' }
    patterns: { 'GNUmakefile$', 'Makefile$' }
    short_comment_prefix: '#'
    config:
      use_tabs: true

  markdown:
    extensions: 'md'
    config:
      caret_line_highlighted: false

  nemerle:
    extensions: 'n'
    short_comment_prefix: '//'

  objective_c:
    extensions: {'m', 'mm', 'objc' }
    short_comment_prefix: '//'

  pascal:
    extensions: { 'dpk', 'dpr', 'p', 'pas' }
    short_comment_prefix: '//'

  perl:
    extensions: { 'al', 'perl', 'pl', 'pm', 'pod' }
    shebangs: '/perl.*$'
    short_comment_prefix: '#'

  php:
    extensions: { 'inc', 'php', 'php3', 'php4', 'phtml' }
    shebangs: '/php.*$'
    short_comment_prefix: '//'

  pike:
    extensions: { 'pike', 'pmod' }
    short_comment_prefix: '//'

  postscript:
    extensions: { 'ps', 'eps' }
    short_comment_prefix: '%'

  prolog:
    extensions: 'prolog'
    short_comment_prefix: '%'

  properties:
    extensions: 'properties'
    short_comment_prefix: '#'

  python:
    extensions: { 'sc', 'py', 'pyw' }
    shebangs: '/python.*$'
    short_comment_prefix: '#'

  rstats:
    extensions: { 'r', 'rout', 'rhistory', 'rt' }
    patterns: { 'Rout%.save$', 'Rout%.fail$' }
    short_comment_prefix: '#'

  rebol:
    extensions: 'reb'
    short_comment_prefix: ';'

  rails: {} -- only used for sublexing

  rhtml:
    extensions: { 'erb', 'rhtml' }

  ruby:
    extensions: { 'rb', 'Rakefile', 'rake', 'rb', 'rbw' }
    patterns: { 'Rakefile$', 'Gemfile$'  }
    short_comment_prefix: '#'

  scala:
    extensions: 'scala'
    short_comment_prefix: '/'

  scheme:
    extensions: { 'sch', 'scm' }
    short_comment_prefix: ';'

  smalltalk:
    extensions: { 'changes', 'st', 'sources' }

  sql:
    extensions: { 'sql', 'ddl' }
    short_comment_prefix: '--'

  tcl:
    extensions: { 'tcl', 'tk' }
    short_comment_prefix: '#'

  vala:
    extensions: 'vala'
    short_comment_prefix: '//'

  verilog:
    extensions: { 'v', 'ver' }
    short_comment_prefix: '//'

  vhdl:
    extensions: { 'vh', 'vhd', 'vhdl' }
    short_comment_prefix: '--'

  xml:
    extensions: { 'dtd', 'svg', 'xml', 'xsd', 'xsl', 'xslt', 'xul' }
}
