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

## Hot reload via terminal — why this and not DAP?

The upstream `zed-extensions/dart` already wires Flutter's DAP
(`flutter debug_adapter`), and that adapter implements hot reload as
DAP custom requests. **But** Zed's debugger UI has no surface for
custom DAP requests yet — that's blocked on the core
[zed#51873](https://github.com/zed-industries/zed/issues/51873) and the
extension-side [zed-extensions/dart#72](https://github.com/zed-extensions/dart/pull/72).

Until both land, hot reload happens through `flutter run`'s own
interactive shell (`r` to reload, `R` to restart, `q` to quit). Our
extension ships:

1. `Flutter — run on macOS / Chrome / default device` tasks
   (gutter-button reachable from `pubspec.yaml`).
2. A documented keymap snippet (in README) that binds `cmd-r` /
   `cmd-shift-r` / `cmd-q` to `terminal::SendText` while the terminal
   pane is focused.

The "save in editor auto-fires hot reload" workflow that JetBrains
ships isn't reliably implementable today: the
`workspace::SendKeystrokes` chain trick has documented async limits
that prevent "focus terminal → send keystroke" from actually
delivering the keystroke to the new view (see Zed key-bindings.md).
Once #51873 lands and we can register custom debug-adapter actions,
this whole section should disappear.

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
