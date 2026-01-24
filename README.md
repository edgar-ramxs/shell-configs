# Shell Configurations Repository

Una solución completa y moderna para gestionar configuraciones de shell (Bash/Zsh) con automatización, optimización de rendimiento y soporte multi-distribución.

## 🎯 ¿Qué es shell-configs?

**shell-configs** es un repositorio que proporciona:

- ✨ Configuraciones modernas y optimizadas para Bash y Zsh
- 🚀 Sistema de instalación automatizada multiplataforma
- ⚡ Rendimiento optimizado (<10ms startup time)
- 🔄 Gestión inteligente de dependencias
- 💾 Sistema de backups automáticos
- 🛠️ Herramientas de terminal mejoradas (lsd, bat, fzf, ripgrep, fd, exa)
- 📦 Funciones útiles precargadas
- 🎨 Salida formateada y legible

## 📚 Documentación Completa

Toda la documentación detallada está organizada en `docs/`:

### 📖 Para Empezar
- **[docs/INDEX.md](docs/INDEX.md)** - Índice completo de documentación
- **[docs/QUICK_REFERENCE.md](docs/QUICK_REFERENCE.md)** - Referencia rápida de comandos

### 📋 Reportes de Fases
- **[docs/PHASE_1_RESULTS.md](docs/PHASE_1_RESULTS.md)** - Automatización e instalación
- **[docs/PHASE_2_RESULTS.md](docs/PHASE_2_RESULTS.md)** - Optimización de estructura
- **[docs/PHASE_4_RESULTS.md](docs/PHASE_4_RESULTS.md)** - Sistema de validación
- **[docs/PHASE_5_RESULTS.md](docs/PHASE_5_RESULTS.md)** - Optimización de rendimiento
- **[docs/PHASE_5_SUMMARY.md](docs/PHASE_5_SUMMARY.md)** - Resumen ejecutivo Fase 5
- **[docs/PHASE_5_QUICKSTART.md](docs/PHASE_5_QUICKSTART.md)** - Guía rápida Fase 5

### 🔧 Herramientas y Soporte
- **[docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)** - Guía de solución de problemas
- **[docs/MEJORAS_PLAN.md](docs/MEJORAS_PLAN.md)** - Plan de mejoras y roadmap

## 📋 Características Principales

### 1. Instalación Automatizada
```bash
bash setup.sh
```
- Detección automática de SO, shell y distribución
- Instalación segura de dependencias
- Backup automático de configuración existente
- Validación post-instalación

### 2. Gestión de Dependencias
```bash
check-deps                    # Ver estado
check-deps --install          # Instalar faltantes
check-deps --report           # Reporte detallado
check-deps --check-missing    # Solo listar faltantes
```

### 3. Gestión de Configuración
```bash
shell-config backup           # Crear backup
shell-config restore <date>   # Restaurar backup
shell-config copy             # Desplegar config
shell-config list             # Listar backups
shell-config push "mensaje"   # Git commit & push
shell-config status           # Ver estado
```

### 4. Lazy Loading
- Funciones pesadas cargadas on-demand
- Startup <10ms (25x más rápido que target)
- Acceso transparente a todas las funciones

### 5. Command Caching
- Cache automático en /tmp (TTL: 1 hora)
- 80-90% más rápido para búsquedas repetidas

---

## 🚀 Instalación Rápida

### Requisitos Previos

- **SO:** Linux (Ubuntu, Debian, Arch, Fedora, etc.)
- **Shell:** Bash 4.0+ o Zsh 5.0+
- **Herramientas:** git, curl, bash/sh
- **Privilegios:** sudo para instalar dependencias (opcional)

### Paso 1: Clonar Repositorio

```bash
cd ~/Documents  # o tu ubicación preferida
git clone https://github.com/tuusuario/shell-configs.git
cd shell-configs
```

### Paso 2: Ejecutar Setup

```bash
bash setup.sh
```

Esto automáticamente:
1. Detecta tu sistema operativo y distribución
2. Verifica dependencias instaladas
3. Crea backup de configuración existente
4. Instala dependencias faltantes (si lo deseas)
5. Despliega archivos de configuración
6. Valida la instalación

