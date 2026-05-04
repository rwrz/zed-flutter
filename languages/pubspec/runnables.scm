; Three gutter "Run" buttons on a pubspec.yaml:
;
;   ▶ name:               → top-of-file anchor (JetBrains-style header actions)
;   ▶ dependencies:       → inline anchor on the deps section
;   ▶ dev_dependencies:   → inline anchor on the dev-deps section
;
; All three share one tag (`pubspec`). Clicking any of them opens the same
; task picker — `flutter pub get`, `pub upgrade`, `pub outdated`, etc. The
; bound tasks live in `tasks.json` next to this file.
;
; Captures named in UPPER_CASE become `$ZED_CUSTOM_*` env vars on the spawned
; task. We don't actually consume KEY today, but exposing it lets future
; tasks specialize per anchor without changing the query.

(
  (block_mapping_pair
    key: (flow_node) @KEY
  ) @run
  (#any-of? @KEY "name" "dependencies" "dev_dependencies")
  (#set! tag pubspec)
)
