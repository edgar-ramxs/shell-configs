#     ██████╗  █████╗ ███████╗██╗  ██╗██████╗  ██████╗
#     ██╔══██╗██╔══██╗██╔════╝██║  ██║██╔══██╗██╔════╝
#     ██████╔╝███████║███████╗███████║██████╔╝██║     
#     ██╔══██╗██╔══██║╚════██║██╔══██║██╔══██╗██║     
#  ██╗██████╔╝██║  ██║███████║██║  ██║██║  ██║╚██████╗
#  ╚═╝╚═════╝ ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝

[[ $- != *i* ]] && return 

[ -f "$XDG_CONFIG_HOME/shell-configs/exports" ] && source "$XDG_CONFIG_HOME/shell-configs/exports"
[ -f "$XDG_CONFIG_HOME/shell-configs/functions" ] && source "$XDG_CONFIG_HOME/shell-configs/functions"
[ -f "$XDG_CONFIG_HOME/shell-configs/aliases" ] && source "$XDG_CONFIG_HOME/shell-configs/aliases"

if [[ -f "$XDG_DATA_HOME/oh-my-bash/oh-my-bash.sh" ]]; then
    source $XDG_DATA_HOME/oh-my-bash/oh-my-bash.sh
fi

[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

shopt -s histappend
shopt -s checkwinsize
shopt -s globstar

export HISTSIZE=10000
export SAVEHIST=$HISTSIZE
export HISTFILE="$XDG_CACHE_HOME/shells-configs/bash_history"

# Configurar historial XDG-compliant de forma segura
if [[ -n "${XDG_CACHE_HOME:-}" ]]; then
    export HISTFILE="$XDG_CACHE_HOME/bash/bash_history"
else
    export HISTFILE="$HOME/.cache/bash/bash_history"
fi

# Asegurar directorio de historial con validación mejorada
local hist_dir
hist_dir="$(dirname "$HISTFILE")"

if [[ ! -d "$hist_dir" ]]; then
    # Crear directorio con permisos seguros
    if mkdir -p "$hist_dir" 2>/dev/null; then
        # Establecer permisos restrictivos (solo usuario)
        chmod 700 "$hist_dir" 2>/dev/null || {
            echo "Warning: No se pueden establecer permisos seguros para $hist_dir" >&2
        }
    else
        # Fallback a directorio temporal si no se puede crear el directorio XDG
        local fallback_hist="/tmp/bash_history_$$"
        export HISTFILE="$fallback_hist"
        echo "Warning: Usando historial temporal en $fallback_hist" >&2
        echo "No se puede crear directorio de historial: $hist_dir" >&2
    fi
fi

# Validar que el archivo de historial se puede escribir
if [[ ! -f "$HISTFILE" ]]; then
    if ! touch "$HISTFILE" 2>/dev/null; then
        echo "Warning: No se puede crear archivo de historial: $HISTFILE" >&2
        # Deshabilitar historial si no se puede escribir
        unset HISTFILE
        export HISTSIZE=0
        export SAVEHIST=0
    else
        # Establecer permisos seguros para el archivo
        chmod 600 "$HISTFILE" 2>/dev/null || true
    fi
elif [[ ! -w "$HISTFILE" ]]; then
    echo "Warning: Archivo de historial no es escribible: $HISTFILE" >&2
    # Deshabilitar historial si no se puede escribir
    unset HISTFILE
    export HISTSIZE=0
    export SAVEHIST=0
fi

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

# Cargar Oh-My-Bash
if [ -f "$OSH/oh-my-bash.sh" ]; then
    source "$OSH/oh-my-bash.sh"
fi

PROMPT_COMMAND='GIT_BRANCH=$(git branch 2>/dev/null | grep "* " | sed "s/* //"); IP_ADDRESS=$(hostname -I | awk "{print \$1}")'
PS1='\[\e[38;5;69;1m\]\u\[\e[0;38;5;255m\]@\[\e[38;5;69;1m\]\h\[\e[0m\] \[\e[38;5;252m\]in\[\e[0m\] [\[\e[38;5;163m\]\w\[\e[0m\]][${GIT_BRANCH}][\[\e[38;5;222m\]\t\[\e[0m\]]\n\[\e[38;5;51m\]>\[\e[0m\] '
