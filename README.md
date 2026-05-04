# Flutter — Zed extension

JetBrains-style pubspec actions for Flutter/Dart projects in Zed, plus
a `.zed/debug.json`-driven launcher that gives you keystroke hot
reload (and lets Zed's debugger attach for breakpoints).

## What you get

Open a `pubspec.yaml`. Gutter ▶ buttons appear on `name:`,
`dependencies:`, `dev_dependencies:`. Clicking any of them opens this
picker:

- `flutter pub get`
- `flutter pub upgrade`
- `flutter pub upgrade --major-versions`
- `flutter pub outdated`
- `flutter clean`
- `flutter doctor -v`
- **`Flutter — pick & run from .zed/debug.json`** (see below)

All commands run from the pubspec's directory, so subpackages in a
monorepo work without extra config.

## Install

In Zed: `cmd-shift-p` → **`zed: install dev extension`** → pick this
folder. Open any `pubspec.yaml` to see the gutter buttons.

## Requirements

- `flutter` on `PATH`
- `jq` (`brew install jq`) — for the debug.json launcher
- Optional: `fzf` for nicer fuzzy picking; falls back to numbered
  Bash `select` menu if absent

## Run from `.zed/debug.json`

Zed's gutter runnables can only point at *tasks*, not debug configs.
This extension bridges the gap with one task — **Flutter — pick & run
from .zed/debug.json** — that reads your project's `.zed/debug.json`,
shows you the list of `type: "flutter"`, `request: "launch"` configs,
and execs the equivalent `flutter run -t <program> <toolArgs>` in the
terminal panel.

So your `.zed/debug.json` becomes the single source of truth for run
configurations — add new configs there and they show up in the picker
automatically. No extension changes needed.

Two flags get auto-injected if you haven't already added them:
`--vm-service-port=8181 --disable-service-auth-codes`. They pin the VM
service to a predictable URI (`http://127.0.0.1:8181/`) so:

1. The terminal stays interactive — keystroke hot reload works (next
   section).
2. Zed's debugger can attach to that exact URI for breakpoints (final
   section).

## Hot reload / hot restart (macOS)

Zed's debugger UI doesn't yet expose hot reload as a button — that's
blocked on [zed#51873](https://github.com/zed-industries/zed/issues/51873)
+ [zed-extensions/dart#72](https://github.com/zed-extensions/dart/pull/72).
Until those land, hot reload is keystroke-driven via the terminal
where `flutter run` lives.

Add this to `~/.config/zed/keymap.json`:

```json
[
  {
    "context": "Terminal",
    "bindings": {
      "cmd-r":       ["terminal::SendText", "r"],
      "cmd-shift-r": ["terminal::SendText", "R"],
      "cmd-q":       ["terminal::SendText", "q"]
    }
  }
]
```

Workflow:

- **`ctrl-`\`** — toggle the terminal panel (focus jumps to it)
- **`cmd-r`** — hot reload (🔥 in flutter run's parlance — `r`)
- **`cmd-shift-r`** — hot restart (`R`)
- **`cmd-q`** — stop the app (`q`)
- **`ctrl-`\`** again — back to the editor

The keystrokes only fire when the terminal pane is focused, which is
the safe contract — `terminal::SendText` requires terminal focus.
Trying to chain "save → focus terminal → send r" from the editor via
`workspace::SendKeystrokes` doesn't work reliably because focus
transitions in that chain are async.

## Hot reload + Zed debugger together

Combine our terminal-driven hot reload **with** Zed's debugger
(breakpoints, step, watches). The upstream
[`zed-extensions/dart`](https://github.com/zed-extensions/dart)
already wires Flutter's DAP. The trick is **attach mode**.

Install both extensions (this one + Dart). Add an `attach` config
alongside your `launch` configs in `.zed/debug.json`:

```json
{
  "label": "Flutter — attach (port 8181)",
  "adapter": "Dart",
  "type": "flutter",
  "request": "attach",
  "vmServiceUri": "http://127.0.0.1:8181/"
}
```

Workflow:

1. Click ▶ on the pubspec → **Flutter — pick & run from
   .zed/debug.json** → pick a launch config. Flutter starts; the VM
   service is at `http://127.0.0.1:8181/`.
2. Command palette → `debugger: start` → pick **Flutter — attach
   (port 8181)**. Zed attaches; breakpoints in `.dart` files now hit.
3. Hot reload keeps working: focus the terminal, `cmd-r` to reload.

Footnotes:

- **One Flutter app at a time per port.** Two apps both bound to 8181
  collide. If you need more, change the port in both your launch
  config's `toolArgs` and the attach config's `vmServiceUri`.
- **`--disable-service-auth-codes` is local-dev-only.** It strips the
  random token from the URI so we can pin it. `flutter build` doesn't
  expose the VM service, so this flag never affects shipped builds.
- **Detach without stopping the app** via the debugger UI's stop
  button — the running flutter process keeps going and you can
  reattach.

## License

Apache-2.0.
