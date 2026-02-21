# Shell Configurations Repository

Configuraciones modernas y optimizadas para Bash/Zsh con instalación automatizada, validación de dependencias y soporte multi-distribución.

## 🚀 Inicio Rápido

```bash
bash setup.sh
```

## 📚 Documentación

**Toda la documentación está organizada en la carpeta [`docs/`](docs/).**

- [`docs/AGENTS.md`](docs/AGENTS.md) - Guía completa del proyecto
- [`docs/CHANGELOG.md`](docs/CHANGELOG.md) - Historial de cambios
- [`docs/CONTRIBUTING.md`](docs/CONTRIBUTING.md) - Guía de contribuciones
- [`docs/TROUBLESHOOTING.md`](docs/TROUBLESHOOTING.md) - Solución de problemas

## 📋 Características

- ✨ Configuraciones optimizadas para **Bash** y **Zsh**
- 🚀 Instalación automatizada multiplataforma (Linux/WSL2)
- ⚡ Rendimiento optimizado (<10ms startup)
- 🔄 Gestión inteligente de dependencias
- 💾 Backups automáticos de configuración
- 🎨 Banner ASCII en el inicio
- 📦 Funciones útiles precargadas
- 🎯 Salida formateada y legible

## 📁 Estructura del Proyecto

```
shell-configs/
├── setup.sh                    # Script de instalación principal
├── .gitignore                  # Archivos para ignorar de Git
├── dependencies.toml           # Dependencias del proyecto
├── README.md                   # Este archivo
├── source/
│   ├── config/                 # Archivos de configuración
│   │   ├── aliases             # Aliases globales
│   │   ├── exports             # Variables de entorno
│   │   ├── functions           # Funciones utilitarias
│   │   └── library.sh          # Librería compartida
│   ├── console/                # Banners ASCII
│   │   └── banner.txt          # Banner principal
│   ├── home/                   # Configuraciones home (vacío por defecto)
│   ├── local/                  # Herramientas y scripts
│   │   ├── ascii/              # Arte ASCII
│   │   │   ├── animations/     # Animaciones (pipe, rain, snow)
│   │   │   ├── asciiarts/      # Arte ASCII (pizza, pacman, pokemon)
│   │   │   ├── colorsscripts/  # Scripts de color
│   │   │   └── fetchinfo/      # Scripts de system info
│   │   ├── bin/                # Herramientas CLI (check-deps, shell-config, etc.)
│   │   └── draws/              # Dibujos en formato .txt
│   ├── shells/                 # Configuraciones de shells
│   │   ├── bash/               # .bashrc, .bash_logout
│   │   └── zsh/                # .zshrc, .p10k.zsh
│   └── templates/              # Plantillas
│       └── backup-info.txt     # Info de backups
└── docs/                       # Documentación (AGENTS.md, CHANGELOG.md, etc.)
```

## 🛠️ Herramientas Incluidas

### Scripts en `local/bin/`

| Script | Descripción |
|--------|-------------|
| `shell-config` | Gestor de configuración (backup, restore, copy) |
| `check-deps` | Verificador e instalador de dependencias |
| `benchmark-startup` | Mide el tiempo de inicio del shell |
| `give-me-ascii` | Muestra arte ASCII aleatorio |
| `packages-search` | Busca paquetes en múltiples distribuciones |
| `ytdlp-downloader` | Descargador de YouTube |
| `download-fonts` | Descarga fuentes Nerd Fonts |
| `optimize-completions` | Optimiza completions de shell |
| `variables-env` | Gestor de variables de entorno |
| `which-system` | Detecta el sistema operativo |
| `sacar-fondo` | Extrae color de fondo de imágenes |
| `test-phase-5` | Ejecuta pruebas de la fase 5 |

### Arte ASCII

- **Animaciones:** pipe-diagonal, pipes, rain, snow
- **ASCII Arts:** burger, colorbars, elfman, fireflower, kaisen, mario-xs, no-signal-tv, pacman-ghosts, pacman, pinguco, pizza, pokemon, rupees, taco, unix
- **Scripts de Color:** alpha, arch, bars, blocks, colortest, colorview, colorwheel, crunch, crunchbang, darthvader, debian, dna, faces, fade, ghosts, hearts, hedgehogs, illumina, invaders, jangofett, monster, mouseface, panes, rails, rally-x, six, skullys, skullz, space-invaders, spectrum, square, table, tanks, thebat, tiefighter, tvs, ubuntu, zwaves
- **Fetch Info:** fetching, sysfetch, zfetch

## 📦 Dependencias Soportadas

### Linux
lsd, bat, fzf, ripgrep, fd-find, exa, tldr, zsh, bash, nodejs, npm, python3, pip, rustc, cargo, build-essential, unzip, tty-clock, neofetch, fastfetch, vim, scrub, shred, xclip, bc, mpstat, htop, btop, starship, coreutils

### Python
httpx, rich, inquirer, pydantic, toml

### Rust
bat, exa, lsd, bottom, eza, zoxide, starship

### Node
typescript, ts-node, pm2, yarn

### Go
gh, lazygit, dog

## 🔧 Configuración Rápida

### Verificar Dependencias

```bash
check-deps                  # Ver estado
check-deps --install        # Instalar faltantes
```

### Gestionar Configuración

```bash
shell-config backup         # Crear backup
shell-config restore <date> # Restaurar backup
shell-config copy           # Desplegar config
```

### Mostrar ASCII

```bash
give-me-ascii               # Arte aleatorio
give-me-ascii pizza         # Arte específico
```

### Medir Rendimiento

```bash
benchmark-startup           # Medir tiempo de inicio
```

## 🎨 Personalización

### Configurar aliases
Edita `source/config/aliases` para agregar tus propios aliases.

### Configurar funciones
Edita `source/config/functions` para agregar funciones personalizadas.

### Configurar entorno
Edita `source/config/exports` para variables de entorno.

## 📝 Más Información

Para documentación completa, ejemplos detallados y guías paso a paso, consulta la carpeta [`docs/`](docs/).

---

**Versión:** 5.0  
**Estado:** ✅ Listo para producción  
**Última actualización:** Febrero 2026