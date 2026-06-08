function _vinilo_devices --description 'Resuelve VINILO_SOURCE / VINILO_SINK / VINILO_CARD / VINILO_PORTS (auto-deteccion + override)'
    # --- Override opcional del usuario ---
    # Crea ~/.config/vinilo/config.fish y exporta/setea cualquiera de:
    #   VINILO_SOURCE  VINILO_SINK  VINILO_CARD  VINILO_PORTS
    if test -f "$HOME/.config/vinilo/config.fish"
        source "$HOME/.config/vinilo/config.fish"
    end

    # --- SOURCE: la entrada que tiene puerto Line-In ---
    if not set -q VINILO_SOURCE; or test -z "$VINILO_SOURCE"
        set -g VINILO_SOURCE (pactl list sources 2>/dev/null | awk '
            /^Source #/ {n=""}
            $1=="Name:" {n=$2}
            /analog-input-linein/ {print n; exit}')
    end
    # Fallback: entrada por defecto
    if test -z "$VINILO_SOURCE"
        set -g VINILO_SOURCE (pactl get-default-source 2>/dev/null)
    end

    # --- SINK: salida de la MISMA placa que el Line-In (suele ir al ampli) ---
    if not set -q VINILO_SINK; or test -z "$VINILO_SINK"
        set -l prefix (string replace 'alsa_input.' 'alsa_output.' -- $VINILO_SOURCE | string replace -r '\.analog.*' '')
        if test -n "$prefix"
            set -g VINILO_SINK (pactl list short sinks 2>/dev/null | awk -v p="$prefix" '$2 ~ "^"p {print $2; exit}')
        end
    end
    # Fallback: salida por defecto
    if test -z "$VINILO_SINK"
        set -g VINILO_SINK (pactl get-default-sink 2>/dev/null)
    end

    # --- CARD: indice ALSA del source (para amixer) ---
    if not set -q VINILO_CARD; or test -z "$VINILO_CARD"
        set -g VINILO_CARD (pactl list sources 2>/dev/null | awk -v s="$VINILO_SOURCE" '
            $1=="Name:" && $2==s {f=1}
            f && /alsa.card = / {gsub(/"/,""); print $3; exit}')
    end
    if test -z "$VINILO_CARD"
        set -g VINILO_CARD 0
    end

    # --- PUERTOS: pares salida:entrada (estereo analogico estandar) ---
    if not set -q VINILO_PORTS; or test -z "$VINILO_PORTS"
        set -g VINILO_PORTS capture_FL:playback_FL capture_FR:playback_FR
    end
end
