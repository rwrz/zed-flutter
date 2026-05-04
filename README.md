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

## License

Apache-2.0.
