#!/data/data/com.termux/files/usr/bin/bash
#
# Kiro CLI Bun TUI Fix
#
# Wraps the Bun binary with glibc-runner to work around ELF interpreter issues.
# Run AFTER kiro-cli has downloaded the bun binary (after first login/run).
#

set -euo pipefail

echo "=== Kiro CLI Bun TUI Fix ==="
echo

if [[ ! -d "$PREFIX" ]]; then
    echo "ERROR: This script must run on Termux (PREFIX not found)"
    exit 1
fi

echo "Installing glibc-runner..."
if ! dpkg -l | grep -q "^ii.*glibc-repo"; then
    pkg install -y glibc-repo
    echo "Installed glibc-repo"
else
    echo "glibc-repo already installed"
fi

if ! command -v grun &>/dev/null; then
    pkg install -y glibc-runner
    echo "Installed glibc-runner"
else
    echo "glibc-runner already installed"
fi

echo

BUN_DIR="$HOME/.local/share/kiro-cli"
if [[ ! -f "$BUN_DIR/bun" ]]; then
    echo "Bun not downloaded yet (downloads after first login)"
    exit 0
fi

cd "$BUN_DIR"

if [[ -f "bun.real" ]]; then
    echo "Bun is already wrapped (bun.real exists)"
    echo "Current setup:"
    ls -lh bun bun.real bun.orig 2>/dev/null || ls -lh bun bun.real
    exit 0
fi

echo "Backing up original bun..."
cp bun bun.orig
echo "✓ Created backup: bun.orig"

echo "Renaming bun to bun.real..."
mv bun bun.real
echo "✓ Renamed: bun -> bun.real"

echo "Creating glibc-runner wrapper..."
cat > bun <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash
exec grun "$(dirname "$0")/bun.real" "$@"
EOF

chmod +x bun
echo "✓ Created wrapper: bun"

echo
echo "=== Bun Fix Complete ==="
echo
echo "The Bun binary has been wrapped with glibc-runner."
echo "You can now use kiro-cli's TUI interface."
echo
echo "Files in $BUN_DIR:"
ls -lh bun bun.real bun.orig
echo
