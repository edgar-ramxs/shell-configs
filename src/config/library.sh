#!/usr/bin/env bash
#    ██╗     ██╗██████╗ ██████╗  █████╗ ██████╗ ██╗   ██╗███████╗██╗  ██╗
#    ██║     ██║██╔══██╗██╔══██╗██╔══██╗██╔══██╗╚██╗ ██╔╝██╔════╝██║  ██║
#    ██║     ██║██████╔╝██████╔╝███████║██████╔╝ ╚████╔╝ ███████╗███████║
#    ██║     ██║██╔══██╗██╔══██╗██╔══██║██╔══██╗  ╚██╔╝  ╚════██║██╔══██║
#    ███████╗██║██████╔╝██║  ██║██║  ██║██║  ██║   ██║██╗███████║██║  ██║
#    ╚══════╝╚═╝╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝╚═╝╚══════╝╚═╝  ╚═╝

# ============================================================================
# DEFINICIÓN DE COLORES (si no están definidos)
# ============================================================================

[[ -z "${WHITE:-}"   ]] && readonly WHITE='\033[0;37m'
[[ -z "${MAGENTA:-}" ]] && readonly MAGENTA='\033[0;35m'
[[ -z "${CYAN_B:-}"  ]] && readonly CYAN_B='\033[38;5;51m'
[[ -z "${BLUE:-}"    ]] && readonly BLUE='\033[0;34m'
[[ -z "${GREEN:-}"   ]] && readonly GREEN='\033[0;32m'
[[ -z "${YELLOW:-}"  ]] && readonly YELLOW='\033[0;33m'
[[ -z "${RED:-}"     ]] && readonly RED='\033[0;31m'
[[ -z "${BOLD:-}"  ]] && readonly BOLD='\033[1m'
[[ -z "${RESET:-}" ]] && readonly RESET='\033[0m'

# ============================================================================
# FUNCIÓN: _lib_message
# ============================================================================
# Imprime mensajes formateados con colores y señales visuales
#
# Tipos de mensaje:
#   -title       Encabezado principal (cian, negrita)
#   -subtitle    Encabezado secundario (azul, negrita)
#   -success     Mensaje de éxito (verde, negrita)
#   -warning     Mensaje de advertencia (amarillo, negrita)
#   -error       Mensaje de error (rojo, negrita)
#   -info        Información (cian sin negrita)
#   (default)    Texto normal
#
# Ejemplo:
#   _lib_message -title "INICIANDO PROCESO"
#   _lib_message -success "Operación completada"
#   _lib_message -error "Error: archivo no encontrado"

_lib_message() {
    local signal color
    case "$1" in
        -title)     color="${WHITE}${BOLD}";    signal="[→]"; shift; echo -e "\n${color}${signal} $*${RESET}";;
        -subtitle)  color="${MAGENTA}${BOLD}";  signal="[*]"; shift; echo -e "${color}${signal} $*${RESET}";;
        -approval)  color="${CYAN_B}${BOLD}";   signal="[?]"; shift; echo -e "${color}${signal} $*${RESET}";;
        -info)      color="${CYAN_B}";          signal="[i]"; shift; echo -e "${color}${signal} $*${RESET}";;
        -cancel)    color="${BLUE}${BOLD}";     signal="[!]"; shift; echo -e "${color}${signal} $*${RESET}";;
        -warning)   color="${YELLOW}${BOLD}";   signal="[&]"; shift; echo -e "\t${color}${signal} $*${RESET}";;
        -success)   color="${GREEN}${BOLD}";    signal="[+]"; shift; echo -e "\t${color}${signal} $*${RESET}";;
        -error)     color="${RED}${BOLD}";      signal="[-]"; shift; echo -e "\t${color}${signal} $*${RESET}";;
        *)          echo -e "$*";;
    esac
}


# ============================================================================
# FUNCIÓN: _lib_check_command_exists
# ============================================================================
# Verifica si un comando está disponible en el sistema
#
# Argumentos:
#   $1: Nombre del comando a verificar
#
# Retorno:
#   0: Comando encontrado
#   1: Comando no encontrado
#
# Ejemplo:
#   if _lib_check_command_exists "git"; then
#       _lib_message -success "Git está disponible"
#   fi

_lib_check_command_exists() {
    command -v "$1" &> /dev/null
}

# ============================================================================
# FUNCIÓN: _lib_check_file_exists
# ============================================================================
# Verifica si un archivo existe
#
# Argumentos:
#   $1: Ruta del archivo
#
# Retorno:
#   0: Archivo existe
#   1: Archivo no existe
#
# Ejemplo:
#   if _lib_check_file_exists "/path/to/file"; then
#       _lib_message -info "El archivo existe"
#   fi

_lib_check_file_exists() {
    [[ -f "$1" ]]
}

# ============================================================================
# FUNCIÓN: _lib_check_dir_exists
# ============================================================================
# Verifica si un directorio existe
#
# Argumentos:
#   $1: Ruta del directorio
#
# Retorno:
#   0: Directorio existe
#   1: Directorio no existe
#
# Ejemplo:
#   if _lib_check_dir_exists "/path/to/dir"; then
#       _lib_message -info "El directorio existe"
#   fi

_lib_check_dir_exists() {
    [[ -d "$1" ]]
}

# ============================================================================
# FUNCIÓN: _lib_ensure_dir
# ============================================================================
# Crea un directorio si no existe
#
# Argumentos:
#   $1: Ruta del directorio
#
# Retorno:
#   0: Directorio creado o ya existe
#   1: Error al crear
#
# Ejemplo:
#   _lib_ensure_dir "$HOME/.config/shell/backups"

_lib_ensure_dir() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir" || return 1
        _lib_message -success "Directorio creado: $dir"
    fi
    return 0
}

# ============================================================================
# FUNCIÓN: _lib_safe_copy_with_backup
# ============================================================================
# Copia un archivo haciendo backup del existente
#
# Argumentos:
#   $1: Archivo origen
#   $2: Archivo destino
#   $3: Directorio de backup (opcional)
#
# Retorno:
#   0: Copia exitosa
#   1: Error en la copia
#
# Ejemplo:
#   _lib_safe_copy_with_backup "$HOME/config" "$HOME/.config/shell/config" "$HOME/.config/shell/backups"

