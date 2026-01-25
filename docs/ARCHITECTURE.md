# Arquitectura del Proyecto - Shell-Configs

**Documento Técnico de Estructura y Componentes**

---

## 📐 Arquitectura General

```
┌─────────────────────────────────────────────────┐
│  Usuario Final (./setup.sh)                    │
└────────────────┬────────────────────────────────┘
                 │
┌────────────────▼────────────────────────────────┐
│  Capa de Orquestación                           │
│  setup.sh (890 líneas)                          │
│  • Detección de distro/shell                    │
│  • Coordinación de instalaciones                │
└────────────────┬────────────────────────────────┘
                 │
    ┌────────────┼────────────┐
    │            │            │
┌───▼──┐  ┌─────▼──┐  ┌─────▼──────┐
│ Libs │  │ Config │  │ Herramientas│
│      │  │        │  │            │
│lib.sh│  │exports │  │check-deps  │
│      │  │aliases │  │shell-config│
└──────┘  │functns │  └────────────┘
          └────────┘
```

---

## 📁 Estructura de Directorios

### Raíz del Proyecto
- **setup.sh** - Script de instalación (890 líneas, point of entry)
- **dependencies.toml** - Especificación de dependencias
- **README.md** - Guía de inicio rápido

### config/ - Configuraciones
- **lib.sh** (498 líneas) - Funciones compartidas
- **exports** - Variables de entorno y PATH
- **aliases** - Atajos de comando
- **functions** (368 líneas) - Funciones ligeras
- **functions-heavy** (214 líneas) - Funciones pesadas (lazy-loaded)

### shells/ - Configuraciones de Shell
```
shells/
├── bash/
│   ├── .bashrc      # Configuración Bash
│   └── .bash_logout
└── zsh/
    ├── .zshrc       # Configuración Zsh
    └── .p10k.zsh    # Powerlevel10k theme
```

### local/bin/ - Scripts y Herramientas
- **shell-config** (487 líneas) - Gestor de configuraciones
- **check-deps** (371 líneas) - Validador de dependencias
- **download-fonts** - Descargador de fuentes
- **ytdlp_downloader** - Descargador de videos
- Otros scripts auxiliares

### local/ascii/ - Contenido ASCII
```
local/ascii/
├── animations/      # Animaciones ASCII (pipes, rain, snow)
├── asciiarts/       # Artísticas ASCII
├── colorsscripts/   # Scripts de colores y test
└── fetchinfo/       # Scripts de información del sistema
```

### docs/ - Documentación
- **AGENTS.md** - Guía para agentes de IA
- **ARCHITECTURE.md** - Este archivo
- **PROCESSES.md** - Procesos clave y flujos
- **TROUBLESHOOTING.md** - Solución de problemas
- **REFERENCE.md** - Referencia rápida
- **PROJECT_STATUS.md** - Roadmap y estado

---

## 🔧 Componentes Principales

### setup.sh - Orquestador Principal

**Responsabilidades:**
- Detectar sistema (distro, shell, WSL2)
- Parsear dependencies.toml
- Instalar paquetes del sistema
- Clonar repositorios GitHub
- Configurar frameworks (oh-my-zsh, oh-my-bash)
- Copiar configuraciones
- Crear backups

**Secciones Clave:**
1. Setup XDG variables (líneas 10-100)
2. Detección del sistema (líneas 100-160)
3. Gestión de dependencias (líneas 163-570)
4. Backup de archivos (líneas 728-790)
5. Instalación de configuraciones (líneas 790-880)
6. Validación post-instalación (líneas 880-950)

### config/lib.sh - Librería Compartida

**Funciones Clave:**
- `message()` - Output formateado con colores
- `ensure_dir()` - Crear directorios seguros
- `lazy_load_function()` - Sistema de lazy loading
- `is_command_available()` - Verificar comando
- `validate_directory_exists()` - Validar directorio

**Propósito:** Centralizar utilidades para reutilización

