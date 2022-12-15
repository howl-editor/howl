Gtk = require 'ljglibs.gtk'
import Window from howl.ui

describe 'Window', ->
  local win

  before_each ->
    win = Window!
    win\realize!

  after_each ->
    win\destroy!

  describe 'add_view(view [, placement, anchor])', ->
    it 'adds the specified view', ->
      win\add_view Gtk.Label!
      assert.equals 1, #win.views

    it 'returns a table containing x, y, width, height and the view', ->
      label = Gtk.Label!
      assert.same { x: 1, y: 1, width: 1, height: 1, view: label }, win\add_view label

    it 'adds the new view to the right of the currently focused one by default', ->
      entry = Gtk.Entry!
      win\add_view entry
      entry\grab_focus!
      label = Gtk.Label!
      assert.same { x: 2, y: 1, width: 1, height: 1, view: label }, win\add_view label

    context 'when placement is specified', ->
      local view, entry

      before_each ->
        entry = Gtk.Entry!
        win\add_view entry
        entry\grab_focus!
        view = Gtk.Entry!

      it '"right_of" places the view on the right side of the focused child', ->
        assert.same { x: 2, y: 1, width: 1, height: 1, :view }, win\add_view view, 'right_of'

      it '"left_of" places the view on the left side of the focused child', ->
        assert.same { x: 1, y: 1, width: 1, height: 1, :view }, win\add_view view, 'left_of'

      it '"above" places the view above the focused child', ->
        assert.same { x: 1, y: 1, width: 1, height: 1, :view }, win\add_view view, 'above'
        assert.same { x: 1, y: 2, width: 1, height: 1, view: entry }, win\get_view entry

      it '"below" places the view below the focused child', ->
        assert.same { x: 1, y: 2, width: 1, height: 1, :view }, win\add_view view, 'below'

      it 'allows specifying the relative view to use with placement', ->
        win\add_view view, 'below'
        next_view = Gtk.Label!
        assert.same { x: 1, y: 2, width: 1, height: 1, view: next_view }, win\add_view next_view, 'left_of', view

      it 'creates new columns as needed', ->
        win\add_view view, 'right_of'
        next_view = Gtk.Label!
        assert.same { x: 2, y: 1, width: 1, height: 1, view: next_view }, win\add_view next_view, 'left_of', view
        assert.same { 1, 2, 3 }, [v.x for v in *win.views]

  describe 'remove_view(view)', ->
    it 'removes the specified view', ->
      label = Gtk.Label!
      win\add_view label
      win\remove_view label
      assert.equals 0, #win.views

    it 'removes the currently focused child if view is nil', ->
      entry = Gtk.Entry!
      win\add_view entry
      entry\grab_focus!
      win\remove_view!
      assert.equals 0, #win.views

    it 'raises an error if view is nil and no child has focus', ->
      label = Gtk.Label!
      win\add_view label
      assert.raises 'remove', -> win\remove_view!

    it 'set focus on its later sibling is possible', ->
      left = Gtk.Entry!
      middle = Gtk.Entry!
      right = Gtk.Entry!
      win\add_view left
      win\add_view middle
      win\add_view right
      middle\grab_focus!
      win\remove_view middle
      assert.equals win.focus_child, right

    it 'set focus on its earlier sibling if no later sibling exists', ->
      left = Gtk.Entry!
      middle = Gtk.Entry!
      right = Gtk.Entry!
      win\add_view left
      win\add_view middle
      win\add_view right
      right\grab_focus!
      win\remove_view right
      assert.equals win.focus_child, middle

  describe '.views', ->
    it 'is a table of view tables, containing x, y and the view itself', ->
      label = Gtk.Label!
      win\add_view label
      assert.same { { x: 1, y: 1, width: 1, height: 1, view: label } }, win.views

    it 'ordered ascendingly', ->
      entry = Gtk.Entry!
      win\add_view entry
      entry\grab_focus!

      l1 = Gtk.Label!
      l2 = Gtk.Label!
      win\add_view l1, 'left_of'
      win\add_view l2, 'below'
      assert.same { l1, entry, l2 }, [v.view for v in *win.views]

  describe '.current_view', ->
    it 'is nil if no child is currently focused', ->
      assert.is_nil, win.current_view

    it 'is a table containing x, y and the view for the currently focused view', ->
      e1 = Gtk.Entry!
      e2 = Gtk.Entry!
      win\add_view e1
      win\add_view e2

      e1\grab_focus!
      assert.same { x: 1, y: 1, width: 1, height: 1, view: e1 }, win.current_view

      e2\grab_focus!
      assert.same { x: 2, y: 1, width: 1, height: 1, view: e2 }, win.current_view

  describe 'siblings(view, wraparound)', ->
    context 'when wraparound is false', ->
       it 'returns a table of siblings for the specified view when present', ->
          left = Gtk.Entry!
          right = Gtk.Entry!
          bottom = Gtk.Entry!
          win\add_view left
          win\add_view right, 'right_of', left
          win\add_view bottom, 'below', left

          assert.same { right: right, down: bottom }, win\siblings left, false
          assert.same { left: left, down: bottom }, win\siblings right, false
          assert.same { up: left }, win\siblings bottom, false

    context 'when wraparound is true', ->
      it 'returns a table of siblings for the specified view in a wraparound fashion', ->
          left = Gtk.Entry!
          right = Gtk.Entry!
          bottom = Gtk.Entry!
          win\add_view left
          win\add_view right, 'right_of', left
          win\add_view bottom, 'below', left

          assert.same { left: bottom, right: right, up: bottom, down: bottom }, win\siblings left, true
          assert.same { left: left, right: bottom, up: bottom, down: bottom }, win\siblings right, true
          assert.same { left: right, right: left, up: left, down: left }, win\siblings bottom, true

    it 'returns an empty table if there are no siblings', ->
        v1 = Gtk.Entry!
        win\add_view v1
        assert.same {}, win\siblings v1

    it 'defaults to the currently focused child if view is not provided', ->
        v1 = Gtk.Entry!
        win\add_view v1
        v1\grab_focus!
        assert.same {}, win\siblings!

    it 'returns an empty table if view is not provided and no child is focused', ->
      assert.same {}, win\siblings!

  describe 'column reflowing', ->
    local left, right, bottom

    before_each ->
      left = Gtk.Entry!
      right = Gtk.Entry!
      bottom = Gtk.Entry!
      win\add_view left
      win\add_view right
      right\grab_focus!
      win\add_view bottom, 'below'

    it 'single columns as expanded as necessary', ->
      assert.same { x: 1, y: 2, width: 2, height: 1, view: bottom }, win\get_view bottom

    it 'columns to the right are adjusted after a remove of a left column', ->
      win\remove_view left
      assert.same { x: 1, y: 1, width: 1, height: 1, view: right }, win\get_view right

    it 'columns to the left are adjusted after a remove of a right column', ->
      win\remove_view right
      assert.same { x: 1, y: 1, width: 1, height: 1, view: left }, win\get_view left

    it 'rows are adjusted after removal of a middle column', ->
      middle = Gtk.Entry!
      win\add_view middle, 'right_of', left
      win\remove_view middle
      assert.same { x: 1, y: 1, width: 1, height: 1, view: left }, win\get_view left
      assert.same { x: 2, y: 1, width: 1, height: 1, view: right }, win\get_view right

  context 'resource management', ->
    it 'added views are not anchored', ->
      v = Gtk.Entry!
      views = setmetatable {v}, __mode: 'v'
      win\add_view v
      v = nil
      collectgarbage!
      assert.is_nil views[1]
