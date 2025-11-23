🚀 MuK Installer for Odoo 17 (Community Edition)

Este repositorio contiene un script automático para instalar los módulos MuK (open source) en Odoo 17 Community, sin necesidad de Enterprise y sin afectar configuraciones previas.

✅ Características

Detecta automáticamente:

Servicio Odoo activo (odoo17, odooA, odooB, etc.)

Archivo odoo.conf

Rutas de instalación (src/odoo, venv, extra-addons)

Base de datos activa (db_name)

Clona solo los módulos MuK Open Source (rama 17.0)

Elimina módulos Enterprise o privados

Actualiza addons_path correctamente

Aplica permisos estándar

Reinicia el servicio de Odoo

Ejecuta update_list() para volver visibles los módulos

NO instala ningún módulo (solo los deja visibles en Apps)

📂 Contenido del repositorio
install_muk_auto.sh   # Script principal
README.md             # Este archivo

🔧 Requisitos

Odoo 17 Community ya instalado

Ubuntu 22.04 / 24.04 (compatible)

Git instalado

Acceso root o sudo

▶️ Instalación

Clona este repositorio:

git clone https://github.com/TU_USUARIO/install_muk_odoo17.git
cd install_muk_odoo17


Haz el script ejecutable:

chmod +x install_muk_auto.sh


Ejecuta:

sudo ./install_muk_auto.sh

🎯 Resultado

Al finalizar, verás una lista como esta:

===== MÓDULOS MUK DETECTADOS =====
- muk_web_theme [uninstalled]
- muk_web_dialog [uninstalled]
- muk_web_chatter [uninstalled]
- muk_web_appsbar [uninstalled]
- muk_web_colors [uninstalled]
- muk_product [uninstalled]


Todos quedarán visibles e instalables en la App Store de Odoo.

⚠️ Nota importante

El script NUNCA:

Instala módulos automáticamente

Toca Enterprise

Modifica bases de datos

Cambia configuraciones previas

Es completamente seguro para instancias productivas.

🧩 Compatibilidad
Odoo	Estado
17.0	✔️ 100% compatible
16.0 / 15.0	❌ No probado
📃 Licencia

Este repositorio se distribuye bajo licencia MIT, libre para uso comercial y personal.

🤝 Autor

Desarrollado por Crystian V.
Contribuciones, pull requests y mejoras son bienvenidos.