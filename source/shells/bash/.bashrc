#     ██████╗  █████╗ ███████╗██╗  ██╗██████╗  ██████╗
#     ██╔══██╗██╔══██╗██╔════╝██║  ██║██╔══██╗██╔════╝
#     ██████╔╝███████║███████╗███████║██████╔╝██║     
#     ██╔══██╗██╔══██║╚════██║██╔══██║██╔══██╗██║     
#  ██╗██████╔╝██║  ██║███████║██║  ██║██║  ██║╚██████╗
#  ╚═╝╚═════╝ ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝

[[ $- != *i* ]] && return

[ -f "$XDG_CONFIG_HOME/shell-configs/aliases" ] && source "$XDG_CONFIG_HOME/shell-configs/aliases"
[ -f "$XDG_CONFIG_HOME/shell-configs/exports" ] && source "$XDG_CONFIG_HOME/shell-configs/exports"
[ -f "$XDG_CONFIG_HOME/shell-configs/functions" ] && source "$XDG_CONFIG_HOME/shell-configs/functions"

[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

shopt -s histappend
shopt -s checkwinsize
shopt -s globstar

export HISTFILE="$XDG_CACHE_HOME/shells-configs/bash_history"
mkdir -p "$(dirname "$HISTFILE")"

if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# Plugins
plugins=(
    git
    bashmarks
)

if [ -f "$OSH/oh-my-bash.sh" ]; then
    source "$OSH/oh-my-bash.sh"
fi

PROMPT_COMMAND='GIT_BRANCH=$(git branch 2>/dev/null | grep "* " | sed "s/* //"); IP_ADDRESS=$(hostname -I | awk "{print \$1}")'
PS1='\[\e[38;5;69;1m\]\u\[\e[0;38;5;255m\]@\[\e[38;5;69;1m\]\h\[\e[0m\] \[\e[38;5;252m\]in\[\e[0m\] [\[\e[38;5;163m\]\w\[\e[0m\]][${GIT_BRANCH}][\[\e[38;5;222m\]\t\[\e[0m\]]\n\[\e[38;5;51m\]>\[\e[0m\] '

