export ZDOTDIR="$HOME/.config/zsh"
export RUSTUP_HOME="$HOME/.local/share/rustup"
export CARGO_HOME="$HOME/.local/share/cargo"
export DOCKER_CONFIG="$HOME/.config/docker"
export PATH="$CARGO_HOME/bin:$PATH"

[[ "$(uname)" == "Linux" ]] && export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent"
