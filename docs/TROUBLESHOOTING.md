# Troubleshooting Guide - Shell-Configs

Soluciones para problemas comunes.

## 🔴 Problemas de Instalación

### Error: "permission denied" al ejecutar setup.sh

**Síntoma:**
```
bash: ./setup.sh: Permission denied
```

**Solución:**

```bash
# Opción 1: Usar bash explícitamente
bash setup.sh

# Opción 2: Dar permisos de ejecución
chmod +x setup.sh
./setup.sh
```

---

### Error: "git: command not found"

**Síntoma:**
```
bash: git: command not found
```

**Solución:**

```bash
# Ubuntu/Debian
sudo apt install git

# Arch/Manjaro
sudo pacman -S git

# Fedora/RHEL
sudo dnf install git

# Verificar instalación
git --version
```

---

### Error: "sudo: comando no encontrado"

**Síntoma:**
```
[→] INSTALANDO DEPENDENCIAS...
sudo: comando no encontrado
```

**Solución:**

```bash
# No tienes permisos de sudo. Opciones:
# 1. Instalar dependencias manualmente
sudo apt install lsd bat fzf

# 2. O usar setup.sh sin sudo (más lento)
bash setup.sh
# Cuando pida contraseña, decir que no
```

---

### Error: Incompatibilidad de distribución

**Síntoma:**
```
[*] Distribución no reconocida
[i] Por favor instala manualmente:
    git, curl, jq, lsd, bat, fzf, ripgrep, fd-find, exa, tldr
```

**Solución:**

```bash
# Instalar manualmente
# Para distribuciones basadas en Debian:
sudo apt install git curl jq lsd bat fzf ripgrep fd-find exa tldr

# Para otras distribuciones, consultar:
# https://repology.org/

# Después verificar:
check-deps
```

---

## 🟠 Problemas de Configuración

### Error: "command not found" para herramientas instaladas

**Síntoma:**
```
command not found: fzf
```

**Causas y Soluciones:**

```bash
# 1. Shell no recargado
source ~/.bashrc  # o source ~/.zshrc

# 2. Comando no está en PATH
which fzf

# 3. Comando no instalado realmente
check-deps
check-deps --install

# 4. Verificar ruta específica
ls -la /usr/bin/fzf

# 5. Si problema persiste:
# - Cerrar y abrir nueva pestaña de terminal
# - O abrir nueva instancia de shell:
bash
# o
zsh
```

---

### Error: "No such file or directory" para ~/.config/shell/

**Síntoma:**
```
bash: /home/user/.config/shell/aliases: No such file or directory
```

**Solución:**

```bash
# 1. Crear directorio manualmente
mkdir -p ~/.config/shell

# 2. Ejecutar setup nuevamente
cd ~/path/to/shell-configs
bash setup.sh

# 3. Verificar archivos copiados
ls -la ~/.config/shell/

# Esperado:
# lib.sh, functions, exports, aliases, functions-heavy
```

---

### Error: Bash/Zsh RC no sourcing shell-configs

**Síntoma:**
```
# Aliases/funciones no disponibles después de shell config
```

**Solución:**

```bash
# 1. Verificar que está en bashrc/zshrc
grep "shell-configs" ~/.bashrc
grep "shell-configs" ~/.zshrc

# 2. Si no está, agregar manualmente:
echo 'source "$HOME/.config/shell/lib.sh"' >> ~/.bashrc
echo 'source "$HOME/.config/shell/functions"' >> ~/.bashrc
echo 'source "$HOME/.config/shell/exports"' >> ~/.bashrc
echo 'source "$HOME/.config/shell/aliases"' >> ~/.bashrc

# 3. Recargar
source ~/.bashrc
```

---

## 🟡 Problemas de Performance

### Startup lento (>50ms)

**Diagnóstico:**

```bash
# Medir tiempo
time bash -i -c exit

# Esperado: <20ms
```

**Soluciones:**

```bash
# 1. Revisar si hay funciones pesadas siendo cargadas
grep "^function " ~/.config/shell/functions | wc -l

# 2. Mover funciones lentas a functions-heavy
# (compilar, APIs, searches, etc.)

# 3. Validar que lazy loading funciona
grep "lazy_load_function" ~/.config/shell/functions | wc -l

# 4. Revisar si hay sourcing extra
cat ~/.bashrc | grep "source" | wc -l

# 5. Reducir alias innecesarios
alias | wc -l
```

---

### Comando lento en primera ejecución

**Síntoma:**
```
$ compile-pls myfile.cpp
# Espera 2-3 segundos en primera llamada
```

