# REFERENCE.md - Referencia Rápida de Comandos

**Cheat sheet para usuarios finales**

---

## ⚡ Instalación

```bash
git clone https://github.com/tu-usuario/shell-configs.git
cd shell-configs
bash setup.sh
source ~/.bashrc    # o ~/.zshrc
```

---

## 🛠️ Comandos Principales

### Gestión de Configuraciones

```bash
# Ver ayuda
shell-config help

# Crear backup
shell-config backup

# Restaurar desde backup
shell-config restore <TIMESTAMP>

# Listar backups disponibles
shell-config list

# Eliminar un backup
shell-config remove <TIMESTAMP>

# Limpiar backups antiguos (>30 días)
shell-config clean

# Copiar configuraciones del repo
shell-config copy

# Mostrar estado de Git
shell-config status

# Hacer commit y push
shell-config push
```

### Verificar Dependencias

```bash
# Ver estado
check-deps

# Verificar e instalar faltantes
check-deps --install

# Generar reporte
check-deps --report

# Solo mostrar lo que falta
check-deps --check-missing
```

### Herramientas Adicionales

```bash
# Descargar fuentes
download-fonts

# Descargar videos (yt-dlp)
ytdlp_downloader <URL>

# Ver directorio actual
show-dirs

# Mostrar información del sistema
zfetch

# Mostrar archivo del sistema
sysfetch
```

---

## 🔄 Flujos Comunes

### Después de Instalar

```bash
1. ./setup.sh              # Ejecutar instalador
2. source ~/.bashrc        # Recargar shell (o ~/.zshrc)
3. check-deps              # Verificar que todo está bien
4. shell-config list       # Ver que se creó backup
```

### Actualizar Configuraciones

```bash
1. Edita config/aliases, config/exports, etc.
2. Ejecuta: source ~/.bashrc (o ~/.zshrc)
3. Crea backup: shell-config backup
4. Prueba cambios
5. Si no te gusta: shell-config restore <TIMESTAMP>
```

### Hacer Cambios Persistentes

```bash
1. Modifica archivos en el repo
2. Copia a tu home: shell-config copy
3. Prueba en tu shell
4. Haz commit: git add . && git commit -m "cambios"
5. Push: git push
```

---

## 📁 Directorios Importantes

```bash
# Configuraciones del usuario
~/.config/shell/
  ├── aliases        # Atajos de comando
  ├── exports        # Variables de entorno
  ├── functions      # Funciones disponibles
  ├── functions-heavy # Funciones (lazy-loaded)
  └── backups/       # Backups automáticos

# Scripts binarios
~/.local/bin/
  ├── shell-config   # Gestor de configuraciones
  ├── check-deps     # Validador de dependencias
  └── ... otros scripts

# Shells instalados
~/.local/share/
  ├── oh-my-zsh/      # Para Zsh
  ├── oh-my-bash/     # Para Bash
  └── powerlevel10k/  # Tema Zsh
```

---

## 🐛 Solución Rápida de Problemas

| Problema | Solución |
|----------|----------|
| Shell no se recarga | `source ~/.bashrc` o `source ~/.zshrc` |
| Comando no encontrado | `check-deps --install` |
| PATH incorrecto | `echo $PATH` para verificar, edita `config/exports` |
| Quiero restaurar | `shell-config restore <TIMESTAMP>` |
| Funciones no se cargan | `source ~/.bashrc` o reinicia terminal |

**Para más problemas:** Ver `docs/TROUBLESHOOTING.md`

---

## 🔗 Documentación

- **README.md** - Guía de inicio rápido
- **docs/ARCHITECTURE.md** - Estructura técnica
- **docs/PROCESSES.md** - Cómo funcionan los procesos
- **docs/TROUBLESHOOTING.md** - Problemas y soluciones
- **docs/PROJECT_STATUS.md** - Roadmap futuro
- **docs/AGENTS.md** - Para agentes IA

---

**Última Actualización:** 25 enero 2026

