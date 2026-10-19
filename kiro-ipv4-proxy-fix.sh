#!/data/data/com.termux/files/usr/bin/bash
#
# Kiro CLI IPv4 Proxy Fix
#
# Sets up tinyproxy to force IPv4 traffic, working around broken IPv6 in Termux.
#
# Based on solution from: https://github.com/kirodotdev/Kiro/issues/6113#issuecomment-4253551678
#

set -euo pipefail

echo "=== Kiro Termux IPv4 Fix Installer ==="
echo

if [[ ! -d "$PREFIX" ]]; then
    echo "ERROR: This script must run on Termux (PREFIX not found)"
    exit 1
fi

echo "[1/4] Installing tinyproxy..."
if ! command -v tinyproxy &>/dev/null; then
    pkg install -y tinyproxy
    echo "Installed tinyproxy"
else
    echo "tinyproxy already installed"
fi

echo
echo "[2/4] Configuring tinyproxy..."
TINYPROXY_CONF="$PREFIX/etc/tinyproxy/tinyproxy.conf"
if [[ -f "$TINYPROXY_CONF" ]]; then
    # Read the current port (use existing, or default to 8888)
    PROXY_PORT=$(grep "^Port " "$TINYPROXY_CONF" | awk '{print $2}')
    if [[ -z "$PROXY_PORT" ]]; then
        PROXY_PORT=8888
        echo "Port $PROXY_PORT" >> "$TINYPROXY_CONF"
        echo "Set Port to $PROXY_PORT"
    else
        echo "Using existing Port: $PROXY_PORT"
    fi
    
    # Ensure Listen 127.0.0.1 is set
    if ! grep -q "^Listen " "$TINYPROXY_CONF"; then
        # Uncomment if commented
        if grep -q "^#Listen" "$TINYPROXY_CONF"; then
            sed -i 's/^#Listen .*/Listen 127.0.0.1/' "$TINYPROXY_CONF"
            echo "Enabled Listen 127.0.0.1"
        else
            # Add after Port line
            sed -i "/^Port /a Listen 127.0.0.1" "$TINYPROXY_CONF"
            echo "Added Listen 127.0.0.1"
        fi
    else
        echo "Using existing Listen setting"
    fi
    
    # Ensure ConnectPort 443 is enabled (required for HTTPS)
    if ! grep -q "^ConnectPort 443" "$TINYPROXY_CONF"; then
        sed -i 's/^#ConnectPort 443/ConnectPort 443/' "$TINYPROXY_CONF"
        sed -i 's/^#\s*ConnectPort 443/ConnectPort 443/' "$TINYPROXY_CONF"
        echo "Enabled ConnectPort 443"
    else
        echo "ConnectPort 443 already enabled"
    fi
    
    echo "tinyproxy configuration complete (port: $PROXY_PORT)"
fi

PROXY_PORT=$(grep "^Port " "$TINYPROXY_CONF" | awk '{print $2}')

if ! pgrep -x tinyproxy &>/dev/null; then
    tinyproxy -c "$TINYPROXY_CONF" 2>/dev/null || true
    sleep 1
    if pgrep -x tinyproxy &>/dev/null; then
        echo "Started tinyproxy"
    else
        echo "Warning: tinyproxy failed to start (wrapper will auto-start it)"
    fi
else
    echo "tinyproxy already running"
fi

echo
echo "[3/4] Creating kiro-cli wrapper script..."
mkdir -p "$HOME/bin"

cat > "$HOME/bin/kiro-cli.sh" <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash
#
# Kiro CLI IPv4 wrapper
# Forces all traffic through tinyproxy (IPv4 only) to work around broken IPv6 in Termux
#

# Ensure tinyproxy is running
if ! pgrep -x tinyproxy >/dev/null; then
    tinyproxy -c "$PREFIX/etc/tinyproxy/tinyproxy.conf" 2>/dev/null &
    sleep 0.5
fi

# Read proxy port from config
PROXY_PORT=$(grep "^Port " "$PREFIX/etc/tinyproxy/tinyproxy.conf" | awk '{print $2}')
PROXY_PORT=${PROXY_PORT:-8888}  # default to 8888 if not found

# Set proxy environment and run real kiro-cli
HTTPS_PROXY=http://127.0.0.1:$PROXY_PORT \
HTTP_PROXY=http://127.0.0.1:$PROXY_PORT \
NO_PROXY=localhost,127.0.0.1,::1 \
SSL_CERT_FILE="$PREFIX/etc/tls/cert.pem" \
exec "$HOME/.local/bin/kiro-cli" "$@"
EOF

chmod +x "$HOME/bin/kiro-cli.sh"
echo "Created wrapper: ~/bin/kiro-cli.sh (using port: $PROXY_PORT)"

echo
echo "[4/4] Adding alias to .bashrc..."
if ! grep -q "alias kiro-cli=" "$HOME/.bashrc" 2>/dev/null; then
    echo "" >> "$HOME/.bashrc"
    echo "# Kiro IPv4 fix - use wrapper script" >> "$HOME/.bashrc"
    echo "alias kiro-cli=\"\$HOME/bin/kiro-cli.sh\"" >> "$HOME/.bashrc"
    echo "Added alias to .bashrc"
else
    echo "Alias already exists in .bashrc"
fi

echo
echo "=== Installation Complete ==="
echo
echo "What was installed:"
echo "  1. tinyproxy (IPv4-only HTTPS proxy on 127.0.0.1:8080)"
echo "  2. Wrapper script at ~/bin/kiro-cli.sh"
echo "  3. Alias in ~/.bashrc: kiro-cli -> ~/bin/kiro-cli.sh"
echo
echo "The wrapper intercepts ALL kiro-cli commands (login, logout, chat)"
echo "and forces IPv4 by routing through tinyproxy."
echo
echo "Usage:"
echo "  - For login (must be in Termux app, NOT SSH):"
echo "      kiro-cli login"
echo
echo "  - For regular use (SSH is fine):"
echo "      kiro-cli"
echo "      echo 'query' | kiro-cli"
echo
echo "  - For logout:"
echo "      kiro-cli logout"
echo
echo "Note: Logout and re-login if you were already logged in, to ensure"
echo "      the wrapper is active for all operations."
echo
