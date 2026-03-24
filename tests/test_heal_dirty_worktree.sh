#!/bin/bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

TMP_REPO="$TMP_DIR/repo"
mkdir -p "$TMP_REPO"
git init -q "$TMP_REPO"
git -C "$TMP_REPO" config user.email "cascade@example.com"
git -C "$TMP_REPO" config user.name "CASCADE Tests"
printf 'hello\n' > "$TMP_REPO/app.txt"
git -C "$TMP_REPO" add app.txt
git -C "$TMP_REPO" commit -qm "init"
printf 'dirty\n' >> "$TMP_REPO/app.txt"

cat > "$TMP_DIR/aider" <<'EOF'
#!/bin/bash
touch "${CASCADE_FAKE_AIDER_CALLED_FILE:?}"
exit 0
EOF
chmod +x "$TMP_DIR/aider"

OUTPUT=$(
    env \
        PATH="$TMP_DIR:$PATH" \
        REPO_ROOT="$REPO_ROOT" \
        TMP_REPO="$TMP_REPO" \
        CASCADE_FAKE_AIDER_CALLED_FILE="$TMP_DIR/aider-called" \
        bash -c 'cd "$TMP_REPO" && source "$REPO_ROOT/scripts/lib/heal_core.sh" && run_heal "fix app"' \
        || true
)

[[ "$OUTPUT" == *"dirty git worktree"* ]]
[[ ! -f "$TMP_DIR/aider-called" ]]