## 🚀 Quick Start (2 minutos)

```bash
# 1. Clonar
git clone https://github.com/tuusuario/shell-configs.git
cd shell-configs

# 2. Instalar
bash setup.sh

# 3. Recargar
source ~/.bashrc  # o source ~/.zshrc

# 4. Verificar
check-deps
```

---

## 📋 Comandos Frecuentes

### Gestión de Backups

```bash
shell-config backup              # Crear backup nuevo
shell-config list                # Ver todos los backups
shell-config restore DATE        # Restaurar backup específico
shell-config remove DATE         # Eliminar backup
shell-config clean --older-than 30  # Limpiar antiguos
```

### Verificar Dependencias

```bash
check-deps                   # Ver estado (default)
check-deps --check-missing   # Solo listar faltantes
check-deps --install         # Instalar automático
check-deps --report          # Reporte completo
```

### Gestión de Configuración

```bash
shell-config status          # Ver estado git
shell-config push "mensaje"  # Commit y push
shell-config copy            # Desplegar archivos
```

---

## ⚙️ Configuración Común

### Agregar Alias

```bash
# Editar
nano ~/.config/shell/aliases

# Agregar línea:
alias mi='mi comando'

# Recargar
source ~/.config/shell/aliases
```

### Agregar Variable de Entorno

```bash
# Editar
nano ~/.config/shell/exports

# Agregar:
export MI_VAR="valor"

# Recargar
source ~/.config/shell/exports
```

### Agregar Función Ligera (Startup rápido)

```bash
nano ~/.config/shell/functions

function mi_func() {
    echo "Aquí va el código"
}

source ~/.config/shell/functions
```

### Agregar Función Pesada (Lazy Loading)

```bash
# 1. Agregar función
nano ~/.config/shell/functions-heavy

function mi_func_pesada() {
    # Código complejo...
}

# 2. Agregar lazy declaration
nano ~/.config/shell/functions

lazy_load_function "mi_func_pesada" "$HOME/.config/shell/functions-heavy"

# 3. Recargar
source ~/.config/shell/functions
```

---

## 🔍 Verificar Instalación

```bash
# ¿Está instalado?
which git
which fzf

# ¿Dónde está?
command -v python

# ¿Funciones disponibles?
declare -f message
declare -f compile-pls

# ¿Aliases?
alias | grep ll
```

---

## 🐛 Debug Rápido

```bash
# Performance
time bash -i -c exit

# Ver exports
echo $PATH

# Ver aliases
alias

# Ver funciones
declare -F

# Ver history
history | tail -20

# Validar sintaxis
bash -n ~/.config/shell/functions
```

---

## 📁 Estructura del Proyecto

```
shell-configs/
├── README.md             # Punto de entrada
├── setup.sh              # Instalador principal
├── dependencies.toml     # Especificación de dependencias
│
├── config/
│   ├── lib.sh           # Librería principal (317 líneas)
│   ├── functions        # Funciones ligeras (368 líneas)
│   ├── functions-heavy  # Funciones pesadas lazy-loaded (214 líneas)
│   ├── exports          # Variables de entorno (196 líneas)
│   ├── aliases          # Alias de comandos
│   └── backups/         # Backups automáticos
│
├── local/bin/
│   ├── check-deps       # Gestor de dependencias (371 líneas)
│   ├── shell-config     # Gestor de configuración (487 líneas)
│   ├── variables-env    # Validador de variables
│   └── ...
│
├── shells/
│   ├── bash/.bashrc
│   └── zsh/.zshrc
│
├── docs/
│   ├── README.md        # Navegación de docs
│   ├── AGENTS.md        # Guía para agentes AI
│   ├── CODE_REVIEW.md   # Análisis de código
│   ├── PROJECT_STATUS.md # Estado y roadmap
│   ├── PHASES_RESULTS.md # Resultados Fases 1-5
│   ├── REFERENCE.md     # Este archivo
│   ├── TROUBLESHOOTING.md
│   └── ...
│
└── home/                # Configuraciones de usuario
```

