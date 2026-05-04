; Standard YAML highlights — adapted from upstream tree-sitter-yaml.
; Zed loads queries per-language, not per-grammar, so even though we reuse
; the YAML grammar we still need our own copy here.

[
  (block_scalar)
  (single_quote_scalar)
  (double_quote_scalar)
  (string_scalar)
] @string

(boolean_scalar) @constant.builtin.boolean
(null_scalar) @constant.builtin

[
  (integer_scalar)
  (float_scalar)
] @number

(comment) @comment

(block_mapping_pair
  key: (flow_node) @property)

(flow_mapping
  (_ key: (flow_node) @property))

(tag) @type

[
  (yaml_directive)
  (tag_directive)
  (reserved_directive)
] @keyword

[
  (anchor_name)
  (alias_name)
] @label

[
  ":"
  "-"
  ">"
  "?"
] @punctuation.delimiter

[
  "["
  "]"
  "{"
  "}"
] @punctuation.bracket

[
  "*"
  "&"
  "---"
  "..."
] @punctuation.special
