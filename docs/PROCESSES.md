# Procesos Clave - Shell-Configs

**Documentación Detallada de Flujos y Procesos**

---

## 🔄 Proceso 1: Instalación Completa

### Entrada
- Usuario ejecuta `./setup.sh`
- Sistema operativo (Linux)
- Shell actual (Bash o Zsh)

### Pasos Detallados

**Fase 1: Preparación**
```
1. Validar git instalado
2. Setup variables XDG (HOME/.config, etc.)
3. Importar lib.sh (funciones compartidas)
4. Detectar distro Linux (Debian/Ubuntu, Arch, Fedora)
5. Detectar shell actual (bash o zsh)
6. Detectar si es WSL2
```

**Fase 2: Backup**
```
1. Crear directorio: ~/.config/shell/backups/{DISTRO}/{SHELL}/{TIMESTAMP}/
2. Hacer backup de archivos existentes:
   - ~/.bashrc / ~/.zshrc
   - ~/.bash_logout / ~/.p10k.zsh
   - ~/.config/shell/* (si existe)
3. Crear archivo metadata (fecha, sistema, usuario)
```

**Fase 3: Instalación de Dependencias**
```
1. Parsear dependencies.toml [linux]
2. Verificar package manager (apt, pacman, dnf)
3. Para cada paquete:
   - Mapear nombre según distro
   - Intenta instalar
   - Registra éxito/fallo
4. Reporta resumen
```

**Fase 4: Instalación de Repositorios**
```
1. Parsear dependencies.toml [repositories]
2. Para cada repositorio:
   - Determinar destino (~/.local/share/oh-my-zsh, etc.)
   - Si existe: saltar
   - Si no existe: clonar con git
   - Configurar framework automáticamente
3. Reporta resumen
```

**Fase 5: Configuración de Shell**
```
1. Detectar shell actual (bash o zsh)
2. Solo copiar archivos de la shell detectada:
   - Si Bash: copiar .bashrc y .bash_logout
   - Si Zsh: copiar .zshrc y .p10k.zsh
3. No copiar configuraciones de otras shells
```

**Fase 6: Instalación de Configuraciones**
```
1. Copiar config/exports → ~/.config/shell/exports
2. Copiar config/aliases → ~/.config/shell/aliases
3. Copiar config/functions → ~/.config/shell/functions
4. Copiar config/functions-heavy → ~/.config/shell/functions-heavy
5. Establecer permisos apropiados (644)
```

**Fase 7: Instalación de Scripts**
```
1. Copiar local/bin/* → ~/.local/bin/
2. Chmod +x (hacer ejecutables)
3. Registra cada copia
```

**Fase 8: Validación**
```
1. Verificar archivos existen
2. Verificar permisos correctos
3. Verificar PATH incluye ~/.local/bin/
4. Verificar shells configuradas correctamente
```

### Salida
- Archivos instalados en su lugar
- Backup creado en ~/.config/shell/backups/
- Resumen mostrado al usuario

### Manejo de Errores
- Si un paquete falla: continúa con los demás
- Si un repo falla: continúa con los demás
- Reporta al final cuáles fallaron
- No afecta pasos posteriores

---

## 🔄 Proceso 2: Detección de Distro

### Entrada
- Sistema Linux actual

### Pasos Detallados

```
1. Leer archivo /etc/os-release
   - Extraer variable ID
   - Ejemplos: ubuntu, debian, arch, fedora

2. Normalizar a familia de distro:
   - ubuntu → debian
   - linuxmint → debian
   - manjaro → arch
   - fedora → fedora
   - rhel → fedora
   - centos → fedora

3. Determinar package manager:
   - debian: apt
   - arch: pacman
   - fedora: dnf

4. Guardar en variable DISTRO
```

### Criticidad
- **ALTA** - Afecta selección de package manager
- Si falla: intenta lsb_release como fallback
- Si todo falla: DISTRO="unknown" y aborta

---

## 🔄 Proceso 3: Instalación de Paquetes

### Entrada
```
system_deps=(git curl jq bat lsd fzf ripgrep)
DISTRO=debian
```

### Pasos por Distro

**Debian/Ubuntu (apt)**
```
1. sudo apt update -qq (actualizar lista de repos)
2. Para cada paquete:
   - sudo apt install -y PAQUETE
   - Si éxito: muestra ✓ PAQUETE
   - Si fallo: muestra ✗ PAQUETE
3. Reporta resumen
```

