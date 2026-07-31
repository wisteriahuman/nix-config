#!/bin/sh
set -e

REPO_SSH_URL="git@github.com:wisteriahuman/nix-config.git"
REPO_HTTPS_URL="https://github.com/wisteriahuman/nix-config.git"
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

# uname から nix の system 文字列 (例: aarch64-linux) を組み立てる
_detect_system() {
  arch=$(uname -m)
  case "$arch" in
    x86_64|amd64) arch=x86_64 ;;
    aarch64|arm64) arch=aarch64 ;;
    i686|i386) arch=i686 ;;
    armv7l|armv7) arch=armv7l ;;
  esac
  case "$(uname -s)" in
    Darwin) echo "$arch-darwin" ;;
    Linux) echo "$arch-linux" ;;
    *) echo "$arch-$(uname -s | tr 'A-Z' 'a-z')" ;;
  esac
}

# git が無い環境でも nix 経由で使えるようにする
_git() {
  if command -v git >/dev/null 2>&1; then
    git "$@"
  else
    nix run nixpkgs#git -- "$@"
  fi
}

# SSH鍵が未設定でも動くよう、SSH → HTTPS の順に試す
_clone() {
  if [ -n "$NIXCONFIG_REPO_URL" ]; then
    echo "==> Cloning nix-config from $NIXCONFIG_REPO_URL"
    _git clone "$NIXCONFIG_REPO_URL" "$REPO_DIR"
    return
  fi

  echo "==> Cloning nix-config (trying SSH)"
  if (
       export GIT_SSH_COMMAND="ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new -o ConnectTimeout=10"
       _git clone "$REPO_SSH_URL" "$REPO_DIR"
     ) >/dev/null 2>&1; then
    return
  fi

  echo "==> SSH not usable; falling back to HTTPS (read-only)"
  _git clone "$REPO_HTTPS_URL" "$REPO_DIR"
  echo "==> Note: push するには SSH鍵を登録したうえで"
  echo "==>       git -C $REPO_DIR remote set-url origin $REPO_SSH_URL"
}

role=$(_resolve_role "$1")
system=$(_detect_system)
echo "==> role: $role"
echo "==> system: $system"

# すでにインストール済みでも PATH に無いことがあるので拾っておく
if ! command -v nix >/dev/null 2>&1; then
  for f in /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh \
           "$HOME/.nix-profile/etc/profile.d/nix.sh"; do
    if [ -e "$f" ]; then
      # shellcheck disable=SC1090
      . "$f"
    fi
  done
fi

if ! command -v nix >/dev/null 2>&1; then
  echo "==> Installing Nix"
  if [ -t 0 ]; then
    curl -fsSL https://install.determinate.systems/nix | sh -s -- install
  else
    # `curl ... | sh` で実行された場合は stdin がスクリプト本体なので確認を出せない
    curl -fsSL https://install.determinate.systems/nix | sh -s -- install --no-confirm
  fi
  echo "==> Nix installed. Open a NEW shell session, then re-run this script to continue."
  exit 0
fi

if [ ! -d "$REPO_DIR" ]; then
  _clone
fi

attr="wisteria@$role-$system"
attrs=$(nix eval --json "$REPO_DIR#homeConfigurations" --apply builtins.attrNames 2>/dev/null || true)

if [ -n "$attrs" ] && ! printf '%s' "$attrs" | grep -qF "\"$attr\""; then
  echo "!! No home-manager configuration '$attr' in flake.nix."
  echo "!! hosts/$role.nix を用意し、flake.nix の roles に role '$role' と"
  echo "!! systems の \"$system\" を登録してから再実行してください。"
  echo "!! Available:"
  printf '%s' "$attrs" | tr ',' '\n' | tr -d '[]"' | sed 's/^/     /'
  exit 1
fi

echo "==> Running home-manager switch"
# USER が未設定のコンテナ等でも common.nix がアカウント名を拾えるようにしておく。
# --impure は common.nix が USER/HOME を読むため（ユーザ名がマシンごとに違う）。
USER="${USER:-$(id -un)}"
export USER
nix run home-manager -- switch --flake "$REPO_DIR#$attr" --impure

# --- ログインシェルを zsh に (apt / sudo に依存しない) ---------------------
_zsh_bin() {
  if [ -x "$HOME/.nix-profile/bin/zsh" ]; then
    echo "$HOME/.nix-profile/bin/zsh"
  else
    command -v zsh 2>/dev/null || true
  fi
}

_append_zsh_handoff() {
  rc="$1"
  marker="# >>> nix-config: exec zsh >>>"
  if [ -e "$rc" ] && grep -qF "$marker" "$rc"; then
    return
  fi
  cat >> "$rc" <<'EOS'

# >>> nix-config: exec zsh >>>
# chsh が使えない環境向け。対話シェルなら zsh に引き継ぐ。
# 無効化したいときは NIXCONFIG_NO_ZSH=1 を設定する。
if [ -z "${NIXCONFIG_NO_ZSH:-}" ] && [ -z "${ZSH_VERSION:-}" ] && [ -x "$HOME/.nix-profile/bin/zsh" ]; then
  case $- in
    *i*) exec "$HOME/.nix-profile/bin/zsh" -l ;;
  esac
fi
# <<< nix-config: exec zsh <<<
EOS
}

if [ "$(uname -s)" != "Darwin" ]; then
  zsh_bin=$(_zsh_bin)
  if [ -z "$zsh_bin" ]; then
    echo "!! zsh not found even after home-manager switch; skipping login shell setup"
  elif [ "${SHELL##*/}" = "zsh" ]; then
    echo "==> Login shell is already zsh"
  elif grep -qxF "$zsh_bin" /etc/shells 2>/dev/null && chsh -s "$zsh_bin" </dev/tty 2>/dev/null; then
    echo "==> Login shell set to $zsh_bin"
  else
    echo "==> chsh unavailable; hooking zsh into ~/.profile and ~/.bashrc instead"
    _append_zsh_handoff "$HOME/.profile"
    if [ -e "$HOME/.bash_profile" ]; then _append_zsh_handoff "$HOME/.bash_profile"; fi
    if [ -e "$HOME/.bashrc" ]; then _append_zsh_handoff "$HOME/.bashrc"; fi
    echo "==> 恒久的にログインシェルを変えたい場合 (root が必要):"
    echo "==>   echo \"$zsh_bin\" | sudo tee -a /etc/shells && chsh -s \"$zsh_bin\""
  fi
fi

echo "==> Done. If this role uses mise-managed tools, run: cd $REPO_DIR && mise install"
