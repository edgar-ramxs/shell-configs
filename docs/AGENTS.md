# AGENTS.md - Guía Completa del Proyecto Shell-Configs

**Última Actualización:** 5 de abril de 2026  
**Status:** Production Ready ✅  
**Mantener Actualizado:** Después de cada cambio importante

---

## 📖 Tabla de Contenidos

1. [Visión General del Proyecto](#visión-general-del-proyecto)
2. [Arquitectura y Componentes](#arquitectura-y-componentes)
3. [Flujo Completo de Instalación](#flujo-completo-de-instalación)
4. [Estructura de Directorios](#estructura-de-directorios)
5. [Archivos Principales y Su Función](#archivos-principales-y-su-función)
6. [Configuración (dependencies.toml)](#configuración-dependenciestom)
7. [Procesos Clave](#procesos-clave)
8. [Estado de Calidad](#estado-de-calidad)
9. [Mejoras Implementadas Recientemente](#mejoras-implementadas-recientemente)
10. [Roadmap Futuro (Fases 6-9)](#roadmap-futuro-fases-6-9)
11. [Guía para Agentes de IA](#guía-para-agentes-de-ia)

---

## Visión General del Proyecto

### Propósito
**shell-configs** es un sistema de automatización modular para configurar shells (Bash/Zsh) en Linux, instalando dependencias, frameworks y configuraciones personalizadas de forma reproducible y XDG-compliant.

### Público Objetivo
- Usuarios técnicos que quieren setup automático de shells
- Desarrolladores que necesitan configuraciones reproducibles
- Administradores de sistemas para despliegues masivos

### Características Principales
- ✅ Instalación automática de dependencias por distro (apt, pacman, dnf)
- ✅ Clonado de repositorios GitHub (oh-my-zsh, oh-my-bash, powerlevel10k)
- ✅ Configuración XDG-compliant (respeta estándares de directorios)
- ✅ Sistema de backup/restore de configuraciones
- ✅ Lazy loading de funciones para startup rápido
- ✅ Caché de comandos con TTL
- ✅ Manejo robusto de errores
- ✅ Totalmente documentado

### Contexto Histórico
- **Fase 1:** Automatización de instalación
- **Fase 2:** Consolidación y optimización de estructura
- **Fase 4:** Gestión inteligente de dependencias
- **Fase 5:** Optimización de rendimiento (<10ms startup)
- **Fase 5+:** Revisión de código y preparación para distribución
- **Fase 6-9:** Mejoras futuras planeadas

---

## Arquitectura y Componentes

### Capas del Sistema

```
┌─────────────────────────────────────────────────────┐
│  Usuario Final                                      │
│  (Ejecuta: ./setup.sh)                              │
└────────────────────┬────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────┐
│  Capa de Orquestación                               │
│  setup.sh (890 líneas)                              │
│  • Detección de distro                              │
│  • Validación de requisitos                         │
│  • Coordinación de instalaciones                    │
└────────────────────┬────────────────────────────────┘
                     │
        ┌────────────┼────────────┐
        │            │            │
┌───────▼──┐  ┌─────▼──┐  ┌─────▼──────┐
│ Libs     │  │Config  │  │ Tools      │
│          │  │        │  │            │
│ lib.sh   │  │ exports│  │check-deps  │
│(498 ln)  │  │aliases │  │(371 ln)    │
│          │  │functns │  │            │
│functions │  │custom  │  │shell-cfg   │
│-heavy    │  │configs │  │(487 ln)    │
└──────────┘  └────────┘  └────────────┘
```

### Componentes Principales

**setup.sh** (559 líneas)
- Punto de entrada
- Detecta distro (Debian/Ubuntu, Arch, Fedora)
- Instala paquetes individuales
- Clona repositorios GitHub
- Configura frameworks
- Manejo de errores robusto
- Instalación de enlaces simbólicos

**src/lib/library.sh** (reutilizable)
- Funciones compartidas
- `message()` - Output formateado con colores
- `lazy_load_function()` - Lazy loading
- `is_command_available()` - Verificación de comandos
- `validate_directory_exists()` - Validación de directorios

**src/config/functions** 
- Funciones ligeras cargadas siempre
- `extract()` - Descompresión inteligente
- `mkcd()` - Crear y entrar a directorio
- Utilidades de uso frecuente

**src/bin/scripts/shell-config**
- Herramienta de gestión de configuraciones
- Comandos: backup, restore, copy, list, remove, clean, push, status
- Sistema de archivos comprimidos para backups

**src/bin/scripts/check-deps**
- Validador de dependencias
- Modos: default (verify), --install, --report, --check-missing
- Multi-distro support

---

## Flujo Completo de Instalación

### Secuencia de Ejecución

```
1. Usuario ejecuta: ./setup.sh
   │
   ├─ 2. Validar prerequisitos
   │  └─ ¿Git instalado?
   │
   ├─ 3. Setup XDG variables
   │  ├─ XDG_CONFIG_HOME
   │  ├─ XDG_DATA_HOME
   │  └─ Crear directorios
   │
   ├─ 4. Importar lib.sh
   │  └─ Cargar funciones compartidas
   │
   ├─ 5. Instalar dependencias Linux
   │  ├─ Parsear dependencies.toml [linux]
   │  ├─ Detectar package manager
   │  ├─ Instalar paquetes uno a uno
   │  └─ Reportar éxitos/fallos
   │
   ├─ 6. Instalar dependencias GitHub
   │  ├─ Parsear dependencies.toml [repositories]
   │  ├─ Clonar oh-my-zsh
   │  ├─ Clonar oh-my-bash
   │  ├─ Clonar powerlevel10k
   │  └─ Configurar automáticamente
   │
   ├─ 7. Instalar desde shells/
   │  ├─ Copiar shells/bash/.bashrc
   │  ├─ Copiar shells/zsh/.zshrc
   │  └─ Crear backups de archivos existentes
   │
   ├─ 8. Instalar scripts binarios
   │  ├─ Copiar local/bin/* → ~/.local/bin/
   │  └─ Hacer ejecutables (chmod +x)
   │
   ├─ 9. Instalar configuraciones
   │  ├─ Crear ~/.config/shell/
   │  ├─ Copiar config/exports
   │  ├─ Copiar config/aliases
   │  └─ Copiar config/functions
   │
   └─ 10. Resumen y siguiente paso
      └─ "Ejecute: source ~/.bashrc o source ~/.zshrc"
```

### Puntos Críticos de Fallo y Recuperación

**Si falla en Paso 5 (Dependencias Linux):**
- Sistema continúa intentando otros paquetes
- Reporta cuáles fallaron al final
- No afecta pasos siguientes

**Si falla en Paso 6 (Repositorios GitHub):**
- Continúa intentando otros repos
- Reporta cuáles no se pudieron clonar
- Sugiere revisar conexión de red

**Si falla en Paso 7-9 (Archivos):**
- Se crea backup de archivos existentes antes
- Los backups están en ~/.config/shell/backups/
- Recuperable con: `shell-config restore <timestamp>`

---

## Estructura de Directorios

```
shell-configs/
├── .git/                          # Repositorio Git
├── .gitignore
│
├── SETUP & MAIN
├── setup.sh                       # Script principal de instalación (559 líneas)
├── dependencies.toml              # Especificación de dependencias (TOML)
├── README.md                      # Documentación principal
│
├── CONFIG/
├── src/
│   ├── config/
│   │   ├── library.sh             # Librería compartida (reutilizable)
│   │   ├── exports                # Variables de entorno
│   │   ├── aliases                # Alias de shell
│   │   ├── functions              # Funciones ligeras
│   │   ├── editing                # Aliases para editar configs (window managers)
│   │   ├── cmd/
│   │   │   ├── cmd.arch.aliases   # Aliases específicos de Arch
│   │   │   ├── cmd.debian.aliases # Aliases específicos de Debian/Ubuntu
│   │   │   └── cmd.fedora.aliases # Aliases específicos de Fedora
│   │
│   ├── home/
│   │   ├── .profile               # Configuración de perfil
│   │   ├── .hushlogin             # Silenciar login
│   │   └── shells/
│   │       ├── bash/
│   │       │   ├── .bashrc        # Configuración de Bash
│   │       │   └── .bash_logout   #Logout de Bash
│   │       └── zsh/
│   │           ├── .zshrc         # Configuración de Zsh
│   │           └── .p10k.zsh      # Configuración de Powerlevel10k
│   │
│   ├── bin/
│   │   ├── scripts/               # Scripts ejecutables en PATH
│   │   │   ├── shell-config       # Gestor de configuraciones
│   │   │   ├── check-deps         # Validador de dependencias
│   │   │   └── [otros scripts]
│   │   │
│   │   ├── ascii/
│   │   │   ├── animations/        # Scripts de animaciones ASCII
│   │   │   ├── asciiarts/         # Artísticas ASCII
│   │   │   ├── colorsscripts/    # Scripts de colores
│   │   │   └── fetchinfo/         # Scripts de información del sistema
│   │   │
│   │   └── draws/                 # Dibujos ASCII
│   │
│   ├── packages/
│   │   └── dependencies.toml      # Definición de dependencias
│   │
│   └── templates/
│       └── backupInfo.template     # Template para backups
│
├── DOCUMENTATION/
├── docs/
│   ├── AGENTS.md                  # Este archivo
│   ├── CHANGELOG.md               # Historial de cambios
│   ├── CONTRIBUTING.md            # Guía de contribuciones
│   └── TROUBLESHOOTING.md         # Guía de problemas comunes
│
└── OTROS/
    └── [Archivos históricos]
```

---

## Archivos Principales y Su Función

### Archivos de Configuración

**dependencies.toml** (~50 líneas)
```toml
[linux]           # Paquetes para apt/pacman/dnf
[python]          # Paquetes para pip
[rust]            # Paquetes para cargo
[node]            # Paquetes para npm
[go]              # Paquetes para go
[repositories]    # URLs de repositorios GitHub
```

Cada sección tiene:
- Nombre del paquete
- Comentario con descripción
- Mapping automático entre distros (ej: fd-find vs fd)

### Archivos de Scripts

**setup.sh** - Flujo principal
- 890 líneas
- Funciones principales:
  - `setup_xdg_variables()` - Configurar directorios XDG
  - `check_distro()` - Detectar sistema operativo
  - `check_linux_dependencies()` - Verificar paquetes
  - `install_dependencies()` - Instalar paquetes
  - `install_github_dependencies()` - Clonar repositorios
  - `configure_oh_my_zsh()` - Setup de oh-my-zsh
  - `configure_oh_my_bash()` - Setup de oh-my-bash
  - `install_from_shells_dir()` - Copiar configuraciones
  - `install_from_local_bin()` - Copiar scripts

**config/lib.sh** - Utilidades compartidas
- 498 líneas
- Funciones:
  - `message()` - Output con colores (info, success, error, warning, title, subtitle)
  - `ensure_dir()` - Crear directorio con permisos
  - `is_command_available()` - Verificar si comando existe
  - `validate_directory_exists()` - Validar directorio
  - `lazy_load_function()` - Sistema de lazy loading
  - `get_distro()` - Detectar distro

**src/bin/scripts/shell-config** - Gestor de configuraciones
- 487 líneas
- Operaciones:
  - `backup_shell_configs()` - Crear backup comprimido
  - `restore_backup()` - Restaurar desde backup
  - `copy_repo_files()` - Copiar archivos del repo
  - `list_backups()` - Listar backups disponibles
  - `remove_backup()` - Eliminar backup específico
  - `clean_old_backups()` - Limpiar backups antiguos
  - `push_changes()` - Commit y push a Git
  - `show_status()` - Ver estado de Git

**src/bin/scripts/check-deps** - Validador de dependencias
- 371 líneas
- Modos:
  - default: Verificar dependencias
  - --install: Verificar e instalar
  - --report: Generar reporte
  - --check-missing: Solo mostrar lo que falta

### Archivos de Configuración de Usuario

**config/exports**
- Variables de entorno
- XDG paths
- PATH personalizado
- Historial de shell

**config/aliases**
- Alias comunes
- Atajos de navegación
- Alias de git
- Alias de herramientas

**config/functions**
- Funciones de uso frecuente
- Cargadas siempre al iniciar
- `extract()` - Descomprimir automáticamente
- `mkcd()` - Crear directorio y entrar

**config/functions-heavy**
- Funciones pesadas
- Cargadas bajo demanda (lazy loading)
- Operaciones menos frecuentes

---

## Configuración (dependencies.toml)

### Estructura y Propósito

El archivo `dependencies.toml` es el corazón de la instalación. Define:
- Qué paquetes instalar
- De dónde clonar repositorios
- Mappings entre nombres de paquetes en distros diferentes

### Secciones

**[linux]** - Paquetes del sistema
```toml
[linux]
git       # Version control
curl      # URL transfer tool
jq        # JSON processor
lsd       # Modern ls replacement
bat       # Better cat with syntax highlighting
fzf       # Fuzzy finder
ripgrep   # Fast grep alternative
fd-find   # User-friendly find
exa       # Modern ls with git support
tldr      # Simplified man pages
```

Instalador automáticamente selecciona según distro:
- Ubuntu/Debian → apt install
- Arch/Manjaro → pacman -S
- Fedora/RHEL → dnf install

**[repositories]** - Repositorios GitHub
```toml
[repositories]
https://github.com/ohmyzsh/ohmyzsh.git
https://github.com/ohmybash/oh-my-bash.git
https://github.com/romkatv/powerlevel10k.git
```

Clonado automáticamente a:
- `~/.local/share/oh-my-zsh/`
- `~/.local/share/oh-my-bash/`
- `~/.local/share/oh-my-zsh/custom/themes/powerlevel10k/`

### Agregar Nuevas Dependencias

**Para agregar un paquete:**
```toml
[linux]
nuevo-paquete    # Descripción del paquete
```

**Para agregar un repositorio:**
```toml
[repositories]
https://github.com/usuario/repo.git
```

**Para agregar paquete con diferentes nombres en distros:**
```bash
# En check-deps, función get_package_name():
case "$dep" in
    "fd-find")
        case "$DISTRO" in
            arch) echo "fd" ;;
            debian) echo "fd-find" ;;
        esac
        ;;
esac
```

---

## Procesos Clave

### Proceso 1: Detección de Distro

```bash
Entrada: Sistema operativo del usuario
  ↓
Leer /etc/os-release
  ↓
Extraer: ID (ubuntu, arch, fedora, etc.)
  ↓
Normalizar: Familia de distros
  - ubuntu/debian/linuxmint → debian
  - arch/manjaro/endeavoros → arch
  - fedora/rhel/centos → fedora
  ↓
Salida: DISTRO variable
```

**Ubicación:** setup.sh líneas 100-150
**Fallback:** Si falla, intenta lsb_release
**Criticidad:** ALTA - afecta selección de package manager

### Proceso 2: Instalación de Paquetes

```bash
Entrada: Lista de paquetes, DISTRO detectada
  ↓
Validar git disponible
  ↓
Parsear dependencies.toml [linux]
  ↓
Para cada paquete:
  ├─ Mapear nombre según distro
  ├─ Intenta instalar
  ├─ Si éxito: agregar a lista exitosos
  └─ Si fallo: agregar a lista fallidos
  ↓
Reporte: Resumen de éxitos/fallos
  ↓
Salida: Retorna 0 si todos éxito, 1 si algunos fallaron
```

**Ubicación:** setup.sh líneas 391-512
**Crítico:** Continúa aunque alguns fallen
**Timeout:** sleep 1 entre cada paquete para estabilidad

### Proceso 3: Clonado de Repositorios

```bash
Entrada: Lista de URLs de repositorios
  ↓
Validar git disponible ← CRÍTICO
  ↓
Parsear dependencies.toml [repositories]
  ↓
Para cada repositorio:
  ├─ Extraer nombre (basename)
  ├─ Determinar destino según nombre
  ├─ Si ya existe: reportar y saltar
  ├─ Si no existe:
  │  ├─ Crear directorio padre
  │  ├─ Clonar con git clone
  │  ├─ Si éxito: configurar framework
  │  └─ Si fallo: agregar a lista fallidos
  │
  └─ Configurar framework:
     ├─ Si oh-my-zsh: ejecutar configure_oh_my_zsh()
     ├─ Si oh-my-bash: ejecutar configure_oh_my_bash()
     └─ Si powerlevel10k: reportar para config manual
  ↓
Reporte: Resumen de repositorios
  ↓
Salida: Retorna 0 si todos éxito, 1 si algunos fallaron
```

**Ubicación:** setup.sh líneas 178-280
**Mejora Reciente:** Ahora continúa si un repo falla
**Error Handling:** Acumula fallos, reporta al final

### Proceso 4: Lazy Loading de Funciones

```bash
En ~/.zshrc o ~/.bashrc:
  ↓
source ~/.config/shell/functions
  ↓
Función lazy_load_function() es definida
  ↓
Usuario llama función pesada: backup_configs
  ↓
lazy_load_function detecta que no está cargada
  ↓
Busca en config/functions-heavy
  ↓
Sourcea el archivo específico
  ↓
Ejecuta la función
  ↓
Siguiente vez que la llame: está ya en memoria
```

**Ventaja:** Startup ~10ms vs ~100ms sin lazy loading
**Ubicación:** config/lib.sh líneas 300-350

### Proceso 5: Sistema de Backups

```bash
Usuario ejecuta: shell-config backup
  ↓
Crear directorio temporal
  ↓
Copiar archivos a hacer backup:
  ├─ ~/.bashrc
  ├─ ~/.zshrc
  ├─ ~/.bash_logout
  ├─ ~/.p10k.zsh
  ├─ ~/.config/shell/
  ├─ ~/.local/bin/
  └─ Historiales
  ↓
Crear metadata (fecha, sistema, usuario, etc.)
  ↓
Comprimir con tar gzip
  ↓
Guardar en ~/.config/shell/backups/
  ↓
Salida: Archivo backup_TIMESTAMP.tar.gz
```

**Recuperación:**
```bash
shell-config restore TIMESTAMP
  ↓
Crea nuevo backup antes (seguridad)
  ↓
Extrae backup old
  ↓
Copia archivos a su lugar
  ↓
Restauración completa
```

---

## Estado de Calidad

### Validación Reciente (25 Enero 2026)

**Problemas Encontrados:** 22  
**Problemas Corregidos:** 22 (100%)

### Errores de Sintaxis
✅ **shellcheck setup.sh** → 0 errores, 0 warnings  
✅ **shellcheck local/bin/check-deps** → 0 errores, 0 warnings  
✅ **bash -n local/bin/shell-config** → Sintaxis válida

### Categorías de Correcciones

**Críticos (3):**
- ✅ Indentación en clonado de repositorios
- ✅ Falta validación de git
- ✅ Error handling no robusto

**Calidad (19):**
- ✅ SC2155: Declare & assign (8 instancias)
- ✅ SC2034: Variables no usadas (6 instancias)
- ✅ SC2046: Quote subshell (3 instancias)
- ✅ SC2088: Tilde en quotes (1 instancia)
- ✅ SC2295: Pattern matching (1 instancia)

### Cobertura de Tests
⚠️ **No hay tests automatizados aún**  
→ Planeado para Fase 9

### Documentación
✅ **README.md** - Completo (1500+ líneas)  
✅ **inline comments** - Buena cobertura  
✅ **Function documentation** - Presente  
⚠️ **API documentation** - Minimal

---

## Mejoras Implementadas Recientemente

### Fase 5 (Rendimiento)
- ✅ Lazy loading de funciones
- ✅ Sistema de caché con TTL
- ✅ Startup optimizado (<10ms)

### Fase 5+ (Revisión de Código)
- ✅ Validación de git antes de clonar
- ✅ Error handling robusto (continúa si algo falla)
- ✅ Limpieza de código muerto
- ✅ Todas las correcciones de shellcheck
- ✅ Documentación exhaustiva

### Fase 6 (Quick Wins)
- ✅ Scripts en PATH (src/bin/scripts/)
- ✅ Variable DOTFILES_DIR en exports
- ✅ Estructura de directorios actualizada (src/ en lugar de config/, local/)

### Fase 7 (Refactorización setup.sh)
- ✅ Sistema de flags completo con gestión granular de dependencias:
  - `--shell <bash|zsh>` - Shell a configurar
  - `--with-deps-linux` - Paquetes Linux
  - `--with-deps-python` - Paquetes Python
  - `--with-deps-node` - Paquetes Node.js
  - `--with-deps-rust` - Paquetes Rust
  - `--with-deps-go` - Paquetes Go
  - `--with-deps` - Todos los paquetes
  - `--with-repos` - Repositorios GitHub
  - `--all` - Instalar todo
- ✅ Sistema de backup integrado:
  - Flag `--with-backup` crea backup de configuraciones
  - Backup en `${XDG_STATE_HOME}/shells-configs/backup/{timestamp}/`
  - Template `backupInfo.template` para metadata
  - Soporta dry-run
- ✅ Sistema de gestión de API keys:
  - `src/templates/keys.template` - Template con +50 variables
  - `src/config/keys` - Archivo privado (ignorado por git)
- ✅ Variables SHELL_CONFIGS_DIR y DOTFILES_DIR actualizadas
- ✅ Rutas actualizadas para usar SHELL_CONFIGS_DIR
- ✅ Aliases específicos por distribución (cmd.*.aliases)
- ✅ Sistema de carga centralizado en bashrc/zshrc
  - Importación automática en exports
- ✅ dependencies.toml limpiado (eliminados duplicados, corregidas descripciones)
- ✅ Rutas actualizadas (DEPS_FILE, SCRIPTS_DIR, DRAWS_DIR)
- ✅ export OSH/ZSH apuntan a ${XDG_DATA_HOME}/repositories/

---

## Roadmap Futuro (Fases 6-9)

### Fase 6: Quick Wins (1-2 semanas)
**Impacto Alto + Esfuerzo Bajo**

1. **Logging Centralizado**
   - Guardar logs en `~/.cache/shells-configs/`
   - Timestamps en cada evento
   - Fácil debugging

2. **Modo Verbose**
   - Flag `--verbose` en setup.sh
   - Ver output completo de comandos
   - Útil para debugging

3. **Pre-check de Requisitos**
   - Validar git, curl, tar
   - Verificar permisos sudo
   - Fail-fast ante problemas

4. **Validación Post-Instalación**
   - Checklist de qué debería existir
   - Reportar qué falta
   - Confirmación de éxito

5. **Documentación Auto-generada**
   - Generar docs de dependencies.toml
   - Lista de paquetes con descripciones
   - Información de alternativas

6. **Scripts en PATH** ✅ (COMPLETADO)
   - Variable DOTFILES_DIR en exports
   - Scripts de src/bin/scripts/ disponibles en PATH
   - Funciona para todas las shells (bash/zsh)

### Fase 7: Robustez (2-3 semanas)
**Impacto Medio + Esfuerzo Medio**

1. **Mejor Detección de Distros**
   - Detectar versiones específicas
   - Mappings precisos de paquetes
   - Soporte para más distros derivadas

2. **Validación de Permisos**
   - Verificar antes de escribir
   - Mensajes claros sobre qué falta
   - Solicitar elevación cuando necesario

3. **Rollback Inteligente**
   - Track de cambios realizados
   - Deshacer en orden inverso si falla
   - Sistema consistente después de error

### Fase 8: UX (3-4 semanas)
**Impacto Alto + Esfuerzo Alto**

1. **Sistema de Profiles**
   - minimal, standard, full
   - Instalación personalizable
   - Presets para diferentes casos de uso

2. **Instalador One-Liner**
   - `curl -sSL ... | bash`
   - Instalación super simple
   - Mejor experiencia inicial

3. **Configuración Interactiva**
   - Wizard de setup
   - Preguntas step-by-step
   - TUI para usuarios no técnicos

### Fase 9: Quality (2-3 semanas)
**Impacto Medio + Esfuerzo Alto**

1. **Test Suite**
   - Tests unitarios para funciones
   - Tests de integración de instalación
   - CI/CD pipeline

2. **Package Distribution**
   - AUR para Arch
   - Homebrew para macOS
   - DEB/RPM packages

---

## Guía para Agentes de IA

### Para Agentes que Leen Este Documento

Este archivo es **el source of truth** del proyecto. Úsalo cuando:
- Necesites entender la arquitectura
- Quieras saber qué hace cada componente
- Requieras contexto del proyecto completo
- Tengas que hacer cambios significativos

### Mantenimiento

**Actualizar este archivo cuando:**
- Se completa una nueva fase
- Se cambia la arquitectura
- Se modifica un proceso clave
- Se agregan nuevas funcionalidades
- Se descubren problemas importantes

**NO actualizar cuando:**
- Son cambios menores (typos, comentarios inline)
- Son cambios en docs/ específicos
- Son cambios en funciones auxiliares

### Proceso para Agentes

**Al recibir una tarea:**
1. Lee la sección relevante aquí
2. Entiende el contexto del proyecto
3. Identifica qué archivos afecta
4. Planifica cambios considerando consecuencias
5. Después: Actualiza AGENTS.md si es significativo

**Al hacer cambios importantes:**
1. Actualiza AGENTS.md
2. Actualiza archivo específico en docs/ si es necesario
3. Mantén código y documentación sincronizados

**Si algo no está claro:**
1. Busca en docs/ archivos específicos
2. Busca en README.md del proyecto
3. Busca comentarios inline en código
4. Si aún no está claro, actualiza AGENTS.md para futuras agentes

### Ejemplo de Uso

**Tarea:** Agregar soporte para Fish shell

1. **Lee aquí:**
   - "Visión General" → Entiende propósito
   - "Arquitectura" → Identifica qué cambiar
   - "Procesos Clave" → Entiende flujo
   - "dependencies.toml" → Cómo agregar

2. **Haz cambios en:**
   - setup.sh → Agregar configuración
   - dependencies.toml → Agregar paquetes
   - config/ → Copiar .fishrc
   - docs/CODE_REVIEW.md → Documentar cambio

3. **Actualiza AGENTS.md:**
   - Sección "Arquitectura" → Agregar Fish
   - Sección "Procesos Clave" → Actualizar flujo
   - Sección "Archivos Principales" → Documentar cambios

---

## Conclusión

Shell-configs es un proyecto maduro, bien documentado y production-ready. 

**Estado:** ✅ Production Ready  
**Confiabilidad:** Alta  
**Mantenibilidad:** Excelente  
**Escalabilidad:** Buena

Uso este documento como tu guía completa del proyecto. ¡Adelante!

---

**Último Update:** 3 de abril de 2026  
**Próximo Update:** Después de cambios significativos

