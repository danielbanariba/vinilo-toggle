#!/usr/bin/env bash
# Instalador de vinilo-toggle: funciones fish + extension GNOME.
set -euo pipefail

UUID="vinilo@banar.local"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

FISH_DEST="${XDG_CONFIG_HOME:-$HOME/.config}/fish/functions"
EXT_DEST="${XDG_DATA_HOME:-$HOME/.local/share}/gnome-shell/extensions/$UUID"

bold() { printf '\033[1m%s\033[0m\n' "$1"; }
ok()   { printf '  \033[32m✓\033[0m %s\n' "$1"; }
warn() { printf '  \033[33m!\033[0m %s\n' "$1"; }

bold "vinilo-toggle — instalando"

# --- Dependencias ---
bold "Chequeando dependencias…"
missing=0
for cmd in pw-link pactl awk; do
  if command -v "$cmd" >/dev/null 2>&1; then ok "$cmd"; else warn "FALTA: $cmd"; missing=1; fi
done
command -v fish    >/dev/null 2>&1 && ok "fish"    || { warn "FALTA: fish (las funciones lo necesitan)"; missing=1; }
command -v amixer  >/dev/null 2>&1 && ok "amixer"  || warn "amixer ausente (opcional: ajuste de niveles)"
command -v gnome-shell >/dev/null 2>&1 && ok "gnome-shell ($(gnome-shell --version 2>/dev/null | awk '{print $3}'))" \
  || warn "gnome-shell ausente (la extension no cargara, pero las funciones fish si)"
[ "$missing" -eq 1 ] && warn "Instala lo que falta antes de seguir (pipewire, fish…)."

# --- Funciones fish ---
bold "Instalando funciones fish en $FISH_DEST"
mkdir -p "$FISH_DEST"
cp "$HERE"/fish/functions/*.fish "$FISH_DEST/"
ok "vinilo-on / vinilo-off / vinilo-status / _vinilo_devices"

# --- Extension GNOME ---
bold "Instalando extension GNOME en $EXT_DEST"
rm -rf "$EXT_DEST"
mkdir -p "$EXT_DEST"
cp -r "$HERE/gnome-extension/$UUID/." "$EXT_DEST/"
ok "archivos copiados"

# --- Habilitar extension ---
if command -v gsettings >/dev/null 2>&1; then
  if command -v python3 >/dev/null 2>&1; then
    python3 - "$UUID" <<'PY' && ok "extension habilitada en dconf"
import subprocess, ast, sys
uuid = sys.argv[1]
cur = subprocess.run(['gsettings','get','org.gnome.shell','enabled-extensions'],
                     capture_output=True, text=True).stdout.strip()
try:
    lst = ast.literal_eval(cur) if cur.startswith('[') else []
except Exception:
    lst = []
if uuid not in lst:
    lst.append(uuid)
    val = '[' + ', '.join("'%s'" % x for x in lst) + ']'
    subprocess.run(['gsettings','set','org.gnome.shell','enabled-extensions', val], check=True)
subprocess.run(['gsettings','set','org.gnome.shell','disable-user-extensions','false'], check=False)
PY
  else
    gnome-extensions enable "$UUID" 2>/dev/null && ok "extension habilitada" \
      || warn "No pude habilitarla automaticamente. Hacelo tras reloguear: gnome-extensions enable $UUID"
  fi
else
  warn "gsettings ausente: habilita la extension a mano tras reloguear."
fi

echo
bold "Listo."
echo "  • Comandos:  vinilo-on   vinilo-off   vinilo-status"
echo "  • En GNOME Wayland: CERRÁ SESIÓN y volvé a entrar para ver el botón en la barra."
echo "  • Override de dispositivos (opcional): ~/.config/vinilo/config.fish"
echo "      set -gx VINILO_SINK   <tu_sink>"
echo "      set -gx VINILO_SOURCE <tu_source>"
