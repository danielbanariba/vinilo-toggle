# 🎶 vinilo-toggle

Escuchá tu **tocadiscos de vinilo** a través de la PC con un clic, en Linux (PipeWire + GNOME).

Un botón de **tornamesa** en la barra superior de GNOME: clic para enrutar el Line-In a tus parlantes, clic de nuevo para cortar. El ícono cambia según el estado (brazo levantado ↔ brazo tocando + verde). Sin el falso indicador de "micrófono en uso".

---

## ¿Para qué sirve?

Si tu preamplificador / amplificador tiene **una sola entrada** (ya ocupada por la PC) y no podés enchufar el tocadiscos directo en la cadena analógica, esta herramienta usa la PC como **puente**: el vinilo entra por el **Line-In**, y se enruta a tu salida (que ya va al ampli) **dentro del grafo de PipeWire**, sin conversiones de más a nivel de aplicación y sin registrar un "stream de grabación".

```
Tocadiscos → Line-In de la PC → [pw-link directo] → Salida → Preamp → Amplificador → Parlantes
```

> Si tu ampli **sí** tiene una entrada de línea libre, no necesitás esto: andá analógico directo. Esta herramienta es para cuando la PC es tu único punto de entrada.

## ¿Por qué `pw-link` y no `module-loopback`?

`module-loopback` crea un *stream de grabación* sobre el Line-In → GNOME muestra el **indicador de micrófono** (privacidad). `pw-link` conecta los puertos directo en el grafo, **sin cliente de grabación**, así que GNOME no muestra nada. Atacamos la raíz, no ocultamos el ícono (eso sería un agujero de privacidad real).

---

## Requisitos

- **PipeWire** con `pw-link` y `pactl` (WirePlumber/pipewire-pulse).
- **fish** shell (las funciones son fish; podés llamarlas desde cualquier lado con `fish -c`).
- **GNOME Shell 45+** (formato ESM) para el botón. Probado en **GNOME 50 / Wayland**.
- `amixer` (alsa-utils) — opcional, para ajustar niveles de captura.
- Una entrada **Line-In** (jack azul) o equivalente que exponga el puerto `analog-input-linein`.

## Instalación

```sh
git clone <URL-de-este-repo> vinilo-toggle
cd vinilo-toggle
./install.sh
```

En **GNOME Wayland**, después de instalar **cerrá sesión y volvé a entrar** (Wayland no recarga extensiones en vivo). Vas a ver el botón de tornamesa en la barra.

## Uso

| Cómo | Qué hace |
|------|----------|
| Clic en el botón de tornamesa | Prende/apaga el enrutado del vinilo |
| `vinilo-on` | Prende (desde la terminal) |
| `vinilo-off` | Apaga |
| `vinilo-status` | Imprime `on` / `off` |

El botón se **sincroniza con el estado real**: aunque prendas/apagues por terminal, el ícono se actualiza.

## Configuración (opcional)

Por defecto **auto-detecta** la entrada Line-In, la salida (misma placa) y el índice de placa ALSA. Para forzar valores, creá `~/.config/vinilo/config.fish`:

```fish
set -gx VINILO_SOURCE alsa_input.pci-0000_00_1f.3.analog-stereo
set -gx VINILO_SINK   alsa_output.pci-0000_00_1f.3.analog-stereo
set -gx VINILO_CARD   0
# Pares salida:entrada (estereo analogico estandar)
set -gx VINILO_PORTS  capture_FL:playback_FL capture_FR:playback_FR
# Nivel del ADC. 0dB = sin ganancia (lo mas limpio, el preamp ya da el nivel).
# Si tu preamp clippea, atenua con un valor negativo (ej "-6dB").
set -gx VINILO_CAPTURE 0dB
set -gx VINILO_BOOST   0
```

Para ver tus dispositivos:

```sh
pactl list short sources   # entradas
pactl list short sinks      # salidas
pw-link -o                  # puertos de salida (capture_*)
pw-link -i                  # puertos de entrada (playback_*)
```

## Troubleshooting

- **Ruido blanco / estática**: la ganancia de captura está demasiado alta. `vinilo-on` pone `Line Boost = 0` y el ADC en `0dB` (sin ganancia — el preamp ya da el nivel). **No uses `pactl set-source-volume` para esto**: en el ALC1220 mapea el ADC y de 40%+ lo clava en +30dB → estática. El nivel se ajusta con `VINILO_CAPTURE` (amixer), y el volumen, en el amplificador.
- **No suena nada**: confirmá que el cable está en el Line-In correcto y que tu salida (`VINILO_SINK`) es la que va al ampli. Probá `vinilo-status` (debe decir `on`).
- **El botón no aparece**: en Wayland, relogueá. Verificá con `gnome-extensions info vinilo@banar.local` y los logs: `journalctl --user -b 0 -o cat | grep -i vinilo`.
- **Sigue el ícono de micrófono**: asegurate de NO tener un `module-loopback` viejo cargado: `pactl list short modules | grep loopback` → si hay, `vinilo-off` lo limpia.

## Desinstalar

```sh
./uninstall.sh
```

## Cómo funciona (por dentro)

- `_vinilo_devices.fish` resuelve `SOURCE`/`SINK`/`CARD`/`PORTS` (auto-detección + override).
- `vinilo-on` ajusta niveles, pone la entrada en Line-In y crea los `pw-link` salida→entrada.
- `vinilo-off` borra esos links.
- `vinilo-status` parsea `pw-link -l` y reporta si el link específico capture→playback existe.
- La extensión GNOME es un `PanelMenu.Button` sin menú que llama a esas funciones vía `fish -c` y refleja el estado con dos íconos symbolic (recoloreados por el shell; verde cuando está activo).

## Licencia

MIT — ver [LICENSE](LICENSE).