**Explicación:**
Este es el comportamiento normal del lazy loading. La función se carga desde functions-heavy en la primera ejecución.

**Soluciones:**

```bash
# 1. Es normal - segunda llamada será instantánea
compile-pls myfile.cpp  # Lenta
compile-pls other.cpp   # Instantánea

# 2. Si quieres precarga, agregar a functions (no lazy):
nano ~/.config/shell/functions
# Mover función desde functions-heavy a functions
# Remover lazy_load_function declaration

# 3. Validar que functions-heavy se sourcing correctamente
bash -n ~/.config/shell/functions-heavy
```

---

## 🔵 Problemas de Funciones

### "function not found" para mi función personalizada

**Síntoma:**
```
command not found: mi_funcion
```

**Solución:**

```bash
# 1. Verificar que existe
declare -f mi_funcion

# 2. Si no existe, verificar dónde la creaste
grep "function mi_funcion" ~/.config/shell/functions
grep "function mi_funcion" ~/.config/shell/functions-heavy

# 3. Si no está, crearla:
nano ~/.config/shell/functions
# Agregar función al final
# Guardar (Ctrl+X, Y, Enter)

# 4. Recargar
source ~/.config/shell/functions

# 5. Verificar
declare -f mi_funcion
mi_funcion  # Ejecutar
```

---

### Alias no funciona después de agregar

**Síntoma:**
```
alias nuevo='comando'
# Pero luego: "command not found: nuevo"
```

**Solución:**

```bash
# 1. Recargar shell
source ~/.config/shell/aliases

# 2. Verificar que se agregó correctamente
grep "nuevo=" ~/.config/shell/aliases

# 3. Sintaxis correcta?
# Debe ser: alias nombre='comando'
# NO: alias nombre = 'comando'

# 4. Si aún no funciona:
# - Cierra terminal y abre nueva
# - O ejecuta: bash
```

---

### Función parece ignorar argumentos

**Síntoma:**
```bash
function mifunc() {
    echo $1
}
mifunc "hola"  # No imprime "hola"
```

**Solución:**

```bash
# 1. Asegúrate de usar comillas
function mifunc() {
    echo "$1"  # Con comillas
}

# 2. O pasar argumentos correctamente
mifunc "hola"   # Bien
mifunc hola     # También funciona

# 3. Para múltiples argumentos:
function mifunc() {
    echo "$@"  # Todos los argumentos
}
mifunc arg1 arg2 arg3
```

---

## 🟣 Problemas de Backups

### Backup no se crea

**Síntoma:**
```
shell-config backup
# No output o error
```

**Diagnóstico y Solución:**

```bash
# 1. Verificar permisos
ls -la ~/.config/shell/

# 2. Crear directorio de backups si falta
mkdir -p ~/.config/shell/backups
chmod 755 ~/.config/shell/backups

# 3. Intentar nuevamente
shell-config backup

# 4. Verificar creación
ls -la ~/.config/shell/backups/
```

---

### Error al restaurar backup

**Síntoma:**
```
shell-config restore 2026-01-24_150530
# Error: archivo no encontrado
```

**Solución:**

```bash
# 1. Ver backups disponibles
shell-config list
# o
ls -la ~/.config/shell/backups/

# 2. Usar fecha correcta
shell-config restore 2026-01-24_150530
# (incluir fecha y hora completas)

# 3. Si backup está corrupto:
# Ver tamaño
du -h ~/.config/shell/backups/

# Intentar extraer manualmente
tar -xzf ~/.config/shell/backups/shell-backup-*.tar.gz -C ~

# 4. Si falla totalmente, copiar archivos manualmente
cd ~/.dotfiles/shell-configs
cp src/lib/library.sh ~/.config/shell/
cp src/config/functions ~/.config/shell/
```

---

## 🟢 Problemas de Dependencias

### check-deps no detecta paquete instalado

**Síntoma:**
```
[*] lsd - NO encontrado
# Pero "which lsd" muestra que existe
```

**Solución:**

```bash
# 1. Verificar que realmente está instalado
which lsd
lsd --version

# 2. Limpiar cache de comandos
rm -rf /tmp/shell-cmd-cache/*

# 3. Ejecutar check-deps nuevamente
check-deps

# 4. Si aún falla, verificar PATH
echo $PATH

# 5. Si lsd no está en PATH:
# Agregar ruta a ~/.config/shell/exports
nano ~/.config/shell/exports
# Agregar: _PATH_COMPONENTS+=("/path/donde/esta/lsd")
```

---

