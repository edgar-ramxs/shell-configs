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
readonly BACKUP_TIMESTAMP=$(date +%Y%m%d_%H%M%S)

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly CONFIG_DIR="${SCRIPT_DIR}/source/config"
readonly SHELLS_DIR="${SCRIPT_DIR}/source/shells"
readonly LOCALS_DIR="${SCRIPT_DIR}/source/local"
readonly DEPS_FILE="${SCRIPT_DIR}/dependencies.toml"

readonly TARGET_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/shells-configs"
readonly TARGET_LOCALS_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/shells-configs"
readonly TARGET_BACKUP_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/shells-configs"

DISTRO=""
IS_WSL2=false
CURRENT_SHELL=""
SHELL_DETECTED="unknown"
LINUX_DEPS_MISSING=()
GITHUB_REPOS_MISSING=()

if ! source "${CONFIG_DIR}/library"; then
    echo "Error: No se pudo cargar la librería compartida"
    exit 1
fi

show_banner() {
    local archivo_banner
    local banner_name="${1:-banner.txt}"

    archivo_banner="$SCRIPT_DIR/assets/console/$banner_name"

    if [[ -f "$archivo_banner" ]]; then
        echo -e "\e[1;34m"
        cat "$archivo_banner"
        echo -e "\e[0m"
    else
        message -error "Error: No se encontró el archivo $archivo_banner"
        return 1
    fi
}

# ============================================================================
# CONFIGURACIÓN XDG BASE DIRECTORY
# ============================================================================

# Validar que los directorios XDG existan o puedan crearse
validate_xdg_directories() {
    local xdg_dirs=("$XDG_CONFIG_HOME" "$XDG_DATA_HOME" "$XDG_CACHE_HOME")
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

# ============================================================================
# DETECCIÓN DEL SISTEMA
# ============================================================================

detect_shell() {
    message -subtitle "Detectando shell actual..."
    CURRENT_SHELL="${SHELL##*/}"
    case "$CURRENT_SHELL" in
        bash)   SHELL_DETECTED="bash"; message -success "Shell detectado: Bash";;
        zsh)    SHELL_DETECTED="zsh";  message -success "Shell detectado: Zsh";;
        fish)   SHELL_DETECTED="fish"; message -success "Shell detectado: Fish";;
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
    sleep 1
    detect_shell
    sleep 1
    detect_wsl2
    sleep 1
    detect_distro
    sleep 1
}

# ============================================================================
# GESTIÓN DE DEPENDENCIAS
# ============================================================================

parse_dependencies() {
    message -subtitle "LEYENDO CONFIGURACIÓN DE DEPENDENCIAS"
    sleep 2
    
    # Verificar archivo de dependencias
    if [[ ! -f "$DEPS_FILE" ]]; then
        message -error "Archivo de dependencias no encontrado: $DEPS_FILE"
        return 1
    fi
    
    message -success "Archivo de dependencias cargado: $DEPS_FILE"
    message -info "XDG Config: ${XDG_CONFIG_HOME:-$HOME/.config}"
    message -info "XDG Data:   ${XDG_DATA_HOME:-$HOME/.local/share}"
}

