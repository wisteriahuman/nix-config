#!/bin/sh
set -e

REPO_URL="git@github.com:wisteriahuman/nix-config.git"
REPO_DIR="$HOME/Projects/nix-config"

_detect_role() {
  if [ "$(uname -s)" = "Darwin" ]; then
    echo mac-full
  else
    echo linux-minimal
  fi
}

_resolve_role() {
  if [ -n "$1" ]; then
    echo "$1"
    return
  fi
  if [ -n "$NIXCONFIG_ROLE" ]; then
    echo "$NIXCONFIG_ROLE"
    return
  fi
  detected=$(_detect_role)
  if { printf "Detected role: %s. Press Enter to accept, or type a different role: " "$detected" > /dev/tty
       read -r answer < /dev/tty; } 2>/dev/null; then
    echo "${answer:-$detected}"
  else
    echo "$detected"
  fi
}

role=$(_resolve_role "$1")
echo "==> role: $role"

os=$(uname -s)

if [ "$os" != "Darwin" ]; then
  if ! command -v git >/dev/null 2>&1; then
    echo "==> Installing git"
    sudo apt-get update && sudo apt-get install -y git
  fi
fi

if [ ! -d "$REPO_DIR" ]; then
  echo "==> Cloning nix-config"
  git clone "$REPO_URL" "$REPO_DIR"
fi

if ! grep -q "\"wisteria@$role\"" "$REPO_DIR/flake.nix"; then
  echo "!! No home-manager configuration for role '$role' in flake.nix."
  echo "!! Add hosts/$role.nix and register it in flake.nix first, then re-run."
  exit 1
fi

if ! command -v nix >/dev/null 2>&1; then
  echo "==> Installing Nix"
  curl -fsSL https://install.determinate.systems/nix | sh -s -- install
  echo "==> Nix installed. Open a NEW shell session, then re-run this script to continue."
  exit 0
fi

if [ "$os" != "Darwin" ]; then
  if ! command -v zsh >/dev/null 2>&1; then
    echo "==> Installing zsh"
    sudo apt-get install -y zsh
  fi
fi

echo "==> Running home-manager switch"
nix run home-manager -- switch --flake "$REPO_DIR#wisteria@$role"

if [ "$os" != "Darwin" ]; then
  echo "==> Setting login shell to zsh"
  chsh -s "$(command -v zsh)"
fi

echo "==> Done. If this role uses mise-managed tools, run: cd $REPO_DIR && mise install"