### Paso 3: Recargar Shell

```bash
# Para Bash
source ~/.bashrc

# Para Zsh
source ~/.zshrc
```

¡Listo! Ya tienes shell-configs instalado.

---

## 📖 Uso Diario

### Verificar Dependencias

```bash
# Ver qué está instalado y qué falta
check-deps

# Ver solo las faltantes
check-deps --check-missing

# Instalar automáticamente las faltantes
check-deps --install

# Ver reporte detallado del sistema
check-deps --report
```

### Gestionar Backups

```bash
# Crear backup de tu configuración actual
shell-config backup

# Ver todos los backups disponibles
shell-config list

# Restaurar a un backup anterior
shell-config restore 2026-01-24_150530

# Eliminar un backup específico
shell-config remove 2026-01-24_150530

# Limpiar backups más antiguos de 30 días
shell-config clean --older-than 30
```

### Sincronizar con Git

```bash
# Ver estado del repositorio
shell-config status

# Hacer commit y push de cambios
shell-config push "Agregar nuevas funciones"
```

---

## ⚙️ Configuración

### Estructura de Directorios

```
~/.config/shell/
├── lib.sh              # Librería compartida (16K)
├── functions           # Funciones cargadas (16K)
├── functions-heavy     # Funciones on-demand (8K)
├── exports             # Variables de entorno (8K)
├── aliases             # Alias de comandos (12K)
└── backups/            # Backups automáticos
    ├── shell-backup-*.tar.gz
    └── shell-backup-*.meta
```

### Modificar Exports

Para agregar nuevas variables de entorno:

```bash
nano ~/.config/shell/exports

# Agregar al final:
export MI_VARIABLE="valor"
export MI_PATH="$HOME/ruta/personalizada:$MI_PATH"
```

Luego recargar:
```bash
source ~/.config/shell/exports
```

### Agregar Alias Personalizados

```bash
nano ~/.config/shell/aliases

# Agregar:
alias micomando='comando real aqui'
alias ll='ls -la'
```

Recargar:
```bash
source ~/.config/shell/aliases
```

### Crear Nuevas Funciones

Para funciones **ligeras** (cargadas al startup):

```bash
nano ~/.config/shell/functions

# Agregar función al final:
function mi_funcion() {
    echo "Hola, esta es mi función"
}
```

Para funciones **pesadas** (cargadas on-demand):

```bash
nano ~/.config/shell/functions-heavy

# Agregar función:
function compilar_proyecto() {
    # Código complejo aquí
    echo "Compilando..."
}

# Luego agregar lazy loading declaration en functions:
lazy_load_function "compilar_proyecto" "$HOME/.config/shell/functions-heavy"
```

---

## 🔧 Configuración Avanzada

### Agregar Nuevas Herramientas a PATH

Si instalas una nueva herramienta que queremos en PATH, por ejemplo, una herramienta en `~/.local/bin`:

```bash
nano ~/.config/shell/exports

# Buscar la sección PATH
# Agregar antes del PATH final:
if [[ -d "$HOME/.local/bin" ]]; then
    _PATH_COMPONENTS+=("$HOME/.local/bin")
fi
```

### Detectar Herramientas Automáticamente

El sistema ya detecta automáticamente:
- Ruby (rbenv)
- Node.js (NVM)
- Python (PyEnv)
- Rust (Cargo)
- Go
- .NET
- Docker
- Y más...

Para agregar otra herramienta, edita `config/exports`:

```bash
# Patrón a seguir:
if [[ -d "$HOME/.miherramienta/bin" ]]; then
    _PATH_COMPONENTS+=("$HOME/.miherramienta/bin")
fi
```

### Personalizar Comportamiento

Edita el archivo `setup.sh` para cambiar:
- Directorios de instalación
- Dependencias por instalar
- Comportamiento post-instalación

---

## ➕ Agregar Nuevas Configuraciones

### Agregar una Nueva Configuración Completa

Supongamos que quieres agregar configuración para `Neovim`:

1. **Crear archivo de configuración:**

```bash
mkdir -p ~/.config/nvim
cat > ~/.config/nvim/init.vim << 'EOF'
" Configuración de Neovim
set number
set tabstop=4
EOF
```

