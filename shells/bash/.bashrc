#     ██████╗  █████╗ ███████╗██╗  ██╗██████╗  ██████╗
#     ██╔══██╗██╔══██╗██╔════╝██║  ██║██╔══██╗██╔════╝
#     ██████╔╝███████║███████╗███████║██████╔╝██║     
#     ██╔══██╗██╔══██║╚════██║██╔══██║██╔══██╗██║     
#  ██╗██████╔╝██║  ██║███████║██║  ██║██║  ██║╚██████╗
#  ╚═╝╚═════╝ ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝

[[ $- != *i* ]] && return 

[ -f "$HOME/.config/shell/exports" ] && source "$HOME/.config/shell/exports"
[ -f "$HOME/.config/shell/functions" ] && source "$HOME/.config/shell/functions"
[ -f "$HOME/.config/shell/aliases" ] && source "$HOME/.config/shell/aliases"

# Cargar Oh-My-Bash si está disponible (XDG-compliant)
if [[ -f "${XDG_DATA_HOME:-$HOME/.local/share}/oh-my-bash/oh-my-bash.sh" ]]; then
    export OSH="${XDG_DATA_HOME:-$HOME/.local/share}/oh-my-bash"
    source ${XDG_DATA_HOME:-$HOME/.local/share}/oh-my-bash/oh-my-bash.sh
fi

[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

shopt -s histappend
shopt -s checkwinsize
shopt -s globstar

export HISTSIZE=10000
export SAVEHIST=$HISTSIZE
export HISTFILE="${XDG_CACHE_HOME:-$HOME/.cache}/bash/bash_history"

# Asegurar directorio de historial
mkdir -p "$(dirname "$HISTFILE")"

if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

PROMPT_COMMAND='PS1_CMD1=$(git branch 2>/dev/null | grep '"'"'*'"'"' | colrm 1 2)'
PS1='\[\e[38;5;69;1m\]\u\[\e[0;38;5;255m\]@\[\e[38;5;69;1m\]\h\[\e[0m\] \[\e[38;5;252m\]in\[\e[0m\] [\[\e[38;5;163m\]\w\[\e[0m\]][${PS1_CMD1}][\[\e[38;5;222m\]\t\[\e[0m\]]\n\[\e[38;5;51m\]>\[\e[0m\] '
