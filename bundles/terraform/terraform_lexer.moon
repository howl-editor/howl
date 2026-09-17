-- Terraform/HCL lexer for Howl Editor
-- License: MIT

howl.util.lpeg_lexer ->
  c = capture

  -- Whitespace (using 'blank' helper for space or tab)
  whitespace = c 'whitespace', blank^1

  -- Comments
  line_comment = c 'comment', any {
    '//' * scan_until(eol),
    '#' * scan_until(eol)
  }
  block_comment = c 'comment', span('/*', '*/')
  comment = any { line_comment, block_comment }

  -- Keywords (blocks and built-in functions)
  keyword = c 'keyword', word {
    'resource', 'data', 'variable', 'output', 'locals', 'provider', 'module',
    'terraform', 'required_providers', 'required_version', 'backend',
    'moved', 'import', 'check', 'for_each', 'count', 'depends_on',
    'lifecycle', 'provisioner', 'connection'
  }

  -- Built-in functions (only match when followed by an opening parenthesis)
  builtin_function_names = {
    'abs', 'can', 'ceil', 'chomp', 'chunklist', 'cidrhost', 'cidrnetmask',
    'cidrsubnet', 'coalesce', 'coalescelist', 'compact', 'concat', 'contains',
    'csvdecode', 'dirname', 'distinct', 'element', 'file', 'fileexists',
    'fileset', 'flatten', 'floor', 'format', 'formatdate', 'formatlist',
    'indent', 'index', 'join', 'jsondecode', 'jsonencode', 'keys', 'length',
    'log', 'lookup', 'lower', 'map', 'matchkeys', 'max', 'md5', 'merge',
    'min', 'nonsensitive', 'parseint', 'pathexpand', 'pow', 'range', 'regex',
    'regexall', 'replace', 'reverse', 'rsadecrypt', 'sensitive', 'setintersection',
    'setproduct', 'setsubtract', 'setunion', 'sha1', 'sha256', 'sha512',
    'signum', 'slice', 'sort', 'split', 'strrev', 'substr', 'sum', 'templatefile',
    'textdecodebase64', 'textencodebase64', 'timeadd', 'timestamp', 'title',
    'tolist', 'tomap', 'tonumber', 'toset', 'tostring', 'transpose', 'trim',
    'trimprefix', 'trimspace', 'trimsuffix', 'try', 'upper', 'urlencode',
    'uuid', 'uuidv5', 'values', 'yamldecode', 'yamlencode', 'zipmap'
  }

  -- Match builtin functions only when followed by an opening parenthesis
  builtin_function = c('function', word(builtin_function_names)) * #(blank^0 * '(')

  -- Booleans and null
  boolean = c 'constant', word { 'true', 'false', 'null' }

  -- Numbers
  number = c 'number', any {
    float,
    hexadecimal,
    digit^1
  }

  -- Raw identifier pattern (not captured itself)
  raw_identifier_pattern = (alpha + '_') * (alnum + S'_-')^0

  -- Identifiers and variables
  identifier = c 'identifier', raw_identifier_pattern -- General identifier
  variable_ref = c('variable', P'var.' * raw_identifier_pattern)
  local_ref = c('variable', P'local.' * raw_identifier_pattern)
  data_ref = c('variable', P'data.' * raw_identifier_pattern * P'.' * raw_identifier_pattern)
  resource_ref = raw_identifier_pattern * c('variable', '.') * raw_identifier_pattern -- e.g. aws_instance.main
  module_ref = c('variable', P'module.' * raw_identifier_pattern)

  -- Function call pattern (for interpolation)
  function_call = c('function', word(builtin_function_names)) * blank^0 * c('operator', '(')

  -- Interpolation content (now defined after the patterns it uses)
  interpolation_content = any {
    variable_ref,
    local_ref,
    data_ref,
    module_ref,
    resource_ref,
    function_call,
    identifier
  }

  -- Strings
  interpolation = c('operator', '${') * interpolation_content * c('operator', '}')
  string_content = any {
    interpolation,
    c('string', (1 - S'"\\${')^1),
    c('string', P'\\\\' * 1),
  }

  string = c('string', P'"') * string_content^0 * c('string', P'"')

  -- Heredoc strings
  heredoc_delimiter_capture = Cg((alpha + '_')^1, 'heredoc_delimiter')
  heredoc_start = '<<' * heredoc_delimiter_capture
  heredoc_content = scan_until(eol * match_back('heredoc_delimiter'))
  heredoc = c 'string', sequence(heredoc_start, scan_until(eol), eol, heredoc_content, eol * match_back('heredoc_delimiter'))

  -- Attribute names (before =). Must be an identifier.
  attribute = c 'identifier', raw_identifier_pattern * #(blank^0 * '=')

  -- Operators and punctuation
  operator = c 'operator', any {
    '==', '!=', '<=', '>=', '&&', '||', '=>',
    S'={}[]().;,<>!+-*/%?:'
  }

  any {
    whitespace, -- IMPORTANT: Match whitespace first
    comment,
    keyword,
    boolean,
    number,
    string,
    heredoc,
    attribute,      -- Before general refs like variable_ref or identifier
    variable_ref,
    local_ref,
    data_ref,
    module_ref,
    resource_ref,   -- This might need care if parts are also 'identifier' or 'key'
    builtin_function, -- Now only matches function calls (with parentheses)
    function_call,    -- For function calls in interpolation
    operator,
    identifier      -- Fallback for identifiers not caught by other rules
  }