_lib_safe_copy_with_backup() {
    local source="$1"
    local dest="$2"
    local backup_dir="${3:-.}"
    
    if [[ ! -e "$source" ]]; then
        _lib_message -error "Archivo de origen no existe: $source"
        return 1
    fi
    
    # Si el destino existe, hacer backup
    if [[ -e "$dest" ]]; then
        local backup_name="$(basename "$dest")_$(date +%Y%m%d_%H%M%S)"
        local backup_path="${backup_dir}/${backup_name}"
        
        _lib_ensure_dir "$backup_dir" || return 1
        cp "$dest" "$backup_path" || return 1
        _lib_message -info "Backup creado: $backup_path"
    fi
    
    # Copiar el nuevo archivo
    cp "$source" "$dest" || return 1
    _lib_message -success "Archivo copiado: $dest"
    
    return 0
}

# ============================================================================
# FUNCIÓN: _lib_validate_bash_syntax
# ============================================================================
# Valida la sintaxis bash de un archivo
#
# Argumentos:
#   $1: Ruta del archivo
#
# Retorno:
#   0: Sintaxis válida
#   1: Errores de sintaxis
#
# Ejemplo:
#   if _lib_validate_bash_syntax "$script"; then
#       _lib_message -success "Script válido"
#   fi

_lib_validate_bash_syntax() {
    local file="$1"
    
    if [[ ! -f "$file" ]]; then
        _lib_message -error "Archivo no encontrado: $file"
        return 1
    fi
    
    if bash -n "$file" 2>/dev/null; then
        return 0
    else
        _lib_message -error "Error de sintaxis bash en: $file"
        bash -n "$file"
        return 1
    fi
}

# ============================================================================
# FUNCIÓN: _lib_print_separator
# ============================================================================
# Imprime un separador visual
#
# Argumentos:
#   $1: Carácter a usar (opcional, default: =)
#   $2: Ancho (opcional, default: 80)
#
# Ejemplo:
#   _lib_print_separator
#   _lib_print_separator "-" 60

_lib_print_separator() {
    local char="${1:-=-}"
    local width="${2:-80}"
    
    printf '%*s\n' "$width" | tr ' ' "$char"
}

# ============================================================================
# FUNCIÓN: _lib_get_timestamp
# ============================================================================
# Obtiene un timestamp formateado
#
# Argumentos:
#   $1: Formato (opcional, default: %Y%m%d_%H%M%S)
#
# Ejemplo:
#   ts=$(_lib_get_timestamp)
#   ts=$(_lib_get_timestamp "%Y-%m-%d %H:%M:%S")

_lib_get_timestamp() {
    local format="${1:-%Y%m%d_%H%M%S}"
    date +"$format"
}

# ============================================================================
# FUNCIÓN: _lib_confirm
# ============================================================================
# Pide confirmación al usuario
#
# Argumentos:
#   $1: Mensaje de confirmación
#
# Retorno:
#   0: Usuario confirmó (s/S/y/Y)
#   1: Usuario canceló (n/N/q/Q o Ctrl+C)
#
# Ejemplo:
#   if _lib_confirm "¿Deseas continuar?"; then
#       _lib_message -info "Continuando..."
#   fi

_lib_confirm() {
    local prompt="${1:-¿Continuar?}"
    local response
    
    echo -ne "${BOLD}${CYAN}[?]${RESET} ${prompt} (s/n): "
    read -r response
    
    case "$response" in
        [sS]|[yY]|[sS][íi]) return 0 ;;
        *) return 1 ;;
    esac
}

# ============================================================================
# FUNCIÓN: _lib_cleanup_temp_files
# ============================================================================
# Función base para limpieza de archivos temporales
# Debe ser sobrescrita en scripts que crean archivos temporales
#
# Ejemplo:
#   _lib_cleanup_temp_files() {
#       [[ -n "${TEMP_LOG:-}" ]] && rm -f "$TEMP_LOG"
#   }
#   trap _lib_cleanup_temp_files EXIT

_lib_cleanup_temp_files() {
    # Función vacía, será sobrescrita si es necesaria
    :
}

# ============================================================================
# FUNCIÓN: _lib_find_first_available_command
# ============================================================================
# Busca y retorna el primer comando disponible de una lista
#
# Argumentos:
#   Nombres de comandos a buscar (múltiples argumentos)
#
# Retorno:
#   Ruta del primer comando encontrado
#   (vacío si ninguno está disponible)
#
# Ejemplo:
#   editor=$(_lib_find_first_available_command vim nano vi)
#   echo "Using editor: $editor"

_lib_find_first_available_command() {
    local cmd type_out
    for cmd in "$@"; do
        # Check if the command exists as an executable or builtin
        if command -v "$cmd" &>/dev/null; then
            # Portable check for alias
            if [[ -n "$BASH_VERSION" ]]; then
                type_out=$(type -t "$cmd" 2>/dev/null)
                if [[ "$type_out" == "alias" ]]; then continue; fi
            elif [[ -n "$ZSH_VERSION" ]]; then
                type_out=$(type -w "$cmd" 2>/dev/null | cut -d: -f2 | xargs)
                if [[ "$type_out" == "alias" ]]; then continue; fi
            fi
            
            # Return the path or name if not an alias
            command -v "$cmd"
            return 0
        fi
    done
    return 1
}

# ============================================================================
# FUNCIÓN: _lib_find_first_available_directory
# ============================================================================
# Busca y retorna el primer directorio disponible de una lista
#
# Argumentos:
#   Rutas de directorios a buscar (múltiples argumentos)
#
# Retorno:
#   Ruta del primer directorio encontrado
#   (vacío si ninguno existe)
#
# Ejemplo:
#   config_dir=$(_lib_find_first_available_directory ~/.config ~/.etc /etc/myapp)
#   echo "Using config: $config_dir"

_lib_find_first_available_directory() {
    local dir
    for dir in "$@"; do
        if _lib_check_dir_exists "$dir"; then
            echo "$dir"
            return 0
        fi
    done
    return 1
}

# ============================================================================
# FUNCIÓN: _lib_deduplicate_path
# ============================================================================
# Elimina duplicados en PATH manteniendo el orden
#
# Argumentos:
#   $1: Variable PATH a limpiar (por defecto: $PATH)
#
# Retorno:
#   PATH sin duplicados
#
# Ejemplo:
#   PATH=$(_lib_deduplicate_path "$PATH")