### local/bin/shell-config - Gestor de Configs

**Comandos:**
- `backup` - Crear backup comprimido
- `restore` - Restaurar desde backup
- `copy` - Copiar configuraciones
- `list` - Listar backups
- `remove` - Eliminar backup
- `clean` - Limpiar backups antiguos
- `push` - Git commit/push
- `status` - Estado de Git

**Almacenamiento:** ~/.config/shell/backups/

### local/bin/check-deps - Validador de Deps

**Modos:**
- Default: Verificar dependencias
- `--install`: Instalar faltantes
- `--report`: Generar reporte
- `--check-missing`: Solo mostrar faltantes

**Soporta:**
- Diferentes package managers por distro
- Mapeo de nombres (fd-find → fd en Arch)
- Validación sin destruir sistema

---

## 🔄 Flujo de Instalación

```
1. Usuario ejecuta: ./setup.sh
   ↓
2. Validar prerequisites (git, bash, etc.)
   ↓
3. Setup XDG variables (HOME/.config, HOME/.local/share)
   ↓
4. Importar lib.sh (funciones compartidas)
   ↓
5. Detectar sistema (distro, shell, WSL2)
   ↓
6. Crear backup de archivos existentes
   ↓
7. Instalar dependencias del sistema (apt/pacman/dnf)
   ↓
8. Instalar repositorios GitHub (oh-my-zsh, powerlevel10k)
   ↓
9. Copiar configuraciones (bash/zsh RC files)
   ↓
10. Copiar scripts binarios (~/.local/bin/)
    ↓
11. Validar instalación
    ↓
12. Mostrar resumen y próximos pasos
```

---

## 🎯 Decisiones Arquitectónicas

### 1. **XDG Compliant**
- Respeta estándares FreeDesktop
- Configaciones en `~/.config/shell/`
- Datos en `~/.local/share/`
- Cachés en `~/.cache/`

### 2. **Shell-Agnostic donde Posible**
- config/exports usa `#!/bin/sh` (compatible)
- lib.sh es sourced por bash y zsh
- Detección automática de shell actual

### 3. **Error Handling Robusto**
- Continúa si un paquete falla
- Valida comandos antes de ejecutar
- Backups antes de cambios

### 4. **Lazy Loading para Performance**
- Funciones pesadas cargadas bajo demanda
- Startup < 10ms
- `lazy_load_function()` en lib.sh

### 5. **Centralización de Configuración**
- dependencies.toml único punto de verdad
- Mapeos de paquetes en un lugar
- Fácil actualizar dependencias

### 6. **Multi-Distro Support**
- Detección automática de distro
- Mapeos de nombres de paquetes
- Comandos específicos por PM (apt/pacman/dnf)

---

## 📊 Estadísticas del Código

| Componente | Líneas | Propósito |
|-----------|--------|----------|
| setup.sh | 890 | Orquestación principal |
| config/lib.sh | 498 | Funciones compartidas |
| config/functions | 368 | Funciones ligeras |
| config/functions-heavy | 214 | Funciones pesadas |
| local/bin/shell-config | 487 | Gestor de configs |
| local/bin/check-deps | 371 | Validador de deps |
| **Total Scripts** | **2,828** | **Código activo** |

---

## 🔐 Seguridad

**Medidas Implementadas:**
- Validación de directorios antes de escritura
- Backups automáticos antes de cambios
- Verificación de git antes de clonar
- Permisos apropiados (chmod +x solo para scripts)
- No ejecuta comandos no autorizados

---

## ⚡ Performance

**Optimizaciones:**
- Lazy loading de funciones pesadas
- PATH construido sin duplicados
- Startup time < 10ms
- Cachés con TTL para comandos frecuentes

---

## 📝 Mantenibilidad

**Características:**
- Código bien comentado
- Funciones pequeñas y específicas
- Nombres descriptivos
- Estructura predecible
- Centralización de lógica común

---

**Última Actualización:** 25 de enero de 2026
