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
readonly HOMEFS_DIR="${SCRIPT_DIR}/src/home"
readonly CONFIG_DIR="${SCRIPT_DIR}/src/config"
readonly SHELLS_DIR="${SCRIPT_DIR}/src/home/shells"
readonly DEPS_FILE="${SCRIPT_DIR}/src/packages/dependencies.toml"
readonly SCRIPTS_DIR="${SCRIPT_DIR}/src/bin/scripts"
readonly DRAWS_DIR="${SCRIPT_DIR}/src/bin/draws"

readonly TARGET_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/shells-configs"
readonly TARGET_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/shells-configs"
readonly TARGET_LOCALS_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/shells-configs"
readonly TARGET_BACKUP_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/shells-configs"

readonly REPOS_BASE="${XDG_DATA_HOME:-$HOME/.local/share}/repositories"

DISTRO=""
IS_WSL2=false
CURRENT_SHELL=""
SHELL_DETECTED="bash"
MISSING_PKGS=()
MISSING_REPOS=()

INSTALL_SHELL="bash"
INSTALL_DEPS_LINUX=false
INSTALL_DEPS_PYTHON=false
INSTALL_DEPS_NODE=false
INSTALL_DEPS_RUST=false
INSTALL_DEPS_GO=false
INSTALL_REPOS=false
INSTALL_BACKUP=false
INSTALL_VALIDATE=false
INSTALL_ALL=false
DRY_RUN=false
VERBOSE=false

if ! source "${CONFIG_DIR}/library.sh"; then
    echo "Error: No se pudo cargar la librería compartida"
    exit 1
fi

# ============================================================================
# PARSEO DE FLAGS
# ============================================================================

parse_flags() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --shell)
                if [[ -z "${2:-}" ]]; then
                    _lib_message -error "Error: --shell requiere un argumento"
                    return 1
                fi
                case "$2" in
                    bash|zsh) INSTALL_SHELL="$2" ;;
                    *) _lib_message -error "Shell no soportada: $2"; return 1 ;;
                esac
                shift 2
                ;;
            --with-deps-linux)
                INSTALL_DEPS_LINUX=true
                shift
                ;;
            --with-deps-python)
                INSTALL_DEPS_PYTHON=true
                shift
                ;;
            --with-deps-node)
                INSTALL_DEPS_NODE=true
                shift
                ;;
            --with-deps-rust)
                INSTALL_DEPS_RUST=true
                shift
                ;;
            --with-deps-go)
                INSTALL_DEPS_GO=true
                shift
                ;;
            --with-deps)
                INSTALL_DEPS_LINUX=true
                INSTALL_DEPS_PYTHON=true
                INSTALL_DEPS_NODE=true
                INSTALL_DEPS_RUST=true
                INSTALL_DEPS_GO=true
                shift
                ;;
            --with-repos)
                INSTALL_REPOS=true
                shift
                ;;
            --with-backup)
                INSTALL_BACKUP=true
                shift
                ;;
            --validate)
                INSTALL_VALIDATE=true
                shift
                ;;
            --all)
                INSTALL_ALL=true
                INSTALL_DEPS_LINUX=true
                INSTALL_DEPS_PYTHON=true
                INSTALL_DEPS_NODE=true
                INSTALL_DEPS_RUST=true
                INSTALL_DEPS_GO=true
                INSTALL_REPOS=true
                INSTALL_BACKUP=true
                INSTALL_VALIDATE=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --verbose|-v)
                VERBOSE=true
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            -*)
                _lib_message -error "Flag desconocido: $1"
                show_help
                exit 1
                ;;
            *)
                _lib_message -error "Argumento desconocido: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

show_banner() {
    local banner_name="${1:-banner.txt}"
    local archivo_banner="${DRAWS_DIR}/${banner_name}"
    
    if [[ -f "$archivo_banner" ]]; then
        echo -e "\e[1;34m"
        cat "$archivo_banner"
        echo -e "\e[0m"
        sleep 2
    fi
}

# ============================================================================
# CONFIGURACIÓN XDG BASE DIRECTORY
# ============================================================================

