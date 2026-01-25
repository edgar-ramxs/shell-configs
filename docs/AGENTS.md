# AGENTS.md - Guía para Agentes de IA

**Documento de Navegación y Mantenimiento del Proyecto**

---

## 📖 Inicio Rápido para Agentes

Eres un agente de IA trabajando en shell-configs. Esta es tu guía.

### Primero: Entiende el Proyecto

1. **Lee README.md** (raíz) - Inicio rápido de 5 minutos
2. **Lee docs/ARCHITECTURE.md** - Estructura técnica
3. **Lee docs/PROCESSES.md** - Cómo funcionan las cosas
4. **Este archivo** - Cómo mantener todo sincronizado

### Estructura de Documentación

```
README.md                        ← Inicio para usuarios finales
├─ docs/
│  ├─ AGENTS.md                 ← Este archivo (para agentes IA)
│  ├─ ARCHITECTURE.md           ← Estructura técnica
│  ├─ PROCESSES.md              ← Procesos detallados
│  ├─ TROUBLESHOOTING.md        ← Problemas comunes
│  ├─ REFERENCE.md              ← Comandos rápidos
│  └─ PROJECT_STATUS.md         ← Roadmap futuro
└─ setup.sh                      ← Script principal
```

---

## 🎯 Rol de Cada Documento

| Archivo | Rol | Para Quién |
|---------|-----|-----------|
| **README.md** | Entrada simple, cómo instalar | Usuarios finales |
| **ARCHITECTURE.md** | Estructura técnica completa | Agentes, Desarrolladores |
| **PROCESSES.md** | Detalle paso-a-paso de flujos | Agentes, Desarrolladores |
| **TROUBLESHOOTING.md** | Problemas y soluciones | Todos |
| **REFERENCE.md** | Comandos rápidos de uso | Usuarios finales |
| **PROJECT_STATUS.md** | Roadmap y fases futuras | Agentes, Planificadores |

---

## ♻️ Ciclo de Mantenimiento - CLAVE

### Cuando Cambias Código

**REGLA ORO:** Si cambias código, actualiza documentación.

#### Cambio: Modificas un proceso (ej: cómo se instalan paquetes)

1. ✏️ Modifica el código en `setup.sh`
2. 📝 **ACTUALIZA docs/PROCESSES.md**
   - Sección del proceso que modificaste
   - Describe el nuevo flujo paso a paso
3. ✅ **Revisa docs/ARCHITECTURE.md**
   - Si cambió la estructura: actualiza diagramas
   - Si cambiaron componentes: actualiza descripción
4. 🎯 **Actualiza este archivo (AGENTS.md)**
   - Sección "Cambios Recientes"
   - Qué cambió, por qué, cuándo
5. 📋 Si es un problema conocido: actualiza TROUBLESHOOTING.md

#### Cambio: Agregas un nuevo script

1. ✏️ Creas script en `local/bin/nuevo-script.sh`
2. 📝 **Documenta en docs/ARCHITECTURE.md**
   - Sección "local/bin/" → Agrega descripción
3. 📖 Si es importante: agrega a REFERENCE.md
4. 🎯 Agrega nota en AGENTS.md "Cambios Recientes"

#### Cambio: Arreglas un bug

1. ✏️ Corrige código
2. ✅ Si es problema común: actualiza TROUBLESHOOTING.md
3. 🎯 Agrega nota en AGENTS.md

#### Cambio: Agregas dependencia

1. ✏️ Modifica `dependencies.toml`
2. ✅ Si necesita mapeos especiales: documenta en PROCESSES.md
3. 🎯 Agrega nota en AGENTS.md

---

## 📋 Checklist para Cambios Significativos

**Antes de dar por completo un cambio:**

- [ ] Código funciona y fue testeado
- [ ] `bash -n script.sh` pasa (sin errores)
- [ ] Documentación actualizada:
  - [ ] ARCHITECTURE.md (si es estructural)
  - [ ] PROCESSES.md (si es un proceso)
  - [ ] REFERENCE.md (si es un comando)
  - [ ] TROUBLESHOOTING.md (si agrega problema)
  - [ ] AGENTS.md (sección "Cambios Recientes")
- [ ] README.md aún es válido (no necesita cambios si es internos)
- [ ] Documentación está clara para futuros agentes IA

---

## 🚦 Niveles de Cambio

### Trivial (Sin documentación)
- Typos en comentarios
- Espacios en blanco
- Variables locales
- Ejemplo: "Corrigí indentación"

