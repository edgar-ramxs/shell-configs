# CHANGELOG.md - Historial de Cambios

## [5.0.0] - 2026-02-21
### Añadido
- Soporte completo para XDG Base Directory.
- Nueva estructura modular en `source/`.
- Scripts de utilidad en `source/local/bin/`.
- Arte ASCII y animaciones en `source/local/ascii/`.
- Librería compartida `library.sh` para funciones comunes.
- Sistema de validación de dependencias con `check-deps`.
- Medición de rendimiento con `benchmark-startup`.

### Cambiado
- Refactorización completa de `setup.sh`.
- Documentación movida a `docs/` con nombres en mayúsculas.
- Mejora en la detección de distros y entornos WSL2.

## [4.0.0] - 2026-01-25
### Añadido
- Gestión inteligente de dependencias mediante `dependencies.toml`.
- Soporte para múltiples gestores de paquetes (apt, pacman, dnf).

## [1.0.0] - 2025-12-15
### Añadido
- Versión inicial con automatización básica de instalación.
