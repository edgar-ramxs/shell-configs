# CHANGELOG.md - Historial de Cambios

## [5.2.0] - 2026-04-03
### Añadido
- Sistema de flags completo para setup.sh con gestión granular de dependencias:
  - `--shell <bash|zsh>` - Shell a configurar (default: bash)
  - `--with-deps-linux` - Paquetes Linux
  - `--with-deps-python` - Paquetes Python (pip)
  - `--with-deps-node` - Paquetes Node.js (npm)
  - `--with-deps-rust` - Paquetes Rust (cargo)
  - `--with-deps-go` - Paquetes Go (go install)
  - `--with-deps` - Todos los paquetes
  - `--with-repos` - Repositorios GitHub
  - `--with-backup` - Crear backup antes de instalar
  - `--validate` - Validar instalación
  - `--dry-run` - Simular
  - `--verbose` - Salida detallada
  - `--all` - Instalar todo
- Sistema de backup integrado:
  - Flag `--with-backup` crea backup de configuraciones
  - Backup en `${XDG_STATE_HOME}/shells-configs/backup/{timestamp}/`
  - Template `backupInfo.template` para metadata
  - Soporta dry-run
- Sistema de gestión de API keys con template:
  - `src/templates/keys.template` - Template con +50 variables de API keys
  - `src/config/keys` - Archivo para claves privadas (ignorado por git)
  - Importación automática en exports para todas las shells
- Funciones separadas para instalar cada tipo de dependencia (Linux, Python, Node, Rust, Go)
- Shell por defecto: bash (si no se especifica)

### Cambiado
- `setup.sh` ahora solo crea enlaces simbólicos por defecto (no instala nada automático)
- Dependencias Linux y repositorios Git son opt-in mediante flags
- `exports` actualizado: OSH y ZSH apuntan a `${XDG_DATA_HOME}/repositories/`
- Rutas corregidas: `DEPS_FILE` → `src/packages/dependencies.toml`, `SCRIPTS_DIR` → `src/bin/scripts`, `DRAWS_DIR` → `src/bin/draws`

### Fixed
- Eliminados paquetes duplicados en dependencies.toml
- Corregidas descripciones incorrectas (líneas con "QEMU KVM virtualization")
- Corregido show_banner() para usar `src/bin/draws/`

## [5.1.0] - 2026-04-03
### Añadido
- Variable `DOTFILES_DIR` en exports para todas las shells.
- Scripts de `src/bin/scripts/` disponibles en PATH automáticamente.
- Soporte para múltiples shells (bash/zsh) con enlaces simbólicos selectivos.

### Cambiado
- Estructura reorganizada: `src/` en lugar de `config/`, `local/`, `shells/`.
- `exports` ahora incluye PATH de scripts global.
- `.bashrc` y `.zshrc` ahora referencian archivos relativos a `DOTFILES_DIR`.

### Fixed
- Verificación de scripts en PATH después de cambios.

## [5.0.0] - 2026-02-21
### Añadido
- Soporte completo para XDG Base Directory.
- Nueva estructura modular en `source/`.
- Scripts de utilidad en `source/local/bin/`.
- Arte ASCII y animaciones en `source/local/ascii/`.
- Librería compartida `library.sh` para funciones comunes.
- Sistema de validación de dependencias con `check-deps`.
- Medición de rendimiento con `benchmark-startup`.

### Cambiado
- Refactorización completa de `setup.sh`.
- Documentación movida a `docs/` con nombres en mayúsculas.
- Mejora en la detección de distros y entornos WSL2.

## [4.0.0] - 2026-01-25
### Añadido
- Gestión inteligente de dependencias mediante `dependencies.toml`.
- Soporte para múltiples gestores de paquetes (apt, pacman, dnf).

## [1.0.0] - 2025-12-15
### Añadido
- Versión inicial con automatización básica de instalación.
