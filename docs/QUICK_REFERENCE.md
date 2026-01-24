# Quick Reference Guide - Shell-Configs

Guía rápida de referencia para acciones comunes.

## 🚀 Primeros Pasos (2 minutos)

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

## ⚙️ Editar Configuración

### Agregar Alias

```bash
# Editar archivo
nano ~/.config/shell/aliases

# Agregar línea:
alias mi='mi comando'

# Guardar (Ctrl+X, Y, Enter) y recargar:
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
# Editar
nano ~/.config/shell/functions

# Agregar al final:
function mi_func() {
    echo "Aquí va el código"
}

# Recargar
source ~/.config/shell/functions
```

### Agregar Función Pesada (Lazy Loading)

```bash
# 1. Agregar función en functions-heavy:
nano ~/.config/shell/functions-heavy

function mi_func_pesada() {
    # Código complejo...
}

# 2. Agregar lazy declaration en functions:
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

# Ver últimos errores
tail ~/.bash_history

# Validar sintaxis
bash -n ~/.config/shell/functions
```

---

## 📁 Estructura Rápida

```
shell-configs/
├── setup.sh              # Instalador
├── config/
│   ├── lib.sh           # Librería principal
│   ├── functions        # Funciones ligeras
│   ├── functions-heavy  # Funciones on-demand
│   ├── exports          # Variables de entorno
│   ├── aliases          # Alias de comandos
│   └── ...
├── local/bin/
│   ├── check-deps       # Gestor de dependencias
│   ├── shell-config     # Gestor de config
│   └── ...
├── docs/                # Documentación
└── README.md            # Este archivo
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

# Eliminar backup
shell-config remove 2026-01-24_150530

# Limpiar todos los backups antiguos
shell-config clean --older-than 30
```

---

## 🚨 Emergencias

### "¡Rompí la configuración!"

```bash
# 1. Ir a la carpeta del repo
cd ~/path/to/shell-configs

# 2. Ver backups disponibles
shell-config list

# 3. Restaurar
shell-config restore FECHA_DESEADA

# 4. Recargar
source ~/.bashrc
```

### "Un alias no funciona"

```bash
# Verificar que existe
alias micomando

# Si no existe, recrearlo:
nano ~/.config/shell/aliases
# ... agregar línea ...
source ~/.config/shell/aliases

# Verificar
alias micomando
```

### "Una función falta"

```bash
# Verificar que existe
declare -f mi_funcion

# Si no:
# Revisar en ~/.config/shell/functions
# o ~/.config/shell/functions-heavy

# Recargar archivos:
source ~/.config/shell/functions
source ~/.config/shell/functions-heavy
```

---

## 🔄 Sincronizar con Git

```bash
# Ver cambios
git status

# Agregar todo
git add .

# Commit
git commit -m "Descripción cambios"

# Push
git push origin main

# O simplemente:
shell-config push "Descripción cambios"
```

---

## 🎯 Atajos Útiles

```bash
# Abrir archivo rápidamente
open-file ~/.config/shell/aliases

# Crear directorio y entrar
mkt mi_proyecto

# Listar y entrar
cdl ~/Documents

# Extraer archivos automático
extract-files archivo.tar.gz

# Verificar sistema
check-deps --report
```

---

## 📞 Soporte Rápido

### Ver Documentación
- Instalación: [README.md](../README.md#-instalación-rápida)
- Fase 1: [PHASE_1_RESULTS.md](../docs/PHASE_1_RESULTS.md)
- Fase 2: [PHASE_2_RESULTS.md](../docs/PHASE_2_RESULTS.md)
- Fase 4: [PHASE_4_RESULTS.md](../docs/PHASE_4_RESULTS.md)
- Fase 5: [PHASE_5_RESULTS.md](../docs/PHASE_5_RESULTS.md)

### Verificar Instalación
```bash
check-deps
```

### Reporte del Sistema
```bash
check-deps --report
```

### Test de Performance
```bash
bash local/bin/benchmark-startup config 5
```

---

## 🎓 Ejemplos Prácticos

### Agregar PyEnv a PATH automáticamente

Ya está incluido en exports. Solo asegúrate de que PyEnv está instalado:

```bash
# Verificar
ls -la ~/.pyenv

# Si existe, será detectado automáticamente
```

### Crear función para backup automático

Agregar a `~/.config/shell/functions`:

```bash
function auto_backup() {
    cd ~/path/to/shell-configs
    shell-config backup
    echo "Backup creado"
}
```

### Alias para ver últimos 10 backups

Agregar a `~/.config/shell/aliases`:

```bash
alias backups='ls -lht ~/.config/shell/backups | head -10'
```

---

## ✅ Checklist de Instalación

- [ ] Git clonado en directorio correcto
- [ ] `bash setup.sh` ejecutado
- [ ] Shell recargado (`source ~/.bashrc`)
- [ ] `check-deps` verifica instalación exitosa
- [ ] Primer backup creado
- [ ] Alias básicos funcionan
- [ ] Funciones disponibles (`declare -f message`)
- [ ] Performance aceptable (`<20ms startup`)

---

**Última actualización:** Enero 2026
**Para ayuda completa:** Ver [README.md](../README.md)
