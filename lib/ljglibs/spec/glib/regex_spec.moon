GRegex = require 'ljglibs.glib.regex'

describe 'GRegex', ->
  context 'creation', ->
    it 'raises an error if the pattern is invalid', ->
      assert.raises 'regular expression', -> GRegex '?\\'

    it 'returns a regex for a valid pattern', ->
      assert.is_not_nil GRegex 'foo()\\d+'

  it '.pattern holds the regex used for construction', ->
    assert.equal 'foo(bar)', GRegex('foo(bar)').pattern

  it '.capture_count holds the number of captures in the pattern', ->
    assert.equal 2, GRegex('foo(bar) (\\w+)').capture_count

  it 'escape_string(s) returns a string with all special regular expression symbols escaped', ->
    assert.equal 'a\\.b\\*c', GRegex.escape_string 'a.b*c'

  describe 'match(s, match_options)', ->
    it 'returns true if it matches', ->
      assert.true GRegex('ri\\S+')\match 'red right hand'

    it 'returns false if the pattern does not match', ->
      assert.is_false GRegex('foo')\match 'bar'

  describe 'match_with_info(s, match_options)', ->
    it 'returns match info if it matches', ->
      info = GRegex('ri\\S+')\match_with_info 'red right hand'
      assert.is_not_nil info

    it 'returns nil if the pattern does not match', ->
      info = GRegex('foo')\match_with_info 'bar'
      assert.is_nil info

  describe 'a match info instance', ->
    it '.match_count contains the number of matched sub strings', ->
      info = GRegex('ri\\S+')\match_with_info 'red right hand'
      assert.equal 1, info.match_count

      info = GRegex('(ri\\S+)')\match_with_info 'red right hand'
      assert.equal 2, info.match_count

    describe 'fetch_pos(match_num)', ->
      it 'returns the start pos and end pos of the specified group', ->
        info = GRegex('ri(\\S+)')\match_with_info 'red right hand'
        start_pos, end_pos = info\fetch_pos 0
        assert.equal 4, start_pos
        assert.equal 9, end_pos

        start_pos, end_pos = info\fetch_pos 1
        assert.equal 6, start_pos
        assert.equal 9, end_pos

      it 'returns nil and an error message if the group could not be found', ->
        info = GRegex('ri\\S+')\match_with_info 'red right hand'
        ret, err = info\fetch_pos 1
        assert.is_nil ret
        assert.is_not_nil err\find('group')

    describe 'fetch(match_num)', ->
      it 'returns the matching text for the specified group', ->
        info = GRegex('ri(\\S+)')\match_with_info 'red right hand'
        assert.equal "right", info\fetch 0
        assert.equal "ght", info\fetch 1

      it 'returns nil if the group could not be found', ->
        info = GRegex('ri\\S+')\match_with_info 'red right hand'
        assert.is_nil info\fetch 1

    context 'iterating over', ->
      it 'matches() returns true while next() finds another match', ->
        info = GRegex('\\w+')\match_with_info 'red right hand'
        matches = {}
        while info\matches!
          matches[#matches + 1] = info\fetch 0
          info\next!
        assert.same { 'red', 'right', 'hand' }, matches

  it 'tostring(regex) returns the pattern', ->
    assert.equal '\\s*(foo)', tostring GRegex '\\s*(foo)'
