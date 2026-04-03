# Shell Configurations

Configuraciones modernas para Bash/Zsh con instalación automatizada, gestión granular de dependencias y soporte multi-distribución.

## 🚀 Inicio Rápido

### 1. Clonar el repositorio

```bash
git clone https://github.com/edgar-ramxs/shell-configs.git ~/.dotfiles/shell-configs
```

### 2. Ejecutar instalación

```bash
cd ~/.dotfiles/shell-configs
./setup.sh install

# Instalación completa (paquetes + repos + backup)
./setup.sh install --all

# Ver todas las opciones
./setup.sh help
```

---

## 📋 Características

- ⚡ **Rendimiento optimizado** (<10ms startup)
- 🔧 **Gestión granular de dependencias** por tecnología (Linux, Python, Node, Rust, Go)
- 📁 **Estructura XDG-compliant** (respeta estándares de directorios)
- 🖥️ **Soporte para Bash y Zsh** con selección flexible
- 🔄 **Instalación dry-run** para simular sin ejecutar
- 📦 **Repositorios clonables** (oh-my-zsh, oh-my-bash, powerlevel10k)

## 📁 Estructura del Proyecto

```
~/.dotfiles/
└── shell-configs/                         # Este repositorio
    ├── setup.sh                           # Script de instalación principal
    ├── .gitignore                         # Archivos ignorados
    ├── README.md                          # Este archivo
    └── src/
        ├── packages/
        │   └── dependencies.toml          # Definición de dependencias
        ├── config/
        │   ├── library.sh                 # Librería compartida
        │   ├── exports                    # Variables de entorno
        │   ├── aliases                    # Alias de shell
        │   ├── functions                  # Funciones utilitarias
        │   └── keys                       # Claves API (opcional)
        ├── home/
        │   ├── .profile                   # Configuración de perfil
        │   ├── .hushlogin                 # Silenciar login
        │   └── shells/
        │       ├── bash/
        │       │   ├── .bashrc            # Configuración de Bash
        │       │   └── .bash_logout       # Logout de Bash
        │       └── zsh/
        │           ├── .zshrc             # Configuración de Zsh
        │           └── .p10k.zsh          # Configuración de Powerlevel10k
        ├── bin/
        │   ├── scripts/                   # Herramientas CLI
        │   ├── ascii/                     # Arte ASCII y animaciones
        │   └── draws/                     # Dibujos ASCII
        └── templates/
            ├── backupInfo.template        # Template para backups
            └── keys.template              # Template para API keys
```

## 🛠️ Uso de setup.sh

### Comandos

```bash
./setup.sh install      # Instalar enlaces (por defecto: bash)
./setup.sh uninstall    # Eliminar enlaces
./setup.sh update       # Actualizar submódulo
./setup.sh push         # Guardar cambios en git
./setup.sh help         # Mostrar ayuda
```

### Flags de Shell

```bash
--shell bash          # Configurar Bash (por defecto)
--shell zsh           # Configurar Zsh
```

### Flags de Paquetes (granular)

```bash
--with-deps-linux    # Paquetes Linux (apt/pacman/dnf)
--with-deps-python   # Paquetes Python (pip)
--with-deps-node     # Paquetes Node.js (npm)
--with-deps-rust     # Paquetes Rust (cargo)
--with-deps-go       # Paquetes Go (go install)
--with-deps          # TODOS los paquetes (linux + python + node + rust + go)
```

### Flags de Repositorios

```bash
--with-repos         # Clonar oh-my-zsh, oh-my-bash, powerlevel10k
```

### Flags de Instalación

```bash
--with-backup        # Crear backup antes de instalar
--validate           # Validar instalación
--dry-run            # Simular sin hacer cambios
--verbose, -v        # Salida detallada
--all                # Instalar todo (paquetes + repos + validate)
```

### Ejemplos

```bash
# Solo enlaces simbólicos (bash)
./setup.sh install

# Enlaces para zsh
./setup.sh install --shell zsh

# Solo paquetes Linux
./setup.sh install --with-deps-linux

# Python + Node
./setup.sh install --with-deps-python --with-deps-node

# Todos los paquetes
./setup.sh install --with-deps

# Paquetes + repos
./setup.sh install --with-deps --with-repos

# Instalación completa
./setup.sh install --all

# Simular instalación
./setup.sh install --dry-run --verbose
```

### Sistema de Backup

