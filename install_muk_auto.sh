#!/usr/bin/env bash
set -euo pipefail

echo "=== Instalador MuK para Odoo 17 (modo seguro) ==="

# Detectar servicio
SERVICE=$(systemctl list-units --type=service --all | grep -oP 'odoo[^ ]+\.service' | head -n1)
if [ -z "${SERVICE:-}" ]; then
    echo "[ERROR] No se detectó ningún servicio Odoo."
    exit 1
fi
echo "[OK] Servicio: $SERVICE"

# Detectar config
CONF=$(systemctl cat "$SERVICE" | grep -oP '(?<=-c ).+' | head -n1)
if [ ! -f "$CONF" ]; then
    echo "[ERROR] No existe archivo de configuración."
    exit 1
fi
echo "[OK] Config: $CONF"

# Detectar rutas
ODOO_HOME=$(realpath "$(dirname "$CONF")/..")
ODOO_SRC="$ODOO_HOME/src/odoo"
VENV="$ODOO_HOME/venv"

# Nueva ruta limpia para MUK
MUK_PATH="/odoo/custom/addons_muk17"
mkdir -p "$MUK_PATH"
chown -R odoo:odoo "$(dirname "$MUK_PATH")"

echo "[OK] Ruta MUK limpia: $MUK_PATH"

# Clonar repositorio MUK original temporalmente
TMP="/tmp/muk17_repo"
rm -rf "$TMP"
git clone --depth 1 --branch 17.0 https://github.com/muk-it/odoo-modules.git "$TMP"

echo "[+] Filtrando módulos compatibles..."

# Lista de módulos seguros para Odoo 17
SAFE_MODS=(
    muk_utils
    muk_web_theme
    muk_web_colors
    muk_web_appsbar
    muk_web_dialog
    muk_web_chatter
    muk_product
)

# Copiar únicamente los módulos seguros
for mod in "${SAFE_MODS[@]}"; do
    if [ -d "$TMP/$mod" ]; then
        cp -r "$TMP/$mod" "$MUK_PATH/"
        echo "[OK] Copiado: $mod"
    else
        echo "[WARN] No encontrado: $mod"
    fi
done

chown -R odoo:odoo "$MUK_PATH"

# Actualizar addons_path
echo "[+] Actualizando addons_path..."

NEW_AP="addons_path = $ODOO_SRC/addons,$ODOO_SRC/odoo/addons,$MUK_PATH"

if grep -qE '^\s*addons_path\s*=' "$CONF"; then
    sed -i "s|^\s*addons_path\s*=.*|$NEW_AP|" "$CONF"
else
    echo "$NEW_AP" >> "$CONF"
fi

# Reiniciar
echo "[+] Reiniciando servicio..."
systemctl restart "$SERVICE"
sleep 5

# Forzar actualización lista
echo "[+] Actualizando módulos..."
sudo -u odoo "$VENV/bin/python3" "$ODOO_SRC/odoo-bin" -c "$CONF" -d test -u base,web --stop-after-init || true

echo "=== COMPLETADO ==="
echo "MuK instalado de forma segura en: $MUK_PATH"
echo "Puedes ir a Apps y activar los módulos MuK compatibles."
