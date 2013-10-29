{
  ada:
    extensions: { 'ada', 'adb', 'ads' }
    comment_syntax: '--'

  antlr:
    extensions: 'g'
    comment_syntax: '//'

  awk:
    extensions: 'awk'
    shebangs: '[/ ]awk$'
    comment_syntax: '#'

  bash:
    extensions: { 'bash', 'bashrc', 'bash_profile', 'configure', 'csh', 'sh', 'zsh' }
    shebangs: {'[/ ]sh$', '[/ ]bash$' }
    comment_syntax: '#'

  batch:
    extensions: { 'bat', 'cmd' }
    comment_syntax: 'REM'

  bibtex:
    extensions: 'bib'

  caml:
    extensions: { 'caml', 'ml', 'mli', 'mll', 'mly' }
    comment_syntax: { '(*', '*)' }

  cmake:
    extensions: { 'cmake', 'ctest' }
    patterns: { '.cmake.in$', '.ctest.in$' }
    comment_syntax: '#'

  coffeescript:
    extensions: 'coffee'
    comment_syntax: '#'

  csharp:
    extensions: 'cs'
    comment_syntax: '//'

  cpp:
    extensions: { 'c', 'cc', 'cpp', 'cxx', 'c++', 'h', 'hh', 'hpp', 'hxx', 'h++' }
    comment_syntax: '//'

  dlang:
    extensions: 'd'
    comment_syntax: { '/*', '*/' }

  desktop:
    extensions: 'desktop'
    comment_syntax: '#'

  diff:
    extensions: { 'diff', 'patch' }
    patterns: { '%.git/COMMIT_EDITMSG$' }

  dot:
    extensions: { 'dot', 'gv' }
    comment_syntax: '//'

  eiffel:
    extensions: { 'e', 'eif' }
    comment_syntax: '--'

  erlang:
    extensions: { 'erl', 'hrl' }
    comment_syntax: '%'

  fsharp:
    extensions: 'fs'
    comment_syntax: '//'

  forth:
    extensions: { 'f', 'forth', 'frt', 'fth' }
    comment_syntax: '\\'

  fortran:
    extensions: { 'for', 'fort', 'fpp', 'f77', 'f90', 'f95', 'f03', 'f08' }
    comment_syntax: '!'

  gettext:
    extensions: { 'po', 'pot' }
    comment_syntax: '#'

  gnuplot:
    extensions: { 'dem', 'plt' }
    comment_syntax: '#'

  go:
    extensions: 'go'
    comment_syntax: '//'

  groovy:
    extensions: { 'groovy', 'gvy' }
    comment_syntax: '//'

  haskell:
    extensions: 'hs'
    comment_syntax: '--'

  hypertext:
    extensions: { 'htm', 'html', 'shtm', 'shtml', 'xhtml' }
    comment_syntax: { '<!--', '-->' }

  ini:
    extensions: { 'cfg', 'cnf', 'inf', 'ini', 'reg' }
    comment_syntax: ';'

  io:
    extensions: 'io'
    comment_syntax: '//'

  java:
    extensions: { 'java', 'bsh' }
    comment_syntax: '//'

  javascript:
    extensions: { 'js', 'jsfl' }
    comment_syntax: '//'

  jsp:
    extensions: 'jsp'
    comment_syntax: { '<%--', '--%>' }

  json:
    extensions: 'json'

  latex:
    extensions: { 'bbl', 'dtx', 'ins', 'ltx', 'tex', 'sty' }
    comment_syntax: '%'

  makefile:
    extensions: { 'iface', 'mak' }
    patterns: { 'GNUmakefile$', 'Makefile$' }
    comment_syntax: '#'
    default_config:
      use_tabs: true

  markdown:
    extensions: 'md'
    default_config:
      caret_line_highlighted: false

  nemerle:
    extensions: 'n'
    comment_syntax: '//'

  objective_c:
    extensions: {'m', 'mm', 'objc' }
    comment_syntax: '//'

  pascal:
    extensions: { 'dpk', 'dpr', 'p', 'pas' }
    comment_syntax: '//'

  perl:
    extensions: { 'al', 'perl', 'pl', 'pm', 'pod' }
    shebangs: '[/ ]perl.*$'
    comment_syntax: '#'

  php:
    extensions: { 'inc', 'php', 'php3', 'php4', 'phtml' }
    shebangs: '[/ ]php.*$'
    comment_syntax: '//'

  pike:
    extensions: { 'pike', 'pmod' }
    comment_syntax: '//'

  postscript:
    extensions: { 'ps', 'eps' }
    comment_syntax: '%'

  prolog:
    extensions: 'prolog'
    comment_syntax: '%'

  properties:
    extensions: 'properties'
    comment_syntax: '#'

  python:
    extensions: { 'sc', 'py', 'pyw' }
    shebangs: '[/ ]python.*$'
    comment_syntax: '#'

  rstats:
    extensions: { 'r', 'rout', 'rhistory', 'rt' }
    patterns: { 'Rout%.save$', 'Rout%.fail$' }
    comment_syntax: '#'

  rebol:
    extensions: 'reb'
    comment_syntax: ';'

  rails: {} -- only used for sublexing

  rhtml:
    extensions: { 'erb', 'rhtml' }
    comment_syntax: { '<%-#', '-%>' }

  ruby:
    extensions: { 'rb', 'Rakefile', 'rake', 'rb', 'rbw'  }
    patterns: { 'Rakefile$', 'Gemfile$', 'Guardfile$'  }
    comment_syntax: '#'
    indent_after_patterns: {
      {r'^\\s*(def|class|if|else|unless)\\b', '%send%s*$'},
      r'\\s(do|{)\\s*\\|[^|]*\\|\\s*$',
      '{%s*$'
    }
    dedent_patterns: { '%s*end%s*$'}

  scala:
    extensions: 'scala'
    comment_syntax: '/'

  scheme:
    extensions: { 'sch', 'scm' }
    comment_syntax: ';'

  smalltalk:
    extensions: { 'changes', 'st', 'sources' }
    comment_syntax: { '"', '"' }

  sql:
    extensions: { 'sql', 'ddl' }
    comment_syntax: '--'

  tcl:
    extensions: { 'tcl', 'tk' }
    comment_syntax: '#'

  vala:
    extensions: 'vala'
    comment_syntax: '//'

  verilog:
    extensions: { 'v', 'ver' }
    comment_syntax: '//'

  vhdl:
    extensions: { 'vh', 'vhd', 'vhdl' }
    comment_syntax: '--'

  xml:
    extensions: { 'dtd', 'svg', 'xml', 'xsd', 'xsl', 'xslt', 'xul' }
    comment_syntax: { '<!--', '-->' }
}
