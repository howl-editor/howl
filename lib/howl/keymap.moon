{
  editor: {
    tab:              'editor-smart-tab'
    shift_tab:        'editor-smart-back-tab'
    backspace:        'editor-delete-back'
    delete:           'editor-delete-forward'
    return:           'editor-newline'

    action_b:         'switch-buffer'
    action_c:         'editor-copy'
    action_d:         'editor-duplicate-current'
    action_f:         'buffer-search-forward'
    action_r:         'buffer-search-backward'
    action_comma:     'buffer-search-word-backward'
    action_period:    'buffer-search-word-forward'
    action_g:         'buffer-grep'
    action_i:         'editor-indent'
    action_k:         'editor-delete-to-end-of-line'
    action_shift_i:   'editor-indent-all'
    action_h:         'buffer-replace'
    action_s:         'save'
    action_shift_s:   'save-as'
    action_v:         'editor-paste'
    action_shift_v:   'editor-paste..'

    action_x:         'editor-cut'
    action_z:         'editor-undo'
    action_Z:         'editor-redo'
    action_q:         'show-doc-at-cursor'
    action_space:     'editor-complete'
    action_slash:     'editor-toggle-comment'
    action_tab:       'view-next'

    shift_insert:     'editor-paste'
    action_insert:    'editor-copy'

    action_shift_a:   'editor-select-all'

    alt_s:            'buffer-structure'
    alt_q:            'editor-reflow-paragraph'

    left:             'cursor-left'
    right:            'cursor-right'
    up:               'cursor-up'
    down:             'cursor-down'
    shift_left:       'cursor-left-extend'
    shift_right:      'cursor-right-extend'
    shift_up:         'cursor-up-extend'
    shift_down:       'cursor-down-extend'

    action_left:        'cursor-word-left'
    action_right:       'cursor-word-right'
    action_up:          'editor-scroll-up'
    action_down:        'editor-scroll-down'

    action_shift_left:  'cursor-word-left-extend'
    action_shift_right: 'cursor-word-right-extend'
    action_shift_up:    'editor-scroll-up'
    action_shift_down:  'editor-scroll-down'

    action_shift_d:     'vc-diff-file'
    action_alt_d:       'vc-diff'

    page_up:          'cursor-page-up'
    shift_page_up:    'cursor-page-up-extend'
    page_down:        'cursor-page-down'
    shift_page_down:  'cursor-page-down-extend'
    end:              'cursor-line-end'
    shift_end:        'cursor-line-end-extend'
    home:             'cursor-home'
    shift_home:       'cursor-home-extend'
  }

  action_o:           'open'
  action_p:           'project-open'
  action_shift_r:     'exec'
  action_alt_r:       'project-exec'
  action_shift_b:     'project-build'

  action_w:           'view-close'
  'action_-':         'zoom-out'
  'action_+':         'zoom-in'

  alt_f11:          'window-toggle-fullscreen'
  alt_x:            'run'
  action_shift_x:   'run'

  shift_alt_left:  'view-left-or-create'
  shift_alt_right: 'view-right-or-create'
  shift_alt_up:    'view-up-or-create'
  shift_alt_down:  'view-down-or-create'
}
