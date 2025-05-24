#!/usr/bin/env zsh

# Copy to zshrc
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="robbyrussell"

path+=($HOME/dev-env/scripts) 
path+=($HOME/go/bin) 

plugins=(zsh-autosuggestions zsh-syntax-highlighting tmux zsh-vi-mode)

source $ZSH/oh-my-zsh.sh


function zvm_after_init() {
    bindkey -rM viins '^['
    bindkey '^]' vi-cmd-mode
    bindkey '^ ' end-of-line
    if command -v atuin &>/dev/null; then
      eval "$(atuin init zsh)"
    else
      [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
      bindkey '^R' fzf-history-widget
    fi
}


# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='nvim'
fi
# Compilation flags

HOMEBREW_NO_AUTO_UPDATE=true

alias zr="zoxide remove -i"
alias lg="lazygit"
alias v="nvim"
alias ll="eza --icons=always -l -a"
alias ls="eza -a"
alias ld="lazydocker"
alias updates="npx npm-check-updates --interactive --format group"
alias jj st='jj st--no-pager'

alias lemur='ssh -t -C lemur "/bin/zsh -il -c \"tmux attach || tmux new-session -A -s home\""'

alias sqlite='/opt/homebrew/opt/sqlite/bin/sqlite3'


eval "$(starship init zsh)"

path+=("$HOME/.config/scripts/")

export _ZO_MAXAGE=400
eval "$(zoxide init zsh)"
source <(fzf --zsh)


autoload -Uz compinit && compinit

# Carapace
export CARAPACE_BRIDGES='zsh,fish,bash,inshellisense' # optional
zstyle ':completion:*' format $'\e[2;37mCompleting %d\e[m'
source <(carapace _carapace)

fwd() {
  if [ "$#" -ne 3 ]; then
    # Use print -u2 for stderr in Zsh, though echo works too
    print -u2 "Usage: fwd <local_port> <remote_host> <remote_port>"
    return 1
  fi
  print "Forwarding local port $1 to $2:$3 via socat..."
  # Double quotes around variables are good practice
  socat TCP-LISTEN:"$1",fork,reuseaddr TCP:"$2":"$3"
}

function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}
