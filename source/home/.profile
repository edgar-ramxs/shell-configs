#     ██████╗ ██████╗  ██████╗ ███████╗██╗██╗     ███████╗
#     ██╔══██╗██╔══██╗██╔═══██╗██╔════╝██║██║     ██╔════╝
#     ██████╔╝██████╔╝██║   ██║█████╗  ██║██║     █████╗  
#     ██╔═══╝ ██╔══██╗██║   ██║██╔══╝  ██║██║     ██╔══╝  
#  ██╗██║     ██║  ██║╚██████╔╝██║     ██║███████╗███████╗
#  ╚═╝╚═╝     ╚═╝  ╚═╝ ╚═════╝ ╚═╝     ╚═╝╚══════╝╚══════╝

if [ -n "$BASH_VERSION" ]; then
    # Bash shell detectado
    if [ -f "$HOME/.bashrc" ]; then
        . "$HOME/.bashrc"
    fi
    
elif [ -n "$ZSH_VERSION" ]; then
    # Zsh shell detectado
    if [ -f "$HOME/.zshrc" ]; then
        . "$HOME/.zshrc"
    fi
    
elif [ -n "$FISH_VERSION" ]; then
    # Fish shell detectado
    if [ -f "$HOME/.config/fish/config.fish" ]; then
        source "$HOME/.config/fish/config.fish"
    fi
fi
