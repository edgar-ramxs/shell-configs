#     ██████╗ ██████╗  ██████╗ ███████╗██╗██╗     ███████╗
#     ██╔══██╗██╔══██╗██╔═══██╗██╔════╝██║██║     ██╔════╝
#     ██████╔╝██████╔╝██║   ██║█████╗  ██║██║     █████╗  
#     ██╔═══╝ ██╔══██╗██║   ██║██╔══╝  ██║██║     ██╔══╝  
#  ██╗██║     ██║  ██║╚██████╔╝██║     ██║███████╗███████╗
#  ╚═╝╚═╝     ╚═╝  ╚═╝ ╚═════╝ ╚═╝     ╚═╝╚══════╝╚══════╝

# ============================================================================

export XDG_DATA_HOME=${XDG_DATA_HOME:-"$HOME/.local/share"}
export XDG_CACHE_HOME=${XDG_CACHE_HOME:-"$HOME/.cache"}
export XDG_STATE_HOME=${XDG_STATE_HOME:-"$HOME/.local/state"}
export XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-"$HOME/.config"}

# ============================================================================

if [ -n "$BASH_VERSION" ]; then
    if [ -f "$HOME/.bashrc" ]; then
        source "$HOME/.bashrc"
    fi
elif [ -n "$ZSH_VERSION" ]; then
    if [ -f "$HOME/.zshrc" ]; then
        source "$HOME/.zshrc"
    fi
fi

# ============================================================================

# Directorio de dotfiles shell-configs
# export DOTFILES_DIR="${HOME}/.dotfiles/shell-configs"

export DOTFILES_DIR="${HOME}/.dotfiles/shell-configs"

[ -f "$DOTFILES_DIR/src/config/aliases" ] && source "$DOTFILES_DIR/src/config/aliases"
if [ -f /etc/os-release ]; then
    . /etc/os-release
    case "${ID_LIKE:-$ID}" in
        *debian*|*ubuntu*)  _d="debian" ;;
        *arch*)             _d="arch"   ;;
        *fedora*|*rhel*)    _d="fedora" ;;
        *)                  _d="$ID"    ;;
    esac

    [ -f "$DOTFILES_DIR/src/config/cmd/cmd.${_d}.aliases" ] && \
        source "$DOTFILES_DIR/src/config/cmd/cmd.${_d}.aliases"

    unset _d
fi
# [ -f "$DOTFILES_DIR/src/config/editing" ] && source "$DOTFILES_DIR/src/config/editing"

[ -f "$DOTFILES_DIR/src/config/exports" ] && source "$DOTFILES_DIR/src/config/exports"
[ -f "$DOTFILES_DIR/src/config/functions" ] && source "$DOTFILES_DIR/src/config/functions"

# ============================================================================
