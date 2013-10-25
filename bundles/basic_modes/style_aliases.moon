import style from howl.ui

-- aliases styles to make Scintillua lexers fit in

with style
  .define_default 'attribute', 'key'
  .define_default 'at_rule', 'preproc'
  .define_default 'cdata', 'comment'
  .define_default 'doctype', 'comment'
  .define_default 'element', 'type'
  .define_default 'em', 'emphasis'
  .define_default 'entity', 'special'
  .define_default 'code', 'embedded'
  .define_default 'color', 'number'
  .define_default 'environment', 'tag'
  .define_default 'jsp_tag', 'embedded'
  .define_default 'list', 'number'
  .define_default 'math', 'function'
  .define_default 'namespace', 'special'
  .define_default 'php_tag', 'embedded'
  .define_default 'rhtml_tag', 'embedded'
  .define_default 'section', 'class'
  .define_default 'target', 'definition'
  .define_default 'unit', 'label'
  .define_default 'value', 'constant'
