#     ██████╗ ██████╗  ██████╗ ███████╗██╗██╗     ███████╗
#     ██╔══██╗██╔══██╗██╔═══██╗██╔════╝██║██║     ██╔════╝
#     ██████╔╝██████╔╝██║   ██║█████╗  ██║██║     █████╗  
#     ██╔═══╝ ██╔══██╗██║   ██║██╔══╝  ██║██║     ██╔══╝  
#  ██╗██║     ██║  ██║╚██████╔╝██║     ██║███████╗███████╗
#  ╚═╝╚═╝     ╚═╝  ╚═╝ ╚═════╝ ╚═╝     ╚═╝╚══════╝╚══════╝

# XDG Base Directory Specification
export XDG_DATA_HOME=${XDG_DATA_HOME:-"$HOME/.local/share"}
export XDG_CACHE_HOME=${XDG_CACHE_HOME:-"$HOME/.cache"}
export XDG_STATE_HOME=${XDG_STATE_HOME:-"$HOME/.local/state"}
export XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-"$HOME/.config"}

export DOTFILES_DIR="${HOME}/.dotfiles"
export SHELL_CONFIGS_DIR="${DOTFILES_DIR}/shell-configs"

if [ -n "$BASH_VERSION" ]; then
    [ -f "$HOME/.bashrc" ] && source "$HOME/.bashrc"
elif [ -n "$ZSH_VERSION" ]; then
    [ -f "$HOME/.zshrc" ] && source "$HOME/.zshrc"
fi
