#!/usr/bin/env bash

#    ██╗     ██╗██████╗    ███████╗██╗  ██╗
#    ██║     ██║██╔══██╗   ██╔════╝██║  ██║
#    ██║     ██║██████╔╝   ███████╗███████║
#    ██║     ██║██╔══██╗   ╚════██║██╔══██║
#    ███████╗██║██████╔╝██╗███████║██║  ██║
#    ╚══════╝╚═╝╚═════╝ ╚═╝╚══════╝╚═╝  ╚═╝
#
# Este archivo contiene funciones comunes que pueden ser utilizadas por
# múltiples scripts en el proyecto. Incluye funciones para mensajes con
# colores, limpieza de recursos y utilidades diversas.
#
# Uso en otros scripts:
#   source "$(dirname "$0")/../config/lib.sh"
#   o
#   source "${SCRIPT_DIR}/config/lib.sh"

# ============================================================================
# DEFINICIÓN DE COLORES (si no están definidos)
# ============================================================================

[[ -z "${RED:-}" ]] && readonly RED='\033[0;31m'
[[ -z "${GREEN:-}" ]] && readonly GREEN='\033[0;32m'
[[ -z "${YELLOW:-}" ]] && readonly YELLOW='\033[1;33m'
[[ -z "${BLUE:-}" ]] && readonly BLUE='\033[0;34m'
[[ -z "${CYAN:-}" ]] && readonly CYAN='\033[0;36m'
[[ -z "${BOLD:-}" ]] && readonly BOLD='\033[1m'
[[ -z "${RESET:-}" ]] && readonly RESET='\033[0m'

# ============================================================================
# FUNCIÓN: message
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
#   message -title "INICIANDO PROCESO"
#   message -success "Operación completada"
#   message -error "Error: archivo no encontrado"

message() {
    local signal color
    case "$1" in
        "-title")       color="${BOLD}${CYAN}";       signal="[→]"; shift; echo -e "\n${color}${signal} $*${RESET}";;
        "-subtitle")    color="${BOLD}${BLUE}";       signal="[*]"; shift; echo -e "${color}${signal} $*${RESET}";;
        "-success")     color="${GREEN}${BOLD}";      signal="[+]"; shift; echo -e "${color}${signal} $*${RESET}";;
        "-warning")     color="${YELLOW}${BOLD}";     signal="[&]"; shift; echo -e "${color}${signal} $*${RESET}";;
        "-error")       color="${RED}${BOLD}";        signal="[-]"; shift; echo -e "${color}${signal} $*${RESET}";;
        "-info")        color="${CYAN}";              signal="[i]"; shift; echo -e "${color}${signal} $*${RESET}";;
        *)              color="${RESET}"; echo -e "${color}$*${RESET}";;
    esac
}

# ============================================================================
# FUNCIÓN: check_command_exists
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
#   if check_command_exists "git"; then
#       message -success "Git está disponible"
#   fi

check_command_exists() {
    command -v "$1" &> /dev/null
}

# ============================================================================
# FUNCIÓN: check_file_exists
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
#   if check_file_exists "/path/to/file"; then
#       message -info "El archivo existe"
#   fi

check_file_exists() {
    [[ -f "$1" ]]
}

# ============================================================================
# FUNCIÓN: check_dir_exists
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
#   if check_dir_exists "/path/to/dir"; then
#       message -info "El directorio existe"
#   fi

check_dir_exists() {
    [[ -d "$1" ]]
}

# ============================================================================
# FUNCIÓN: ensure_dir
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
#   ensure_dir "$HOME/.config/shell/backups"

ensure_dir() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        mkdir -p "$dir" || return 1
        message -success "Directorio creado: $dir"
    fi
    return 0
}

# ============================================================================
# FUNCIÓN: safe_copy_with_backup
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
#   safe_copy_with_backup "$HOME/config" "$HOME/.config/shell/config" "$HOME/.config/shell/backups"

