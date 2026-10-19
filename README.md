# Kiro CLI Termux Installation Scripts

Scripts to get kiro-cli fully working on Termux (Android).

## Problem

Kiro CLI has two issues on Termux:
1. **IPv6 networking is broken** → Login and chat fail
2. **Bun TUI uses glibc** → TUI runtime fails to launch

## Quick Start

Run on F-Droid Termux:

```bash
curl -fsSL https://raw.githubusercontent.com/wi99/kiro-cli-termux/main/install.sh | bash
```

Log out of Termux and log back in. Then run `kiro-cli login`, and after logging in run the same installer command again (press up arrow or copy below):

```bash
curl -fsSL https://raw.githubusercontent.com/wi99/kiro-cli-termux/main/install.sh | bash
```

Done!

## Scripts

**`install.sh`** - Main installer

Complete installation script that downloads and applies fixes as needed. Safe to run multiple times (idempotent).

**`kiro-ipv4-proxy-fix.sh`** - IPv4/networking fix

Installs tinyproxy, creates wrapper script, adds alias. Downloaded and run automatically by install.sh on first run.

**`kiro-bun-fix.sh`** - Bun TUI fix

Wraps Bun binary with glibc-runner. Downloaded and run automatically by install.sh on second run (after login).

## Requirements

- F-Droid Termux (Google Play version has additional unsolved issues)

## Notes

- I personally just have tested this with Google login

## Reference

IPv6 networking fix based on: https://github.com/kirodotdev/Kiro/issues/6113#issuecomment-4253551678