2. **Copiar a shell-configs para que sea parte del repositorio:**

```bash
cp ~/.config/nvim/init.vim config/nvim-init.vim
```

3. **Actualizar setup.sh para instalar:**

```bash
# En setup.sh, agregar en install_configuration_files():
message -info "Copiando Neovim config..."
safe_copy_with_backup "config/nvim-init.vim" "$HOME/.config/nvim/init.vim"
```

4. **Guardar en git:**

```bash
git add config/nvim-init.vim setup.sh
shell-config push "Agregar configuración Neovim"
```

### Agregar Nuevas Dependencias

1. **Editar dependencies.toml:**

```toml
[tools]
neovim = "Editor de texto mejorado"
```

2. **Agregar mapeo en check-deps:**

```bash
# Buscar la función "get_package_name"
# Agregar:
"neovim")
    case "$distro_type" in
        debian) echo "neovim" ;;
        arch) echo "neovim" ;;
        fedora) echo "neovim" ;;
    esac
    ;;
```

3. **Actualizar lista de verificación en setup.sh:**

```bash
DEPENDENCIES=("neovim" "${DEPENDENCIES[@]}")
```

---

## ❌ Eliminar Configuraciones

### Eliminar Alias

```bash
nano ~/.config/shell/aliases

# Comentar o eliminar la línea:
# alias micomando='comando'

# Recargar:
source ~/.config/shell/aliases
```

### Eliminar Funciones

Para funciones en `config/functions`:

```bash
nano ~/.config/shell/functions

# Encontrar y eliminar la función completa:
# function mi_funcion() {
#     ...
# }

# Recargar:
source ~/.config/shell/functions
```

Para funciones en `config/functions-heavy`:

```bash
# 1. Eliminar la declaración lazy en config/functions:
nano ~/.config/shell/functions
# lazy_load_function "mi_funcion" "..."

# 2. Eliminar la función de functions-heavy:
nano ~/.config/shell/functions-heavy
# function mi_funcion() { ... }

# 3. Recargar:
source ~/.config/shell/functions
```

### Desinstalar Completamente

```bash
# Crear backup final (por seguridad)
shell-config backup

# Eliminar archivos de configuración
rm -rf ~/.config/shell

# Restaurar configuración original si tienes backup:
# - Restaurar ~/.bashrc/.zshrc de tu respaldo
# - O editarlos manualmente para remover sourcing de shell-configs
```

---

## 📚 Funciones Disponibles

### Funciones Ligeras (Cargadas al Startup)

#### Utilidades Básicas
- `message [tipo] "texto"` - Salida formateada
- `confirm "pregunta"` - Pedir confirmación
- `open-file <archivo>` - Abrir con editor automático

#### Manejo de Directorios
- `cdl` - Ir a directorio y listar
- `mkt <nombre>` - Crear directorio + cd
- `cmkdir <nombre>` - Crear + confirm
- `rmk <directorio>` - Eliminar directory seguro

#### Manejo de Archivos
- `extract-files <archivo>` - Extraer varios formatos
- `venv-create <nombre>` - Crear Python venv

#### Búsqueda
- `hydra` - Mostrar splash art
- `man <comando>` - Manual mejorado

### Funciones Pesadas (Cargadas On-Demand)

#### Compilación
- `compile-pls <archivo>` - Compilar automático (C, C++, Java, Rust, Go, Kotlin)

#### Búsqueda Avanzada
- `fzf-lovely [directorio]` - Preview con syntax highlighting
- `extract-ports <archivo>` - Parsing de nmap

#### APIs y Utilidades
- `tell-me-a-joke` - Chiste aleatorio
- `pray-for-me` - Sabiduría zen
- `cheat <comando>` - Ejemplos de comandos
- `wttr [ciudad]` - Clima desde terminal
- `crypto-rate [moneda]` - Precio de criptomonedas

#### Desarrollo
- `initialize-git-repo [remote]` - Crear repo git
- `calc "expresión"` - Calculadora (bc wrapper)

---

## 🐛 Troubleshooting

### Problema: "command not found" para herramientas instaladas