safe_copy_with_backup() {
    local source="$1"
    local dest="$2"
    local backup_dir="${3:-.}"
    
    if [[ ! -e "$source" ]]; then
        message -error "Archivo de origen no existe: $source"
        return 1
    fi
    
    # Si el destino existe, hacer backup
    if [[ -e "$dest" ]]; then
        local backup_name="$(basename "$dest")_$(date +%Y%m%d_%H%M%S)"
        local backup_path="${backup_dir}/${backup_name}"
        
        ensure_dir "$backup_dir" || return 1
        cp "$dest" "$backup_path" || return 1
        message -info "Backup creado: $backup_path"
    fi
    
    # Copiar el nuevo archivo
    cp "$source" "$dest" || return 1
    message -success "Archivo copiado: $dest"
    
    return 0
}

# ============================================================================
# FUNCIÓN: validate_bash_syntax
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
#   if validate_bash_syntax "$script"; then
#       message -success "Script válido"
#   fi

validate_bash_syntax() {
    local file="$1"
    
    if [[ ! -f "$file" ]]; then
        message -error "Archivo no encontrado: $file"
        return 1
    fi
    
    if bash -n "$file" 2>/dev/null; then
        return 0
    else
        message -error "Error de sintaxis bash en: $file"
        bash -n "$file"
        return 1
    fi
}

# ============================================================================
# FUNCIÓN: print_separator
# ============================================================================
# Imprime un separador visual
#
# Argumentos:
#   $1: Carácter a usar (opcional, default: =)
#   $2: Ancho (opcional, default: 80)
#
# Ejemplo:
#   print_separator
#   print_separator "-" 60

print_separator() {
    local char="${1:-=-}"
    local width="${2:-80}"
    
    printf '%*s\n' "$width" | tr ' ' "$char"
}

# ============================================================================
# FUNCIÓN: get_timestamp
# ============================================================================
# Obtiene un timestamp formateado
#
# Argumentos:
#   $1: Formato (opcional, default: %Y%m%d_%H%M%S)
#
# Ejemplo:
#   ts=$(get_timestamp)
#   ts=$(get_timestamp "%Y-%m-%d %H:%M:%S")

get_timestamp() {
    local format="${1:-%Y%m%d_%H%M%S}"
    date +"$format"
}

# ============================================================================
# FUNCIÓN: confirm
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
#   if confirm "¿Deseas continuar?"; then
#       message -info "Continuando..."
#   fi