check_linux_dependencies() {
    message -subtitle "VERIFICANDO PAQUETES DE LINUX"
    LINUX_DEPS_MISSING=()
    local deps=()
    local in_linux=false
    local in_packages=false

    while IFS= read -r line || [[ -n "$line" ]]; do
        line="${line#"${line%%[![:space:]]*}"}"
        line="${line%"${line##*[![:space:]]}"}"

        [[ -z "$line" || "$line" == \#* ]] && continue

        if [[ "$line" == "[linux]" ]]; then
            in_linux=true
            continue
        fi

        if [[ "$line" == \[*\] && "$in_linux" == true ]]; then
            break
        fi

        if [[ "$in_linux" == true && "$line" == "packages = [" ]]; then
            in_packages=true
            continue
        fi

        if [[ "$in_packages" == true && "$line" == "]" ]]; then
            break
        fi

        if [[ "$in_packages" == true && "$line" =~ \"([^\"]+)\" ]]; then
            deps+=("${BASH_REMATCH[1]}")
        fi
    done < "$DEPS_FILE"

    for dep in "${deps[@]}"; do
        if command -v "$dep" >/dev/null 2>&1; then
            message -success "$dep -> disponible"
        else
            message -warning "$dep -> no encontrado"
            LINUX_DEPS_MISSING+=("$dep")
        fi
    done
}

check_github_dependencies() {
    message -subtitle "VERIFICANDO REPOSITORIOS DE GITHUB"
    GITHUB_REPOS_MISSING=()
    local data_dir="${XDG_DATA_HOME:-$HOME/.local/share}"
    local repos_base="$data_dir/repositories"
    local in_section=false

    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ -z "$line" || "$line" =~ ^# ]] && continue

        if [[ "$line" =~ ^\[repositories\]$ ]]; then
            in_section=true
            continue
        fi

        if [[ "$line" =~ ^\[ && "$in_section" == true ]]; then
            break
        fi

        [[ "$in_section" != true ]] && continue

        if [[ "$line" =~ name[[:space:]]*=[[:space:]]*\"([^\"]+)\" ]]; then
            local name="${BASH_REMATCH[1]}"
            local repo_dir="$repos_base/$name"

            if [[ -d "$repo_dir/.git" ]]; then
                message -success "$name -> disponible"
            else
                message -warning "$name -> no encontrado"
                GITHUB_REPOS_MISSING+=("$name")
            fi
        fi
    done < "$DEPS_FILE"
}

check_dependencies() {
    message -title "VERIFICACIÓN DE DEPENDENCIAS"

    parse_dependencies || return 1
    check_linux_dependencies
    check_github_dependencies

    if [[ ${#LINUX_DEPS_MISSING[@]} -gt 0 ]] || [[ ${#GITHUB_REPOS_MISSING[@]} -gt 0 ]]; then
        return 1
    fi

    return 0
}

install_linux_dependencies() {
    if [[ ${#LINUX_DEPS_MISSING[@]} -eq 0 ]]; then
        message -success "No hay paquetes de Linux pendientes"
        return 0
    fi
    message -title "INSTALANDO PAQUETES DE LINUX"
    sleep 1

    local system_deps=("${LINUX_DEPS_MISSING[@]}")
    local failed_packages=()
    local successful_packages=()
    local PKG_UPDATE_CMD=""
    local PKG_INSTALL_CMD=""
    local PKG_CHECK_CMD=""

    case "$DISTRO" in
        ubuntu|debian)
            PKG_UPDATE_CMD="sudo apt update -qq"
            PKG_INSTALL_CMD="sudo apt install -y"
            PKG_CHECK_CMD="dpkg -l"
            ;;
        arch|manjaro)
            PKG_UPDATE_CMD="sudo pacman -Sy --noconfirm"
            PKG_INSTALL_CMD="sudo pacman -S --noconfirm"
            PKG_CHECK_CMD="pacman -Q"
            ;;
        fedora|rhel)
            PKG_UPDATE_CMD="sudo dnf check-update"
            PKG_INSTALL_CMD="sudo dnf install -y"
            PKG_CHECK_CMD="dnf list installed"
            ;;
        *)
            message -error "Distribución no soportada: $DISTRO"
            message -warning "Instale manualmente: ${system_deps[*]}"
            return 1
            ;;
    esac

    # ------------------------------------------------------------
    # Solicitar sudo una sola vez
    # ------------------------------------------------------------
    message -warning "Se requieren permisos de sudo"
    local sudo_attempt=0
    while (( sudo_attempt < 3 )); do
        sudo -n true 2>/dev/null || sudo true && break
        ((sudo_attempt++))
        sleep 1
    done

    if (( sudo_attempt >= 3 )); then
        message -error "No se pudieron obtener permisos de sudo"
        return 1
    fi
    message -success "Permisos de sudo obtenidos"

    # ------------------------------------------------------------
    # Actualizar repositorios
    # ------------------------------------------------------------
    if ! eval "$PKG_UPDATE_CMD" &>/dev/null; then
        message -error "Error actualizando repositorios"
        return 1
    fi

    # ------------------------------------------------------------
    # Instalación de paquetes
    # ------------------------------------------------------------
    message -subtitle "Instalando paquetes..."
    for dep in "${system_deps[@]}"; do
        local pkg="$dep"
        message -info "Instalando: $pkg"
        if eval "$PKG_INSTALL_CMD $pkg" &>/dev/null; then
            if command -v "$pkg" &>/dev/null || eval "$PKG_CHECK_CMD $pkg" &>/dev/null; then
                message -success "✓ Instalado: $dep"
                successful_packages+=("$dep")
            else
                message -error "✗ Instalado pero no detectable: $pkg"
                failed_packages+=("$dep")
            fi
        else
            message -error "✗ Falló: $dep"
            failed_packages+=("$dep")
        fi
        sleep 1
    done

    # ------------------------------------------------------------
    # Resumen
    # ------------------------------------------------------------
    [[ ${#successful_packages[@]} -gt 0 ]] && \
        message -success "Paquetes instalados: ${successful_packages[*]}"

    if [[ ${#failed_packages[@]} -gt 0 ]]; then
        message -warning "Paquetes que fallaron: ${failed_packages[*]}"
        return 1
    fi

    return 0
}

install_github_dependencies() {
    [[ ${#GITHUB_REPOS_MISSING[@]} -eq 0 ]] && {
        message -success "No hay repositorios pendientes"
        return 0
    }

    message -title "INSTALANDO REPOSITORIOS DE GITHUB"

    local data_dir="${XDG_DATA_HOME:-$HOME/.local/share}"
    local repos_base="$data_dir/repositories"
    mkdir -p "$repos_base"

    for repo in "${GITHUB_REPOS_MISSING[@]}"; do
        local url
        url=$(grep -A5 "name *= *\"$repo\"" "$DEPS_FILE" \
            | grep url \
            | sed -E 's/.*"([^"]+)".*/\1/')

        [[ -z "$url" ]] && {
            message -error "No se encontró URL para $repo"
            continue
        }

        message -info "Clonando $repo..."
        git clone "$url" "$repos_base/$repo" \
            && message -success "$repo instalado" \
            || message -error "Error instalando $repo"
    done
}

# ============================================================================
# CONFIGURACIÓN AUTOMÁTICA DE OH-MY-SHELLS
# ============================================================================


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
            local rel_path="${item#"$HOME"/}"
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
    
    mkdir -p "$TARGET_LOCALS_DIR"
    
    message -subtitle "Copiando scripts..."
    
    if [[ -d "$LOCALS_DIR" ]]; then
        for script in "$LOCALS_DIR"/*; do
            if [[ -f "$script" ]]; then
                local script_name
                script_name=$(basename "$script")
                cp "$script" "$TARGET_LOCALS_DIR/$script_name"
                chmod +x "$TARGET_LOCALS_DIR/$script_name"
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
    echo "  • Scripts: $TARGET_LOCALS_DIR"
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

    # Mostrar banner
    show_banner
    
    # Ejecución de pasos principales
    system_detection
    
    # Verificar dependencias
    if ! check_dependencies; then
        message -info "Se detectaron dependencias faltantes. Intentando instalar automáticamente..."

        if [[ ${#LINUX_DEPS_MISSING[@]} -gt 0 ]]; then
            message -info "Instalando paquetes de Linux faltantes..."
            # install_linux_dependencies || message -warning "Algunos paquetes Linux fallaron"
            message -info "Dependencias Linux no encontradas: ${#LINUX_DEPS_MISSING[@]}"
        fi
        sleep 2

        if [[ ${#GITHUB_REPOS_MISSING[@]} -gt 0 ]]; then
            message -info "Instalando repositorios GitHub faltantes..."
            # install_github_dependencies || message -warning "Algunos repositorios fallaron"
            message -info "Dependencias Github no encontradas: ${#GITHUB_REPOS_MISSING[@]}"
        fi
        sleep 2

    fi
    
    # message -title "PASO 2: Backup de configuraciones actuales"
    # backup_existing_files
    # sleep 2
    
    # message -title "PASO 3: Instalando archivos de configuración"
    # install_config_files
    # sleep 2
    
    # message -title "PASO 4: Instalando archivos de shell"
    # install_shell_rc_files
    # sleep 2
    
    # message -title "PASO 5: Instalando scripts"
    # install_scripts
    # sleep 2
    
    # if validate_installation; thencd
    #     message -success "✓ Instalación completada exitosamente"
    # else
    #     message -error "✗ Se encontraron errores durante la validación"
    # fi
    
    # show_summary
    
    # echo ""
    # message -warning "Para aplicar los cambios, ejecute:"
    # echo -e "${CYAN}  source ~/.bashrc   # o${RESET}"
    # echo -e "${CYAN}  source ~/.zshrc    # según su shell${RESET}"
    
    echo ""
}

# Ejecutar main
main "$@"
