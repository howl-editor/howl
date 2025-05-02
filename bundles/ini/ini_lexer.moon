-- Copyright 2019 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

table = _G.table

(type) ->
  howl.util.lpeg_lexer ->
    c = capture

    one_line_ws = (space - eol)^0

    hash_comment = P'#' * scan_until eol
    semicolon_comment = P';' * scan_until eol

    comment = c 'comment',
      switch type
        when 'ini', 'editorconfig'
          any {
            hash_comment
            semicolon_comment
          }
        when 'xdg', 'systemd'
          hash_comment
        when 'regedit'
          semicolon_comment

    section = sequence {
      space^0
      c 'operator', '['

      switch type
        when 'ini'
          sequence {
            c 'keyword', scan_until(P']'^-1 * one_line_ws * eol)
            c 'operator', P']'^-1
            scan_until eol
          }
        when 'editorconfig'
          sequence {
            any({
              P {
                'glob'

                glob: any {
                  c 'error', P'\\'
                  c 'operator', S'*?/.'
                  sequence {
                    c 'operator', P'['
                    c 'operator', P'!'^-1
                    any({
                      V 'glob'
                      c 'keyword', P(1) - ']'
                    })^0
                    c 'operator', P']'^-1
                  }
                  sequence {
                    c 'operator', P'{'
                    any({
                      c 'operator', ','
                      V 'glob'
                      c 'keyword', P(1) - S',}'
                    })^0
                    c 'operator', P'}'^-1
                  }
                }
              }
              c 'keyword', P(1) - P']'
            })^0
            c 'operator', P']'^-1
            one_line_ws
            c 'error', scan_until eol
          }
        else
          section_char = {
            c 'error', '['
            c 'keyword', P(1) - ']'
          }

          if type == 'regedit'
            table.insert section_char, 1, c 'operator', P'\\'

          section_name = {
            any(section_char)^0
            c 'operator', P']'^-1
            one_line_ws
            c 'error', scan_until eol
          }

          if type == 'regedit'
            table.insert section_name, 1, c 'operator', P'-'^-1

          sequence section_name
    }

    key = switch type
      when 'ini', 'editorconfig'
        c 'key', (P(1) - S'=:' - eol)^1
      when 'xdg', 'systemd'
        sequence {
          (-eol * any {
            space
            c 'key', any { alnum, P'-' }
            c 'error', P(1) - (if type == 'xdg' then S'=[' else P'=')
          })^1
          if type == 'xdg'
            sequence({
              c 'operator', P'['
              c 'special', (P(1) - (S'=]' + eol))^0
              c 'operator', P']'^-1
            })^-1
          else
            nil
        }
      when 'regedit'
        c 'key', P'"' * scan_to P'"'

    bool_value = c 'special', word { 'true', 'false' }
    decimal_value = c 'number', digit^1 * (P'.' * digit^0)^-1
    string_char = c 'string', P(1) - eol

    operator = c 'operator', switch type
      when 'ini', 'editorconfig'
        S':='
      else
        P'='

    value = switch type
      when 'ini'
        any {
          bool_value
          decimal_value
          -- XXX: Substitutions are only highlighted on the first line.
          sequence {
            any({
              sequence {
                c 'operator', '%('
                c 'identifier', scan_until P')' + eol
                c 'operator', ')'
                c 'special', (P(1) - eol)^-1
              }
              sequence {
                c 'operator', '${'
                c 'identifier', scan_until S':}' + eol
                sequence({
                  c 'operator', ':'
                  c 'identifier', scan_until P'}' + eol
                })^-1
                c 'operator', '}'
              }
              string_char
            })^0
            c('string', eol * #(space - eol) * scan_through_indented!)^-1
          }
        }

      when 'editorconfig'
        any {
          bool_value
          decimal_value
          string_char^0
        }

      when 'xdg', 'systemd'
        xdg_string_values = if type == 'xdg'
          string_char
        else
          any {
            c 'string', P'\\' * eol
            sequence {
              c 'operator', '$'
              any {
                sequence {
                  c 'operator', '{'
                  c 'identifier', scan_until P'}' + eol
                  c 'operator', '}'
                }
                c 'identifier', scan_until space
              }
            }
            c 'string', '%%'
            sequence {
              c 'special', '%'
              any {
                c 'special', S'bCEfhHiIjJLmnNpPsStTgGuUvV'
                c 'error', P(1) - eol
              }
            }
            c 'error', P'%'
            string_char
          }

        any({
          bool_value
          decimal_value
          xdg_string_values^1
        })

      when 'regedit'
        scan_until_colon = scan_until eol + P':'
        skip_continuation = sequence {
          c 'operator', P'\\'
          c 'whitespace', eol
          one_line_ws
        }

        byte = any {
          c 'number', xdigit * xdigit
          c 'error', scan_until eol + P','
        }

        any {
          c 'operator', '-'
          c 'string', P'"' * scan_to P'"'
          sequence {
            any {
              sequence {
                c 'type', word { 'dword' }
                c 'error', scan_until_colon
                c 'operator', P':'^-1
                any({
                  c 'number', xdigit
                  c 'error', P(1) - eol
                })^0
              }

              sequence {
                c 'type', word { 'hex' }
                sequence({
                  c 'operator', '('
                  any {
                    c 'number', S'27'
                    c 'error', P(1) - (eol + S'):')
                  }
                  c 'operator', ')'
                })^-1
                c 'error', scan_until_colon
                c 'operator', P':'^-1
                sequence({
                  byte
                  skip_continuation^0
                  sequence({
                    skip_continuation^0
                    c 'error', scan_until eol + ','
                    skip_continuation^0
                    c 'operator', P','
                    skip_continuation^0
                    c 'error', scan_until eol + xdigit
                    skip_continuation^0
                    byte
                  })^0
                  c 'error', scan_until eol
                })^-1
              }
            }
          }
          c 'error', scan_until eol
        }

    setting = sequence {
      key
      one_line_ws
      (operator * one_line_ws * (value * one_line_ws)^-1)^-1
    }

    any {
      comment
      section
      setting
    }
