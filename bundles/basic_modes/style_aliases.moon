import style from howl.ui

-- aliases styles to make Scintillua lexers fit in, mostly as the lexers' own
-- _tokenstyles declare them (which Howl doesn't read)

with style
  .define_default 'annotation', 'preproc'
  .define_default 'attribute', 'key'
  .define_default 'builtInVariable', 'constant'
  .define_default 'cdata', 'comment'
  .define_default 'color', 'number'
  .define_default 'directive', 'preproc'
  .define_default 'doctype', 'comment'
  .define_default 'element', 'type'
  .define_default 'entity', 'special'
  .define_default 'entry', 'preproc'
  .define_default 'environment', 'tag'
  -- BibTeX declares it a constant, AWK a label
  .define_default 'field', 'constant'
  .define_default 'gawkBuiltInVariable', 'constant'
  .define_default 'gawkKeyword', 'keyword'
  .define_default 'gawkNumber', 'number'
  .define_default 'gawkOperator', 'operator'
  .define_default 'gawkRegex', 'preproc'
  .define_default 'header', 'comment'
  .define_default 'jsp_tag', 'embedded'
  .define_default 'math', 'function'
  .define_default 'namespace', 'special'
  .define_default 'preprocessor', 'preproc'
  .define_default 'section', 'class'
  .define_default 'target', 'definition'
  .define_default 'traits', 'definition'
  .define_default 'versions', 'constant'
