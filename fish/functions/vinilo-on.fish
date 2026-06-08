function vinilo-on --description 'Escuchar el tocadiscos: links directos PipeWire Line-In -> salida. Sin stream de grabacion = sin icono de microfono.'
    _vinilo_devices

    if test -z "$VINILO_SOURCE"
        echo "vinilo: no encontre una entrada Line-In. Revisa el cable o set VINILO_SOURCE." >&2
        return 1
    end
    if test -z "$VINILO_SINK"
        echo "vinilo: no encontre una salida. Set VINILO_SINK en ~/.config/vinilo/config.fish." >&2
        return 1
    end

    # 1. Entrada en Line-In, sin mutear
    pactl set-source-port $VINILO_SOURCE analog-input-linein 2>/dev/null
    pactl set-source-mute $VINILO_SOURCE 0 2>/dev/null

    # 2. Limpiar el metodo viejo (module-loopback) si quedo de antes
    for m in (pactl list short modules 2>/dev/null | string match -r '^\d+\s+module-loopback' | awk '{print $1}')
        pactl unload-module $m >/dev/null 2>&1
    end

    # 3. Links directos en el grafo (desconecto primero para no duplicar)
    for pair in $VINILO_PORTS
        set -l o (string split ':' $pair)[1]
        set -l i (string split ':' $pair)[2]
        pw-link -d "$VINILO_SOURCE:$o" "$VINILO_SINK:$i" >/dev/null 2>&1
        pw-link "$VINILO_SOURCE:$o" "$VINILO_SINK:$i" >/dev/null 2>&1
    end

    # 4. NIVELES HARDWARE — AL FINAL, asi ganan sobre el remapeo de pactl/port.
    #    Boost en 0 (linea no necesita boost) y ADC a nivel limpio.
    #    El volumen se sube/baja en el AMPLIFICADOR, no aca.
    amixer -c $VINILO_CARD sset 'Line Boost' $VINILO_BOOST >/dev/null 2>&1
    amixer -c $VINILO_CARD sset 'Capture' $VINILO_CAPTURE >/dev/null 2>&1

    echo "🎵 Vinilo ON  ($VINILO_SOURCE → $VINILO_SINK)"
end