validate_xdg_directories() {
    local xdg_dirs=("${XDG_CONFIG_HOME:-$HOME/.config}" "${XDG_DATA_HOME:-$HOME/.local/share}" "${XDG_CACHE_HOME:-$HOME/.cache}")
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
        *)      SHELL_DETECTED="bash"; _lib_message -warning "Shell desconocido: $CURRENT_SHELL, usando bash";;
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
# GESTIÓN DE DEPENDENCIAS - LINUX
# ============================================================================

parse_dependencies() {
    _lib_message -subtitle "LEYENDO CONFIGURACIÓN DE DEPENDENCIAS"
    sleep 2
    
    if [[ ! -f "$DEPS_FILE" ]]; then
        _lib_message -error "Archivo de dependencias no encontrado: $DEPS_FILE"
        return 1
    fi
    
    _lib_message -info "Archivo de dependencias: $DEPS_FILE"
}

check_linux_dependencies() {
    _lib_message -subtitle "VERIFICANDO PAQUETES DE LINUX"
    
    local deps=()
    mapfile -t deps < <(tomlq -r '.linux.packages[].name' "$DEPS_FILE" 2>/dev/null)
    
    if [[ ${#deps[@]} -eq 0 ]]; then
        _lib_message -warning "No se encontraron paquetes Linux en $DEPS_FILE"
        return 0
    fi

    _lib_check_packages_array "$DISTRO" deps MISSING_PKGS
}

install_core_dependencies() {
    _lib_message -subtitle "INSTALANDO DEPENDENCIAS CORE"
    local core_packages=("git" "curl" "wget" "jq")
    _lib_install_packages_array "$DISTRO" core_packages
}

install_linux_dependencies() {
    check_linux_dependencies
    
    if [[ ${#MISSING_PKGS[@]} -eq 0 ]]; then
        _lib_message -success "Todos los paquetes Linux ya están instalados"
        return 0
    fi
    
    _lib_message -title "INSTALANDO PAQUETES DE LINUX"
    _lib_install_packages_array "$DISTRO" MISSING_PKGS
}

# ============================================================================
# GESTIÓN DE DEPENDENCIAS - PYTHON
# ============================================================================

check_python_dependencies() {
    _lib_message -subtitle "VERIFICANDO PAQUETES DE PYTHON"
    
    local python_pkgs=()
    mapfile -t python_pkgs < <(tomlq -r '.python.packages[].name' "$DEPS_FILE" 2>/dev/null)
    
    if [[ ${#python_pkgs[@]} -eq 0 ]]; then
        _lib_message -warning "No se encontraron paquetes Python"
        return 0
    fi
    
    for pkg in "${python_pkgs[@]}"; do
        if pip show "$pkg" &>/dev/null; then
            _lib_message -success "$pkg -> instalado"
        else
            _lib_message -warning "$pkg -> no instalado"
        fi
    done
}

install_python_dependencies() {
    _lib_message -title "INSTALANDO PAQUETES DE PYTHON"
    
    local python_pkgs=()
    mapfile -t python_pkgs < <(tomlq -r '.python.packages[].name' "$DEPS_FILE" 2>/dev/null)
    
    if [[ ${#python_pkgs[@]} -eq 0 ]]; then
        _lib_message -warning "No hay paquetes Python para instalar"
        return 0
    fi
    
    if ! command -v pip &>/dev/null; then
        _lib_message -error "pip no está instalado"
        return 1
    fi
    
    for pkg in "${python_pkgs[@]}"; do
        if [[ "$DRY_RUN" == "true" ]]; then
            _lib_message -info "[DRY-RUN] pip install $pkg"
        else
            if pip show "$pkg" &>/dev/null; then
                _lib_message -success "$pkg -> ya instalado"
            else
                _lib_message -info "Instalando: $pkg"
                if pip install "$pkg" &>/dev/null; then
                    _lib_message -success "Instalado: $pkg"
                else
                    _lib_message -error "Falló: $pkg"
                fi
            fi
        fi
    done
}

# ============================================================================
# GESTIÓN DE DEPENDENCIAS - NODE
# ============================================================================

check_node_dependencies() {
    _lib_message -subtitle "VERIFICANDO PAQUETES DE NODE"
    
    local node_pkgs=()
    mapfile -t node_pkgs < <(tomlq -r '.node.packages[].name' "$DEPS_FILE" 2>/dev/null)
    
    if [[ ${#node_pkgs[@]} -eq 0 ]]; then
        _lib_message -warning "No se encontraron paquetes Node"
        return 0
    fi
    
    for pkg in "${node_pkgs[@]}"; do
        if npm list -g "$pkg" &>/dev/null; then
            _lib_message -success "$pkg -> instalado"
        else
            _lib_message -warning "$pkg -> no instalado"
        fi
    done
}

install_node_dependencies() {
    _lib_message -title "INSTALANDO PAQUETES DE NODE"
    
    local node_pkgs=()
    mapfile -t node_pkgs < <(tomlq -r '.node.packages[].name' "$DEPS_FILE" 2>/dev/null)
    
    if [[ ${#node_pkgs[@]} -eq 0 ]]; then
        _lib_message -warning "No hay paquetes Node para instalar"
        return 0
    fi
    
    if ! command -v npm &>/dev/null; then
        _lib_message -error "npm no está instalado"
        return 1
    fi
    
    for pkg in "${node_pkgs[@]}"; do
        if [[ "$DRY_RUN" == "true" ]]; then
            _lib_message -info "[DRY-RUN] npm install -g $pkg"
        else
            if npm list -g "$pkg" &>/dev/null; then
                _lib_message -success "$pkg -> ya instalado"
            else
                _lib_message -info "Instalando: $pkg"
                if npm install -g "$pkg" &>/dev/null; then
                    _lib_message -success "Instalado: $pkg"
                else
                    _lib_message -error "Falló: $pkg"
                fi
            fi
        fi
    done
}

# ============================================================================
# GESTIÓN DE DEPENDENCIAS - RUST
# ============================================================================

check_rust_dependencies() {
    _lib_message -subtitle "VERIFICANDO PAQUETES DE RUST"
    
    local rust_pkgs=()
    mapfile -t rust_pkgs < <(tomlq -r '.rust.packages[].name' "$DEPS_FILE" 2>/dev/null)
    
    if [[ ${#rust_pkgs[@]} -eq 0 ]]; then
        _lib_message -warning "No se encontraron paquetes Rust"
        return 0
    fi
    
    for pkg in "${rust_pkgs[@]}"; do
        if cargo install --list 2>/dev/null | grep -q "^$pkg "; then
            _lib_message -success "$pkg -> instalado"
        else
            _lib_message -warning "$pkg -> no instalado"
        fi
    done
}

install_rust_dependencies() {
    _lib_message -title "INSTALANDO PAQUETES DE RUST"
    
    local rust_pkgs=()
    mapfile -t rust_pkgs < <(tomlq -r '.rust.packages[].name' "$DEPS_FILE" 2>/dev/null)
    
    if [[ ${#rust_pkgs[@]} -eq 0 ]]; then
        _lib_message -warning "No hay paquetes Rust para instalar"
        return 0
    fi
    
    if ! command -v cargo &>/dev/null; then
        _lib_message -error "cargo no está instalado"
        return 1
    fi
    
    for pkg in "${rust_pkgs[@]}"; do
        if [[ "$DRY_RUN" == "true" ]]; then
            _lib_message -info "[DRY-RUN] cargo install $pkg"
        else
            if cargo install --list 2>/dev/null | grep -q "^$pkg "; then
                _lib_message -success "$pkg -> ya instalado"
            else
                _lib_message -info "Instalando: $pkg"
                if cargo install "$pkg" &>/dev/null; then
                    _lib_message -success "Instalado: $pkg"
                else
                    _lib_message -error "Falló: $pkg"
                fi
            fi
        fi
    done
}

# ============================================================================
# GESTIÓN DE DEPENDENCIAS - GO
# ============================================================================

check_go_dependencies() {
    _lib_message -subtitle "VERIFICANDO PAQUETES DE GO"
    
    local go_pkgs=()
    mapfile -t go_pkgs < <(tomlq -r '.go.packages[].name' "$DEPS_FILE" 2>/dev/null)
    
    if [[ ${#go_pkgs[@]} -eq 0 ]]; then
        _lib_message -warning "No se encontraron paquetes Go"
        return 0
    fi
    
    for pkg in "${go_pkgs[@]}"; do
        if go list -m "$pkg" &>/dev/null; then
            _lib_message -success "$pkg -> instalado"
        else
            _lib_message -warning "$pkg -> no instalado"
        fi
    done
}

install_go_dependencies() {
    _lib_message -title "INSTALANDO PAQUETES DE GO"
    
    local go_pkgs=()
    mapfile -t go_pkgs < <(tomlq -r '.go.packages[].name' "$DEPS_FILE" 2>/dev/null)
    
    if [[ ${#go_pkgs[@]} -eq 0 ]]; then
        _lib_message -warning "No hay paquetes Go para instalar"
        return 0
    fi
    
    if ! command -v go &>/dev/null; then
        _lib_message -error "go no está instalado"
        return 1
    fi
    
    for pkg in "${go_pkgs[@]}"; do
        if [[ "$DRY_RUN" == "true" ]]; then
            _lib_message -info "[DRY-RUN] go install $pkg"
        else
            if go list -m "$pkg" &>/dev/null; then
                _lib_message -success "$pkg -> ya instalado"
            else
                _lib_message -info "Instalando: $pkg"
                if go install "$pkg" &>/dev/null; then
                    _lib_message -success "Instalado: $pkg"
                else
                    _lib_message -error "Falló: $pkg"
                fi
            fi
        fi
    done
}

# ============================================================================
# REPOSITORIOS GITHUB
# ============================================================================

check_github_dependencies() {
    _lib_message -subtitle "VERIFICANDO REPOSITORIOS DE GITHUB"
    MISSING_REPOS=()
    
    local repo_names=()
    mapfile -t repo_names < <(tomlq -r '.repositories.repos[].name' "$DEPS_FILE" 2>/dev/null)

    for name in "${repo_names[@]}"; do
        if [[ -d "${REPOS_BASE}/${name}/.git" ]]; then
            _lib_message -success "$name -> disponible"
        else
            _lib_message -warning "$name -> no encontrado"
            MISSING_REPOS+=("$name")
        fi
    done
}

install_github_dependencies() {
    check_github_dependencies
    
    if [[ ${#MISSING_REPOS[@]} -eq 0 ]]; then
        _lib_message -success "Todos los repositorios ya están instalados"
        return 0
    fi

    _lib_message -title "INSTALANDO REPOSITORIOS DE GITHUB"
    _lib_ensure_dir "$REPOS_BASE" || return 1

    for repo in "${MISSING_REPOS[@]}"; do
        local url
        url=$(tomlq -r ".repositories.repos[] | select(.name == \"$repo\") | .url" "$DEPS_FILE" 2>/dev/null)

        if [[ -z "$url" || "$url" == "null" ]]; then
            _lib_message -error "No se encontró URL para $repo"
            continue
        fi

        _lib_message -info "Clonando $repo..."
        if [[ "$DRY_RUN" == "true" ]]; then
            _lib_message -info "[DRY-RUN] git clone --depth 1 $url ${REPOS_BASE}/${repo}"
        else
            if git clone --depth 1 "$url" "${REPOS_BASE}/${repo}" &>/dev/null; then
                _lib_message -success "$repo instalado en ${REPOS_BASE}/${repo}"
            else
                _lib_message -error "Error instalando $repo"
            fi
        fi
    done
}

# ============================================================================
# BACKUP DE CONFIGURACIONES
# ============================================================================

backup_existing_files() {
    _lib_message -title "CREANDO BACKUP DE CONFIGURACIONES"
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
        if [[ "$DRY_RUN" == "true" ]]; then
            _lib_message -info "[DRY-RUN] cp -r $item $dest_path"
        else
            cp -r "$item" "$dest_path"
            _lib_message -success "Backup: $rel_path"
            backed_up=true
        fi
    done
    
    local template_file="${SCRIPT_DIR}/src/templates/backupInfo.template"
    if [[ -f "$template_file" ]]; then
        local backup_created distro_name system_name host_name user_name
        backup_created=$(date '+%Y-%m-%d %H:%M:%S')
        distro_name=$(lsb_release -ds 2>/dev/null || echo "Unknown")
        system_name=$(uname -s)
        host_name=$(hostname)
        user_name=$(whoami)

        if [[ "$DRY_RUN" == "true" ]]; then
            _lib_message -info "[DRY-RUN] _lib_render_template $template_file $backup_dir/backupInfo.template"
        else
            _lib_render_template "$template_file" "$backup_dir/backupInfo.template" \
                "BACKUP_CREATED=$backup_created" \
                "BACKUP_TIMESTAMP=$BACKUP_TIMESTAMP" \
                "SYSTEM_NAME=$system_name" \
                "DISTRO_NAME=$distro_name" \
                "SHELL_NAME=$INSTALL_SHELL" \
                "HOST_NAME=$host_name" \
                "USER_NAME=$user_name"
        fi
    else
        _lib_message -warning "Template de backup no encontrado: $template_file"
    fi
    
    _lib_message -success "Backup guardado en: $backup_dir"
}

# ============================================================================
# INSTALACIÓN DE ENLACES SIMBÓLICOS
# ============================================================================

readonly DOTFILES_REPO="${HOME}/.dotfiles/shell-configs"

install_symlinks() {
    local target_shell="${1:-$INSTALL_SHELL}"
    [[ -z "$target_shell" ]] && target_shell="bash"
    
    _lib_message -title "INSTALANDO ENLACES SIMBÓLICOS PARA: $target_shell"
    
    if [[ "$VERBOSE" == "true" ]]; then
        _lib_message -info "HOMEFS_DIR: $HOMEFS_DIR"
        _lib_message -info "SHELLS_DIR: $SHELLS_DIR"
        _lib_message -info "target_shell: $target_shell"
    fi

    local created=0

    _lib_message -subtitle "Archivos home generales"
    if [[ -d "$HOMEFS_DIR" ]]; then
        # Usar find para evitar problemas con globs y dotglob
        while IFS= read -r -d '' src_file; do
            local filename
            filename=$(basename "$src_file")
            local target="${HOME}/${filename}"
            
            if [[ "$VERBOSE" == "true" ]]; then
                _lib_message -info "Procesando home file: $filename"
            fi

            if [[ "$DRY_RUN" == "true" ]]; then
                _lib_message -info "[DRY-RUN] ln -sfn $src_file $target"
            else
                if ln -sfn "$src_file" "$target"; then
                    _lib_message -success "✓ $filename"
                    ((created++))
                else
                    _lib_message -error "✗ Error al vincular $filename"
                fi
            fi
        done < <(find "$HOMEFS_DIR" -maxdepth 1 -type f -print0)
    else
        _lib_message -warning "Directorio home base no encontrado: $HOMEFS_DIR"
    fi

    _lib_message -subtitle "Archivos específicos de shell: $target_shell"
    local shell_src="${SHELLS_DIR}/${target_shell}"
    
    if [[ -d "$shell_src" ]]; then
        if [[ "$VERBOSE" == "true" ]]; then
            _lib_message -info "Buscando archivos de shell en: $shell_src"
        fi
        
        while IFS= read -r -d '' src_file; do
            local filename
            filename=$(basename "$src_file")
            local target="${HOME}/${filename}"
            
            if [[ "$VERBOSE" == "true" ]]; then
                _lib_message -info "Procesando shell file: $filename"
            fi

            if [[ "$DRY_RUN" == "true" ]]; then
                _lib_message -info "[DRY-RUN] ln -sfn $src_file $target"
            else
                if ln -sfn "$src_file" "$target"; then
                    _lib_message -success "✓ $filename"
                    ((created++))
                else
                    _lib_message -error "✗ Error al vincular $filename"
                fi
            fi
        done < <(find "$shell_src" -maxdepth 1 -type f -print0)
    else
        _lib_message -warning "Directorio de shell no encontrado: $shell_src"
    fi

    _lib_message -success "Total: $created enlaces creados"
    return 0
}

uninstall_symlinks() {
    _lib_message -title "DESINSTALANDO ENLACES SIMBÓLICOS"
    sleep 1

    local files=(".profile" ".hushlogin" ".bashrc" ".zshrc" ".bash_logout" ".p10k.zsh")
    local removed=0

    for file in "${files[@]}"; do
        local target="${HOME}/${file}"
        if [[ -L "$target" ]]; then
            rm "$target" && {
                _lib_message -success "✓ $file eliminado"
                ((removed++))
            }
        fi
    done

    _lib_message -success "Total: $removed enlaces eliminados"
    return 0
}

# ============================================================================
# FUNCIONES DE GIT
# ============================================================================

update_submodule() {
    _lib_message -title "ACTUALIZANDO SUBMÓDULO"

    local dotfiles_dir="${HOME}/.dotfiles"
    if [[ ! -d "$dotfiles_dir/.git" ]]; then
        _lib_message -error "No se encontró ~/.dotfiles"
        return 1
    fi

    cd "$DOTFILES_REPO" || return 1
    git submodule update --init --recursive 2>/dev/null || true
    git pull 2>/dev/null || true

    _lib_message -success "Submódulo actualizado"
    return 0
}

push_changes() {
    _lib_message -title "GUARDANDO CAMBIOS"

    cd "$DOTFILES_REPO" || return 1

    local changes
    changes=$(git status --short 2>/dev/null)

    if [[ -z "$changes" ]]; then
        _lib_message -info "No hay cambios para guardar"
        return 0
    fi

    git add -A
    git commit -m "Update: $(date '+%Y-%m-%d %H:%M%S')"
    git push

    _lib_message -success "Cambios guardados y enviados"
    return 0
}

# ============================================================================
# AYUDA
# ============================================================================

show_help() {
    cat << 'EOF'
USO: setup.sh [COMANDO] [OPCIONES]

COMANDOS:
    install     Instalar enlaces simbólicos y opcionalmente dependencias
    uninstall   Eliminar enlaces simbólicos
    update      Actualizar submódulo desde repositorio principal
    push        Guardar y enviar cambios al repositorio
    help        Mostrar esta ayuda

OPCIONES DE SHELL:
    --shell <bash|zsh>    Shell a configurar (default: bash)

OPCIONES DE PAQUETES (instalar grupos específicos):
    --with-deps-linux     Instalar paquetes Linux (apt/pacman/dnf)
    --with-deps-python    Instalar paquetes Python (pip)
    --with-deps-node      Instalar paquetes Node.js (npm)
    --with-deps-rust      Instalar paquetes Rust (cargo)
    --with-deps-go        Instalar paquetes Go (go install)
    --with-deps           Instalar TODOS los paquetes (linux + python + node + rust + go)

OPCIONES DE REPOSITORIOS:
    --with-repos          Clonar repositorios GitHub (oh-my-zsh, oh-my-bash, powerlevel10k)

OPCIONES DE INSTALACIÓN:
    --with-backup         Crear backup antes de instalar
    --validate            Ejecutar validación post-instalación
    --dry-run             Simular sin hacer cambios reales
    --verbose, -v         Salida detallada

OPCIONES COMBINADAS:
    --all                 Instalar todo (todos los deps + repos + validate)

EJEMPLOS:
    ./setup.sh install                           # Solo enlaces (bash)
    ./setup.sh install --shell zsh                # Enlaces para zsh
    ./setup.sh install --with-deps-linux          # Solo paquetes Linux
    ./setup.sh install --with-deps-python         # Solo paquetes Python
    ./setup.sh install --with-deps-python --with-deps-node  # Python + Node
    ./setup.sh install --with-deps                # Todos los paquetes
    ./setup.sh install --with-deps --with-repos   # Paquetes + repos
    ./setup.sh install --all                      # Instalación completa
    ./setup.sh install --dry-run --verbose       # Simular con detalles
    ./setup.sh uninstall                          # Eliminar todos los enlaces

SHELLS SOPORTADAS:
    bash                                   Configuración de Bash
    zsh                                    Configuración de Zsh

EOF
}

# ============================================================================
# RESUMEN
# ============================================================================

show_summary() {
    _lib_message -title "RESUMEN DE INSTALACIÓN"
    
    _lib_message -subtitle "Sistema:"
    _lib_message -info "WSL2: $([ "$IS_WSL2" = true ] && echo "Sí" || echo "No")"
    _lib_message -info "Distribución: $DISTRO"
    _lib_message -info "Shell: $INSTALL_SHELL"
    echo ""

    _lib_message -subtitle "Scripts:"
    _lib_message -info "Scripts disponibles en: $SCRIPTS_DIR"
    echo ""
    
    _lib_message -subtitle "Dependencias a instalar:"
    _lib_message -info "Linux:    $([ "$INSTALL_DEPS_LINUX" == "true" ] && echo "Sí" || echo "No")"
    _lib_message -info "Python:   $([ "$INSTALL_DEPS_PYTHON" == "true" ] && echo "Sí" || echo "No")"
    _lib_message -info "Node:     $([ "$INSTALL_DEPS_NODE" == "true" ] && echo "Sí" || echo "No")"
    _lib_message -info "Rust:     $([ "$INSTALL_DEPS_RUST" == "true" ] && echo "Sí" || echo "No")"
    _lib_message -info "Go:       $([ "$INSTALL_DEPS_GO" == "true" ] && echo "Sí" || echo "No")"
    _lib_message -info "Repos:    $([ "$INSTALL_REPOS" == "true" ] && echo "Sí" || echo "No")"
    echo ""

    _lib_message -subtitle "Opciones:"
    _lib_message -info "Backup:   $([ "$INSTALL_BACKUP" == "true" ] && echo "Sí" || echo "No")"
    _lib_message -info "Validate: $([ "$INSTALL_VALIDATE" == "true" ] && echo "Sí" || echo "No")"
    _lib_message -info "Dry-run:  $([ "$DRY_RUN" == "true" ] && echo "Sí" || echo "No")"
    echo ""

    _lib_message -subtitle "Para aplicar los cambios, reinicie su terminal o ejecute:"
    _lib_message -info "source ~/.${INSTALL_SHELL}rc"
    echo ""
}

# ============================================================================
# MAIN
# ============================================================================

main() {
    local command="${1:-install}"
    shift 2>/dev/null || true

    case "$command" in
        install)
            parse_flags "$@"
            
            if [[ "$VERBOSE" == "true" ]]; then
                _lib_message -info "Shell: $INSTALL_SHELL"
                _lib_message -info "Deps Linux: $INSTALL_DEPS_LINUX"
                _lib_message -info "Deps Python: $INSTALL_DEPS_PYTHON"
                _lib_message -info "Deps Node: $INSTALL_DEPS_NODE"
                _lib_message -info "Deps Rust: $INSTALL_DEPS_RUST"
                _lib_message -info "Deps Go: $INSTALL_DEPS_GO"
                _lib_message -info "Repos: $INSTALL_REPOS"
            fi
            
            system_detection
            
            # Usar shell detectada si no se especificó explícitamente
            if [[ "$INSTALL_SHELL" == "bash" && -n "$SHELL_DETECTED" && "$SHELL_DETECTED" != "bash" ]]; then
                INSTALL_SHELL="$SHELL_DETECTED"
            fi
            
            # Asegurar que INSTALL_SHELL tenga un valor
            [[ -z "$INSTALL_SHELL" ]] && INSTALL_SHELL="bash"
            
            # Dependencias Linux
            if [[ "$INSTALL_DEPS_LINUX" == "true" ]]; then
                parse_dependencies
                install_linux_dependencies
            fi
            
            # Dependencias Python
            if [[ "$INSTALL_DEPS_PYTHON" == "true" ]]; then
                install_python_dependencies
            fi
            
            # Dependencias Node
            if [[ "$INSTALL_DEPS_NODE" == "true" ]]; then
                install_node_dependencies
            fi
            
            # Dependencias Rust
            if [[ "$INSTALL_DEPS_RUST" == "true" ]]; then
                install_rust_dependencies
            fi
            
            # Dependencias Go
            if [[ "$INSTALL_DEPS_GO" == "true" ]]; then
                install_go_dependencies
            fi
            
            # Repositorios
            if [[ "$INSTALL_REPOS" == "true" ]]; then
                parse_dependencies
                install_github_dependencies
            fi
            
            # Backup
            if [[ "$INSTALL_BACKUP" == "true" ]]; then
                backup_existing_files
            fi
            
            # Enlaces simbólicos
            install_symlinks "$INSTALL_SHELL"
            
            if [[ "$INSTALL_VALIDATE" == "true" ]]; then
                _lib_message -info "Validación habilitada (no implementada)"
            fi
            
            show_summary
            _lib_message -success "Instalación completada para shell: $INSTALL_SHELL"
            ;;
        uninstall)
            uninstall_symlinks
            ;;
        update)
            update_submodule
            ;;
        push)
            push_changes
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            _lib_message -error "Comando desconocido: $command"
            show_help
            exit 1
            ;;
    esac
}

main "$@"