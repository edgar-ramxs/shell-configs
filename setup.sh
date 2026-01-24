#!/usr/bin/env bash

#  ███████╗███████╗████████╗██╗   ██╗██████╗
#  ██╔════╝██╔════╝╚══██╔══╝██║   ██║██╔══██╗
#  ███████╗█████╗     ██║   ██║   ██║██████╔╝
#  ╚════██║██╔══╝     ██║   ██║   ██║██╔═══╝
#  ███████║███████╗   ██║   ╚██████╔╝██║
#  ╚══════╝╚══════╝   ╚═╝    ╚═════╝ ╚═╝

set -euo pipefail

# ============================================================================
# VARIABLES GLOBALES Y CONFIGURACIÓN
# ============================================================================

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly CONFIG_DIR="${SCRIPT_DIR}/config"
readonly SHELLS_DIR="${SCRIPT_DIR}/shells"
readonly BIN_DIR="${SCRIPT_DIR}/local/bin"
readonly DEPS_FILE="${SCRIPT_DIR}/dependencies.toml"
readonly TARGET_CONFIG_DIR="${HOME}/.config/shell"
readonly TARGET_BACKUP_DIR="${TARGET_CONFIG_DIR}/backups"
readonly TARGET_BIN_DIR="${HOME}/.local/bin"
readonly BACKUP_TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# ============================================================================
# IMPORTAR LIBRERÍA COMPARTIDA
# ============================================================================

# shellcheck disable=SC1091
if ! source "${CONFIG_DIR}/lib.sh"; then
    echo "Error: No se pudo cargar la librería compartida"
    exit 1
fi

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
    detect_wsl2
    detect_distro
}

# ============================================================================
# GESTIÓN DE DEPENDENCIAS
# ============================================================================

parse_dependencies() {
    message -title "LEYENDO CONFIGURACIÓN DE DEPENDENCIAS"
    
    if [[ ! -f "$DEPS_FILE" ]]; then
        message -error "Archivo de dependencias no encontrado: $DEPS_FILE"
        return 1
    fi
    
    message -success "Archivo de dependencias cargado: $DEPS_FILE"
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

check_dependencies() {
    message -title "VERIFICACIÓN DE DEPENDENCIAS"
    
    parse_dependencies || return 1
    check_linux_dependencies
    
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
    message -warning "Se necesita permisos de sudo para instalar dependencias"
    
    case "$DISTRO" in
        ubuntu|debian)
            message -subtitle "Usando apt (Debian/Ubuntu)..."
            sudo apt update -qq
            declare -A apt_map=(
                ["lsd"]="lsd"
                ["bat"]="bat"
                ["fzf"]="fzf"
                ["jq"]="jq"
                ["ripgrep"]="ripgrep"
                ["fd-find"]="fd-find"
                ["exa"]="exa"
                ["tldr"]="tldr"
            )
            for dep in "${DEPENDENCIES_MISSING[@]}"; do
                local pkg="${apt_map[$dep]:-$dep}"
                sudo apt install -y "$pkg" && message -success "Instalado: $dep" || message -error "Error instalando: $dep"
            done
            ;;
        arch|manjaro)
            message -subtitle "Usando pacman (Arch Linux)..."
            for dep in "${DEPENDENCIES_MISSING[@]}"; do
                sudo pacman -S --noconfirm "$dep" && message -success "Instalado: $dep" || message -error "Error instalando: $dep"
            done
            ;;
        fedora|rhel)
            message -subtitle "Usando dnf (Fedora/RHEL)..."
            for dep in "${DEPENDENCIES_MISSING[@]}"; do
                sudo dnf install -y "$dep" && message -success "Instalado: $dep" || message -error "Error instalando: $dep"
            done
            ;;
        *)
            message -error "No se puede instalar automáticamente en $DISTRO"
            message -warning "Por favor instale manualmente: ${DEPENDENCIES_MISSING[*]}"
            return 1
            ;;
    esac
}

# ============================================================================
# BACKUP
# ============================================================================

backup_existing_files() {
    message -title "CREANDO BACKUP DE CONFIGURACIONES ACTUALES"
    
    mkdir -p "$TARGET_BACKUP_DIR"
    local backup_dir="${TARGET_BACKUP_DIR}/${BACKUP_TIMESTAMP}"
    mkdir -p "$backup_dir"
    
    message -subtitle "Guardando archivos existentes..."
    
    # Archivos a hacer backup
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
    
    message -subtitle "Instalando archivos de shell desde shells/..."
    
    # Instalar archivos Bash
    if [[ -f "$SHELLS_DIR/bash/.bashrc" ]]; then
        cp "$SHELLS_DIR/bash/.bashrc" "$HOME/.bashrc"
        message -success "Instalado: ~/.bashrc"
    fi
    
    if [[ -f "$SHELLS_DIR/bash/.bash_logout" ]]; then
        cp "$SHELLS_DIR/bash/.bash_logout" "$HOME/.bash_logout"
        message -success "Instalado: ~/.bash_logout"
    fi
    
    # Instalar archivos Zsh
    if [[ -f "$SHELLS_DIR/zsh/.zshrc" ]]; then
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
    
    # Verificar sourcing
    message -subtitle "Verificando sourcing..."
    if bash -c "source $TARGET_CONFIG_DIR/exports && source $TARGET_CONFIG_DIR/functions && source $TARGET_CONFIG_DIR/aliases" 2>/dev/null; then
        message -success "✓ Archivos pueden ser sourceados correctamente"
    else
        message -error "✗ Error al sourcear archivos"
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
    
    message -title "PASO 1: Verificación de dependencias"
    if ! check_dependencies; then
        read -p "¿Desea intentar instalar dependencias faltantes? (s/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Ss]$ ]]; then
            install_dependencies || message -warning "No todas las dependencias pudieron ser instaladas"
        fi
    fi
    
    message -title "PASO 2: Backup de configuraciones actuales"
    backup_existing_files
    
    message -title "PASO 3: Instalando archivos de configuración"
    install_config_files
    
    message -title "PASO 4: Instalando archivos de shell"
    install_shell_rc_files
    
    message -title "PASO 5: Instalando scripts"
    install_scripts
    
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
