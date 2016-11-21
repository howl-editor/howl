{
  ------------------------------------------------------------------------------
  -- Default bindings
  ------------------------------------------------------------------------------

  editor: {
    left:             'cursor-left'
    right:            'cursor-right'
    up:               'cursor-up'
    down:             'cursor-down'
    shift_left:       'cursor-left-extend'
    shift_right:      'cursor-right-extend'
    shift_up:         'cursor-up-extend'
    shift_down:       'cursor-down-extend'
    alt_up:           'editor-move-lines-up'
    alt_down:         'editor-move-lines-down'
    alt_left:         'editor-move-text-left'
    alt_right:        'editor-move-text-right'

    tab:              'editor-smart-tab'
    shift_tab:        'editor-smart-back-tab'
    backspace:        'editor-delete-back'
    ctrl_backspace:   'editor-delete-back-word'
    delete:           'editor-delete-forward'
    ctrl_delete:      'editor-delete-forward-word'
    return:           'editor-newline'

    page_up:          'cursor-page-up'
    shift_page_up:    'cursor-page-up-extend'
    page_down:        'cursor-page-down'
    shift_page_down:  'cursor-page-down-extend'
    end:              'cursor-line-end'
    shift_end:        'cursor-line-end-extend'
    home:             'cursor-home'
    shift_home:       'cursor-home-extend'
    ctrl_home:        'cursor-start'
    ctrl_shift_home:  'cursor-start-extend'
    ctrl_end:         'cursor-eof'
    ctrl_shift_end:   'cursor-eof-extend'

    ctrl_b:           'switch-buffer'
    ctrl_c:           'editor-copy'
    ctrl_d:           'editor-duplicate-current'
    ctrl_shift_e:     'cursor-goto-inspection'
    ctrl_f:           'buffer-search-forward'
    ctrl_r:           'buffer-search-backward'
    ctrl_comma:       'buffer-search-word-backward'
    ctrl_period:      'buffer-search-word-forward'
    ctrl_g:           'buffer-grep'
    ctrl_i:           'editor-indent'
    ctrl_k:           'editor-delete-to-end-of-line'
    ctrl_shift_k:     'editor-delete-line'
    ctrl_n:           'new-buffer'
    ctrl_w:           'buffer-close'
    ctrl_shift_i:     'editor-indent-all'
    ctrl_h:           'buffer-replace'
    ctrl_s:           'save'
    ctrl_shift_s:     'save-as'
    ctrl_v:           'editor-paste'
    ctrl_shift_v:     'editor-paste..'

    ctrl_x:           'editor-cut'
    ctrl_z:           'editor-undo'
    ctrl_Z:           'editor-redo'
    ctrl_q:           'show-doc-at-cursor'
    ctrl_space:       'editor-complete'
    ctrl_slash:       'editor-toggle-comment'
    ctrl_tab:         'view-next'

    shift_delete:     'editor-cut'
    shift_insert:     'editor-paste'
    ctrl_insert:      'editor-copy'

    ctrl_shift_a:     'editor-select-all'

    alt_s:            'buffer-structure'
    alt_q:            'editor-reflow-paragraph'

    ctrl_left:        'cursor-word-left'
    ctrl_right:       'cursor-word-right'
    ctrl_up:          'editor-scroll-up'
    ctrl_down:        'editor-scroll-down'

    ctrl_shift_left:  'cursor-word-left-extend'
    ctrl_shift_right: 'cursor-word-right-extend'
    ctrl_shift_up:    'editor-scroll-up'
    ctrl_shift_down:  'editor-scroll-down'

    ctrl_shift_d:     'vc-diff-file'
    ctrl_alt_d:       'vc-diff'

    alt_g:            'cursor-goto-line'

  }

  ctrl_o:           'open'
  ctrl_shift_o:     'open-recent'
  ctrl_p:           'project-open'
  ctrl_shift_r:     'exec'
  ctrl_alt_r:       'project-exec'
  ctrl_shift_b:     'project-build'

  ctrl_shift_w:     'view-close'
  'ctrl_-':         'zoom-out'
  'ctrl_+':         'zoom-in'

  alt_f11:          'window-toggle-fullscreen'
  alt_x:            'run'

  shift_alt_left:  'view-left-or-create'
  shift_alt_right: 'view-right-or-create'
  shift_alt_up:    'view-up-or-create'
  shift_alt_down:  'view-down-or-create'

  ------------------------------------------------------------------------------
  -- OS specific bindings
  ------------------------------------------------------------------------------

  for_os:

    osx:
      editor: {
        meta_shift_a:     'editor-select-all'
        meta_b:           'switch-buffer'
        meta_c:           'editor-copy'
        meta_d:           'editor-duplicate-current'
        meta_f:           'buffer-search-forward'
        meta_r:           'buffer-search-backward'
        meta_comma:       'buffer-search-word-backward'
        meta_period:      'buffer-search-word-forward'
        meta_g:           'buffer-grep'
        meta_i:           'editor-indent'
        meta_k:           'editor-delete-to-end-of-line'
        meta_shift_k:     'editor-delete-line'
        meta_shift_i:     'editor-indent-all'
        meta_h:           'buffer-replace'
        meta_n:           'new-buffer'
        meta_w:           'buffer-close'
        meta_s:           'save'
        meta_shift_s:     'save-as'
        meta_v:           'editor-paste'
        meta_shift_v:     'editor-paste..'
        meta_x:           'editor-cut'
        meta_z:           'editor-undo'
        meta_Z:           'editor-redo'
        meta_space:       'editor-complete'
        meta_slash:       'editor-toggle-comment'
        meta_insert:      'editor-copy'

        ctrl_tab:         'view-right-wraparound'
        ctrl_shift_tab:   'view-left-wraparound'
        ctrl_meta_d:      'show-doc-at-cursor'

        ctrl_shift_s:     'buffer-structure'
        ctrl_q:           'editor-reflow-paragraph'

        meta_up:          'editor-scroll-up'
        meta_down:        'editor-scroll-down'

        -- needs option key
        -- meta_shift_left:  'cursor-word-left-extend'
        -- meta_shift_right: 'cursor-word-right-extend'
        -- meta_backspace:   'editor-delete-back-word'
        -- meta_delete:      'editor-delete-forward-word'

        ctrl_shift_d:     'vc-diff-file'
        ctrl_meta_d:      'vc-diff'

        ctrl_g:           'cursor-goto-line'
      }

      meta_o:           'open'
      meta_shift_o:     'open-recent'
      meta_p:           'project-open'
      meta_q:           'quit'
      meta_shift_r:     'project-exec'
      meta_shift_b:     'project-build'

      meta_shift_w:     'view-close'
      'meta_-':         'zoom-out'
      'meta_+':         'zoom-in'

      ctrl_meta_f:      'window-toggle-fullscreen'
      ctrl_meta_x:      'run'
}
