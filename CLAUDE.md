# zed-flutter — architecture

Zed extension that adds JetBrains-style pubspec actions to Flutter/Dart
projects. The MVP is just a new "Pubspec" language with three gutter
runnables wired to `flutter pub` tasks.

## Layout

```
flutter/
├── extension.toml                 ← Zed manifest
├── languages/pubspec/
│   ├── config.toml                ← registers Pubspec on pubspec.{yaml,yml}
│   ├── highlights.scm             ← standard YAML highlights (own copy — see below)
│   ├── runnables.scm              ← gutter ▶ buttons on name:/dependencies:/dev_dependencies:
│   └── tasks.json                 ← tasks bound to tag `pubspec`
└── test/pubspec.yaml              ← smoke test
```

## Why a separate "Pubspec" language?

Zed extensions can't extend an existing language, so to attach
`runnables.scm` to `pubspec.yaml` we register a new language that:

1. Matches `path_suffixes = ["pubspec.yaml", "pubspec.yml"]` (the suffix
   matcher handles full filenames, so it shadows the built-in YAML for
   these files only).
2. Reuses Zed's built-in YAML grammar via `grammar = "yaml"` — no need to
   declare `[grammars.yaml]` in `extension.toml`.
3. Ships its own `highlights.scm`. Zed loads highlight queries
   per-language, not per-grammar, so reusing the grammar doesn't carry
   highlights across.

## Why no LSP / code lens?

JetBrains shows pubspec actions in a top-of-file toolbar. Zed has no
equivalent extension API, so the closest replication is gutter buttons
via `runnables.scm`. A real top-of-file rendering would require shipping
a tiny LSP server that emits `textDocument/codeLens` (~300–400 LOC of
Rust + a binary release pipeline). Worth doing if the gutter affordance
ever feels wrong; not worth it yet.

## Why `flutter pub` (not `dart pub`)?

This is the Flutter extension — Flutter projects need `flutter pub` to
pick up SDK pinning. Pure-Dart packages can override tasks via
`.zed/tasks.json` in their project.

## Reference reading

- Zed extension docs: <https://zed.dev/docs/extensions/developing-extensions>
- Language extensions: <https://zed.dev/docs/extensions/languages>
- Task system: <https://zed.dev/docs/tasks>
- Sibling extension we modeled after: `../zed-http-grpc` — same
  runnables-tag-to-tasks pattern.

## Local dev workflow

1. `cmd-shift-p` → `zed: install dev extension` → pick this folder.
2. Open `test/pubspec.yaml`. Verify highlights + three gutter ▶ buttons.
3. Iterate on `runnables.scm` / `tasks.json` → `cmd-shift-p` →
   `zed: reload extensions`.
