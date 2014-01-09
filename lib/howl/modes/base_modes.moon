import mode from howl

curly_mode = {
  indent_after_patterns: {
    authoritive: true
    '[[{(]%s*$',
  }

  dedent_patterns: {
    authoritive: true
    '^%s*[]})]',
  }

  code_blocks:
    multiline: {
      { '{%s*$', '^%s*}', '}'}
      { '%[%s*$', '^%s*%]', ']'}
      { '%(%s*$', '^%s*%)', ')'}
    }

}

mode.register name: 'curly_mode', create: -> curly_mode
