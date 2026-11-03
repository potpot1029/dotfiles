export ZSH="$HOME/.oh-my-zsh"

plugins=(git)

source $ZSH/oh-my-zsh.sh

# env, fzf, aliases
export XDG_CONFIG_HOME=$HOME/.config
export EDITOR=nvim
export VISUAL=nvim

source <(fzf --zsh)

alias sd="cd ~ && cd \$(find * -type d | fzf)"

alias ls='eza --color=always'
alias ll='eza -lh --color=always --icons'
alias la='eza -lah --color=always --icons'
alias l='eza -lah --color=always --icons --git'

eval "$(starship init zsh)"
export PATH=$PATH:$HOME/go/bin

# fnm
FNM_PATH="$HOME/.local/share/fnm"
if [ -d "$FNM_PATH" ]; then
  export PATH="$FNM_PATH:$PATH"
  eval "$(fnm env --shell zsh)"
fi

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
[ -s "$BUN_INSTALL/_bun" ] && source "$BUN_INSTALL/_bun"
