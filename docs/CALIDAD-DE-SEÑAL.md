# 🎚️ Calidad de señal — ¿qué tan limpio es esto?

Pregunta honesta: cuando escuchás el vinilo a través de la PC con esta herramienta,
¿estás escuchando la señal lo más limpia posible? Hay que separar **dos planos**:
el **software** (qué le hace PipeWire a los samples) y el **hardware** (los conversores).

---

## TL;DR

- **A nivel software: es el techo.** La señal viaja **bit-transparente**, sin resampling,
  sin volumen por software, sin conversión de formato, sin DSP. No se puede ganar un solo bit.
- **A nivel hardware: NO es lo más limpio absoluto.** Pasás por una vuelta de conversión
  Analógico→Digital→Analógico. El límite de fidelidad es el conversor de la placa madre.
  Lo único más limpio es **no pasar por la PC** (analógico puro) — pero eso es hardware.

---

## La cadena de señal

```
Tocadiscos → Line-In → [ADC] → PipeWire (pw-link directo) → [DAC] → Salida → Preamp → Ampli → Parlantes
            └─ analógico ─┘ └────────── digital ──────────┘ └───────── analógico ─────────┘
```

La PC actúa de **puente**: digitaliza lo que entra por el Line-In y lo devuelve por la
salida que va al amplificador. La parte de "software" es lo que pasa entre el ADC y el DAC.

---

## Plano SOFTWARE: por qué es lo más limpio posible

`pw-link` crea una conexión **directa nodo-a-nodo** en el grafo de PipeWire. Entre que el
sample entra (ADC) y sale (DAC) **no pasa por ningún procesamiento**:

| Riesgo de degradación | ¿Presente acá? | Por qué |
|-----------------------|----------------|---------|
| **Resampling** (conversión de sample-rate) | ❌ No | Capture y playback van a **48000 Hz** los dos, y son la **misma placa** → comparten reloj físico → no hace falta resampler |
| **Volumen por software** | ❌ No | El link es bit-transparente. La única ganancia es el **ADC analógico**, ANTES de digitalizar |
| **Conversión de formato** | ❌ No | `s32le` (32-bit) de punta a punta |
| **EQ / filtros / DSP** | ❌ No | No hay ningún efecto en el camino |
| **Glitches (xruns)** | ❌ No | `ERR = 0` |

Es prácticamente un `memcpy`: el número que sale del ADC es **el mismo** que entra al DAC.

### El detalle clave: la MISMA placa

Si el Line-In y la salida fueran **placas distintas** (ej. entrar por el onboard y salir por
un DAC USB), tendrían **relojes independientes**, y PipeWire estaría obligado a meter un
**resampler adaptativo** para que no se desincronicen — y eso SÍ procesa la señal.

Como entrás y salís por la **misma placa** (mismo reloj), el resampler **no existe**. Por eso
el loopback va a la salida onboard, **no** al DAC USB.

### Verificalo vos mismo

```sh
# Rate del grafo (debe coincidir con el de los nodos)
pw-metadata -n settings | grep clock.rate

# Rates de capture y playback (deben ser iguales -> sin resampling)
pw-top -b -n 1 | grep -E 'alsa_(input|output)'

# Que no haya un module-loopback (eso SI mete resampler + volumen)
pactl list short modules | grep loopback   # vacio = bien
```

Lo que **NO** tiene sentido tocar: `resample.quality` (no hay resampling) ni el `quantum`
(eso es latencia, no limpieza).

---

## Gain staging: el ADC en 0dB

Con un **preamp externo** que ya entrega line-level, el ADC de la PC **no necesita amplificar**:

- **`Capture` (ADC) = 0dB** → la PC no agrega ganancia, solo digitaliza. **Lo más limpio.**
- Bajar de 0dB solo **atenúa**: resignás nivel y usás menos bits del ADC (más ruido de
  cuantización). "Más bajo" **no** es "más limpio".
- El **volumen se controla en el amplificador**, no en el ADC.

> Si tu preamp es "caliente" (saca más que line-level) y clippea el ADC, ahí sí conviene
> atenuar: poné `VINILO_CAPTURE` negativo (ej `-6dB`) en `~/.config/vinilo/config.fish`.

---

## Plano HARDWARE: los tres niveles de "limpio"

| Nivel | Cadena | Conversiones | Notas |
|-------|--------|--------------|-------|
| 🥇 **Analógico puro** | Tocadiscos → Preamp → entrada analógica del ampli | **0** | Lo más limpio que existe. Requiere una entrada analógica libre en el ampli |
| 🥈 **Esta herramienta** | …→ Line-In → ADC→DAC → salida →… | **1 (AD/DA)** | Software óptimo. Cuello de botella = conversor de la placa |
| 🥉 **Mal configurado** | + boost/ganancia de más | 1 + ruido | Estática. Evitado con `Line Boost 0` y ADC a 0dB |

### ¿Cómo se llega al Nivel 1?

Un **selector RCA pasivo de 2 entradas** (~$10-15): el tocadiscos y la PC entran al selector,
y la salida va a la única entrada del preamp. Elegís con un switch. El vinilo **nunca toca la PC**.

### ¿Y para mejorar dentro del Nivel 2?

Una **interfaz de audio externa** (ADC dedicado) supera al conversor onboard. Solo tiene
sentido si querés quedarte con la PC en el camino (por ejemplo, para **grabar** los vinilos).

---

## Conclusión

A nivel **software no hay un bit que ganar**: la señal es bit-transparente. El límite de
fidelidad ahora es **puramente hardware** (el conversor de la placa). Lo mejorás con
hardware (interfaz externa) o salteándolo (analógico puro) — pero el software ya está
en el óptimo.