```bash
# Crear backup antes de instalar
./setup.sh install --with-backup

# El backup se guarda en:
# ${XDG_STATE_HOME}/shells-configs/backup/{timestamp}/
# Por defecto: ~/.local/state/shells-configs/backup/
```

Archivos respaldados:
- `~/.bashrc`, `~/.zshrc`, `~/.bash_logout`
- `~/.p10k.zsh`, `~/.profile`, `~/.hushlogin`

El sistema:
- Detecta archivos reales (omite enlaces simbólicos)
- Copia a directorio con timestamp
- Genera `backupInfo.template` con metadata

## 📦 Dependencias Soportadas

### Linux (apt/pacman/dnf)
lsd, bat, fzf, ripgrep, fd-find, exa, tldr, zsh, bash, nodejs, npm, python3, rustc, cargo, git, jq, curl, wget, y más (~100 paquetes)

### Python (pip)
pip, pipx, setuptools, virtualenv, pillow, requests, rembg, argparse

### Node.js (npm)
typescript, ts-node, yarn, pnpm, deno, eslint, prettier, @openai/codex, @google/gemini-cli, opencode-ai

### Rust (cargo)
Paquetes Rust del archivo TOML

### Repositorios Git
- oh-my-zsh (Framework para Zsh)
- oh-my-bash (Framework para Bash)
- powerlevel10k (Tema para Zsh)

## 🛠️ Herramientas Incluidas

### Scripts en [`src/bin/scripts/`](src/bin/scripts/)

| Script | Descripción |
|--------|-------------|
| `shell-config` | Gestor de configuración (backup, restore, copy) |
| `check-deps` | Verificador de dependencias |
| `benchmark-startup` | Mide el tiempo de inicio del shell |
| `give-me-ascii` | Muestra arte ASCII |
| `packages-search` | Busca paquetes en distribuciones |
| `ytdlp-downloader` | Descargador de YouTube |
| `download-fonts` | Descarga fuentes Nerd Fonts |
| `optimize-completions` | Optimiza completions |
| `variables-env` | Gestor de variables de entorno |
| `which-system` | Detecta el sistema operativo |

### Arte ASCII en [`src/bin/ascii/`](src/bin/ascii/)

- **Animaciones:** pipes, pipe-diagonal, rain, snow
- **ASCII Arts:** burger, pacman, pokemon, pizza, taco, etc.
- **Scripts de color:** arch, debian, ubuntu, spectrum, etc.
- **Fetch:** fetching, sysfetch, zfetch

## 🎨 Personalización

### Configurar aliases
Edita [`src/config/aliases`](src/config/aliases) para agregar tus propios aliases.

### Configurar funciones
Edita [`src/config/functions`](src/config/functions) para agregar funciones personalizadas.

### Configurar entorno
Edita [`src/config/exports`](src/config/exports) para variables de entorno.

### Claves API (opcional)
El archivo [`src/config/keys`](src/config/keys) está ignorado por [`.gitignore`](.gitignore) para proteger tus claves privadas.

```bash
# 1. Copia el template
cp src/templates/keys.template src/config/keys

# 2. Edita tus claves
vim src/config/keys
```

El template incluye claves para:
- **AI Providers:** OpenAI, Anthropic, Google, Groq, Mistral, Hugging Face, Replicate, Cohere
- **Cloud:** AWS, Azure, Google Cloud
- **Dev Tools:** Stripe, Twilio, SendGrid, Datadog, Sentry
- **Databases:** MongoDB, PostgreSQL, Redis, Supabase, Neon
- **APIs Públicas:** OpenWeather, WeatherAPI, NewsAPI
- **Social:** Spotify, Discord, Twitter
- **Y más...**

Las variables se importan automáticamente en [`exports`](src/config/exports) para todas las shells.

## 📚 Documentación

- [`docs/AGENTS.md`](docs/AGENTS.md) - Guía completa del proyecto para agentes IA
- [`docs/CHANGELOG.md`](docs/CHANGELOG.md) - Historial de cambios
- [`docs/CONTRIBUTING.md`](docs/CONTRIBUTING.md) - Guía de contribuciones
- [`docs/TROUBLESHOOTING.md`](docs/TROUBLESHOOTING.md) - Solución de problemas

---

**Versión:** 5.2.0  
**Estado:** ✅ Production Ready  
**Última actualización:** Abril 2026