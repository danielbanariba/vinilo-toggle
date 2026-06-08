#!/usr/bin/env bash
# Desinstalador de vinilo-toggle.
set -euo pipefail

UUID="vinilo@banar.local"
FISH_DEST="${XDG_CONFIG_HOME:-$HOME/.config}/fish/functions"
EXT_DEST="${XDG_DATA_HOME:-$HOME/.local/share}/gnome-shell/extensions/$UUID"

ok() { printf '  \033[32m✓\033[0m %s\n' "$1"; }

printf '\033[1m%s\033[0m\n' "vinilo-toggle — desinstalando"

# Cortar cualquier link activo antes de irse
command -v fish >/dev/null 2>&1 && fish -c vinilo-off >/dev/null 2>&1 || true

# Funciones fish
for f in vinilo-on vinilo-off vinilo-status _vinilo_devices; do
  rm -f "$FISH_DEST/$f.fish"
done
ok "funciones fish removidas"

# Deshabilitar + borrar extension
if command -v gnome-extensions >/dev/null 2>&1; then
  gnome-extensions disable "$UUID" 2>/dev/null || true
fi
if command -v gsettings >/dev/null 2>&1 && command -v python3 >/dev/null 2>&1; then
  python3 - "$UUID" <<'PY' || true
import subprocess, ast, sys
uuid = sys.argv[1]
cur = subprocess.run(['gsettings','get','org.gnome.shell','enabled-extensions'],
                     capture_output=True, text=True).stdout.strip()
try:
    lst = ast.literal_eval(cur) if cur.startswith('[') else []
except Exception:
    lst = []
if uuid in lst:
    lst.remove(uuid)
    val = '[' + ', '.join("'%s'" % x for x in lst) + ']'
    subprocess.run(['gsettings','set','org.gnome.shell','enabled-extensions', val], check=True)
PY
fi
rm -rf "$EXT_DEST"
ok "extension removida"

echo "Listo. Relogueá para que GNOME la descargue del todo."