_lib_deduplicate_path() {
    local path="${1:-$PATH}"
    echo "$path" | tr ':' '\n' | awk '!a[$0]++' | paste -sd: -
}

# ============================================================================
# FUNCIÓN: _lib_lazy_load_function
# ============================================================================
# Carga funciones grandes bajo demanda para mejorar tiempo de inicio
#
# Esta función crea un "stub" que carga la función real la primera vez
# que se ejecuta, mejorando el tiempo de inicio del shell.
#
# Argumentos:
#   $1: Nombre de la función a cargar bajo demanda
#   $2: Archivo fuente con la función
#
# Ejemplo:
#   _lib_lazy_load_function "compile-pls" "$HOME/.config/shell/functions-heavy"
#   _lib_lazy_load_function "fzf-lovely" "$HOME/.config/shell/functions-heavy"

_lib_lazy_load_function() {
    local func_name="$1"
    local source_file="$2"
    
    # Validación de entrada
    if [[ -z "$func_name" ]] || [[ -z "$source_file" ]]; then
        _lib_message -error "lazy_load_function: función o archivo no especificado"
        return 1
    fi
    
    # Sanitizar nombre de función (solo permitir alfanuméricos, guiones y guiones bajos)
    if [[ ! "$func_name" =~ ^[a-zA-Z][a-zA-Z0-9_-]*$ ]]; then
        _lib_message -error "lazy_load_function: nombre de función inválido: $func_name"
        return 1
    fi
    
    # Validar y normalizar path (prevenir directory traversal)
    local normalized_file
    normalized_file=$(realpath "$source_file" 2>/dev/null) || {
        _lib_message -error "lazy_load_function: path inválido: $source_file"
        return 1
    }
    
    # Verificar que el archivo existe y es legible
    if [[ ! -f "$normalized_file" ]] || [[ ! -r "$normalized_file" ]]; then
        _lib_message -warning "lazy_load_function: archivo no encontrado o no legible: $normalized_file"
        return 1
    fi
    
    # Verificar que es un archivo seguro (dentro del proyecto)
    local project_root
    project_root=$(realpath "$(dirname "${BASH_SOURCE[0]}")/.." 2>/dev/null) || {
        _lib_message -error "lazy_load_function: no se puede determinar el project root"
        return 1
    }
    
    if [[ ! "$normalized_file" == "$project_root"* ]]; then
        _lib_message -error "lazy_load_function: archivo fuera del proyecto: $normalized_file"
        return 1
    fi
    
    # Crear un "stub" seguro que carga la función real cuando se ejecuta
    eval '
    '"$func_name"'() {
        # Descargar el stub
        unset -f '"$func_name"'
        # Cargar la función real
        source "'"$normalized_file"'"
        # Ejecutar la función con los argumentos originales
        '"$func_name"' "$@"
    }
    '
}

# ==========================================================================
# FUNCIÓN: _lib_escape_for_sed
# ==========================================================================
# Escapa caracteres especiales para sustituciones con sed
#
# Argumentos:
#   $1: Texto a escapar
#
# Retorno:
#   Texto seguro para reemplazo en sed

_lib_escape_for_sed() {
    local str="$1"
    str="${str//\\/\\\\}"
    str="${str//\//\\/}"
    str="${str//&/\\&}"
    printf '%s' "$str"
}

# ==========================================================================
# FUNCIÓN: _lib_render_template
# ==========================================================================
# Renderiza un archivo template reemplazando placeholders {{VAR}}
#
# Argumentos:
#   $1: Ruta del template
#   $2: Ruta de salida
#   $3+: Lista de pares clave=valor para reemplazar
#
# Retorno:
#   0 si se renderizó correctamente, 1 en caso de error

