function vinilo-status --description 'Devuelve on/off segun si el link del tocadiscos esta activo'
    _vinilo_devices

    set -l first $VINILO_PORTS[1]
    set -l o (string split ':' $first)[1]
    set -l i (string split ':' $first)[2]

    set -l linked (pw-link -l 2>/dev/null | awk -v src="$VINILO_SOURCE:$o" -v dst="$VINILO_SINK:$i" '
        $0==src {found=1; next}
        /^[^[:space:]]/ {found=0}
        found && index($0, dst) {print "yes"; exit}')

    if test "$linked" = yes
        echo on
    else
        echo off
    end
end
