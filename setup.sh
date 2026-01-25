#!/usr/bin/env bash

#  ███████╗███████╗████████╗██╗   ██╗██████╗
#  ██╔════╝██╔════╝╚══██╔══╝██║   ██║██╔══██╗
#  ███████╗█████╗     ██║   ██║   ██║██████╔╝
#  ╚════██║██╔══╝     ██║   ██║   ██║██╔═══╝
#  ███████║███████╗   ██║   ╚██████╔╝██║
#  ╚══════╝╚══════╝   ╚═╝    ╚═════╝ ╚═╝

set -euo pipefail

# ============================================================================
# CONFIGURACIÓN XDG BASE DIRECTORY
# ============================================================================

# Función para configurar variables XDG si no están definidas
setup_xdg_variables() {
    # XDG_CONFIG_HOME - Directorio de configuraciones del usuario
    export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
    
    # XDG_DATA_HOME - Directorio de datos del usuario  
    export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
    
    # XDG_CACHE_HOME - Directorio de cache del usuario
    export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
    
    # XDG_STATE_HOME - Directorio de estado del usuario
    export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
    
    # Informar al usuario
    message -info "Variables XDG configuradas:"
    message -info "  XDG_CONFIG_HOME: $XDG_CONFIG_HOME"
    message -info "  XDG_DATA_HOME: $XDG_DATA_HOME"
    message -info "  XDG_CACHE_HOME: $XDG_CACHE_HOME"
}

# ============================================================================
# VARIABLES GLOBALES Y CONFIGURACIÓN
# ============================================================================

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly CONFIG_DIR="${SCRIPT_DIR}/config"
readonly SHELLS_DIR="${SCRIPT_DIR}/shells"
readonly BIN_DIR="${SCRIPT_DIR}/local/bin"
readonly DEPS_FILE="${SCRIPT_DIR}/dependencies.toml"

# Estas variables se establecerán después de setup_xdg_variables()
TARGET_CONFIG_DIR=""
TARGET_BACKUP_DIR=""
TARGET_BIN_DIR=""
readonly BACKUP_TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# ============================================================================
# IMPORTAR LIBRERÍA COMPARTIDA
# ============================================================================

# shellcheck disable=SC1091
if ! source "${CONFIG_DIR}/lib.sh"; then
    echo "Error: No se pudo cargar la librería compartida"
    exit 1
fi

# Configurar variables XDG antes de continuar
setup_xdg_variables

# Validar que los directorios XDG existan o puedan crearse
validate_xdg_directories() {
    local xdg_dirs=(
        "$XDG_CONFIG_HOME"
        "$XDG_DATA_HOME" 
        "$XDG_CACHE_HOME"
    )
    
    for dir in "${xdg_dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            mkdir -p "$dir" || {
                message -error "No se puede crear directorio XDG: $dir"
                return 1
            }
            message -success "Directorio XDG creado: $dir"
        fi
    done
}

# Validar y crear directorios XDG
validate_xdg_directories || {
    message -error "Error crítico: No se pueden crear directorios XDG"
    exit 1
}

# Ahora que XDG está configurado y validado, establecer las variables readonly
readonly TARGET_CONFIG_DIR="${XDG_CONFIG_HOME}/shell"
readonly TARGET_BACKUP_DIR="${TARGET_CONFIG_DIR}/backups"
readonly TARGET_BIN_DIR="${XDG_DATA_HOME}/bin"

# ============================================================================
# ESTADO DE INSTALACIÓN
# ============================================================================

CURRENT_SHELL=""
IS_WSL2=false
DISTRO=""
SHELL_DETECTED="unknown"
DEPENDENCIES_MISSING=()

# ============================================================================
# DETECCIÓN DEL SISTEMA
# ============================================================================

detect_shell() {
    message -subtitle "Detectando shell actual..."
    
    CURRENT_SHELL="${SHELL##*/}"
    
    case "$CURRENT_SHELL" in
        bash)   SHELL_DETECTED="bash"; message -success "Shell detectado: Bash";;
        zsh)    SHELL_DETECTED="zsh";  message -success "Shell detectado: Zsh";;
        *)      SHELL_DETECTED="unknown"; message -warning "Shell desconocido: $CURRENT_SHELL";;
    esac
}