_lib_render_template() {
    local template_file="$1"
    local output_file="$2"
    shift 2

    if [[ ! -f "$template_file" ]]; then
        _lib_message -warning "Template no encontrado: $template_file"
        return 1
    fi

    local sed_args=()
    local pair key value
    for pair in "$@"; do
        key="${pair%%=*}"
        value="${pair#*=}"
        sed_args+=("-e" "s/{{${key}}}/$(_lib_escape_for_sed "$value")/")
    done

    if [[ ${#sed_args[@]} -eq 0 ]]; then
        _lib_message -warning "Sin variables para renderizar template"
        return 1
    fi

    sed "${sed_args[@]}" "$template_file" > "$output_file"
}

# ==========================================================================
# FUNCIÓN: _lib_install_symlinks
# ==========================================================================
# Crea enlaces simbólicos de todos los archivos de un origen a un destino
#
# Argumentos:
#   $1: Directorio origen
#   $2: Directorio destino
#   $3: Título para el mensaje (opcional)
#
# Retorno:
#   0 si se procesó correctamente

_lib_install_symlinks() {
    local src_dir="$1"
    local dest_dir="$2"
    local title="${3:-Instalando enlaces simbólicos}"
    local recursive="${4:-false}"

    _lib_message -subtitle "$title"

    if [[ ! -d "$src_dir" ]]; then
        _lib_message -warning "Directorio origen no encontrado: $src_dir"
        return 1
    fi

    _lib_ensure_dir "$dest_dir" || return 1

    local created=false
    local item base_name target_path
    
    # Usar dotglob para incluir archivos ocultos
    for item in "$src_dir"/* "$src_dir"/.[!.]* "$src_dir"/..?*; do
        # Validar que el item exista (evitar globs fallidos)
        [[ -e "$item" ]] || continue
        
        base_name=$(basename "$item")
        target_path="$dest_dir/$base_name"

        if [[ -d "$item" && "$recursive" == "true" ]]; then
            # Si es un directorio y estamos en modo recursivo, crear el directorio destino
            # y llamar de nuevo; marcar 'created' solo si la recursión reporta éxito
            if _lib_install_symlinks "$item" "$target_path" "Enlazando subdirectorio: $base_name" "true"; then
                created=true
            fi
        elif [[ -f "$item" ]]; then
            # Si es un archivo, crear el enlace
            if ln -sfn "$item" "$target_path"; then
                _lib_message -success "Enlace: $base_name -> $dest_dir"
                created=true
            else
                _lib_message -error "Error al enlazar: $base_name"
            fi
        fi
    done

    [[ $created == true ]] || _lib_message -info "No se procesaron elementos en $(basename "$src_dir")"
    return 0
}

# ============================================================================
# FUNCIÓN: _lib_is_command_available
# ============================================================================
# Versión mejorada de check_command_exists con caching
#
# Cachea resultados en /tmp para evitar múltiples búsquedas
#
# Argumentos:
#   $1: Nombre del comando a verificar
#
# Retorno:
#   0: Comando encontrado
#   1: Comando no encontrado
#
# Ejemplo:
#   if _lib_is_command_available "fzf"; then
#       enable_fzf_features
#   fi

_lib_is_command_available() {
    local cmd="$1"
    local cache_file="/tmp/.shell-cmd-cache-${cmd}"
    
    # Usar cache si existe y es reciente (menos de 1 hora)
    if [[ -f "$cache_file" ]]; then
        local cache_age=$(($(date +%s) - $(stat -c %Y "$cache_file" 2>/dev/null || echo 0)))
        if [[ $cache_age -lt 3600 ]]; then
            return $(command cat "$cache_file")
        fi
    fi
    
    # Verificar comando y cachear resultado
    if command -v "$cmd" &>/dev/null; then
        echo "0" > "$cache_file"
        return 0
    else
        echo "1" > "$cache_file"
        return 1
    fi
}

# ============================================================================
# FUNCIÓN: _lib_clear_command_cache
# ============================================================================
# Limpia la caché de comandos con opciones granulares
#
# Argumentos:
#   $1: Patrón a limpiar (opcional, por defecto todos)
#   $2: Forzar limpieza (opcional, --force para ignorar edad)
#
# Ejemplo:
#   _lib_clear_command_cache              # Limpia toda la caché
#   _lib_clear_command_cache "git"       # Limpia solo cache de comandos git*
#   _lib_clear_command_cache "" --force   # Fuerza limpieza de toda la caché

_lib_clear_command_cache() {
    local pattern="${1:-*}"
    local force_clean="$2"
    local cache_dir="/tmp"
    local cleaned=0
    local total_size=0
    
    # Buscar archivos de cache
    while IFS= read -r -d '' cache_file; do
        local basename=$(basename "$cache_file")
        
        # Verificar si coincide con el patrón
        if [[ "$pattern" != "*" ]] && [[ ! "$basename" =~ ^\.shell-cmd-cache-${pattern} ]]; then
            continue
        fi
        
        # Si no es force, verificar edad (solo limpiar si es mayor a 1 hora)
        if [[ "$force_clean" != "--force" ]]; then
            local cache_age=$(($(date +%s) - $(stat -c %Y "$cache_file" 2>/dev/null || echo 0)))
            if [[ $cache_age -lt 3600 ]]; then
                continue
            fi
        fi
        
        # Acumular tamaño antes de eliminar
        local file_size=$(stat -c%s "$cache_file" 2>/dev/null || echo 0)
        total_size=$((total_size + file_size))
        
        rm -f "$cache_file"
        ((cleaned++))
    done < <(find "$cache_dir" -name ".shell-cmd-cache-*" -type f -print0 2>/dev/null)
    
    if [[ $cleaned -gt 0 ]]; then
        _lib_message -success "Cache limpiada: $cleaned archivos liberados (${total_size} bytes)"
    else
        _lib_message -info "No se encontraron archivos de cache para limpiar"
    fi
}

# ============================================================================
# FUNCIÓN: _lib_get_cache_stats
# ============================================================================
# Muestra estadísticas de uso de la caché de comandos
#
# Argumentos:
#   Ninguno
#
# Ejemplo:
#   _lib_get_cache_stats

_lib_get_cache_stats() {
    local cache_dir="/tmp"
    local total_files=0
    local total_size=0
    local old_files=0
    
    while IFS= read -r -d '' cache_file; do
        local file_size=$(stat -c%s "$cache_file" 2>/dev/null || echo 0)
        local cache_age=$(($(date +%s) - $(stat -c %Y "$cache_file" 2>/dev/null || echo 0)))
        
        ((total_files++))
        total_size=$((total_size + file_size))
        
        if [[ $cache_age -gt 3600 ]]; then
            ((old_files++))
        fi
    done < <(find "$cache_dir" -name ".shell-cmd-cache-*" -type f -print0 2>/dev/null)
    
    echo "📊 Estadísticas de Caché:"
    echo "   Archivos totales: $total_files"
    echo "   Tamaño total: $((total_size / 1024))KB"
    echo "   Archivos antiguos (>1h): $old_files"
    
    if [[ $old_files -gt 0 ]]; then
        echo "   💡 Ejecuta '_lib_clear_command_cache' para limpiar archivos antiguos"
    fi
}

# ============================================================================
# FUNCIÓN: _lib_validate_directory_exists
# ============================================================================
# Valida existencia de múltiples directorios en PATH
#
# Argumentos:
#   Directorios a validar (múltiples argumentos)
#
# Retorno:
#   0: Al menos uno existe
#   1: Ninguno existe
#
# Ejemplo:
#   if _lib_validate_directory_exists "$HOME/.local/bin" "/usr/local/bin"; then
#       _lib_message -success "Directorios válidos encontrados"
#   fi

_lib_validate_directory_exists() {
    for dir in "$@"; do
        [[ -d "$dir" ]] && return 0
    done
    return 1
}

# ============================================================================
# FUNCIÓN: _lib_get_package_manager_commands
# ============================================================================
# Obtiene los comandos del gestor de paquetes según la distribución
#
# Argumentos:
#   $1: Distribución (ubuntu, debian, arch, manjaro, fedora, rhel)
#
# Retorno:
#   Exporta variables: PKG_UPDATE_CMD, PKG_INSTALL_CMD, PKG_CHECK_CMD
#
# Ejemplo:
#   _lib_get_package_manager_commands "ubuntu"
#   eval "$PKG_INSTALL_CMD git"

_lib_get_package_manager_commands() {
    local distro="$1"
    
    case "$distro" in
        ubuntu|debian)
            export PKG_UPDATE_CMD="sudo apt update -qq"
            export PKG_INSTALL_CMD="sudo apt install -y"
            export PKG_CHECK_CMD="dpkg -l"
            ;;
        arch|manjaro)
            export PKG_UPDATE_CMD="sudo pacman -Sy --noconfirm"
            export PKG_INSTALL_CMD="sudo pacman -S --noconfirm"
            export PKG_CHECK_CMD="pacman -Q"
            ;;
        fedora|rhel)
            export PKG_UPDATE_CMD="sudo dnf check-update"
            export PKG_INSTALL_CMD="sudo dnf install -y"
            export PKG_CHECK_CMD="dnf list installed"
            ;;
        *)
            _lib_message -error "Distribución no soportada: $distro"
            return 1
            ;;
    esac
    
    return 0
}

# ============================================================================
# FUNCIÓN: _lib_check_packages_array
# ============================================================================
# Verifica disponibilidad de un array de paquetes
#
# Argumentos:
#   $1: Distribución
#   $2: Nombre del array de paquetes (pasado por nombre)
#   $3: Nombre del array destino para paquetes faltantes (pasado por nombre)
#
# Retorno:
#   0: Todos los paquetes están disponibles
#   1: Al menos un paquete falta
#
# Uso:
#   packages=("git" "curl" "jq")
#   missing=()                      # declare aquí la lista vacía que quieras usar
#   if _lib_check_packages_array "ubuntu" packages missing; then
#       _lib_message -success "Todos los paquetes disponibles"
#   else
#       _lib_message -warning "Paquetes faltantes: ${missing[*]}"
#   fi

_lib_check_packages_array() {
    local distro="$1"
    local -n packages_ref="$2"
    local -n missing_ref="$3"

    # Inicializar salida
    missing_ref=()

    # Obtener comandos del gestor de paquetes
    _lib_get_package_manager_commands "$distro" || return 1

    # Verificar cada paquete
    for pkg in "${packages_ref[@]}"; do
        if command -v "$pkg" >/dev/null 2>&1; then
            _lib_message -success "$pkg -> disponible"
        else
            _lib_message -warning "$pkg -> no encontrado"
            missing_ref+=("$pkg")
        fi
    done

    # Retornar 0 si todos están disponibles, 1 si faltan
    [[ ${#missing_ref[@]} -eq 0 ]]
}

# ============================================================================
# FUNCIÓN: _lib_install_packages_array
# ============================================================================
# Instala un array de paquetes según la distribución
#
# Argumentos:
#   $1: Distribución
#   $2: Array de paquetes (pasado por nombre)
#   $3: Omitir actualización (opcional, default: false)
#
# Retorno:
#   0: Todos los paquetes instalados exitosamente
#   1: Al menos un paquete falló
#   Exporta variables: SUCCESSFUL_PACKAGES[], FAILED_PACKAGES[]
#
# Ejemplo:
#   packages=("git" "curl" "jq")
#   if _lib_install_packages_array "ubuntu" packages; then
#       _lib_message -success "Instalación completada"
#   fi

_lib_install_packages_array() {
    local distro="$1"
    local -n packages_ref="$2"
    local skip_update="${3:-false}"
    SUCCESSFUL_PACKAGES=()
    FAILED_PACKAGES=()
    
    # Validar que hay paquetes para instalar
    [[ ${#packages_ref[@]} -eq 0 ]] && {
        _lib_message -info "No hay paquetes para instalar"
        return 0
    }
    
    # Obtener comandos del gestor de paquetes
    _lib_get_package_manager_commands "$distro" || return 1
    
    # Obtener permisos sudo una sola vez
    _lib_message -warning "Se requieren permisos de sudo"
    local sudo_attempt=0
    while (( sudo_attempt < 3 )); do
        sudo -n true 2>/dev/null || sudo true && break
        ((sudo_attempt++))
        sleep 1
    done

    if (( sudo_attempt >= 3 )); then
        _lib_message -error "No se pudieron obtener permisos de sudo"
        return 1
    fi
    _lib_message -success "Permisos de sudo obtenidos"
    
    # Actualizar repositorios si no se omite
    if [[ "$skip_update" != "true" ]]; then
        _lib_message -info "Actualizando repositorios..."
        if ! eval "$PKG_UPDATE_CMD" &>/dev/null; then
            _lib_message -error "Error actualizando repositorios"
            return 1
        fi
    fi
    
    # Instalar paquetes
    _lib_message -subtitle "Instalando paquetes..."
    for pkg in "${packages_ref[@]}"; do
        # Verificar si ya está instalado
        if command -v "$pkg" >/dev/null 2>&1 || eval "$PKG_CHECK_CMD $pkg" &>/dev/null; then
            _lib_message -success "$pkg -> ya disponible"
            SUCCESSFUL_PACKAGES+=("$pkg")
            continue
        fi
        
        _lib_message -info "Instalando: $pkg"
        if eval "$PKG_INSTALL_CMD $pkg" &>/dev/null; then
            # Verificar que se instaló correctamente
            if command -v "$pkg" &>/dev/null || eval "$PKG_CHECK_CMD $pkg" &>/dev/null; then
                _lib_message -success "Instalado: $pkg"
                SUCCESSFUL_PACKAGES+=("$pkg")
            else
                _lib_message -error "Instalado pero no detectable: $pkg"
                FAILED_PACKAGES+=("$pkg")
            fi
        else
            _lib_message -error "Falló instalación: $pkg"
            FAILED_PACKAGES+=("$pkg")
        fi
        sleep 1
    done
    
    # Resumen
    [[ ${#SUCCESSFUL_PACKAGES[@]} -gt 0 ]] && \
        _lib_message -info "Paquetes instalados: ${SUCCESSFUL_PACKAGES[*]}"

    if [[ ${#FAILED_PACKAGES[@]} -gt 0 ]]; then
        _lib_message -warning "Paquetes que fallaron: ${FAILED_PACKAGES[*]}"
        return 1
    fi

    return 0
}


# ============================================================================
# FUNCIÓN: _lib_extract_archive
# ============================================================================
# Extrae archivos comprimidos de múltiples formatos
#
# Argumentos:
#   $1: Ruta del archivo a extraer
#
# Retorno:
#   0: Extracción exitosa
#   1: Error o formato no soportado
#
# Ejemplo:
#   _lib_extract_archive "archivo.tar.gz"
#   _lib_extract_archive "documento.zip"

_lib_extract_archive() {
    local file="$1"
    _lib_check_file_exists "$file" || {
        _lib_message -error "Archivo no existe: $file"
        return 1
    }
    
    case "$file" in
        *.tar.bz2)   tar xvjf "$file" ;;
        *.tar.gz)    tar xvzf "$file" ;;
        *.bz2)       bunzip2 "$file" ;;
        *.rar)       unrar x "$file" ;;
        *.gz)        gunzip "$file" ;;
        *.tar)       tar xvf "$file" ;;
        *.tbz2)      tar xvjf "$file" ;;
        *.tgz)       tar xvzf "$file" ;;
        *.zip)       unzip "$file" ;;
        *.Z)         uncompress "$file" ;;
        *.7z)        7z x "$file" ;;
        *) 
            _lib_message -error "Formato no soportado: $file"
            return 1 
            ;;
    esac
    
    _lib_message -success "Archivo extraído: $file"
    return 0
}

# ============================================================================
# FUNCIÓN: _lib_smart_open
# ============================================================================
# Abre archivos con el editor apropiado, detectando automáticamente
#
# Argumentos:
#   $1: Ruta del archivo a abrir
#
# Retorno:
#   0: Archivo abierto exitosamente
#   1: Error al abrir o editor no disponible
#
# Ejemplo:
#   _lib_smart_open "script.py"
#   _lib_smart_open "config.txt"

_lib_smart_open() {
    local file="$1"
    if [[ -z "$file" ]]; then
        _lib_message -error "Debe especificar un archivo"
        return 1
    fi
    
    if ! _lib_check_file_exists "$file"; then
        _lib_message -error "Archivo no existe: $file"
        return 1
    fi
    
    if [[ -z "${EDITOR:-}" ]]; then
        _lib_message -warning "La variable EDITOR no está definida"
        
        local editor=$(_lib_find_first_available_command code vim nano micro)
        if [[ -n "$editor" ]]; then
            _lib_message -info "Usando editor encontrado: $editor"
            "$editor" "$file"
        else
            _lib_message -error "No se encontró ningún editor disponible"
            return 1
        fi
    else
        case "$EDITOR" in
            code|vim|nano|micro|emacs|vi)
                "$EDITOR" "$file"
                _lib_message -success "Archivo abierto con $EDITOR"
                ;;
            *)
                _lib_message -error "Editor no soportado: $EDITOR"
                return 1
                ;;
        esac
    fi
    
    return 0
}

# ============================================================================
# FUNCIÓN: _lib_compile_code
# ============================================================================
# Compila y ejecuta código en múltiples lenguajes
#
# Argumentos:
#   $1: Ruta del archivo a compilar
#   $@: Argumentos adicionales para el programa compilado
#
# Retorno:
#   0: Compilación y ejecución exitosas
#   1: Error en compilación o ejecución
#
# Ejemplo:
#   _lib_compile_code "hola.c"
#   _lib_compile_code "programa.cpp"

_lib_compile_code() {
    local file="$1"
    shift
    local args=("$@")
    
    if ! _lib_check_file_exists "$file"; then
        _lib_message -error "Archivo no existe: $file"
        return 1
    fi
    
    local filename=$(basename "$file")
    local extension="${filename##*.}"
    local name_without_ext="${filename%.*}"
    
    case "$extension" in
        "kt")
            if _lib_check_command_exists kotlinc && _lib_check_command_exists java; then
                kotlinc "$filename" -include-runtime -d "${name_without_ext}.jar" && \
                java -jar "${name_without_ext}.jar" "${args[@]}"
            else
                _lib_message -error "Kotlin o Java no están instalados"
                return 1
            fi
            ;;
        "java")
            if _lib_check_command_exists javac && _lib_check_command_exists java; then
                javac "$filename" && java "$name_without_ext" "${args[@]}"
            else
                _lib_message -error "Java no está instalado"
                return 1
            fi
            ;;
        "cpp")
            if _lib_check_command_exists g++; then
                g++ "$filename" -o "$name_without_ext" && "./$name_without_ext" "${args[@]}"
            else
                _lib_message -error "g++ no está instalado"
                return 1
            fi
            ;;
        "c")
            if _lib_check_command_exists gcc; then
                gcc "$filename" -o "$name_without_ext" && "./$name_without_ext" "${args[@]}"
            else
                _lib_message -error "gcc no está instalado"
                return 1
            fi
            ;;
        "pas")
            if _lib_check_command_exists fpc; then
                fpc "$filename" && "./$name_without_ext" "${args[@]}"
            else
                _lib_message -error "Free Pascal Compiler (fpc) no está instalado"
                return 1
            fi
            ;;
        *)
            _lib_message -error "Extensión no soportada: .$extension"
            return 1
            ;;
    esac
    
    return 0
}


# ============================================================================
# FUNCIÓN: _lib_simple_calc
# ============================================================================
# Calculadora simple usando bc
#
# Argumentos:
#   $1: Expresión matemática a evaluar
#
# Retorno:
#   0: Cálculo exitoso
#   1: Error en la expresión o bc no disponible
#
# Ejemplo:
#   _lib_simple_calc "2+2*3"
#   _lib_simple_calc "sqrt(16)"

_lib_simple_calc() {
    local expression="$1"
    
    if [[ -z "$expression" ]]; then
        _lib_message -error "Debe proporcionar una expresión matemática"
        return 1
    fi
    
    if ! _lib_check_command_exists bc; then
        _lib_message -error "bc no está instalado. Instale con: sudo apt install bc"
        return 1
    fi
    
    local result
    result=$(echo "$expression" | bc -ql 2>/dev/null)
    
    if [[ $? -eq 0 ]]; then
        echo "$result"
        return 0
    else
        _lib_message -error "Error en la expresión matemática: $expression"
        return 1
    fi
}

# ============================================================================
# FUNCIONES DE VALIDACIÓN REUTILIZABLES
# ============================================================================

# FUNCIÓN: _lib_validate_file_with_message
# ============================================================================
# Valida existencia de archivo con mensaje de error personalizado
#
# Argumentos:
#   $1: Ruta del archivo a validar
#   $2: Mensaje de error personalizado (opcional)
#
# Retorno:
#   0: Archivo existe
#   1: Archivo no existe
#
# Ejemplo:
#   _lib_validate_file_with_message "$HOME/config.txt" "Configuración no encontrada"

_lib_validate_file_with_message() {
    local file_path="$1"
    local error_message="${2:-Error: Archivo no encontrado: $file_path}"
    
    if [[ -f "$file_path" ]]; then
        return 0
    else
        _lib_message -error "$error_message"
        return 1
    fi
}

# FUNCIÓN: _lib_validate_required_param
# ============================================================================
# Valida que un parámetro requerido no esté vacío
#
# Argumentos:
#   $1: Parámetro a validar
#   $2: Mensaje de uso o error
#
# Retorno:
#   0: Parámetro válido
#   1: Parámetro vacío
#
# Ejemplo:
#   _lib_validate_required_param "$filename" "Debe especificar un nombre de archivo"

_lib_validate_required_param() {
    local param="$1"
    local usage_message="$2"
    
    if [[ -z "$param" ]]; then
        _lib_message -error "$usage_message"
        return 1
    fi
    return 0
}

# FUNCIÓN: _lib_validate_param_count
# ============================================================================
# Valida que el número de parámetros esté dentro de un rango
#
# Argumentos:
#   $1: Cantidad actual de parámetros
#   $2: Mínimo requerido
#   $3: Máximo permitido (opcional, default = mínimo)
#   $4: Mensaje de uso
#
# Retorno:
#   0: Cantidad válida
#   1: Cantidad inválida
#
# Ejemplo:
#   _lib_validate_param_count $# 1 2 "Uso: comando <archivo> [opción]"

_lib_validate_param_count() {
    local actual_count="$1"
    local expected_min="$2"
    local expected_max="${3:-$2}"
    local usage_message="$4"
    
    if [[ $actual_count -lt $expected_min ]] || [[ $actual_count -gt $expected_max ]]; then
        _lib_message -error "$usage_message"
        return 1
    fi
    return 0
}

# ============================================================================
# FUNCIONES DE RED Y API REUTILIZABLES
# ============================================================================

# FUNCIÓN: _lib_fetch_json_api
# ============================================================================
# Realiza petición HTTP a API y procesa respuesta JSON
#
# Argumentos:
#   $1: URL de la API
#   $2: Filtro jq (opcional, default = ".")
#   $3: Opciones curl (opcional, default = "sSL")
#
# Retorno:
#   0: Éxito, imprime JSON procesado
#   1: Error, imprime mensaje de error
#
# Ejemplo:
#   _lib_fetch_json_api "https://api.example.com/data" ".results"

_lib_fetch_json_api() {
    local url="$1"
    local jq_filter="${2:-.}"
    local options="${3:-sSL}"
    
    _lib_validate_required_param "$url" "Debe proporcionar una URL para la API" || return 1
    
    _lib_check_command_exists "curl" || {
        _lib_message -error "curl no está disponible. Instale con: sudo apt install curl"
        return 1
    }
    
    _lib_check_command_exists "jq" || {
        _lib_message -error "jq no está disponible. Instale con: sudo apt install jq"
        return 1
    }
    
    local response
    response=$(curl -"$options" "$url" 2>/dev/null)
    
    if [[ $? -ne 0 ]]; then
        _lib_message -error "Error al conectar con la API: $url"
        return 1
    fi
    
    echo "$response" | jq -r "$jq_filter" 2>/dev/null
}


# FUNCIÓN: _lib_fetch_text_api
# ============================================================================
# Realiza petición HTTP a API y devuelve respuesta en texto plano
#
# Argumentos:
#   $1: Endpoint o ruta
#   $2: URL base (opcional, default = "https://cheat.sh")
#   $3: Opciones curl (opcional, default = "s")
#
# Retorno:
#   0: Éxito, imprime respuesta en texto
#   1: Error, imprime mensaje de error
#
# Ejemplo:
#   _lib_fetch_text_api "git" "https://cheat.sh"

_lib_fetch_text_api() {
    local endpoint="$1"
    local base_url="${2:-https://cheat.sh}"
    local options="${3:-s}"
    
    _lib_validate_required_param "$endpoint" "Debe proporcionar un endpoint" || return 1
    
    _lib_check_command_exists "curl" || {
        _lib_message -error "curl no está disponible. Instale con: sudo apt install curl"
        return 1
    }
    
    curl -"$options" "${base_url}/${endpoint}" 2>/dev/null
}


# ============================================================================
# FUNCIÓN: _lib_extract_patterns (versión portable mejorada)
# ============================================================================
# Extrae patrones desde un archivo usando regex portable.
#
# Argumentos:
#   $1 → archivo
#   $2 → patrón regex
#   $3 → separador de campo (opcional, default=" ")
#   $4 → delimitador de salida (opcional, default=",")
#   $5 → número de campo a extraer (opcional, default=1)
#
# Retorna:
#   0 → éxito
#   1 → error
#
# Ejemplo:
#   _lib_extract_patterns scan.txt '\d+/open' '/' ',' 1
# ============================================================================

_lib_extract_patterns() {
    local file="$1"
    local pattern="$2"
    local field_separator="${3:- }"
    local output_delimiter="${4:-,}"
    local field_number="${5:-1}"

    # Validar archivo usando función existente
    _lib_validate_file_with_message "$file" "Archivo inválido: $file" || return 1
    
    # Validar patrón usando función existente
    _lib_validate_required_param "$pattern" "Debe proporcionar un patrón regex" || return 1

    # Validar comandos necesarios usando función existente
    _lib_check_command_exists "grep" || {
        _lib_message -error "grep no está disponible"
        return 1
    }

    _lib_check_command_exists "awk" || {
        _lib_message -error "awk no está disponible"
        return 1
    }

    # Detectar soporte PCRE (-P)
    local grep_cmd
    if grep -P "" </dev/null &>/dev/null; then
        grep_cmd=(grep -oP)
    else
        grep_cmd=(grep -oE)
    fi

    # Pipeline principal
    "${grep_cmd[@]}" "$pattern" "$file" 2>/dev/null \
        | awk -v FS="$field_separator" -v field="$field_number" '
            NF >= field { print $field }
        ' \
        | awk -v delim="$output_delimiter" '
            BEGIN { first=1 }
            {
                if (!first) printf "%s", delim
                printf "%s", $0
                first=0
            }
            END { if (!first) printf "\n" }
        '

    return 0
}


# FUNCIÓN: _lib_normalize_text
# ============================================================================
# Normaliza texto a minúsculas y caracteres ASCII
#
# Argumentos:
#   $1: Texto a normalizar
#   $2: Prefijo (opcional)
#   $3: Sufijo (opcional)
#   $4: Texto alternativo si falla normalización (opcional)
#
# Retorno:
#   0: Éxito, imprime texto normalizado
#
# Ejemplo:
#   _lib_normalize_text "Mi Proyecto" "." "-env"

_lib_normalize_text() {
    local text="$1"
    local prefix="${2:-}"
    local suffix="${3:-}"
    local fallback="${4:-$text}"
    
    _lib_validate_required_param "$text" "Debe proporcionar texto para normalizar" || return 1
    
    local normalized
    normalized=$(echo "$text" | tr '[:upper:]' '[:lower:]' | iconv -f utf8 -t ascii//TRANSLIT 2>/dev/null || echo "$fallback")
    
    echo "${prefix}${normalized}${suffix}"
}

# FUNCIÓN: _lib_build_api_url
# ============================================================================
# Construye URL con parámetros de consulta
#
# Argumentos:
#   $1: URL base
#   $2: Path o endpoint (opcional)
#   $@: Array de parámetros en formato "clave=valor"
#
# Retorno:
#   0: Éxito, imprime URL completa
#
# Ejemplo:
#   _lib_build_api_url "https://wttr.in" "" "lang=es" "format=2mp"

_lib_build_api_url() {
    local base_url="$1"
    local path="${2:-}"
    shift 2
    local params=("$@")
    
    _lib_validate_required_param "$base_url" "Debe proporcionar una URL base" || return 1
    
    local url="${base_url}"
    [[ -n "$path" ]] && url="${url}/${path}"
    
    if [[ ${#params[@]} -gt 0 ]]; then
        local query_string
        query_string=$(printf "&%s" "${params[@]}" | cut -c2-)
        url="${url}?${query_string}"
    fi
    
    echo "$url"
}

# ============================================================================
# FUNCIONES DE MANEJO DE ARCHIVOS TEMPORALES REUTILIZABLES
# ============================================================================

# FUNCIÓN: _lib_create_temp_report
# ============================================================================
# Crea archivo temporal con limpieza automática
#
# Argumentos:
#   $1: Nombre del archivo (opcional, auto-generado)
#   $2: Limpiar después de uso (opcional, default = true)
#
# Retorno:
#   0: Éxito, imprime ruta del archivo temporal
#
# Ejemplo:
#   local temp_file=$(_lib_create_temp_report "report" true)

_lib_create_temp_report() {
    local name="${1:-temp_report}"
    local cleanup_after="${2:-true}"
    local temp_file="/tmp/${name}_$(_lib_get_timestamp)"
    
    # Crear trap para limpieza automática si se solicita
    if [[ "$cleanup_after" == "true" ]]; then
        trap "_lib_cleanup_temp_file '$temp_file'" EXIT
    fi
    
    touch "$temp_file" 2>/dev/null || {
        _lib_message -error "No se puede crear archivo temporal: $temp_file"
        return 1
    }
    
    echo "$temp_file"
}

# FUNCIÓN: _lib_cleanup_temp_file
# ============================================================================
# Limpia archivo temporal específico
#
# Argumentos:
#   $1: Ruta del archivo temporal
#
# Retorno:
#   0: Siempre
#
# Ejemplo:
#   _lib_cleanup_temp_file "/tmp/temp_file_123456"

_lib_cleanup_temp_file() {
    local temp_file="$1"
    [[ -f "$temp_file" ]] && rm -f "$temp_file" 2>/dev/null
    return 0
}

# FUNCIÓN: _lib_write_to_temp
# ============================================================================
# Escribe contenido en archivo temporal
#
# Argumentos:
#   $1: Ruta del archivo temporal
#   $2: Contenido a escribir
#   $3: Modo de escritura (opcional, default = "append")
#
# Retorno:
#   0: Éxito
#   1: Error
#
# Ejemplo:
#   _lib_write_to_temp "$temp_file" "Datos del reporte" "append"

_lib_write_to_temp() {
    local temp_file="$1"
    local content="$2"
    local mode="${3:-append}"  # append or overwrite
    
    _lib_validate_file_with_message "$temp_file" "Archivo temporal no existe: $temp_file" || return 1
    _lib_validate_required_param "$content" "Debe proporcionar contenido para escribir" || return 1
    
    if [[ "$mode" == "overwrite" ]]; then
        echo -e "$content" > "$temp_file" 2>/dev/null || {
            _lib_message -error "Error al escribir en archivo temporal"
            return 1
        }
    else
        echo -e "$content" >> "$temp_file" 2>/dev/null || {
            _lib_message -error "Error al agregar contenido al archivo temporal"
            return 1
        }
    fi
    
    return 0
}

# FUNCIÓN: _lib_safe_numeric_input
# ============================================================================
# Valida que un parámetro sea numérico y está en un rango
#
# Argumentos:
#   $1: Valor a validar
#   $2: Valor mínimo (opcional)
#   $3: Valor máximo (opcional)
#   $4: Mensaje de error personalizado (opcional)
#
# Retorno:
#   0: Valor válido
#   1: Valor inválido
#
# Ejemplo:
#   _lib_safe_numeric_input "$count" 1 10 "Debe estar entre 1 y 10"

_lib_safe_numeric_input() {
    local value="$1"
    local min="${2:-}"
    local max="${3:-}"
    local error_msg="${4:-Valor numérico inválido: $value}"
    
    _lib_validate_required_param "$value" "$error_msg" || return 1
    
    # Verificar que sea numérico
    if ! [[ "$value" =~ ^[0-9]+$ ]]; then
        _lib_message -error "$error_msg (debe ser un número positivo)"
        return 1
    fi
    
    # Verificar rango mínimo
    if [[ -n "$min" ]] && [[ $value -lt $min ]]; then
        _lib_message -error "$error_msg (debe ser mayor o igual a $min)"
        return 1
    fi
    
    # Verificar rango máximo
    if [[ -n "$max" ]] && [[ $value -gt $max ]]; then
        _lib_message -error "$error_msg (debe ser menor o igual a $max)"
        return 1
    fi
    
    return 0
}

# ============================================================================
# FIN DE LA LIBRERÍA
# ============================================================================