### Instalación automática de dependencias falla

**Síntoma:**
```
check-deps --install
# Error durante instalación
```

**Solución:**

```bash
# 1. Intentar con verbosidad
check-deps --install -v

# 2. Instalar manualmente
sudo apt install lsd bat fzf ripgrep fd-find exa

# 3. Verificar instalación
check-deps

# 4. Si hay paquete específico problemático:
# Instalarlo por separado
sudo apt install <paquete_especifico>

# 5. Si persiste, ver log:
# Buscar en salida de error exacta
# Googlear ese error específico
```

---

## 🔴🔵 Problemas Git/Sync

### "git: not a git repository"

**Síntoma:**
```
shell-config push "mensaje"
# fatal: not a git repository
```

**Solución:**

```bash
# 1. Asegúrate de estar en la carpeta correcta
cd ~/path/to/shell-configs

# 2. Verificar que es repo git
ls -la .git/

# 3. Si no existe .git, reinicializar
git init
git remote add origin https://github.com/tu/repo.git
git branch -M main
git push -u origin main
```

---

### "fatal: 'origin' does not appear to be a 'git' repository"

**Síntoma:**
```
shell-config push "mensaje"
# error: fatal: 'origin' does not appear to be a git repository
```

**Solución:**

```bash
# 1. Verificar remoto
git remote -v

# 2. Si no aparece origin, agregarlo
git remote add origin https://github.com/tu/repo.git

# 3. Verificar nuevamente
git remote -v

# 4. Intentar push
git push origin main
```

---

### Permission denied al hacer push

**Síntoma:**
```
error: Permission denied (publickey)
```

**Solución:**

```bash
# 1. Configurar git
git config user.name "Tu Nombre"
git config user.email "tu@email.com"

# 2. Generar SSH key si no existe
ssh-keygen -t ed25519 -C "tu@email.com"

# 3. Agregar a GitHub
# Copiar contenido de ~/.ssh/id_ed25519.pub
# Ir a GitHub > Settings > SSH Keys > New SSH Key
# Pegar contenido

# 4. Probar conexión
ssh -T git@github.com

# 5. Usar SSH en remote
git remote set-url origin git@github.com:tu/repo.git

# 6. Intentar push
git push origin main
```

---

## 🛠️ Debugging Avanzado

### Ver archivos siendo ejecutados

```bash
# Modo verbose
bash -x ~/.bashrc

# Ver qué se ejecuta en setup.sh
bash -x setup.sh

# Salida mostrará cada línea antes de ejecutar
```

---

### Validar sintaxis de scripts

```bash
# Verificar sin ejecutar
bash -n ~/.config/shell/functions
bash -n ~/.config/shell/aliases
bash -n ~/.config/shell/exports
bash -n setup.sh
bash -n src/bin/scripts/shell-config

# Si no hay error, sintaxis está bien
```

---

### Listar todas las variables

```bash
# Variables set
set

# Solo variables de entorno
env | sort

# Variables específicas
echo $PATH
echo $HOME
echo $SHELL
```

---

### Rastrear un comando

```bash
# Ver dónde viene el comando
type micomando

# Ver cómo se expandiría
set -x
micomando
set +x
```

---

## 📞 Cuando Nada Funciona

### Nuclear Reset (Última opción)

```bash
# ¡ADVERTENCIA! Esto elimina toda la config:
rm -rf ~/.config/shell

# Crear backup de archivos RC
cp ~/.bashrc ~/.bashrc.backup
cp ~/.zshrc ~/.zshrc.backup

# Remover sourcing de shell-configs
nano ~/.bashrc
# Eliminar líneas que contengan: source $HOME/.config/shell

nano ~/.zshrc
# Eliminar líneas que contengan: source $HOME/.config/shell

# Recargar
source ~/.bashrc

# Luego reinstalar limpiamente
cd ~/path/to/shell-configs
bash setup.sh
```

---

### Obtener Ayuda

Si nada de esto funciona:

1. **Revisar documentación:**
   - [README.md](../README.md)
   - [PHASE_*_RESULTS.md](.)

2. **Verificar síntomas similares:**
   - Busca en issues de GitHub
   - Busca en foros de tu distribución

3. **Crear issue con detalles:**
   - Qué intentaste hacer
   - Qué error obtuviste (exacto)
   - Output de:
     ```bash
     uname -a
     bash --version
     echo $SHELL
     check-deps --report
     ```

---

**Última actualización:** Enero 2026
**Versión:** 5.0
**Para soporte completo:** Ver [README.md](../README.md#-soporte)