confirm() {
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
# FUNCIÓN: cleanup_temp_files
# ============================================================================
# Función base para limpieza de archivos temporales
# Debe ser sobrescrita en scripts que crean archivos temporales
#
# Ejemplo:
#   cleanup_temp_files() {
#       [[ -n "${TEMP_LOG:-}" ]] && rm -f "$TEMP_LOG"
#   }
#   trap cleanup_temp_files EXIT

cleanup_temp_files() {
    # Función vacía, será sobrescrita si es necesaria
    :
}

# ============================================================================
# FUNCIÓN: find_first_available_command
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
#   editor=$(find_first_available_command vim nano vi)
#   echo "Using editor: $editor"

find_first_available_command() {
    local cmd
    for cmd in "$@"; do
        if check_command_exists "$cmd"; then
            command -v "$cmd"
            return 0
        fi
    done
    return 1
}

# ============================================================================
# FUNCIÓN: find_first_available_directory
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
#   config_dir=$(find_first_available_directory ~/.config ~/.etc /etc/myapp)
#   echo "Using config: $config_dir"

find_first_available_directory() {
    local dir
    for dir in "$@"; do
        if check_dir_exists "$dir"; then
            echo "$dir"
            return 0
        fi
    done
    return 1
}

# ============================================================================
# FUNCIÓN: deduplicate_path
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
#   PATH=$(deduplicate_path "$PATH")

deduplicate_path() {
    local path="${1:-$PATH}"
    echo "$path" | tr ':' '\n' | awk '!a[$0]++' | paste -sd: -
}

# ============================================================================
# FUNCIÓN: lazy_load_function
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
#   lazy_load_function "compile-pls" "$HOME/.config/shell/functions-heavy"
#   lazy_load_function "fzf-lovely" "$HOME/.config/shell/functions-heavy"

lazy_load_function() {
    local func_name="$1"
    local source_file="$2"
    
    # Validación de entrada
    if [[ -z "$func_name" ]] || [[ -z "$source_file" ]]; then
        message -error "lazy_load_function: función o archivo no especificado"
        return 1
    fi
    
    # Sanitizar nombre de función (solo permitir alfanuméricos, guiones y guiones bajos)
    if [[ ! "$func_name" =~ ^[a-zA-Z][a-zA-Z0-9_-]*$ ]]; then
        message -error "lazy_load_function: nombre de función inválido: $func_name"
        return 1
    fi
    
    # Validación de seguridad mejorada del path
    local normalized_file
    local project_root
    
    # Determinar project root de forma segura
    project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)" || {
        message -error "lazy_load_function: no se puede determinar el project root"
        return 1
    }
    
    # Validar que el path no contiene patrones peligrosos
    if [[ "$source_file" =~ \.\./|\.\.\\|~[/\\]|\$ ]]; then
        message -error "lazy_load_function: path contiene patrones peligrosos: $source_file"
        return 1
    fi
    
    # Convertir a path absoluto de forma segura
    if [[ "$source_file" = /* ]]; then
        normalized_file="$source_file"
    else
        normalized_file="$project_root/$source_file"
    fi
    
    # Normalizar el path de forma segura
    normalized_file="$(realpath -m "$normalized_file" 2>/dev/null)" || {
        message -error "lazy_load_function: path inválido: $source_file"
        return 1
    }
    
    # Verificar que el archivo existe, es regular y legible
    if [[ ! -f "$normalized_file" ]] || [[ ! -r "$normalized_file" ]]; then
        message -warning "lazy_load_function: archivo no encontrado o no legible: $normalized_file"
        return 1
    fi
    
    # Verificación de seguridad estricta: debe estar dentro del project root
    if [[ ! "$normalized_file" == "$project_root"* ]]; then
        message -error "lazy_load_function: archivo fuera del proyecto: $normalized_file"
        return 1
    fi
    
    # Verificar que el archivo es seguro (no contiene symlinks peligrosos)
    local file_dir
    file_dir="$(dirname "$normalized_file")"
    if [[ -L "$file_dir" ]]; then
        message -error "lazy_load_function: directorio padre es symlink: $file_dir"
        return 1
    fi
    
    # Crear un "stub" seguro que carga la función real cuando se ejecuta
    eval '
    '"$func_name"'() {
        # Descargar el stub
        unset -f '"$func_name"'
        # Cargar la función real de forma segura
        if [[ -f "'"$normalized_file"'" ]] && [[ -r "'"$normalized_file"'" ]]; then
            source "'"$normalized_file"'"
        else
            message -error "lazy_load_function: archivo ya no disponible: '"$normalized_file"'"
            return 1
        fi
        # Ejecutar la función con los argumentos originales
        '"$func_name"' "$@"
    }
    '
}

# ============================================================================
# FUNCIÓN: is_command_available
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
#   if is_command_available "fzf"; then
#       enable_fzf_features
#   fi

is_command_available() {
    local cmd="$1"
    local cache_file="/tmp/.shell-cmd-cache-${cmd}"
    
    # Usar cache si existe y es reciente (menos de 1 hora)
    if [[ -f "$cache_file" ]]; then
        local cache_age=$(($(date +%s) - $(stat -c %Y "$cache_file" 2>/dev/null || echo 0)))
        if [[ $cache_age -lt 3600 ]]; then
            return $(cat "$cache_file")
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
# FUNCIÓN: clear_command_cache
# ============================================================================
# Limpia la caché de comandos con opciones granulares
#
# Argumentos:
#   $1: Patrón a limpiar (opcional, por defecto todos)
#   $2: Forzar limpieza (opcional, --force para ignorar edad)
#
# Ejemplo:
#   clear_command_cache              # Limpia toda la caché
#   clear_command_cache "git"       # Limpia solo cache de comandos git*
#   clear_command_cache "" --force   # Fuerza limpieza de toda la caché

clear_command_cache() {
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
        message -success "Cache limpiada: $cleaned archivos liberados (${total_size} bytes)"
    else
        message -info "No se encontraron archivos de cache para limpiar"
    fi
}

# ============================================================================
# FUNCIÓN: get_cache_stats
# ============================================================================
# Muestra estadísticas de uso de la caché de comandos
#
# Argumentos:
#   Ninguno
#
# Ejemplo:
#   get_cache_stats

get_cache_stats() {
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
        echo "   💡 Ejecuta 'clear_command_cache' para limpiar archivos antiguos"
    fi
}

# ============================================================================
# FUNCIÓN: validate_directory_exists
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
#   if validate_directory_exists "$HOME/.local/bin" "/usr/local/bin"; then
#       message -success "Directorios válidos encontrados"
#   fi

validate_directory_exists() {
    for dir in "$@"; do
        [[ -d "$dir" ]] && return 0
    done
    return 1
}

# ============================================================================
# FUNCIÓN: parse_toml_section
# ============================================================================
# Parser TOML mejorado y seguro para extraer valores de una sección específica
#
# Argumentos:
#   $1: Path del archivo TOML
#   $2: Nombre de la sección (sin corchetes)
#   $3: Variable de salida para el array de valores (opcional)
#
# Retorno:
#   0: Éxito
#   1: Error
#
# Ejemplo:
#   parse_toml_section "deps.toml" "linux" deps_array
#   echo "${deps_array[@]}"
#
# Salida directa (si no se especifica variable de salida):
#   Imprime cada valor en una línea

parse_toml_section() {
    local toml_file="$1"
    local section_name="$2"
    local output_var="$3"
    
    # Validación de entrada
    if [[ -z "$toml_file" ]] || [[ -z "$section_name" ]]; then
        message -error "parse_toml_section: archivo y sección son requeridos"
        return 1
    fi
    
    # Validar que el archivo existe y es legible
    if [[ ! -f "$toml_file" ]] || [[ ! -r "$toml_file" ]]; then
        message -error "parse_toml_section: archivo no encontrado o no legible: $toml_file"
        return 1
    fi
    
    # Validar nombre de sección
    if [[ ! "$section_name" =~ ^[a-zA-Z][a-zA-Z0-9_-]*$ ]]; then
        message -error "parse_toml_section: nombre de sección inválido: $section_name"
        return 1
    fi
    
    # Variables locales
    local in_section=false
    local line_num=0
    local values=()
    
    # Procesar archivo línea por línea
    while IFS= read -r line || [[ -n "$line" ]]; do
        ((line_num++))
        
        # Eliminar espacios en blanco al inicio y final
        line="${line#"${line%%[![:space:]]*}"}"
        line="${line%"${line##*[![:space:]]}"}"
        
        # Saltar líneas vacías
        [[ -z "$line" ]] && continue
        
        # Detectar sección objetivo
        if [[ "$line" =~ ^\[""$section_name""\]$ ]]; then
            in_section=true
            continue
        fi
        
        # Si encontramos otra sección, terminar
        if [[ "$line" =~ ^\[.+\]$ ]] && [[ "$in_section" == true ]]; then
            break
        fi
        
        # Procesar líneas dentro de la sección
        if [[ "$in_section" == true ]]; then
            # Saltar comentarios (desde # hasta final de línea)
            if [[ "$line" =~ ^[[:space:]]*# ]]; then
                continue
            fi
            
            # Eliminar comentarios inline (después de # si no está entre comillas)
            if [[ "$line" =~ ^[^#]*# ]]; then
                # Verificar si el # está dentro de una cadena entrecomillada
                local temp_line="${line%%#*}"
                local quote_count
                quote_count=$(grep -o '"' <<< "$temp_line" | wc -l)
                
                if (( quote_count % 2 == 0 )); then
                    line="$temp_line"
                fi
            fi
            
            # Liminar espacios en blanco
            line="${line#"${line%%[![:space:]]*}"}"
            line="${line%"${line##*[![:space:]]}"}"
            
            # Saltar si quedó vacío después de limpiar
            [[ -z "$line" ]] && continue
            
            # Validar que no sea una asignación (clave = valor)
            if [[ "$line" =~ ^[a-zA-Z][a-zA-Z0-9_-]*[[:space:]]*= ]]; then
                # Extraer valor después del =
                local value="${line#*=}"
                # Limpiar espacios y comillas
                value="${value#"${value%%[![:space:]]*}"}"
                value="${value%"${value##*[![:space:]]}"}"
                value="${value#\"}"
                value="${value%\"}"
                value="${value#\'}"
                value="${value%\'}"
                [[ -n "$value" ]] && values+=("$value")
            else
                # Es un valor simple (solo el nombre del paquete/dependencia)
                values+=("$line")
            fi
        fi
    done < "$toml_file"
    
    # Manejo de salida
    if [[ -n "$output_var" ]]; then
        if declare -p "$output_var" 2>/dev/null | grep -q "declare -a"; then
            # Asignar al array existente
            eval "$output_var=(\"\${values[@]}\")"
        else
            # Crear nuevo array
            declare -ga "$output_var=(\"\${values[@]}\")"
        fi
    else
        # Imprimir valores
        printf '%s\n' "${values[@]}"
    fi
    
    return 0
}

# ============================================================================
# FUNCIÓN: parse_toml_key_value
# ============================================================================
# Parser TOML para extraer un valor específico de una sección
#
# Argumentos:
#   $1: Path del archivo TOML
#   $2: Nombre de la sección
#   $3: Nombre de la clave
#   $4: Variable de salida (opcional)
#
# Retorno:
#   0: Éxito
#   1: Error o clave no encontrada
#
# Ejemplo:
#   parse_toml_key_value "config.toml" "database" "host" db_host

parse_toml_key_value() {
    local toml_file="$1"
    local section_name="$2"
    local key_name="$3"
    local output_var="$4"
    
    # Validación de entrada
    if [[ -z "$toml_file" ]] || [[ -z "$section_name" ]] || [[ -z "$key_name" ]]; then
        message -error "parse_toml_key_value: archivo, sección y clave son requeridos"
        return 1
    fi
    
    # Validar que el archivo existe
    if [[ ! -f "$toml_file" ]] || [[ ! -r "$toml_file" ]]; then
        message -error "parse_toml_key_value: archivo no encontrado o no legible: $toml_file"
        return 1
    fi
    
    # Validar nombres
    if [[ ! "$section_name" =~ ^[a-zA-Z][a-zA-Z0-9_-]*$ ]] || [[ ! "$key_name" =~ ^[a-zA-Z][a-zA-Z0-9_-]*$ ]]; then
        message -error "parse_toml_key_value: nombres inválidos"
        return 1
    fi
    
    local in_section=false
    local line_num=0
    
    while IFS= read -r line || [[ -n "$line" ]]; do
        ((line_num++))
        
        # Limpiar línea
        line="${line#"${line%%[![:space:]]*}"}"
        line="${line%"${line##*[![:space:]]}"}"
        
        [[ -z "$line" ]] && continue
        
        # Detectar sección
        if [[ "$line" =~ ^\[""$section_name""\]$ ]]; then
            in_section=true
            continue
        fi
        
        # Salir si encontramos otra sección
        if [[ "$line" =~ ^\[.+\]$ ]] && [[ "$in_section" == true ]]; then
            break
        fi
        
        # Procesar líneas en la sección
        if [[ "$in_section" == true ]]; then
            # Saltar comentarios
            [[ "$line" =~ ^[[:space:]]*# ]] && continue
            
            # Buscar clave = valor
            if [[ "$line" =~ ^[[:space:]]*"$key_name"[[:space:]]*= ]]; then
                local value="${line#*=}"
                # Limpiar valor
                value="${value#"${value%%[![:space:]]*}"}"
                value="${value%"${value##*[![:space:]]}"}"
                
                # Eliminar comentarios inline
                if [[ "$value" =~ ^[^#]*# ]]; then
                    local temp_value="${value%%#*}"
                    local quote_count
                    quote_count=$(grep -o '"' <<< "$temp_value" | wc -l)
                    if (( quote_count % 2 == 0 )); then
                        value="$temp_value"
                    fi
                fi
                
                value="${value#"${value%%[![:space:]]*}"}"
                value="${value%"${value##*[![:space:]]}"}"
                
                # Quitar comillas
                value="${value#\"}"
                value="${value%\"}"
                value="${value#\'}"
                value="${value%\'}"
                
                # Asignar o imprimir valor
                if [[ -n "$output_var" ]]; then
                    printf -v "$output_var" '%s' "$value"
                else
                    printf '%s\n' "$value"
                fi
                
                return 0
            fi
        fi
    done < "$toml_file"
    
    # Clave no encontrada
    message -warning "parse_toml_key_value: clave '$key_name' no encontrada en sección '$section_name'"
    return 1
}

# ============================================================================
# CONFIGURACIÓN DE TRAP
# ============================================================================

trap cleanup_temp_files EXIT

# ============================================================================
# FIN DE LA LIBRERÍA
# ============================================================================