**Arch/Manjaro (pacman)**
```
1. sudo pacman -Sy (actualizar lista de repos)
2. Para cada paquete:
   - sudo pacman -S --noconfirm PAQUETE
   - Si éxito: muestra ✓ PAQUETE
   - Si fallo: muestra ✗ PAQUETE
3. Reporta resumen
```

**Fedora/RHEL (dnf)**
```
1. sudo dnf check-update -q (actualizar lista)
2. Para cada paquete:
   - sudo dnf install -y PAQUETE
   - Si éxito: muestra ✓ PAQUETE
   - Si fallo: muestra ✗ PAQUETE
3. Reporta resumen
```

### Output Minimalista
```
✓ git
✓ curl
✗ some-package
✓ bat
...
Paquetes instalados: git curl bat
Paquetes fallidos: some-package
```

### Por Qué es Minimalista
- Elimina output verbose de package managers
- Solo muestra resultado final
- No intenta validar por nombre exacto (varían entre distros)
- Confía en código de salida del PM

---

## 🔄 Proceso 4: Clonado de Repositorios

### Entrada
```
repos=(
  https://github.com/ohmyzsh/ohmyzsh.git
  https://github.com/ohmybash/oh-my-bash.git
  https://github.com/romkatv/powerlevel10k.git
)
```

### Pasos Detallados

```
1. Validar git disponible (CRÍTICO)

2. Para cada repositorio:
   a. Extraer nombre: basename URL .git
      Ejemplos: ohmyzsh, oh-my-bash, powerlevel10k
   
   b. Determinar destino según nombre:
      - ohmyzsh → ~/.local/share/oh-my-zsh
      - oh-my-bash → ~/.local/share/oh-my-bash
      - powerlevel10k → ~/.local/share/oh-my-zsh/custom/themes/powerlevel10k
   
   c. Si destino existe:
      - Mostrar: ✓ NOMBRE ya existe
      - Saltar
   
   d. Si no existe:
      - Crear directorio padre
      - git clone URL DESTINO
      
      - Si clone exitoso:
        * Validar no esté vacío
        * Configurar framework automáticamente
        * Mostrar: ✓ NOMBRE instalado
      
      - Si clone fallido:
        * Agregar a lista de fallos
        * Limpiar directorio
        * Mostrar: ✗ NOMBRE falló

3. Reporta resumen al final
```

### Configuración Automática

**Oh-My-Zsh:**
```bash
- Crear/actualizar ~/.config/zsh/.zshrc
- Exportar ZSH="~/.local/share/oh-my-zsh"
- Cargar plugins recomendados
```

**Oh-My-Bash:**
```bash
- Crear/actualizar ~/.bashrc
- Exportar OSH="~/.local/share/oh-my-bash"
- Cargar tema apropiado
```

**Powerlevel10k:**
```bash
- Solo clonar (requiere configuración manual)
- Indicar al usuario qué hacer
```

---

## 🔄 Proceso 5: Detección de Shell y Copia Selectiva

### Entrada
- Sistema en ejecución
- Shells disponibles

### Pasos Detallados

```
1. Detectar shell actual:
   - Leer variable SHELL
   - Extraer nombre: bash o zsh
   - Guardar en SHELL_DETECTED

2. Basado en shell detectada:
   
   Si BASH:
   - Copiar shells/bash/.bashrc → ~/.bashrc
   - Copiar shells/bash/.bash_logout → ~/.bash_logout
   - NO copiar nada de zsh
   
   Si ZSH:
   - Copiar shells/zsh/.zshrc → ~/.zshrc
   - Copiar shells/zsh/.p10k.zsh → ~/.p10k.zsh
   - NO copiar nada de bash

3. Respetar backups previos
   - Solo copiar archivos de shell actual
   - Otros archivos ya fueron backup en Fase 2
```

### Ventaja
- Evita conflictos entre configuraciones
- Mantiene archivos limpios
- No duplica configuraciones innecesarias

---

## 🔄 Proceso 6: Sistema de Lazy Loading

### Concepto
Funciones pesadas se cargan bajo demanda, no al inicio de shell.

### Cómo Funciona

