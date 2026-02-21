# CONTRIBUTING.md - Guía de Contribuciones

¡Gracias por querer contribuir a **shell-configs**!

## 🚀 Cómo Empezar

1. Haz un **Fork** del repositorio.
2. Crea una **Rama** para tu característica (`git checkout -b feature/nueva-funcionalidad`).
3. Realiza tus **Cambios** y asegúrate de seguir las guías de estilo.
4. Haz **Commit** de tus cambios (`git commit -m 'Añadir nueva funcionalidad'`).
5. Haz **Push** a la rama (`git push origin feature/nueva-funcionalidad`).
6. Abre un **Pull Request**.

## 🛠️ Guías de Estilo

- Usa `set -euo pipefail` en todos los scripts de Bash.
- Documenta las funciones con comentarios claros.
- Sigue el estándar XDG para el almacenamiento de archivos.
- Valida siempre los parámetros de entrada.

## 📁 Estructura de Contribución

- **Scripts:** Deben ir en `source/local/bin/`.
- **Configuraciones:** Deben ir en `source/config/` o `source/shells/`.
- **Arte ASCII:** Debe ir en `source/local/ascii/`.
- **Documentación:** Debe ir en `docs/` con nombres en mayúsculas.

## 🧪 Pruebas

Antes de enviar un PR, ejecuta las pruebas de la fase 5:
```bash
./source/local/bin/test-phase-5
```
