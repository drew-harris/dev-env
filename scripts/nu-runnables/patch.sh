#!/usr/bin/env bash
# Copy our runnables.scm into the installed Zed `nu` extension so that
# zero-arg `def` / `export def` declarations get a "run" gutter button.
#
# Usage:
#   patch.sh            # captures only the function name (default)
#   patch.sh --body     # captures the whole decl_def — runnable is
#                       # detected when the cursor is anywhere inside the
#                       # function body, so `task: spawn` and run-at-cursor
#                       # work without seeking to the `def` line.
#                       # The visible gutter button still sits on the `def`
#                       # line — that part is per-row in Zed.
#
# Re-run after any Zed extension update — marketplace updates will wipe the
# installed extension directory.
set -euo pipefail

variant="name"
for arg in "$@"; do
  case "$arg" in
    --body) variant="body" ;;
    --name) variant="name" ;;
    -h|--help)
      sed -n '2,14p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "error: unknown argument: $arg" >&2
      exit 2
      ;;
  esac
done

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ "$variant" == "body" ]]; then
  SRC="$SRC_DIR/runnables.body.scm"
else
  SRC="$SRC_DIR/runnables.scm"
fi
DEST_DIR="$HOME/Library/Application Support/Zed/extensions/installed/nu/languages/nu"
DEST="$DEST_DIR/runnables.scm"

if [[ ! -d "$DEST_DIR" ]]; then
  echo "error: nu extension not installed at:" >&2
  echo "  $DEST_DIR" >&2
  echo "install the 'nu' extension from Zed's extension marketplace first." >&2
  exit 1
fi

if [[ ! -f "$SRC" ]]; then
  echo "error: source query missing: $SRC" >&2
  exit 1
fi

cp "$SRC" "$DEST"
echo "patched ($variant variant): $DEST"
echo
echo "next: ensure ~/.config/zed/tasks.json has a task tagged 'nu-run', e.g.:"
cat <<'EOF'
  {
    "label": "nu: $ZED_CUSTOM_name",
    "command": "nu",
    "args": ["-c", "source $ZED_FILE; $ZED_CUSTOM_name"],
    "tags": ["nu-run"]
  }
EOF
echo
echo "note: \$ZED_RUNNABLE_SYMBOL is declared in Zed but never populated;"
echo "use the @name capture exposed as \$ZED_CUSTOM_name instead."
echo
echo "zed file-watches the extension dir, so the change should hot-reload."
echo "if the run button doesn't appear, reopen the .nu file or restart zed."