**Al iniciar shell:**
```
1. source ~/.config/shell/functions (función lazy_load_function)
2. Define: lazy_load_function() {
     # Verifica si función ya está en memoria
     # Si no: busca en config/functions-heavy
     # Sourcea el archivo correspondiente
     # Ejecuta la función
   }
3. Shell listo, tiempo < 10ms
```

**Cuando usuario ejecuta función pesada:**
```
1. Usuario escribe: backup_configs
2. Shell no la encuentra en memoria
3. lazy_load_function activa
4. Sourcea config/functions-heavy
5. Ejecuta backup_configs
6. Próximas veces está en memoria (rápido)
```

### Función Definida en lib.sh
```bash
lazy_load_function() {
    local func_name=$1
    local function_file="$HOME/.config/shell/functions-heavy"
    
    if ! declare -F "$func_name" &>/dev/null; then
        source "$function_file"
    fi
}
```

---

## 🔄 Proceso 7: Sistema de Backups

### Creación de Backup

```
1. Usuario ejecuta: shell-config backup

2. Crear estructura:
   ~/.config/shell/backups/{DISTRO}/{SHELL}/{TIMESTAMP}/

3. Copiar archivos:
   - ~/.bashrc / ~/.zshrc
   - ~/.bash_logout / ~/.p10k.zsh
   - ~/.config/shell/
   - ~/.local/bin/
   - Archivos de historial

4. Crear metadata:
   - Fecha/hora exacta
   - Sistema (Linux, versión)
   - Distro
   - Shell
   - Hostname
   - Usuario

5. Comprimir:
   tar czf backup_{TIMESTAMP}.tar.gz

6. Guardar en:
   ~/.config/shell/backups/{DISTRO}/{SHELL}/{TIMESTAMP}/
```

### Restauración de Backup

```
1. Usuario ejecuta: shell-config restore TIMESTAMP

2. Validar backup existe

3. Crear nuevo backup primero (seguridad)

4. Extraer backup antiguo

5. Copiar archivos a su lugar

6. Restauración completada
```

### Ventajas de Estructura DISTRO/SHELL
- Backups organizados por distro
- Backups organizados por shell
- Fácil encontrar backup específico
- Previene restaurar config de otra distro

---

## 📊 Flujo Completo Visualizado

```
┌─────────────────────────────────────────┐
│ Usuario ejecuta: ./setup.sh              │
└──────────────┬──────────────────────────┘
               │
        ┌──────▼──────┐
        │ Validar Git │
        └──────┬──────┘
               │
        ┌──────▼──────────────┐
        │ Setup XDG Variables │
        └──────┬──────────────┘
               │
        ┌──────▼────────────────┐
        │ Detectar Sistema      │
        │ (Distro/Shell/WSL2)   │
        └──────┬────────────────┘
               │
        ┌──────▼─────────────────┐
        │ Crear Backup Archivos  │
        │ Ubicación:             │
        │ ~/.config/shell/       │
        │ backups/{D}/{S}/{T}/   │
        └──────┬─────────────────┘
               │
        ┌──────▼──────────────────────┐
        │ Instalar Dependencias Linux │
        │ (apt/pacman/dnf)            │
        └──────┬──────────────────────┘
               │
        ┌──────▼────────────────────────┐
        │ Instalar Repositorios GitHub   │
        │ (oh-my-zsh, powerlevel10k)    │
        └──────┬────────────────────────┘
               │
        ┌──────▼──────────────────────┐
        │ Copiar Config Shell Detectada│
        │ Bash: .bashrc, .bash_logout  │
        │ Zsh: .zshrc, .p10k.zsh       │
        └──────┬──────────────────────┘
               │
        ┌──────▼──────────────────────┐
        │ Instalar Configuraciones      │
        │ exports, aliases, functions   │
        └──────┬──────────────────────┘
               │
        ┌──────▼──────────────────┐
        │ Instalar Scripts Binarios│
        │ (~/.local/bin/)          │
        └──────┬──────────────────┘
               │
        ┌──────▼──────────────────┐
        │ Validar Instalación      │
        └──────┬──────────────────┘
               │
        ┌──────▼──────────────────┐
        │ Mostrar Resumen          │
        │ & Próximos Pasos         │
        └──────────────────────────┘
```

---

**Última Actualización:** 25 de enero de 2026
