# Flutter — Zed extension

JetBrains-style pubspec actions for Flutter/Dart projects in Zed.

Open a `pubspec.yaml` and you get a gutter ▶ button on three lines —
`name:`, `dependencies:`, `dev_dependencies:`. Click any of them to pick
from:

- `flutter pub get`
- `flutter pub upgrade`
- `flutter pub upgrade --major-versions`
- `flutter pub outdated`
- `flutter clean`
- `flutter doctor -v`

All commands run in the directory of the pubspec, so subpackages in a
monorepo work without extra config.

## Install

In Zed: `cmd-shift-p` → **`zed: install dev extension`** → pick this
folder. Open any `pubspec.yaml` to see the gutter buttons.

## Requirements

- `flutter` on `PATH`. Pure-Dart packages (no Flutter SDK) can override
  the tasks via a project-local `.zed/tasks.json`.

## Hot reload / hot restart (macOS)

Zed's debugger UI doesn't yet expose hot reload as a button — that's
blocked on [zed#51873](https://github.com/zed-industries/zed/issues/51873)
+ [zed-extensions/dart#72](https://github.com/zed-extensions/dart/pull/72).
Until those land, this extension ships a terminal-driven workflow:

1. Open a `pubspec.yaml`, click the gutter ▶, pick **Flutter — run on
   macOS** (or **Chrome**, or **default device**).
2. The terminal panel runs `flutter run` and stays interactive.
3. Add the snippet below to `~/.config/zed/keymap.json`:

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

4. Workflow:
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

When upstream lands the proper toolbar buttons, this section
deprecates.

## License

Apache-2.0.