detect_wsl2() {
    message -subtitle "Detectando entorno WSL2..."
    
    if [[ -f /proc/version ]] && grep -qi "microsoft" /proc/version; then
        IS_WSL2=true
        message -success "Entorno WSL2 detectado"
    else
        message -info "Entorno nativo Linux detectado"
    fi
}

detect_distro() {
    message -subtitle "Detectando distribución Linux..."
    
    if [[ -f /etc/os-release ]]; then
        # Cargar variables de /etc/os-release
        # shellcheck disable=SC1091
        source /etc/os-release
        DISTRO="${ID:-unknown}"
        message -success "Distribución detectada: ${PRETTY_NAME:-$DISTRO}"
    else
        DISTRO="unknown"
        message -warning "No se pudo detectar la distribución"
    fi
}

system_detection() {
    message -title "DETECCIÓN DEL SISTEMA"
    detect_shell
    sleep 2
    detect_wsl2
    sleep 2
    detect_distro
    sleep 2
}

# ============================================================================
# GESTIÓN DE DEPENDENCIAS
# ============================================================================

parse_dependencies() {
    message -title "LEYENDO CONFIGURACIÓN DE DEPENDENCIAS"
    sleep 2
    
    # Verificar archivo de dependencias
    if [[ ! -f "$DEPS_FILE" ]]; then
        message -error "Archivo de dependencias no encontrado: $DEPS_FILE"
        return 1
    fi
    
    message -success "Archivo de dependencias cargado: $DEPS_FILE"
    message -info "Usando variables XDG:"
    message -info "  Config: $XDG_CONFIG_HOME"
    message -info "  Data: $XDG_DATA_HOME"
}

install_github_dependencies() {
    message -title "INSTALANDO DEPENDENCIAS DE GITHUB"
    sleep 2
    
    # Parser TOML para sección [repositories]
    local repos=()
    local in_section=false
    
    while IFS= read -r line; do
        # Detectar sección [repositories]
        if [[ "$line" =~ ^\[repositories\]$ ]]; then
            in_section=true
            continue
        fi
        
        # Si encontramos otra sección, terminar
        if [[ "$line" =~ ^\[ ]] && [[ "$in_section" == true ]]; then
            break
        fi
        
        # Si estamos en la sección repositories
        if [[ "$in_section" == true ]]; then
            # Saltar líneas vacías
            [[ -z "$line" ]] && continue
            # Saltar comentarios puros
            [[ "$line" =~ ^# ]] && continue
            
            # Extraer URL del repositorio (antes del # si existe)
            local repo="${line%%#*}"
            # Eliminar espacios en blanco
            repo="$(echo "$repo" | xargs)"
            
            [[ -z "$repo" ]] && continue
            repos+=("$repo")
        fi
    done < "$DEPS_FILE"
    
    # Procesar cada repositorio
    for repo in "${repos[@]}"; do
        local repo_name=$(basename "$repo" .git)
        local target_dir=""
        
        # Usar XDG_DATA_HOME o ~/.local/share como base
        local data_dir="${XDG_DATA_HOME:-$HOME/.local/share}"
        local shell_data_dir="$data_dir/shell"
        
        case "$repo_name" in
            "ohmyzsh")
                target_dir="$data_dir/oh-my-zsh"
                ;;
            "oh-my-bash")
                target_dir="$data_dir/oh-my-bash"
                ;;
            "powerlevel10k")
                # Powerlevel10k como plugin de oh-my-zsh
                target_dir="$data_dir/oh-my-zsh/custom/themes/powerlevel10k"
                ;;
            *)
                # Para repositorios desconocidos, usar directorio genérico
                target_dir="$shell_data_dir/$repo_name"
                message -info "Repositorio genérico: $repo_name -> $target_dir"
                ;;
        esac
        
        # Verificar si ya existe
        if [[ -d "$target_dir" ]]; then
            message -success "✓ $repo_name ya existe en $target_dir"
        else
            # Crear directorio padre si es necesario
            mkdir -p "$(dirname "$target_dir")"
            
                message -subtitle "Clonando $repo_name..."
            sleep 1
            if git clone "$repo" "$target_dir" 2>/dev/null; then
                message -success "✓ $repo_name instalado en $target_dir"
                
                # Configurar automáticamente oh-my-zsh y oh-my-bash
                case "$repo_name" in
                    "ohmyzsh")
                        configure_oh_my_zsh "$target_dir"
                        ;;
                    "oh-my-bash")
                        configure_oh_my_bash "$target_dir"
                        ;;
                    "powerlevel10k")
                        # Powerlevel10k necesita configuración especial en .zshrc
                        message -info "Powerlevel10k disponible para configurar con oh-my-zsh"
                        ;;
                esac
                sleep 1
            else
                message -error "✗ Error al clonar $repo_name"
                return 1
            fi
        fi
    done
    
    # Verificar instalación de oh-my-zsh
    local data_dir="${XDG_DATA_HOME:-$HOME/.local/share}"
    if [[ -f "$data_dir/oh-my-zsh/oh-my-zsh.sh" ]]; then
        message -success "✓ oh-my-zsh disponible (XDG-compliant)"
    else
        message -warning "✗ oh-my-zsh no encontrado (se instalará automáticamente)"
        DEPENDENCIES_MISSING+=("github-repos")
    fi
    
    # Verificar powerlevel10k (XDG-compliant)
    if [[ -f "$data_dir/oh-my-zsh/custom/themes/powerlevel10k/powerlevel10k.zsh-theme" ]]; then
        message -success "✓ powerlevel10k disponible (XDG-compliant)"
    else
        message -warning "✗ powerlevel10k no encontrado (se instalará automáticamente)"
        DEPENDENCIES_MISSING+=("github-repos")
    fi
}

