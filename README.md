# Shell Configurations Repository

Configuraciones modernas y optimizadas para Bash/Zsh con instalación automatizada, validación de dependencias y soporte multi-distribución.

## 🚀 Inicio Rápido

```bash
bash setup.sh
```

## 📚 Documentación

**Toda la documentación está organizada en la carpeta [`docs/`](docs/).**

👉 **[Comienza aquí: docs/README.md](docs/README.md)** - Guía de navegación completa

### Para Agentes de IA y Continuidad del Proyecto

Lee estos archivos en este orden:
1. **[docs/AGENTS.md](docs/AGENTS.md)** - Guía completa del proyecto (COMIENZA AQUÍ)
2. **[docs/CODE_REVIEW.md](docs/CODE_REVIEW.md)** - Validación de código y correcciones
3. **[docs/PROJECT_STATUS.md](docs/PROJECT_STATUS.md)** - Estado actual y roadmap (Fases 6-9)

## 📋 Características

- ✨ Configuraciones optimizadas para Bash y Zsh
- 🚀 Instalación automatizada multiplataforma
- ⚡ Rendimiento optimizado (<10ms startup)
- 🔄 Gestión inteligente de dependencias
- 💾 Backups automáticos de configuración
- 🛠️ Herramientas de terminal incluidas (lsd, bat, fzf, ripgrep, etc.)
- 📦 Funciones útiles precargadas
- 🎨 Salida formateada y legible

## 📁 Estructura del Proyecto

```
shell-configs/
├── README.md              # Este archivo (inicio rápido)
├── setup.sh              # Script de instalación principal
├── config/               # Archivos de configuración
├── local/                # Herramientas y scripts locales
├── shells/               # Configuraciones de shells (bash, zsh)
└── docs/                 # Documentación completa
    ├── README.md         # Guía de navegación
    ├── AGENTS.md         # Guía para agentes de IA
    ├── CODE_REVIEW.md    # Análisis de código
    ├── PROJECT_STATUS.md # Estado y roadmap
    └── PHASE_*.md        # Reportes de cada fase
```

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

## 🐛 Ayuda

- **[docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)** - Solución de problemas
- **[docs/QUICK_REFERENCE.md](docs/QUICK_REFERENCE.md)** - Referencia rápida de comandos

## 📝 Más Información

Para documentación completa, ejemplos detallados y guías paso a paso, consulta la carpeta [`docs/`](docs/).

---

**Versión:** 5.0  
**Estado:** ✅ Listo para producción  
**Última actualización:** Enero 2026
