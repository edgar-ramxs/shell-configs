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
readonly HOMEFS_DIR="${SCRIPT_DIR}/source/home"
readonly LOCALS_DIR="${SCRIPT_DIR}/source/local"
readonly CONFIG_DIR="${SCRIPT_DIR}/source/config"
readonly SHELLS_DIR="${SCRIPT_DIR}/source/shells"
readonly DEPS_FILE="${SCRIPT_DIR}/dependencies.toml"

readonly TARGET_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/shells-configs"
readonly TARGET_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/shells-configs"
readonly TARGET_LOCALS_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/shells-configs"
readonly TARGET_BACKUP_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/shells-configs"

DISTRO=""
IS_WSL2=false
CURRENT_SHELL=""
SHELL_DETECTED="unknown"
MISSING_PKGS=()
MISSING_REPS=()

if ! source "${CONFIG_DIR}/library.sh"; then
    echo "Error: No se pudo cargar la librería compartida"
    exit 1
fi

show_banner() {
    local banner_name="${1:-banner.txt}"
    _lib_validate_required_param "$banner_name" "Uso: show_banner <nombre_ascii>" || return 1

    local archivo_banner="$SCRIPT_DIR/source/console/$banner_name"
    _lib_validate_file_with_message "$archivo_banner" "Error: No se encontró el archivo $banner_name" || return 1

    echo -e "\e[1;34m"
    cat "$archivo_banner"
    echo -e "\e[0m"

    sleep 2
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
    _lib_message -subtitle "Detectando shell actual..."
    CURRENT_SHELL="${SHELL##*/}"
    case "$CURRENT_SHELL" in
        bash)   SHELL_DETECTED="bash"; _lib_message -success "Shell detectado: Bash";;
        zsh)    SHELL_DETECTED="zsh";  _lib_message -success "Shell detectado: Zsh";;
        *)      SHELL_DETECTED="unknown"; _lib_message -warning "Shell desconocido: $CURRENT_SHELL";;
    esac
}

detect_wsl2() {
    _lib_message -subtitle "Detectando entorno WSL2..."
    if [[ -f /proc/version ]] && grep -qi "microsoft" /proc/version; then
        IS_WSL2=true
        _lib_message -success "Entorno WSL2 detectado"
    else
        _lib_message -info "Entorno nativo Linux detectado"
    fi
}

detect_distro() {
    _lib_message -subtitle "Detectando distribución Linux..."
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        DISTRO="${ID:-unknown}"
        _lib_message -success "Distribución detectada: ${PRETTY_NAME:-$DISTRO}"
    else
        DISTRO="unknown"
        _lib_message -warning "No se pudo detectar la distribución"
    fi
}

system_detection() {
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
    _lib_message -subtitle "LEYENDO CONFIGURACIÓN DE DEPENDENCIAS"
    sleep 2
    
    # Verificar archivo de dependencias
    if [[ ! -f "$DEPS_FILE" ]]; then
        _lib_message -error "Archivo de dependencias no encontrado: $DEPS_FILE"
        return 1
    fi
    
    _lib_message -info "Archivo de dependencias cargado: $DEPS_FILE"
    _lib_message -warning "XDG Config: ${XDG_CONFIG_HOME:-$HOME/.config}"
    _lib_message -warning "XDG Data:   ${XDG_DATA_HOME:-$HOME/.local/share}"
}

