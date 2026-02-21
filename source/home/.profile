#     ██████╗ ██████╗  ██████╗ ███████╗██╗██╗     ███████╗
#     ██╔══██╗██╔══██╗██╔═══██╗██╔════╝██║██║     ██╔════╝
#     ██████╔╝██████╔╝██║   ██║█████╗  ██║██║     █████╗  
#     ██╔═══╝ ██╔══██╗██║   ██║██╔══╝  ██║██║     ██╔══╝  
#  ██╗██║     ██║  ██║╚██████╔╝██║     ██║███████╗███████╗
#  ╚═╝╚═╝     ╚═╝  ╚═╝ ╚═════╝ ╚═╝     ╚═╝╚══════╝╚══════╝

# ============================================================================
# RUTAS XDG (FREEDESKTOP STANDARD)
# ============================================================================

export XDG_CACHE_HOME=${XDG_CACHE_HOME:-"$HOME/.cache"}
export XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-"$HOME/.config"}
export XDG_DATA_HOME=${XDG_DATA_HOME:-"$HOME/.local/share"}
export XDG_STATE_HOME=${XDG_STATE_HOME:-"$HOME/.local/state"}

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
