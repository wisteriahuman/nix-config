export ZDOTDIR="$HOME/.config/zsh"
export RUSTUP_HOME="$HOME/.local/share/rustup"
export CARGO_HOME="$HOME/.local/share/cargo"
export DOCKER_CONFIG="$HOME/.config/docker"
export PATH="$CARGO_HOME/bin:$PATH"
# Claude Code の mods（function hooks。wisteria.cc）を有効にする
export CLAUDE_CODE_ENABLE_FUNCTION_HOOKS=1

[[ "$(uname)" == "Linux" ]] && export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent"