check_linux_dependencies() {
    message -subtitle "Verificando paquetes de Linux..."
    
    # Parser TOML simplificado: busca [linux] y extrae paquetes
    local deps=()
    local in_section=false
    
    while IFS= read -r line; do
        # Detectar sección [linux]
        if [[ "$line" =~ ^\[linux\]$ ]]; then
            in_section=true
            continue
        fi
        
        # Si encontramos otra sección, terminar
        if [[ "$line" =~ ^\[ ]] && [[ "$in_section" == true ]]; then
            break
        fi
        
        # Si estamos en la sección linux
        if [[ "$in_section" == true ]]; then
            # Saltar líneas vacías
            [[ -z "$line" ]] && continue
            # Saltar comentarios puros
            [[ "$line" =~ ^# ]] && continue
            
            # Extraer el nombre del paquete (antes del # si existe)
            local pkg="${line%%#*}"
            # Eliminar espacios en blanco
            pkg="$(echo "$pkg" | xargs)"
            
            [[ -z "$pkg" ]] && continue
            deps+=("$pkg")
        fi
    done < "$DEPS_FILE"
    
    DEPENDENCIES_MISSING=()
    
    for dep in "${deps[@]}"; do
        if check_command_exists "$dep"; then
            message -success "✓ $dep disponible"
        else
            message -warning "✗ $dep no encontrado"
            DEPENDENCIES_MISSING+=("$dep")
        fi
    done
}

check_github_dependencies() {
    message -subtitle "Verificando dependencias de GitHub..."
    
    # Verificar oh-my-zsh (XDG-compliant)
    local data_dir="${XDG_DATA_HOME:-$HOME/.local/share}"
    local github_repos_needed=false
    
    if [[ -f "$data_dir/oh-my-zsh/oh-my-zsh.sh" ]]; then
        export ZSH="$data_dir/oh-my-zsh"
        message -success "✓ oh-my-zsh disponible (XDG-compliant)"
    else
        message -warning "✗ oh-my-zsh no encontrado (se instalará automáticamente)"
        github_repos_needed=true
    fi
    
    # Verificar powerlevel10k (XDG-compliant)
    if [[ -f "$data_dir/oh-my-zsh/custom/themes/powerlevel10k/powerlevel10k.zsh-theme" ]]; then
        message -success "✓ powerlevel10k disponible (XDG-compliant)"
    else
        message -warning "✗ powerlevel10k no encontrado (se instalará automáticamente)"
        github_repos_needed=true
    fi
    
    # Agregar github-repos solo una vez si se necesita alguno
    if [[ "$github_repos_needed" == true ]]; then
        # Verificar que no esté ya en la lista
        if [[ ! " ${DEPENDENCIES_MISSING[*]} " =~ " github-repos " ]]; then
            DEPENDENCIES_MISSING+=("github-repos")
            message -info "✓ Agregado github-repos a dependencias faltantes"
        fi
    fi
}

check_dependencies() {
    message -title "VERIFICACIÓN DE DEPENDENCIAS"
    sleep 2
    
    parse_dependencies || return 1
    check_linux_dependencies
    check_github_dependencies
    
    if [[ ${#DEPENDENCIES_MISSING[@]} -gt 0 ]]; then
        message -warning "Dependencias faltantes: ${DEPENDENCIES_MISSING[*]}"
        return 1
    else
        message -success "Todas las dependencias verificadas"
        return 0
    fi
}

install_dependencies() {
    if [[ ${#DEPENDENCIES_MISSING[@]} -eq 0 ]]; then
        message -info "No hay dependencias que instalar"
        return 0
    fi
    
    message -title "INSTALACIÓN DE DEPENDENCIAS"
    sleep 2
    
    # Primero instalar dependencias del sistema
    local system_deps=()
    local github_deps=false
    
    for dep in "${DEPENDENCIES_MISSING[@]}"; do
        if [[ "$dep" == "github-repos" ]]; then
            github_deps=true
        else
            system_deps+=("$dep")
        fi
    done
    
    # Instalar dependencias del sistema
    if [[ ${#system_deps[@]} -gt 0 ]]; then
        message -warning "Se necesita permisos de sudo para instalar dependencias del sistema"
        
        # Solicitar sudo una sola vez al principio
        if ! sudo -n true 2>/dev/null; then
            message -info "Solicitando permisos de sudo para instalación de paquetes..."
            sudo true || {
                message -error "No se pueden obtener permisos de sudo"
                return 1
            }
        fi
        message -success "Permisos de sudo obtenidos"
        
        # Instalar paquetes individualmente con actualización incluida
        message -subtitle "Instalando paquetes individualmente..."
        local failed_packages=()
        local successful_packages=()
        
        case "$DISTRO" in
            ubuntu|debian)
                # Actualizar repos e instalar
                sudo apt update -qq || message -error "Error actualizando repos apt"
                
                for dep in "${system_deps[@]}"; do
                    message -info "Instalando: $dep"
                    if sudo apt install -y "$dep" 2>/dev/null; then
                        message -success "✓ Instalado: $dep"
                        successful_packages+=("$dep")
                    else
                        message -error "✗ Falló: $dep"
                        failed_packages+=("$dep")
                    fi
                    sleep 1
                done
                ;;
                
            arch|manjaro)
                # Actualizar repos e instalar
                sudo pacman -Sy || message -error "Error actualizando repos pacman"
                
                for dep in "${system_deps[@]}"; do
                    message -info "Instalando: $dep"
                    # Mapeo especial para Arch
                    local arch_pkg="$dep"
                    case "$dep" in "fd-find") arch_pkg="fd" ;; esac
                    
                    if sudo pacman -S --noconfirm "$arch_pkg" 2>/dev/null; then
                        message -success "✓ Instalado: $dep"
                        successful_packages+=("$dep")
                    else
                        message -error "✗ Falló: $dep"
                        failed_packages+=("$dep")
                    fi
                    sleep 1
                done
                ;;
                
            fedora|rhel)
                # Actualizar repos e instalar
                sudo dnf check-update || message -error "Error actualizando repos dnf"
                
                for dep in "${system_deps[@]}"; do
                    message -info "Instalando: $dep"
                    # Mapeo especial para Fedora
                    local fedora_pkg="$dep"
                    case "$dep" in 
                        "fd-find") fedora_pkg="fd-find" ;;
                        "bat") fedora_pkg="bat" ;;
                    esac
                    
                    if sudo dnf install -y "$fedora_pkg" 2>/dev/null; then
                        message -success "✓ Instalado: $dep"
                        successful_packages+=("$dep")
                    else
                        message -error "✗ Falló: $dep"
                        failed_packages+=("$dep")
                    fi
                    sleep 1
                done
                ;;
                
            *)
                message -error "No se puede instalar automáticamente en $DISTRO"
                message -warning "Por favor instale manualmente: ${system_deps[*]}"
                return 1
                ;;
        esac
        
        # Resumen de instalación
        if [[ ${#failed_packages[@]} -gt 0 ]]; then
            message -warning "Paquetes fallidos: ${failed_packages[*]}"
        fi
        if [[ ${#successful_packages[@]} -gt 0 ]]; then
            message -success "Paquetes instalados: ${successful_packages[*]}"
        fi
    fi
    
    # Instalar dependencias de GitHub
    if [[ "$github_deps" == true ]]; then
        install_github_dependencies || return 1
    fi
}
# ============================================================================
# CONFIGURACIÓN AUTOMÁTICA DE OH-MY SHELLS
# ============================================================================

configure_oh_my_zsh() {
    local oh_my_zsh_dir="$1"
    
    message -subtitle "Configurando Oh My Zsh..."
    
    # Verificar si zsh está instalado
    if ! command -v zsh &>/dev/null; then
        message -warning "Zsh no está instalado. Instalando..."
        case "$DISTRO" in
            ubuntu|debian)
                sudo apt install -y zsh || message -error "Error instalando zsh"
                ;;
            arch|manjaro)
                sudo pacman -S --noconfirm zsh || message -error "Error instalando zsh"
                ;;
            fedora|rhel)
                sudo dnf install -y zsh || message -error "Error instalando zsh"
                ;;
        esac
    fi
    
    # Configurar .zshrc para usar oh-my-zsh
    local zshrc_path="$HOME/.zshrc"
    local data_dir="${XDG_DATA_HOME:-$HOME/.local/share}"
    local oh_my_zsh_data="$data_dir/oh-my-zsh"
    
    # Crear .zshrc con configuración de oh-my-zsh si no existe o está vacío
    if [[ ! -f "$zshrc_path" ]] || [[ ! -s "$zshrc_path" ]]; then
        cat > "$zshrc_path" << EOF
# Oh My Zsh Configuration
export ZSH="\${XDG_DATA_HOME:-\$HOME/.local/share}/oh-my-zsh"
export ZDOTDIR="\${XDG_CONFIG_HOME:-\$HOME/.config}/zsh"
ZSH_THEME="robbyrussell"
plugins=(git)

source \$ZSH/oh-my-zsh.sh

# Custom configurations
source ~/.config/shell/exports
source ~/.config/shell/aliases  
source ~/.config/shell/functions
EOF
        message -success "Configurado: ~/.zshrc para Oh My Zsh"
    else
        message -info "~/.zshrc ya existe, conservando configuración existente"
    fi
    
    # Cambiar shell a zsh si no es ya el default
    if [[ "$SHELL" != */zsh ]]; then
        message -info "Cambiando shell a zsh (ZDOTDIR: ${XDG_CONFIG_HOME:-$HOME/.config}/zsh)..."
        chsh -s "$(which zsh)" || message -warning "No se pudo cambiar shell a zsh"
    fi
    
    sleep 2
}

configure_oh_my_bash() {
    local oh_my_bash_dir="$1"
    
    message -subtitle "Configurando Oh My Bash..."
    
    # Configurar .bashrc para usar oh-my-bash
    local bashrc_path="$HOME/.bashrc"
    local data_dir="${XDG_DATA_HOME:-$HOME/.local/share}"
    local oh_my_bash_data="$data_dir/oh-my-bash"
    
    # Hacer backup del .bashrc existente si no tiene oh-my-bash
    if [[ -f "$bashrc_path" ]] && ! grep -q "oh-my-bash" "$bashrc_path"; then
        cp "$bashrc_path" "${bashrc_path}.omb-backup-$(date +%Y%m%d_%H%M%S)"
        message -info "Backup creado: ~/.bashrc.omb-backup"
    fi
    
    # Crear nuevo .bashrc con oh-my-bash (directamente en ~/)
    cat > "$bashrc_path" << EOF
# Oh My Bash Configuration
export OSH="\${XDG_DATA_HOME:-\$HOME/.local/share}/oh-my-bash"

# Custom configurations (loaded before oh-my-bash)
source ~/.config/shell/exports
source ~/.config/shell/aliases
source ~/.config/shell/functions

# Load Oh My Bash
\$OSH/themes/colours.theme.sh
\$OSH/themes/base.theme.sh
\$OSH/themes/prompt.theme.sh

# Oh My Bash initialization
source \$OSH/oh-my-bash.sh
EOF
        message -success "Configurado: ~/.bashrc para Oh My Bash"
    
    sleep 2
}

# ============================================================================

# BACKUP
# ============================================================================

backup_existing_files() {
    message -title "CREANDO BACKUP DE CONFIGURACIONES ACTUALES"
    sleep 2
    
    mkdir -p "$TARGET_BACKUP_DIR"
    local backup_dir="${TARGET_BACKUP_DIR}/${BACKUP_TIMESTAMP}"
    mkdir -p "$backup_dir"
    
    message -subtitle "Guardando archivos existentes..."
    
    # Archivos a hacer backup (solo ~/ y configs del proyecto)
    local items_to_backup=(
        "$HOME/.bashrc"
        "$HOME/.zshrc"
        "$HOME/.bash_logout"
        "$HOME/.p10k.zsh"
        "$TARGET_CONFIG_DIR/aliases"
        "$TARGET_CONFIG_DIR/exports"
        "$TARGET_CONFIG_DIR/functions"
    )
    
    for item in "${items_to_backup[@]}"; do
        if [[ -e "$item" ]]; then
            local rel_path="${item#$HOME/}"
            local dest_path="$backup_dir/$rel_path"
            mkdir -p "$(dirname "$dest_path")"
            cp -r "$item" "$dest_path"
            message -success "Backup: $rel_path"
        fi
    done
    
    # Crear archivo de metadata
    cat > "$backup_dir/backup-info.txt" << EOF
Backup creado: $(date '+%Y-%m-%d %H:%M:%S')
Timestamp: $BACKUP_TIMESTAMP
Sistema: $(uname -s)
Distro: $(lsb_release -ds 2>/dev/null || echo "Unknown")
Shell: $SHELL_DETECTED
Hostname: $(hostname)
Usuario: $(whoami)
EOF
    
    message -success "Backup guardado en: $backup_dir"
}

# ============================================================================
# INSTALACIÓN DE ARCHIVOS
# ============================================================================

install_config_files() {
    message -title "INSTALANDO ARCHIVOS DE CONFIGURACIÓN"
    sleep 2
    
    mkdir -p "$TARGET_CONFIG_DIR"
    
    message -subtitle "Copiando archivos de config..."
    
    local config_files=("aliases" "exports" "functions")
    for file in "${config_files[@]}"; do
        if [[ -f "$CONFIG_DIR/$file" ]]; then
            cp "$CONFIG_DIR/$file" "$TARGET_CONFIG_DIR/$file"
            chmod 644 "$TARGET_CONFIG_DIR/$file"
            message -success "Copiado: $file"
        fi
    done
}

install_shell_rc_files() {
    message -title "INSTALANDO ARCHIVOS DE SHELL RC"
    sleep 2
    
    message -subtitle "Instalando archivos de shell desde shells/..."
    
    # Directorios para validación (solo si se necesitan)
    local config_dir="${XDG_CONFIG_HOME:-$HOME/.config}"
    
    # Instalar archivos Bash (directamente en ~/)
    if [[ -f "$SHELLS_DIR/bash/.bashrc" ]]; then
        # Backup si ya existe en home
        [[ -f "$HOME/.bashrc" ]] && cp "$HOME/.bashrc" "$HOME/.bashrc.backup-$(date +%Y%m%d_%H%M%S)"
        # Copiar directamente a home
        cp "$SHELLS_DIR/bash/.bashrc" "$HOME/.bashrc"
        message -success "Instalado: ~/.bashrc"
    fi
    
    if [[ -f "$SHELLS_DIR/bash/.bash_logout" ]]; then
        cp "$SHELLS_DIR/bash/.bash_logout" "$HOME/.bash_logout"
        message -success "Instalado: ~/.bash_logout"
    fi
    
    # Instalar archivos Zsh (directamente en ~/)
    if [[ -f "$SHELLS_DIR/zsh/.zshrc" ]]; then
        # Backup si ya existe en home
        [[ -f "$HOME/.zshrc" ]] && cp "$HOME/.zshrc" "$HOME/.zshrc.backup-$(date +%Y%m%d_%H%M%S)"
        # Copiar directamente a home
        cp "$SHELLS_DIR/zsh/.zshrc" "$HOME/.zshrc"
        message -success "Instalado: ~/.zshrc"
    fi
    
    if [[ -f "$SHELLS_DIR/zsh/.p10k.zsh" ]]; then
        cp "$SHELLS_DIR/zsh/.p10k.zsh" "$HOME/.p10k.zsh"
        message -success "Instalado: ~/.p10k.zsh"
    fi
}

install_scripts() {
    message -title "INSTALANDO SCRIPTS"
    sleep 2
    
    mkdir -p "$TARGET_BIN_DIR"
    
    message -subtitle "Copiando scripts..."
    
    if [[ -d "$BIN_DIR" ]]; then
        for script in "$BIN_DIR"/*; do
            if [[ -f "$script" ]]; then
                local script_name=$(basename "$script")
                cp "$script" "$TARGET_BIN_DIR/$script_name"
                chmod +x "$TARGET_BIN_DIR/$script_name"
                message -success "Script: $script_name"
            fi
        done
    fi
}

# ============================================================================
# VALIDACIÓN POST-INSTALACIÓN
# ============================================================================

validate_installation() {
    message -title "VALIDACIÓN POST-INSTALACIÓN"
    sleep 2
    
    local errors=0
    
    # Verificar archivos de configuración
    message -subtitle "Verificando archivos de configuración..."
    for file in aliases exports functions; do
        if [[ -f "$TARGET_CONFIG_DIR/$file" ]]; then
            message -success "✓ $file"
        else
            message -error "✗ $file no existe"
            ((errors++))
        fi
    done
    
    # Verificar sintaxis de archivos shell
    message -subtitle "Verificando sintaxis..."
    for file in "$TARGET_CONFIG_DIR"/*; do
        if [[ -f "$file" ]] && bash -n "$file" 2>/dev/null; then
            message -success "✓ $(basename "$file") sintaxis válida"
        else
            message -error "✗ $(basename "$file") tiene errores de sintaxis"
            ((errors++))
        fi
    done
    
    # Verificar sourcing con variables XDG
    message -subtitle "Verificando sourcing con variables XDG..."
    local test_cmd="source $TARGET_CONFIG_DIR/exports && source $TARGET_CONFIG_DIR/functions && source $TARGET_CONFIG_DIR/aliases"
    
    # Test con valores reales de variables XDG
    if XDG_CONFIG_HOME="$XDG_CONFIG_HOME" XDG_DATA_HOME="$XDG_DATA_HOME" XDG_CACHE_HOME="$XDG_CACHE_HOME" bash -c "$test_cmd" 2>/dev/null; then
        message -success "✓ Archivos pueden ser sourceados con variables XDG"
    else
        message -error "✗ Error al sourcear archivos con XDG"
        ((errors++))
    fi
    
    # Validar variables clave en exports.sh
    message -subtitle "Validando variables XDG en exports.sh..."
    if XDG_CONFIG_HOME="$XDG_CONFIG_HOME" XDG_DATA_HOME="$XDG_DATA_HOME" XDG_CACHE_HOME="$XDG_CACHE_HOME" bash -c "source $TARGET_CONFIG_DIR/exports && echo \"XDG_CONFIG_HOME: \$XDG_CONFIG_HOME\" && echo \"XDG_DATA_HOME: \$XDG_DATA_HOME\" && echo \"XDG_CACHE_HOME: \$XDG_CACHE_HOME\"" 2>/dev/null; then
        message -success "✓ Variables XDG configuradas en exports.sh"
    else
        message -error "✗ Error en variables XDG de exports.sh"
        ((errors++))
    fi
    
    return $errors
}

# ============================================================================
# MENÚ DE RESUMEN
# ============================================================================

show_summary() {
    message -title "RESUMEN DE INSTALACIÓN"
    
    echo -e "${CYAN}Sistema:${RESET}"
    echo "  • Shell: $SHELL_DETECTED"
    echo "  • Distribución: $DISTRO"
    echo "  • WSL2: $([ "$IS_WSL2" = true ] && echo "Sí" || echo "No")"
    echo ""
    
    echo -e "${CYAN}Directorios:${RESET}"
    echo "  • Configuraciones: $TARGET_CONFIG_DIR"
    echo "  • Scripts: $TARGET_BIN_DIR"
    echo "  • Backups: $TARGET_BACKUP_DIR/$BACKUP_TIMESTAMP"
    echo ""
    
    if [[ ${#DEPENDENCIES_MISSING[@]} -eq 0 ]]; then
        echo -e "${GREEN}Todas las dependencias están instaladas${RESET}"
    else
        echo -e "${YELLOW}Dependencias faltantes: ${DEPENDENCIES_MISSING[*]}${RESET}"
    fi
}

# ============================================================================
# MAIN
# ============================================================================

main() {
    clear
    echo -e "${BOLD}${CYAN}"
    cat << 'EOF'
   ███████╗███████╗████████╗██╗   ██╗██████╗
   ██╔════╝██╔════╝╚══██╔══╝██║   ██║██╔══██╗
   ███████╗█████╗     ██║   ██║   ██║██████╔╝
   ╚════██║██╔══╝     ██║   ██║   ██║██╔═══╝
   ███████║███████╗   ██║   ╚██████╔╝██║
   ╚══════╝╚══════╝   ╚═╝    ╚═════╝ ╚═╝

        Shell Configuration Installer
EOF
    echo -e "${RESET}"
    
    # Ejecución de pasos principales
    system_detection
    sleep 3
    
    message -title "PASO 1: Verificación de dependencias"
    sleep 2
    if ! check_dependencies; then
        message -info "Se detectaron dependencias faltantes. Intentando instalar automáticamente..."
        install_dependencies || message -warning "No todas las dependencias pudieron ser instaladas"
    fi
    sleep 2
    
    message -title "PASO 2: Backup de configuraciones actuales"
    backup_existing_files
    sleep 2
    
    message -title "PASO 3: Instalando archivos de configuración"
    install_config_files
    sleep 2
    
    message -title "PASO 4: Instalando archivos de shell"
    install_shell_rc_files
    sleep 2
    
    message -title "PASO 5: Instalando scripts"
    install_scripts
    sleep 2
    
    if validate_installation; then
        message -success "✓ Instalación completada exitosamente"
    else
        message -error "✗ Se encontraron errores durante la validación"
    fi
    
    show_summary
    
    echo ""
    message -warning "Para aplicar los cambios, ejecute:"
    echo -e "${CYAN}  source ~/.bashrc   # o${RESET}"
    echo -e "${CYAN}  source ~/.zshrc    # según su shell${RESET}"
    echo ""
}

# Ejecutar main
main "$@"