---

## 💾 Respaldo y Recuperación

```bash
# Crear backup
shell-config backup

# Ver todos los backups
ls -la ~/.config/shell/backups/

# Restaurar
shell-config restore 2026-01-24_150530

# Ver contenido sin restaurar
tar -tzf ~/.config/shell/backups/shell-backup-*.tar.gz
```

---

## 📊 Plan de Mejoras Futuras

### Fase 6: Quick Wins (~10 horas)

**Logging Centralizado:**
- [ ] Sistema de logging unificado
- [ ] Rotación automática de logs
- [ ] Niveles de verbosidad

**Modo Verbose:**
- [ ] Flag `--verbose` en todos los scripts
- [ ] Output detallado de ejecución
- [ ] Debug information

**Pre-check Mejorado:**
- [ ] Validaciones adicionales
- [ ] Detección de conflictos
- [ ] Sugerencias automáticas

**Auto-Documentación:**
- [ ] Generar docs automáticamente
- [ ] Comentarios en código
- [ ] Ejemplos auto-generados

### Fase 7: Robustness (~15 horas)

**Manejo de Errores Avanzado:**
- [ ] Try-catch para bash
- [ ] Error recovery automático
- [ ] Rollback inteligente

**Recuperación de Fallos:**
- [ ] Reintentos automáticos
- [ ] Puntos de recuperación
- [ ] State management

**Validación Exhaustiva:**
- [ ] Pre-validation completo
- [ ] Post-validation
- [ ] Compatibility checks

### Fase 8: UX Improvements (~25 horas)

**Perfiles de Configuración:**
- [ ] Perfil "ligero" (minimal)
- [ ] Perfil "estándar" (default)
- [ ] Perfil "completo" (todo)
- [ ] Perfiles personalizados

**Instalador Interactivo:**
- [ ] CLI con menús
- [ ] Preguntas paso a paso
- [ ] Validación de respuestas

**Temas Personalizables:**
- [ ] Colores configurables
- [ ] Símbolos personalizables
- [ ] Estilos de output

### Fase 9: Quality & CI/CD (~20 horas)

**Suite de Pruebas:**
- [ ] Unit tests
- [ ] Integration tests
- [ ] End-to-end tests

**CI/CD Pipeline:**
- [ ] GitHub Actions
- [ ] Validación automática
- [ ] Deploy automático

**Coverage & Metrics:**
- [ ] Code coverage
- [ ] Performance benchmarks
- [ ] Quality metrics

---

## 🎯 Estado Actual

| Aspecto | Fase | Status | Calidad |
|---------|------|--------|---------|
| Instalación | 1 | ✅ | Listo |
| Estructura | 2 | ✅ | Listo |
| Dependencias | 4 | ✅ | Listo |
| Performance | 5 | ✅ | Listo |
| Code Review | - | ✅ | 22/22 problemas solucionados |
| Documentación | - | ✅ | Completa y consolidada |

---

## 📞 Soporte

- **Problemas comunes**: Ver [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
- **Arquitectura**: Ver [AGENTS.md](AGENTS.md)
- **Validación**: Ver [CODE_REVIEW.md](CODE_REVIEW.md)
- **Roadmap**: Ver [PROJECT_STATUS.md](PROJECT_STATUS.md)

---

## 🔗 Enlaces Rápidos

- [README.md](../README.md) - Inicio
- [docs/README.md](README.md) - Navegación de docs
- [AGENTS.md](AGENTS.md) - Guía completa
- [PHASES_RESULTS.md](PHASES_RESULTS.md) - Fases 1-5
- [PROJECT_STATUS.md](PROJECT_STATUS.md) - Roadmap
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Ayuda

---

**Última actualización:** 25 de enero de 2026  
**Estado:** ✅ Listo para producción  
**Versión:** 5.0 (Fases 1-5 completadas)