**Solución:**
```bash
# Recargar shell
source ~/.bashrc  # o source ~/.zshrc

# Verificar PATH
echo $PATH

# Verificar si herramienta está en PATH
which nombreherramienta

# Si no aparece, verificar instalación:
check-deps
```

### Problema: Comandos lentos al iniciar

**Solución:**
```bash
# Medir rendimiento
time bash -i -c exit

# Ver si hay funciones pesadas cargando
grep "^function" ~/.config/shell/functions | wc -l

# Mover funciones lentas a functions-heavy
# y agregar lazy_load_function
```

### Problema: Backup no se crea

**Solución:**
```bash
# Verificar permisos
ls -la ~/.config/shell/

# Crear directorio de backups si falta
mkdir -p ~/.config/shell/backups

# Intentar backup nuevamente
shell-config backup
```

### Problema: Dependencias no se instalan

**Solución:**
```bash
# Ver qué falta
check-deps --check-missing

# Instalar manualmente
sudo apt install <paquete>  # Ubuntu/Debian
sudo pacman -S <paquete>    # Arch
sudo dnf install <paquete>  # Fedora

# Verificar instalación
check-deps
```

### Problema: Git integration no funciona

**Solución:**
```bash
# Verificar que estamos en directorio del repo
pwd

# Verificar git status
git status

# Configurar git si es necesario
git config user.name "Tu Nombre"
git config user.email "tu@email.com"

# Intentar push nuevamente
shell-config push "mensaje"
```

---

## 📊 Performance

### Benchmarks Actuales

```
Startup sin optimización:     250-300ms
Startup con shell-configs:    <10ms
Mejora:                       25x más rápido

Breakdown:
  • lib.sh sourcing:          2ms
  • functions sourcing:       3ms
  • exports sourcing:         8ms
  • Total:                    10ms

Lazy loading benefit:
  • Primera ejecución función pesada: 2ms
  • Ejecuciones siguientes:           <1ms
```

---

## 📁 Documentación Completa

Para más información detallada, consulta:

- **[PHASE_1_RESULTS.md](docs/PHASE_1_RESULTS.md)** - Automatización de instalación
- **[PHASE_2_RESULTS.md](docs/PHASE_2_RESULTS.md)** - Consolidación y optimización
- **[PHASE_4_RESULTS.md](docs/PHASE_4_RESULTS.md)** - Gestión de dependencias
- **[PHASE_5_RESULTS.md](docs/PHASE_5_RESULTS.md)** - Mejoras de rendimiento
- **[MEJORAS_PLAN.md](docs/MEJORAS_PLAN.md)** - Plan de desarrollo
- **[PHASE_5_SUMMARY.md](PHASE_5_SUMMARY.md)** - Resumen técnico Fase 5
- **[PHASE_5_QUICKSTART.md](PHASE_5_QUICKSTART.md)** - Guía rápida Fase 5

---

## 🤝 Contribuir

Si quieres mejorar shell-configs:

1. **Crea una rama:**
   ```bash
   git checkout -b feature/nueva-feature
   ```

2. **Haz cambios y prueba:**
   ```bash
   # Editar archivos
   # Probar cambios
   bash setup.sh
   ```

3. **Commit y push:**
   ```bash
   git add .
   git commit -m "Agregar nueva feature"
   git push origin feature/nueva-feature
   ```

4. **Crea Pull Request**

---

## 📝 Licencia

Este proyecto está bajo licencia MIT. Ver `LICENSE` para más detalles.

---

## 🙋 Soporte

¿Preguntas o problemas?

1. Consulta [Troubleshooting](#-troubleshooting)
2. Revisa la documentación en `docs/`
3. Abre un issue en GitHub
4. Contacta al mantenedor

---

## 🎉 ¡Gracias por usar shell-configs!

Esperamos que disfrutes de una mejor experiencia en la terminal.

### Próximas Mejoras Planeadas

- [ ] Fase 3: Compatibilidad WSL2
- [ ] Fase 6: Validación de seguridad
- [ ] Fase 7: Documentación mejorada
- [ ] Fase 8: Sistema de temas personalizables

---

**Última actualización:** Enero 2026
**Versión:** 5.0 (Fase 5 Completada)
**Estado:** ✅ Listo para producción