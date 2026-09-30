{
  whitelist_shadowing: {
    ['bundles/vi']: {
      'editor'
    }
  }

  whitelist_globals: {
    ["."]: {
      'bundle_file',
      'bundle_load',
      'bundles',
      'callable',
      'nr_active_coroutines',
      'howl',
      'jit',
      'log',
      'moon',
      'moonscript',
      'r',
      'typeof',
      'user_load',
    },

    ['bundles/']: {
      'provide_module',
      'require_bundle'
    }

    spec: {
      'after_each',
      'async',
      'before_each',
      'close_all_buffers',
      'collect_memory',
      'context',
      'describe',
      'get_ui_list_widget_column',
      'howl_async',
      'howl_main_ctx'
      'it',
      'moon',
      'set_howl_loop',
      'settimeout',
      'setup',
      'spy',
      'Spy',
      'teardown',
      'within_command_line',
      'with_signal_handler',
      'with_tmpdir',
      'trimmed_text',
      'test_window',
      'pending',
      'use_test_buffers'
   },

    sandboxed_loader_spec: {
      'foo_load',
      'foo_file'
    }

    sandbox_spec: {
      'from_env'
    }

    _lexer: {
      'alpha',
      'alnum',
      'any',
      'back_was',
      'blank',
      'capture',
      'B',
      'C',
      'Cc',
      'Cg',
      'Cmt',
      'compose',
      'complement',
      'digit',
      'eol',
      'float',
      'hexadecimal',
      'hexadecimal_float',
      'last_token_matches',
      'line_start',
      'lower',
      'match_back',
      'match_until',
      'sequence',
      'S',
      'scan_to',
      'scan_until',
      'separate',
      'octal',
      'P',
      'paired',
      'R',
      'scan_through_indented',
      'scan_until_capture',
      'space',
      'span',
      'sub_lex',
      'sub_lex_by_lexer',
      'sub_lex_by_inline',
      'sub_lex_match_time',
      'sub_lex_by_pattern',
      'sub_lex_by_pattern_match_time',
      'word',
      'V',
      'upper',
      'xdigit'
    }
  }
}
