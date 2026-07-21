# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.config/zsh/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export LANG=en_US.UTF-8
export EDITOR=nvim

autoload -Uz compinit
compinit

eval "$(sheldon source)"

eval "$(fzf --zsh)"
export FZF_DEFAULT_OPTS='--highlight-line'

export PATH="$HOME/.local/bin:$HOME/go/bin:$PATH"

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

alias ls='eza --icons --group-directories-first'
alias la='eza -a --icons --group-directories-first'
alias ll='eza -l --icons --group-directories-first'
alias lt='eza -aT --icons --group-directories-first'

alias cat='bat'
export MANPAGER="sh -c 'col -bx | bat -l man -p'"

eval "$(zoxide init zsh)"

alias grep='rg'

eval "$(mise activate zsh)"

source ~/.config/zsh/functions.zsh

for f in ~/.config/zsh/hidden/*.zsh(N); do
    source "$f"
done

# To customize prompt, run `p10k configure` or edit ~/.config/zsh/.p10k.zsh.
[[ ! -f ~/.config/zsh/.p10k.zsh ]] || source ~/.config/zsh/.p10k.zsh
