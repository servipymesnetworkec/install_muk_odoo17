#!/usr/bin/env bash
set -euo pipefail

echo "=== Instalador Automático MuK para Odoo 17 Community ==="

# ============================================================
# 1) DETECTAR SERVICIO ODOO
# ============================================================
SERVICE=$(systemctl list-units --type=service --all | grep -oP 'odoo[^ ]+\.service' | head -n1)

if [ -z "${SERVICE:-}" ]; then
    echo "[ERROR] No se detectó ningún servicio Odoo en systemctl."
    exit 1
fi
echo "[OK] Servicio detectado: $SERVICE"

# ============================================================
# 2) DETECTAR ARCHIVO DE CONFIGURACIÓN
# ============================================================
CONF=$(systemctl cat "$SERVICE" | grep -oP '(?<=-c ).+' | head -n1)

if [ -z "${CONF:-}" ] || [ ! -f "$CONF" ]; then
    echo "[ERROR] No se encontró archivo de configuración asociado a $SERVICE"
    exit 1
fi
echo "[OK] Archivo de configuración: $CONF"

# ============================================================
# 3) PROTECCIÓN ANTI-BD FANTASMA (NUNCA MÁS “test”)
# ============================================================
DB_NAME=$(awk -F= '/^\s*db_name/ {gsub(/[[:space:]]/,"",$2); print $2}' "$CONF")

if [ -z "${DB_NAME:-}" ]; then
    echo
    echo "[ERROR] El archivo de configuración NO tiene 'db_name' definido."
    echo "Agrega en $CONF por ejemplo:"
    echo "    db_name = producc"
    echo
    echo "Abortando para evitar creación accidental de bases nuevas."
    exit 1
fi

echo "[OK] Base de datos detectada correctamente: $DB_NAME"

# ============================================================
# 4) DETECTAR DIRECTORIOS ODOO
# ============================================================
ODOO_HOME=$(realpath "$(dirname "$CONF")/..")
ODOO_SRC="$ODOO_HOME/src/odoo"
VENV="$ODOO_HOME/venv"
EXTRA="$ODOO_HOME/extra-addons"

# Ruta nueva recomendada para MuK
MUK_BASE="$EXTRA/muk17"
MUK_DIR="$MUK_BASE/odoo-modules"

echo "[OK] Odoo Home: $ODOO_HOME"
echo "[OK] SRC:        $ODOO_SRC"
echo "[OK] VENV:       $VENV"
echo "[OK] Extra:      $EXTRA"
echo "[OK] MuK target: $MUK_DIR"

mkdir -p "$MUK_DIR"
chown -R odoo:odoo "$EXTRA"

# ============================================================
# 5) CLONAR MUK PARA ODOO 17
# ============================================================
echo "[+] Clonando MuK (rama 17.0 en $MUK_DIR)..."

if [ ! -d "$MUK_DIR/.git" ]; then
    sudo -u odoo git clone --depth 1 --branch 17.0 \
        https://github.com/muk-it/odoo-modules.git \
        "$MUK_DIR"
else
    echo "[+] Repo existente, actualizando..."
    sudo -u odoo git -C "$MUK_DIR" fetch origin || true
    sudo -u odoo git -C "$MUK_DIR" reset --hard origin/17.0 || true
fi

# ============================================================
# 6) ELIMINAR MÓDULOS ENTERPRISE (prohibidos en community)
# ============================================================
echo "[+] Eliminando módulos Enterprise de MuK..."

REMOVE_LIST=(
    muk_web_enterprise
    muk_dms_enterprise
    muk_rest_enterprise
    muk_templates
    muk_web_enterprise_theme
)

for mod in "${REMOVE_LIST[@]}"; do
    find "$MUK_DIR" -type d -name "$mod" -exec rm -rf {} + || true
done

# ============================================================
# 7) ACTUALIZAR addons_path EN LA CONFIGURACIÓN
# ============================================================
echo "[+] Actualizando addons_path en $CONF..."

NEW_AP="addons_path = $ODOO_SRC/addons,$ODOO_SRC/odoo/addons,$EXTRA,$MUK_DIR"

if grep -qE '^\s*addons_path\s*=' "$CONF"; then
    sed -i "s|^\s*addons_path\s*=.*|$NEW_AP|" "$CONF"
else
    echo "$NEW_AP" >> "$CONF"
fi

# ============================================================
# 8) PERMISOS
# ============================================================
echo "[+] Ajustando permisos..."
chown -R odoo:odoo "$MUK_BASE"
find "$MUK_BASE" -type d -exec chmod 755 {} \;
find "$MUK_BASE" -type f -exec chmod 644 {} \;

# ============================================================
# 9) REINICIAR SERVICIO
# ============================================================
echo "[+] Reiniciando $SERVICE..."
systemctl restart "$SERVICE"
sleep 4

# ============================================================
# 10) FORZAR update_list()
# ============================================================
echo "[+] Actualizando lista de módulos en BD: $DB_NAME ..."
sudo -u odoo "$VENV/bin/python3" "$ODOO_SRC/odoo-bin" \
    -c "$CONF" -d "$DB_NAME" -u base,web --stop-after-init

# ============================================================
# 11) MOSTRAR MÓDULOS MUK DETECTADOS
# ============================================================
echo "[+] Verificando módulos MuK detectados..."
sudo -u odoo "$VENV/bin/python3" "$ODOO_SRC/odoo-bin" shell -c "$CONF" -d "$DB_NAME" <<'PY'
import odoo
db = odoo.tools.config.get('db_name')
cr = odoo.sql_db.db_connect(db).cursor()
env = odoo.api.Environment(cr, 1, {})
mods = env['ir.module.module'].search([('name','ilike','muk_')])
print("\n===== MÓDULOS MUK DETECTADOS =====")
for m in mods:
    print(f"- {m.name} [{m.state}]")
cr.close()
PY

echo
echo "=== COMPLETADO: MuK listo para instalar desde Apps (sin riesgos) ==="
