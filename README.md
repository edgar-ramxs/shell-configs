# Shell Configurations - Setup Automático

Instalación rápida y automatizada de configuraciones modernas para Bash/Zsh en Linux.

## 🚀 Instalación Rápida

```bash
git clone https://github.com/edgar-ramxs/shell-configs.git
cd shell-configs
bash setup.sh
```

Luego, recarga tu shell:
```bash
source ~/.bashrc    # Para Bash
# o
source ~/.zshrc     # Para Zsh
```

## ✨ Qué Instala

- **Shells Modernos:** Bash y Zsh optimizados
- **Frameworks:** Oh-My-Zsh, Oh-My-Bash, Powerlevel10k
- **Herramientas:** git, curl, jq, lsd, bat, fzf, ripgrep, fd, exa, tldr
- **Configuraciones:** Aliases, funciones, variables de entorno
- **Scripts Útiles:** check-deps, shell-config, download-fonts, ytdlp_downloader

## 📚 Documentación

La documentación detallada está en la carpeta `docs/`:

| Archivo | Propósito |
|---------|-----------|
| **docs/AGENTS.md** | Guía para agentes IA y mantenimiento del proyecto |
| **docs/ARCHITECTURE.md** | Estructura técnica y componentes |
| **docs/PROCESSES.md** | Procesos clave y flujos de instalación |
| **docs/TROUBLESHOOTING.md** | Solución de problemas comunes |
| **docs/REFERENCE.md** | Referencia rápida de comandos |
| **docs/PROJECT_STATUS.md** | Roadmap y estado del proyecto |

## 🔧 Comandos Útiles

```bash
# Verificar dependencias
check-deps

# Gestionar configuraciones
shell-config backup          # Crear backup
shell-config restore <date>  # Restaurar

# Ver más opciones
shell-config help
```

## 📋 Requisitos

- Linux (Debian/Ubuntu, Arch, o Fedora)
- Bash o Zsh
- Git instalado
- Acceso a sudo (para instalar paquetes)

## 🐛 ¿Problemas?

Consulta **docs/TROUBLESHOOTING.md** para soluciones comunes.

---

**Status:** ✅ Listo para producción | **Última actualización:** Enero 2026