check_linux_dependencies() {
    _lib_message -subtitle "VERIFICANDO PAQUETES DE LINUX"
    local deps=()
    mapfile -t deps < <(tomlq -r '.linux.packages[].name' "$DEPS_FILE")
    
    if [[ ${#deps[@]} -eq 0 ]]; then
        _lib_message -warning "No se encontraron paquetes en $DEPS_FILE"
        return 0
    fi

    _lib_check_packages_array "$DISTRO" deps MISSING_PKGS
}

check_github_dependencies() {
    _lib_message -subtitle "VERIFICANDO REPOSITORIOS DE GITHUB"
    MISSING_REPS=()
    local repos_base="${XDG_DATA_HOME:-$HOME/.local/share}/repositories"
    
    local repo_names=()
    mapfile -t repo_names < <(tomlq -r '.repositories.repos[].name' "$DEPS_FILE")

    for name in "${repo_names[@]}"; do
        if [[ -d "$repos_base/$name/.git" ]]; then
            _lib_message -success "$name -> disponible"
        else
            _lib_message -warning "$name -> no encontrado"
            MISSING_REPS+=("$name")
        fi
    done
}

install_core_dependencies() {
    _lib_message -subtitle "INSTALANDO DEPENDENCIAS CORE"
    local core_packages=("git" "curl" "wget" "jq" "yq")
    _lib_install_packages_array "$DISTRO" core_packages
}

check_dependencies() {
    parse_dependencies || return 1
    check_linux_dependencies
    check_github_dependencies

    if [[ ${#MISSING_PKGS[@]} -gt 0 ]] || [[ ${#MISSING_REPS[@]} -gt 0 ]]; then
        return 1
    fi

    return 0
}

install_linux_dependencies() {
    if [[ ${#MISSING_PKGS[@]} -eq 0 ]]; then
        _lib_message -success "No hay paquetes de Linux pendientes"
        return 0
    fi
    _lib_message -title "INSTALANDO PAQUETES DE LINUX"
    _lib_install_packages_array "$DISTRO" MISSING_PKGS
}

install_github_dependencies() {
    if [[ ${#MISSING_REPS[@]} -eq 0 ]]; then
        _lib_message -success "No hay repositorios pendientes"
        return 0
    fi

    _lib_message -title "INSTALANDO REPOSITORIOS DE GITHUB"
    local repos_base="${XDG_DATA_HOME:-$HOME/.local/share}/repositories"
    _lib_ensure_dir "$repos_base" || return 1

    for repo in "${MISSING_REPS[@]}"; do
        local url
        url=$(tomlq -r ".repositories.repos[] | select(.name == \"$repo\") | .url" "$DEPS_FILE")

        if [[ -z "$url" || "$url" == "null" ]]; then
            _lib_message -error "No se encontró URL para $repo"
            continue
        fi

        _lib_message -info "Clonando $repo..."
        if git clone "$url" "$repos_base/$repo" &>/dev/null; then
            _lib_message -success "$repo instalado"
        else
            _lib_message -error "Error instalando $repo"
        fi
    done
}

# ============================================================================
# CONFIGURACIÓN AUTOMÁTICA DE OH-MY-SHELLS
# ============================================================================


# ============================================================================
# BACKUP
# ============================================================================

backup_existing_files() {
    _lib_message -subtitle "CREANDO BACKUP DE CONFIGURACIONES ACTUALES"
    sleep 1

    local items_to_backup=(
        "$HOME/.hushlogin"
        "$HOME/.profile"
        "$HOME/.bashrc"
        "$HOME/.zshrc"
        "$HOME/.bash_logout"
        "$HOME/.p10k.zsh"
    )

    local real_files=()
    local item
    for item in "${items_to_backup[@]}"; do
        if [[ -e "$item" && ! -L "$item" ]]; then
            real_files+=("$item")
        else
            _lib_message -warning "Omitiendo enlace simbólico o inexistente: ${item#"$HOME"/}"
        fi
    done

    if [[ ${#real_files[@]} -eq 0 ]]; then
        _lib_message -info "No hay archivos reales para respaldar; proceso omitido"
        return 0
    fi

    _lib_ensure_dir "$TARGET_BACKUP_DIR"
    local backup_dir="${TARGET_BACKUP_DIR}/backup/${BACKUP_TIMESTAMP}"
    _lib_ensure_dir "$backup_dir"

    _lib_message -subtitle "Guardando archivos existentes..."
    local backed_up=false
    for item in "${real_files[@]}"; do
        local rel_path="${item#"$HOME"/}"
        local dest_path="$backup_dir/$rel_path"
        _lib_ensure_dir "$(dirname "$dest_path")"
        cp -r "$item" "$dest_path"
        _lib_message -success "Backup: $rel_path"
        backed_up=true
    done
    
    # Crear archivo de metadata a partir del template
    local template_file="$SCRIPT_DIR/source/templates/backup-info.txt"
    if [[ -f "$template_file" ]]; then
        local backup_created distro_name system_name host_name user_name
        backup_created=$(date '+%Y-%m-%d %H:%M:%S')
        distro_name=$(lsb_release -ds 2>/dev/null || echo "Unknown")
        system_name=$(uname -s)
        host_name=$(hostname)
        user_name=$(whoami)

        _lib_render_template "$template_file" "$backup_dir/backup-info.txt" \
            "BACKUP_CREATED=$backup_created" \
            "BACKUP_TIMESTAMP=$BACKUP_TIMESTAMP" \
            "SYSTEM_NAME=$system_name" \
            "DISTRO_NAME=$distro_name" \
            "SHELL_NAME=$SHELL_DETECTED" \
            "HOST_NAME=$host_name" \
            "USER_NAME=$user_name"
    else
        _lib_message -warning "Template de backup-info no encontrado; se omite metadata"
    fi
    
    _lib_message -success "Backup guardado en: $backup_dir"
}

# ============================================================================
# INSTALACIÓN DE ARCHIVOS
# ============================================================================

install_config_files() {
    _lib_message -title "INSTALANDO ARCHIVOS DE CONFIGURACIÓN"
    sleep 1

    # 1. Enlaces de configuración (source/config -> TARGET_CONFIG_DIR)
    _lib_install_symlinks "$CONFIG_DIR" "$TARGET_CONFIG_DIR" "Enlaces de configuración"

    # 2. Enlaces de home (source/home -> $HOME)
    _lib_install_symlinks "$HOMEFS_DIR" "$HOME" "Enlaces de archivos home"

    # 3. Enlaces de shell específica (source/shells/{shell} -> $HOME)
    if [[ "$SHELL_DETECTED" != "unknown" ]]; then
        local shell_src="${SHELLS_DIR}/${SHELL_DETECTED}"
        _lib_install_symlinks "$shell_src" "$HOME" "Enlaces de archivos para ${SHELL_DETECTED}"
    fi

    # 4. Enlaces de scripts locales (source/local -> TARGET_LOCALS_DIR) recursivo
    _lib_install_symlinks "$LOCALS_DIR" "$TARGET_LOCALS_DIR" "Enlaces de scripts locales" "true"
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
    _lib_message -title "RESUMEN DE INSTALACIÓN"
    
    _lib_message -subtitle "Sistema:"
    _lib_message -info "WSL2: $([ "$IS_WSL2" = true ] && echo "Sí" || echo "No")"
    _lib_message -info "Distribución: $DISTRO"
    _lib_message -info "Shell: $SHELL_DETECTED"
    echo ""

    _lib_message -subtitle "Directorios:"
    _lib_message -info "Configuraciones: $TARGET_CONFIG_DIR"
    _lib_message -info "Scripts: $TARGET_LOCALS_DIR"
    _lib_message -info "Backups: $TARGET_BACKUP_DIR/backup/$BACKUP_TIMESTAMP"
    echo ""
    
    _lib_message -subtitle "Dependencias:"
    if [[ ${#MISSING_PKGS[@]} -eq 0 ]]; then
        _lib_message -info "Todas las dependencias están instaladas"
    else
        _lib_message -info "Dependencias faltantes:"
        _lib_message -warning "${MISSING_PKGS[*]}"
    fi
    echo ""

    _lib_message -subtitle "Para aplicar los cambios, reinicie su terminal o ejecute:"
    _lib_message -info "source ~/.${SHELL_DETECTED}rc"
    echo ""
}

# ============================================================================
# MAIN
# ============================================================================

main() {
    # Limpiar pantalla al iniciar
    clear

    # Mostrar banner
    show_banner
    _lib_message -title "INICIANDO INSTALACIÓN DE SHELL CONFIGS..."; sleep 1;

    # PASO 1: Ejecución de pasos principales
    _lib_message -title "PASO 1: Detección del sistema"
    system_detection

    # PASO 2: Instalación de dependencias core
    _lib_message -title "PASO 2: Instalación de paquetes CORE del sistema"
    if _lib_get_package_manager_commands "$DISTRO" >/dev/null 2>&1; then
        # Paquetes esenciales para el funcionamiento del script y utilidades comunes
        local core_packages=(git curl wget jq yq vim cmatrix)
        
        _lib_message -subtitle "Paquetes CORE: ${core_packages[*]}"
        if _lib_install_packages_array "$DISTRO" core_packages; then
            _lib_message -success "Paquetes CORE instalados exitosamente"
        else
            _lib_message -warning "Algunos paquetes CORE no pudieron instalarse"
        fi
    else
        _lib_message -warning "Gestor de paquetes no soportado para distro: $DISTRO"
        return 1
    fi
    
    # PASO 3: Verificación e instalación de dependencias del proyecto
    _lib_message -title "PASO 3: Gestión de dependencias del proyecto"
    if ! check_dependencies; then
        _lib_message -info "Se detectaron dependencias faltantes en el proyecto"

        if [[ ${#MISSING_PKGS[@]} -gt 0 ]]; then
            _lib_message -subtitle "Instalando paquetes faltantes: ${#MISSING_PKGS[@]}"
            # install_linux_dependencies || _lib_message -warning "Algunos paquetes fallaron"
        fi

        if [[ ${#MISSING_REPS[@]} -gt 0 ]]; then
            _lib_message -subtitle "Instalando repositorios faltantes: ${#MISSING_REPS[@]}"
            # install_github_dependencies || _lib_message -warning "Algunos repositorios fallaron"
        fi
    else
        _lib_message -success "Todas las dependencias del proyecto están satisfechas"
    fi


    # PASO 4: Backup de configuraciones actuales
    _lib_message -title "PASO 4: Backup de configuraciones actuales"
    backup_existing_files

    # # PASO 5: Instalación de archivos de configuración
    # _lib_message -title "PASO 5: Instalación de archivos de configuración"
    # install_config_files

    

    
    show_summary
    
}

# Ejecutar main
main "$@"
