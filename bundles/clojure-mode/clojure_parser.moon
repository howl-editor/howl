parse_ns = (text) ->
  ns = text\match '%b()'
  return {} unless ns
  name = ns\match '%(ns%s+([%w-.]+)'
  :name

{
  parse: (buffer) ->
    text = buffer.text
    ns: parse_ns text
}