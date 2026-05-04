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

## Hot reload + Zed debugger together

You can combine our terminal-driven hot reload **with** Zed's debugger
(breakpoints, step, watches) — the upstream
[`zed-extensions/dart`](https://github.com/zed-extensions/dart)
extension already wires Flutter's DAP. The trick is **attach mode**:
run Flutter ourselves, then have Zed's debugger attach to the running
VM service.

Install both extensions (this one + Dart). Then:

1. Open `pubspec.yaml`, click ▶, pick **Flutter — run on macOS
   (debugger-ready, port 8181)**. The `--vm-service-port=8181
   --disable-service-auth-codes` flags pin the VM service to a
   predictable URI: `ws://127.0.0.1:8181/ws`.
2. Drop `.zed/debug.json` into your project root:

   ```json
   [
     {
       "label": "Flutter — attach (macOS, port 8181)",
       "adapter": "Dart",
       "type": "flutter",
       "request": "attach",
       "vmServiceUri": "ws://127.0.0.1:8181/ws"
     }
   ]
   ```

3. Once Flutter prints `A Dart VM Service is available at:
   http://127.0.0.1:8181/`, run `debugger: start` from the command
   palette and pick the attach config. Zed attaches; breakpoints set in
   `.dart` files now hit.
4. Hot reload still works the way it did before: focus the terminal
   pane (`ctrl-`\`), `cmd-r` to reload, `cmd-shift-r` to restart.

So you get **breakpoints from Zed + hot reload from the terminal**
simultaneously, on one running app. The debugger doesn't own the
process — it's just attached, so killing the app means `cmd-q` in the
terminal as before.

A few footnotes:

- **One Flutter app at a time per port.** Two apps both bound to 8181
  collide. If you need more, change the port in both the task args and
  `vmServiceUri`.
- **`--disable-service-auth-codes` is local-dev-only.** It strips the
  random token from the URI so we can pin it. Don't ship a build with
  it (it'd be a non-issue anyway since `flutter build` doesn't expose
  the VM service).
- **Detach without stopping the app** via the debugger UI's stop
  button — the running flutter process keeps going and you can
  reattach.

## License

Apache-2.0.
