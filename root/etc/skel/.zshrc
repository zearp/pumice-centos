# basic zshrc -- the best shell there is =]
#
# sudo usermod --shell /bin/zsh $USER
#

# enable colours and set prompt
#
autoload -U colors && colors
PS1="%B%{$fg[blue]%}[%{$fg[cyan]%}%n%{$fg[white]%}@%{$fg[green]%}%M %{$fg[magenta]%}%~%{$fg[blue]%}]%{$reset_color%}$%b "

# save some history
#
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory
setopt hist_ignore_all_dups
setopt hist_ignore_space

# setup simple aliases
#
alias cat="bat -p"
alias grep="rg"
alias diff="diff --color=auto"
alias ip="ip -color=auto"
alias ls="eza --group-directories-first"
alias ll="eza --group-directories-first -alg --git"
alias tree="eza -Tla --time-style=long-iso"
alias nano="nano -c"
alias ncdu="ncdu --color=dark"
alias lsblk="lsblk -o name,mountpoint,label,size,uuid"
alias fastfetch="fastfetch -l small"
alias neofetch="fastfetch -l small"
alias pfetch="fastfetch -l small"

# env
#
export LESS="-R --use-color --quit-if-one-screen"
export EDITOR="nano"
export VISUAL="nano"

# enable auto completion
#
autoload -U compinit
zstyle ':completion:*' menu select
zmodload zsh/complist
compinit
_comp_options+=(globdots)

# timers
#
function preexec() {
  timer=$(($(date +%s%0N)/1000000))
}

function precmd() {
  if [ $timer ]; then
    now=$(($(date +%s%0N)/1000000))
    elapsed=$(($now-$timer))

    export RPROMPT="%F{yellow}${elapsed}ms %{$reset_color%}"
    unset timer
  fi
	}

# use vim and arrow heys to navigate auto complete
#
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'l' vi-forward-char
bindkey -M menuselect 'j' vi-down-line-or-history
bindkey -M menuselect 'left' vi-backward-char
bindkey -M menuselect 'up' vi-up-line-or-history
bindkey -M menuselect 'right' vi-forward-char
bindkey -M menuselect 'down' vi-down-line-or-history

# autocomplete/search history with up/down keys and hg "search query"
#
autoload -U history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end
bindkey "^[[A" history-beginning-search-backward-end
bindkey "^[[B" history-beginning-search-forward-end
alias hg='history 1 | grep'

# make it so newly added executables can be auto completed
#
zstyle ':completion:*' rehash true

# auto suggestions
#
source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# enable syntax highlighting, needs to be loaded last
#
source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
