#!/usr/bin/env bash
# flutter-pick.sh — read .zed/debug.json, pick a Flutter launch config,
# and exec `flutter run` with the matching toolArgs + hot-reload-friendly
# flags (--vm-service-port=8181 --disable-service-auth-codes) auto-injected
# so terminal keystroke hot reload AND Zed-debugger-attach both keep working.
#
# Why: Zed's debugger UI doesn't yet expose hot reload as a button
# (zed#51873). Running flutter ourselves (instead of via DAP launch) lets
# us keep the terminal-based reload workflow while still letting Zed's
# debugger attach for breakpoints — single source of truth: debug.json.
#
# Usage: flutter-pick.sh [worktree_root]
# Default worktree_root: $ZED_WORKTREE_ROOT or $(pwd).

set -euo pipefail

ROOT="${1:-${ZED_WORKTREE_ROOT:-$(pwd)}}"
F="$ROOT/.zed/debug.json"

if [[ ! -f "$F" ]]; then
  echo "flutter-pick: no debug.json at $F" >&2
  exit 66
fi

if ! command -v jq >/dev/null 2>&1; then
  cat >&2 <<EOF
flutter-pick: jq is required.
  brew install jq
EOF
  exit 127
fi

# Strip JSONC trailing commas so jq can parse the file. Uses perl
# (-0777 slurps the whole file) so it handles trailing commas across
# line breaks, which BSD sed on macOS can't do without an awkward
# label-based slurp incantation.
JSON=$(perl -0777 -pe 's/,(\s*[}\]])/$1/g' "$F")

# Pull all Flutter launch configs. (Avoiding `mapfile` because macOS
# ships bash 3.2.)
labels=()
while IFS= read -r line; do
  labels+=("$line")
done < <(echo "$JSON" | jq -r '
  [.[] | select(.type == "flutter" and .request == "launch")] | .[].label
')

if [[ ${#labels[@]} -eq 0 ]]; then
  echo "flutter-pick: no Flutter 'launch' configs in $F" >&2
  exit 65
fi

# Pick a config — fzf if available, else Bash select.
chosen=""
if command -v fzf >/dev/null 2>&1; then
  chosen=$(printf '%s\n' "${labels[@]}" | fzf --prompt="Flutter config: " --height=40% --reverse) || true
else
  echo "Pick a Flutter config:" >&2
  PS3="> "
  select item in "${labels[@]}"; do
    chosen="$item"
    break
  done
fi

[[ -z "$chosen" ]] && { echo "flutter-pick: cancelled" >&2; exit 1; }

# Extract the chosen config.
CONFIG=$(echo "$JSON" | jq --arg label "$chosen" '.[] | select(.label == $label)')
program=$(echo "$CONFIG" | jq -r '.program // "lib/main.dart"')
cwd=$(echo "$CONFIG" | jq -r '.cwd // "."')

# Substitute Zed variables in cwd ourselves (we read the file directly).
cwd="${cwd//\$ZED_WORKTREE_ROOT/$ROOT}"
cwd="${cwd//\$ZED_DIRNAME/${ZED_DIRNAME:-$ROOT}}"
[[ "$cwd" == "." ]] && cwd="$ROOT"

# Collect toolArgs. (Avoiding `mapfile` for macOS bash 3.2.)
toolArgs=()
while IFS= read -r arg; do
  toolArgs+=("$arg")
done < <(echo "$CONFIG" | jq -r '.toolArgs[]? // empty')

# Inject hot-reload-friendly flags only if not already present.
# (bash 3.2 + set -u trips on empty `${arr[@]}` — guard with length.)
has_port=0
has_auth=0
if [[ ${#toolArgs[@]} -gt 0 ]]; then
  for a in "${toolArgs[@]}"; do
    [[ "$a" == --vm-service-port=* ]] && has_port=1
    [[ "$a" == --disable-service-auth-codes ]] && has_auth=1
  done
fi
[[ "$has_port" -eq 0 ]] && toolArgs+=("--vm-service-port=8181")
[[ "$has_auth" -eq 0 ]] && toolArgs+=("--disable-service-auth-codes")

cd "$cwd"

# Pretty-print the resolved command.
printf '\033[1;36m▶\033[0m \033[1mflutter\033[0m run -t %s' "$program"
for a in "${toolArgs[@]}"; do printf ' %q' "$a"; done
printf '\n\n'

exec flutter run -t "$program" "${toolArgs[@]}"
