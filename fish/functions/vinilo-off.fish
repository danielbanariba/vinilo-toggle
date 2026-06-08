function vinilo-off --description 'Cortar los links del tocadiscos'
    _vinilo_devices

    for pair in $VINILO_PORTS
        set -l o (string split ':' $pair)[1]
        set -l i (string split ':' $pair)[2]
        pw-link -d "$VINILO_SOURCE:$o" "$VINILO_SINK:$i" >/dev/null 2>&1
    end

    # por las dudas, limpiar loopback viejo tambien
    for m in (pactl list short modules 2>/dev/null | string match -r '^\d+\s+module-loopback' | awk '{print $1}')
        pactl unload-module $m >/dev/null 2>&1
    end

    echo "🔇 Vinilo OFF"
end
