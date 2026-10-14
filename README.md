# ZeePub Plugins for ZeeTools

Conjunto de complementos oficiales de ZeePub para [ZeeTools](https://github.com/zeedif/ZeeTools).

## Complementos incluidos:
- 📚 **Catálogo ZeePub** (`zeepub_catalog`): Gestión y catalogación de series y volúmenes de novelas y mangas.
- 👥 **Editor de Fansub** (`zeepub_fansub`): Administración de roles, miembros de trabajo y asignación de tareas.
- ⏱️ **Programador de Publicaciones** (`zeepub_scheduler`): Programación y colas de publicación en canales de Telegram y redes sociales.
- 🚀 **Subidor de EPUBs** (`zeepub_uploader`): Validación de metadatos EPUB contra el servidor editorial de ZeePub y carga directa.

## Arquitectura
Este paquete implementa la arquitectura de plugins extensible de ZeeTools (`ZeeToolsPluginExtension`).
Cada herramienta se ejecuta en su propia vista modular y se integra nativamente en el Dashboard y la sección de Complementos.