### Pequeño (Actualizar AGENTS.md)
- Bug fixes menores
- Mejoras de performance
- Refactoring sin cambio funcional
- Ejemplo: "Optimicé loop en install_packages"

→ Acción: Agrega nota en AGENTS.md

### Medio (Actualizar 2-3 docs)
- Nuevo script/comando
- Cambio en un flujo
- Nueva funcionalidad
- Ejemplo: "Agregué soporte para dry-run"

→ Acción: Actualiza ARCHITECTURE.md + PROCESSES.md + AGENTS.md

### Grande (Actualizar múltiples docs)
- Cambio de arquitectura
- Nuevo proceso completo
- Cambio en cómo instala
- Ejemplo: "Soporte para Fish shell"

→ Acción: Actualiza ARCHITECTURE.md + PROCESSES.md + TROUBLESHOOTING.md + AGENTS.md + posiblemente README.md

---

## 🎯 Guía Rápida: "Voy a Hacer X"

### "Voy a agregar soporte para Fish shell"

1. Lee docs/ARCHITECTURE.md (ver cómo está estructurado)
2. Lee docs/PROCESSES.md (Proceso 5: Detección Shell)
3. Modifica:
   - setup.sh (agregar detección + config)
   - config/ (crear .fishrc si corresponde)
4. Actualiza:
   - ARCHITECTURE.md (agregar Fish en secciones relevantes)
   - PROCESSES.md (Proceso 5 ahora incluye Fish)
   - REFERENCE.md (agregar comandos si aplica)
   - AGENTS.md (nota en "Cambios Recientes")

### "Voy a mejorar la detección de distro"

1. Lee docs/PROCESSES.md (Proceso 2)
2. Modifica setup.sh (función detect_distro)
3. Actualiza:
   - PROCESSES.md (describe nuevo flujo)
   - TROUBLESHOOTING.md (si mejora soporte)
   - AGENTS.md (nota de cambio)

### "Voy a arreglar un bug"

1. Corrige código
2. Si es problema común: agrega a TROUBLESHOOTING.md
3. Nota en AGENTS.md (sección "Bugs Corregidos")

---

## 📊 Resumen del Proyecto

**Propósito:** Instalador automático de shells Bash/Zsh para Linux

**Características:**
- Multi-distro (Debian, Arch, Fedora)
- XDG-compliant
- Shell-aware (detecta bash vs zsh)
- Backups automáticos
- Lazy loading de funciones
- Error handling robusto

**Componentes Clave:**
- setup.sh (890 líneas) - Orquestador principal
- config/lib.sh (498 líneas) - Funciones compartidas
- local/bin/ - Scripts y herramientas
- shells/ - Configuraciones de shell
- dependencies.toml - Especificación de deps

**Estado:** ✅ Production Ready

---

## 📝 Cambios Recientes

*Actualiza esta sección cada vez que hagas un cambio significativo*

### Reestructuración de Documentación
**Fecha:** 25 enero 2026  
**Cambios Realizados:**
- Simplificada documentación de 11 a 6 archivos clave
- README.md (raíz) → Ahora simple: solo instalación
- **NUEVO:** docs/ARCHITECTURE.md → Info técnica
- **NUEVO:** docs/PROCESSES.md → Procesos detallados
- **ACTUALIZADO:** AGENTS.md → Con ciclo de mantenimiento
- Otros docs simplificados/consolidados

**Archivos Eliminados:**
- docs/README.md (redundante, consolidado en README raíz)
- CODE_REVIEW.md (info en ARCHITECTURE.md)
- CONSOLIDATION_*.txt (histórico)
- DOCUMENTATION_MAP.md (redundante)
- INSTALLATION_REVIEW.md (obsoleto)
- PHASES_RESULTS.md (histórico)

**Impacto:** Documentación más clara, enfoque en lo importante

---

## 💡 Consejos para Agentes

1. **Siempre leer primero** antes de modificar
2. **Testing básico:** `bash -n setup.sh` para validar
3. **Mantener docs sincronizadas** - ¡Es CRÍTICO!
4. **Ser específico** en notas de cambio
5. **Si algo no está claro:** Actualizar AGENTS.md para aclarar
6. **Documentación es código** - Dedica tiempo

---

**Última Actualización:** 25 de enero de 2026  
**Próxima Revisión:** Después de próximo cambio significativo

