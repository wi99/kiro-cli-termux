#!/data/data/com.termux/files/usr/bin/bash
#
# Kiro CLI Termux Installer
#
# Installs kiro-cli and applies fixes for Termux.
# Run twice: once before login, once after login.
#

set -euo pipefail

echo "=== Kiro CLI Termux Installer ==="
echo

if [[ ! -d "$PREFIX" ]]; then
    echo "ERROR: This script must run on Termux (PREFIX not found)"
    exit 1
fi

if [[ "${TERMUX_APK_RELEASE:-}" != "F_DROID" ]]; then
    echo "ERROR: This script requires F-Droid Termux."
    echo "You are running: ${TERMUX_APK_RELEASE:-Google Play or unknown version}"
    echo
    echo "Google Play Termux has additional issues that are not yet solved."
    echo "Please install Termux from F-Droid:"
    echo "  https://f-droid.org/en/packages/com.termux/"
    echo
    exit 1
fi

TEMP_DIR=$(mktemp -d)
trap "rm -rf '$TEMP_DIR'" EXIT
cd "$TEMP_DIR"

BASE_URL="https://raw.githubusercontent.com/wi99/kiro-cli-termux/main"

echo "Step 1: Installing kiro-cli..."
if command -v kiro-cli &>/dev/null && [[ -f "$HOME/.local/bin/kiro-cli" ]]; then
    echo "kiro-cli already installed ($(kiro-cli --version 2>&1 || echo 'unknown version'))"
else
    echo "Running official kiro-cli installer..."
    curl -fsSL https://cli.kiro.dev/install | bash
    if [[ -f "$HOME/.local/bin/kiro-cli" ]]; then
        echo "kiro-cli installed successfully"
    else
        echo "ERROR: kiro-cli installation failed"
        exit 1
    fi
fi

echo
echo "Step 2: Configuring PATH..."
mkdir -p "$HOME/bin"

if ! grep -q '\$HOME/bin' "$HOME/.bashrc" 2>/dev/null; then
    echo 'export PATH="$HOME/bin:$PATH"' >> "$HOME/.bashrc"
    echo "Added ~/bin to PATH"
fi

if ! grep -q '\$HOME/.local/bin' "$HOME/.bashrc" 2>/dev/null; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
    echo "Added ~/.local/bin to PATH"
fi

export PATH="$HOME/bin:$HOME/.local/bin:$PATH"

echo
echo "Step 3: Applying IPv4 proxy fix..."
echo "Downloading proxy fix script..."
curl -fsSL "$BASE_URL/kiro-ipv4-proxy-fix.sh" -o kiro-ipv4-proxy-fix.sh
chmod +x kiro-ipv4-proxy-fix.sh
bash kiro-ipv4-proxy-fix.sh

BUN_DIR="$HOME/.local/share/kiro-cli"
if [[ ! -f "$BUN_DIR/bun" ]]; then
    echo
    echo "Bun not downloaded yet (downloads after first login)"
    BUN_NOT_READY=true
else
    echo
    echo "Step 4: Applying Bun TUI fix..."
    curl -fsSL "$BASE_URL/kiro-bun-fix.sh" -o kiro-bun-fix.sh
    chmod +x kiro-bun-fix.sh
    bash kiro-bun-fix.sh
fi

echo
if [[ "${BUN_NOT_READY:-false}" == "true" ]]; then
    echo "=== Setup Complete (Step 1 of 2) ==="
    echo
    echo "Next steps:"
    echo "  1. Log out of Termux and log back in"
    echo "  2. Login: kiro-cli login"
    echo "  3. Run this installer again to complete the Bun fix"
else
    echo "=== Installation Complete ==="
    echo
    echo "kiro-cli is now fully functional!"
fi
echo
