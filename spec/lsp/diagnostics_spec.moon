diagnostics = require 'howl.lsp.diagnostics'

diagnostic = (opts = {}) ->
  d = {
    range: {
      start: { line: 0, character: 2 },
      ['end']: { line: 1, character: 5 }
    },
    message: 'oops'
  }
  d[k] = v for k, v in pairs opts
  d

describe 'lsp.diagnostics', ->
  describe 'to_items(diagnostics)', ->
    it 'converts ranges to one-based lines and byte columns', ->
      assert.same {
        {
          line: 1,
          byte_start_col: 3,
          end_line: 2,
          byte_end_col: 6,
          type: 'error',
          message: 'oops'
        }
      }, diagnostics.to_items { diagnostic! }

    it 'maps errors to "error" and the other severities to "warning"', ->
      types = [i.type for i in *diagnostics.to_items {
        diagnostic(severity: 1),
        diagnostic(severity: 2),
        diagnostic(severity: 3),
        diagnostic(severity: 4)
      }]
      assert.same { 'error', 'warning', 'warning', 'warning' }, types

    it 'appends the code to the message when present', ->
      items = diagnostics.to_items {
        diagnostic(code: 'name-defined'),
        diagnostic(code: 42),
        diagnostic(code: '')
      }
      assert.same { 'oops [name-defined]', 'oops [42]', 'oops' }, [i.message for i in *items]
