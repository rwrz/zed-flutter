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
├── bin/
│   └── flutter-pick.sh            ← reads .zed/debug.json, picker, exec flutter run
└── test/
    ├── pubspec.yaml               ← smoke test
    └── .zed/debug.json            ← sample launch + attach configs
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

## Combining with Zed's debugger

The upstream Dart extension's DAP supports `request: "attach"` +
`vmServiceUri` (see `dart.rs:139` in `zed-extensions/dart`). Our
`Flutter — run on macOS (debugger-ready, port 8181)` task pins
`--vm-service-port=8181 --disable-service-auth-codes` so the URI is
predictable (`http://127.0.0.1:8181/`). Users drop a matching
`.zed/debug.json` (template at `test/.zed/debug.json`) and Zed's
debugger attaches.

This gives both surfaces simultaneously: hot reload via terminal
keystrokes (we own that), breakpoints/step/watches via Zed's
debugger UI (upstream owns that). The debug session **attaches**
rather than launches, so killing the app is still a terminal `q`.

Why pin a port instead of letting Flutter choose? Because the alternative
is the user copy-pasting the random URI into `.zed/debug.json` every
run. Pinning the port is a one-time setup; the auth-code skip is the
only way to get a stable URI shape (`/ws` instead of `/<token>=/ws`).
Both flags are local-dev-only.

## Why `bin/flutter-pick.sh` instead of N hardcoded tasks

Users define their run configurations in `.zed/debug.json` (Zed's
debugger config file). Real Flutter apps have many — different
flavors (dev/stag/prod), modes (debug/profile/release), and rich
`toolArgs` (`--dart-define=…`, `--web-port=…`, etc). Hardcoding
"Flutter — run on macOS" / "Flutter — run on Chrome" tasks in our
extension means users either edit the extension every time they need
a new variant, or duplicate config between `.zed/tasks.json` and
`.zed/debug.json`.

Instead, one task — **Flutter — pick & run from .zed/debug.json** —
reads the user's `debug.json`, fzf/select-picks a `type: "flutter"`,
`request: "launch"` entry, translates it to the equivalent
`flutter run -t <program> <toolArgs>`, and execs in the terminal.
Auto-injects `--vm-service-port=8181 --disable-service-auth-codes`
so terminal-keystroke hot reload + Zed-debugger-attach both keep
working.

The script lives in `bin/flutter-pick.sh` for readability, then gets
base64-embedded into `tasks.json` because Zed exposes no
`$ZED_EXTENSION_DIR` for tasks to find shipped files at runtime.
Same pattern as `../zed-http-grpc/bin/grpcrun.sh`. To regenerate:

```sh
B64=$(base64 -i bin/flutter-pick.sh | tr -d '\n')
jq --arg b64 "$B64" '(.[] | select(.label == "Flutter — pick & run from .zed/debug.json") | .args[1]) =
  ("'"'"'echo " + $b64 + " | base64 --decode | bash -s -- \"$ZED_WORKTREE_ROOT\"'"'"'")' \
  languages/pubspec/tasks.json > /tmp/x && mv /tmp/x languages/pubspec/tasks.json
```

The single-quote-wrapping is required to survive Zed's broken task
shell wrapping ([zed#53046](https://github.com/zed-industries/zed/issues/53046)).
See `../zed-http-grpc/CLAUDE.md` for the full rationale.

### Dependencies on the user's machine

- `jq` — required (parsing debug.json). Script aborts with a
  `brew install jq` hint if missing.
- `perl` — required (multi-line trailing-comma stripping for JSONC).
  Ships with macOS.
- `fzf` — optional. If present, used as the picker; otherwise we
  fall back to bash `select`. Both work; fzf is just nicer.
- `bash` — script runs under `/bin/bash` 3.2 (macOS default), so no
  `mapfile`, no `declare -A`, length-guard `${arr[@]}` under
  `set -u`.

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
