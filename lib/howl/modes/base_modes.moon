import mode from howl

curly_mode = {
  indentation: {
    more_after: {
      '[[{(]%s*$',
    }

    less_for: {
      '^%s*[]})]',
    }
  }

  code_blocks:
    multiline: {
      { '{%s*$', '^%s*}', '}'}
      { '%[%s*$', '^%s*%]', ']'}
      { '%(%s*$', '^%s*%)', ')'}
    }

}

mode.register name: 'curly_mode', create: -> curly_mode
