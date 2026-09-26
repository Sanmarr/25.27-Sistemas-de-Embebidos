// ==========================================
// FUNCIONES DE CUADROS DIDÁCTICOS (CALLOUTS)
// ==========================================

#let cuadro-concepto(titulo:[Concepto Clave], cuerpo) = block(
  width: 100%, inset: 10pt, radius: 4pt,
  fill: rgb("#e8f4f8"), stroke: (left: 4pt + rgb("#1b6ec2")),
[
    #text(weight: "bold", fill: rgb("#104e8b"), size: 10.5pt)[💡 #titulo] \
    #v(0.4em)
    #cuerpo
  ]
)

#let cuadro-ejemplo(titulo:[Ejemplo Práctico], cuerpo) = block(
  width: 100%, inset: 10pt, radius: 4pt,
  fill: rgb("#eafaf1"), stroke: (left: 4pt + rgb("#2ecc71")),
[
    #text(weight: "bold", fill: rgb("#1e8449"), size: 10.5pt)[🛠️ #titulo] \
    #v(0.4em)
    #cuerpo
  ]
)

#let cuadro-atencion(titulo:[¡Atención / Cuidado!], cuerpo) = block(
  width: 100%, inset: 10pt, radius: 4pt,
  fill: rgb("#fdf2e9"), stroke: (left: 4pt + rgb("#e67e22")),
[
    #text(weight: "bold", fill: rgb("#a04000"), size: 10.5pt)[⚠️ #titulo] \
    #v(0.4em)
    #cuerpo
  ]
)

#let cuadro-registro(titulo:[Detalle Técnico / Registro], cuerpo) = block(
  width: 100%, inset: 10pt, radius: 4pt,
  fill: rgb("#f4ecf7"), stroke: (left: 4pt + rgb("#8e44ad")),
[
    #text(weight: "bold", fill: rgb("#5b2c6f"), size: 10.5pt)[⚙️ #titulo] \
    #v(0.4em)
    #cuerpo
  ]
)

= Fundamentos de la Comunicación Serial Asincrónica (UART)

La *UART* (*Universal Asynchronous Receiver-Transmitter*) es el módulo periférico encargado de traducir datos en paralelo (bytes dentro de la CPU) a un flujo secuencial de bits que viajan por una sola línea física de transmisión (TX) y se reciben por otra de recepción (RX).

== Estructura de la Trama UART Estándar
A diferencia de los protocolos sincrónicos (donde viaja una señal de reloj compartida), la UART es *asincrónica*: emisor y receptor acuerdan previamente una velocidad común llamada *Baud Rate* (bits por segundo, bps).

#cuadro-concepto(titulo:[Anatomía de una Trama de Datos])[
  - *Estado Reposo (Idle):* La línea física permanece en nivel lógico *HIGH (1)*.
  - *Start Bit (1 bit):* Transición de `1` a `0` (flanco de bajada) que indica al receptor el inicio inminente de un byte.
  - *Bits de Datos (8 o 9 bits):* Se envían secuencialmente empezando *siempre por el bit menos significativo (LSB primero)*.
  - *Bit de Paridad (Opcional):* Bit de verificación de redundancia (paridad PAR o IMPAR) para detectar corrupción en la línea.
  - *Stop Bit (1 o 2 bits):* Retorno de la línea a nivel lógico *HIGH (1)* para finalizar el frame y restablecer el reposo.
]

#v(0.5em)

#table(
  columns: (1.5fr, 1fr, 3fr, 1.2fr, 1.5fr),
  inset: 6pt,
  stroke: 0.5pt + luma(180),
  fill: (_, y) => if y == 0 { rgb("#0f2b48") } else if calc.odd(y) { rgb("#f9f9f9") },
  align: (center, center, center, center, center),
  table.header(
  [ *IDLE* ],[ *START* ],[ *BITS DE DATOS (D0 .. D7)* ],[ *PARIDAD* ],[ *STOP* ]
  ),
[ Nivel HIGH (`1`) ],[ `0` (1 bit) ],[ LSB primero $ -> $ MSB último (8 bits) ],[ Opcional ],[ Nivel HIGH (`1`) ]
)

== Estándares Eléctricos y Conversión de Niveles

El microcontrolador Kinetis K64F opera externamente con niveles *TTL / CMOS (0V = '0', 3.3V = '1')*. Para interconectarse con computadoras u otros sistemas industriales se requieren integrados conversores:

#grid(
  columns: (1fr, 1fr),
  gutter: 12pt,
[
    #cuadro-concepto(titulo:[Norma RS-232])[
      - Utiliza lógica invertida con altos voltajes:
        - `'0'` lógico: $+3"V"$ a $+15"V"$
        - `'1'` lógico: $-3"V"$ a $-15"V"$
      - Requiere un chip transceptor (ej. MAX232) para adaptar los niveles eléctricos a los $3.3"V"$ del microcontrolador.
    ]
  ],
[
    #cuadro-concepto(titulo:[Interfaz USB-UART (OpenSDA)])[
      - La placa *FRDM-K64F* incluye un segundo chip microcontrolador configurado como interfaz *OpenSDA*.
      - Convierte las señales RX/TX del puerto `UART0` en un puerto COM virtual USB para la PC.
    ]
  ]
)

= Cálculo y Ajuste Fino del Baud Rate en Kinetis K64F

Para lograr un muestreo preciso sin deriva temporal en comunicaciones asincrónicas, el K64F dispone de una arquitectura de división de reloj con *ajuste grueso ($"SBR"$)* y *ajuste fino ($"BRFA"$)*.

== Fórmula Matemática del Baud Rate

$ "Baud Rate" = "UART_Clock" / (16 times ("SBR" + "BRFA" / 32)) $

#cuadro-registro(titulo:[Campos de Registros para el Baud Rate])[
  1. *Modulo Baud Rate $"SBR"$ (13 bits):*
     - Dividido en dos registros: `UARTx->BDH` (bits[12:8] altos) y `UARTx->BDL` (bits[7:0] bajos).
     - Valor entero de división gruesa: $"SBR" = floor("UART_Clock" / (16 times "Baud Rate"))$.
  2. *Baud Rate Fine Adjust $"BRFA"$ (5 bits):*
     - Ubicado en los bits[4:0] del registro `UARTx->C4`.
     - Permite ajustar la parte fraccionaria multiplicando el residuo decimal por $32$:
       $ "BRFA" = "round"((("UART_Clock" / (16 times "Baud Rate")) - "SBR") times 32) $
]

#cuadro-ejemplo(titulo:[Ejemplo de Cálculo para 115200 Baudios a 60 MHz])[
  Si el reloj asignado al periférico UART es $f_"bus"= 60"MHz"$ y se requiere operar a $115200 "baudios"$:
  1. $"Divisor Teórico" = 60 times 10^6 / (16  times 115200) = 32.55208$

  2. $"SBR" = 32 -> "Escribir" 32 "en" "BDL" ("BDH"=0)$.

  3. $"Parte Fraccionaria" = 0.55208  times 32 = 17.666 -> "BRFA" = 18   ("Escribir" 18 "en" "C4")$.
]

= 3. Registros de Datos, Estado y Control del Periférico (`UARTx`)

En el SDK de NXP / CMSIS, la comunicación UART se controla a través de la estructura `UART_Type`.

#table(
  columns: (1.5fr, 1.2fr, 3.5fr),
  inset: 6pt,
  stroke: 0.5pt + luma(180),
  fill: (_, y) => if y == 0 { rgb("#0f2b48") } else if calc.odd(y) { rgb("#f9f9f9") },
  align: (left, center, left),
  table.header(
  [ *Registro* ],[ *Modo* ],[ *Descripción y Uso Técnico* ]
  ),
[ `UARTx->D` ],[ R / W ],[ *Registro de Datos:* Físicamente son dos buffers separados. Escribir en `D` coloca el byte en la cola de transmisión. Leer `D` retira el byte recibido de la cola de recepción. ],
[ `UARTx->S1` ],[ R / w1c ],[ *Status Register 1:* Contiene las banderas de estado del periférico (`TDRE`, `TC`, `RDRF`). ],
[ `UARTx->C2` ],[ R / W ],[ *Control Register 2:* Habilita el transmisor (`TE`), receptor (`RE`) e interrupciones (`TIE`, `RIE`). ],
[ `UARTx->C4` ],[ R / W ],[ *Control Register 4:* Contiene el ajuste fino de reloj (`"BRFA"`) y control de la FIFO. ]
)

== Banderas Clave de Estado (`UARTx->S1`)

#grid(
  columns: (1fr, 1fr, 1fr),
  gutter: 8pt,
[
    #cuadro-concepto(titulo:[1. `RDRF` (Bit 5)])[
      *Receive Data Register Full:*
      Se pone en `1` por hardware cuando ha ingresado un nuevo byte completo a la UART.
      *Limpieza:* Se limpia automáticamente al *leer `S1` y luego leer `D`*.
    ]
  ],
[
    #cuadro-concepto(titulo:[2. `TDRE` (Bit 7)])[
      *Transmit Data Register Empty:*
      Se pone en `1` cuando el buffer de transmisión está libre para recibir un nuevo byte.
      *Limpieza:* Se limpia automáticamente al *leer `S1` y luego escribir en `D`*.
    ]
  ],
[
    #cuadro-concepto(titulo:[3. `TC` (Bit 6)])[
      *Transmission Complete:*
      Se pone en `1` cuando *el último bit salió físicamente del pin TX*.
      *Uso:* Indispensable para transceptores RS-485 / RS-422 antes de cortar la línea.
    ]
  ]
)

= 4. Arquitectura de Firmware e Interrupciones en UART

Debido a que el tiempo de transmisión de un byte a $9600 "baudios"$ toma aproximadamente $1.04"ms"$ (un abismo en ciclos de CPU a $120"MHz"$), *nunca se debe utilizar código bloqueante en sistemas de tiempo real*.

== Estrategia de Interrupciones Compartidas (RX / TX Vector)
En el K64F, las interrupciones de transmisión y recepción de un mismo canal UART están *multiplexadas en un único vector de la IVT* (por ejemplo `UART0_RX_TX_IRQn`). Por lo tanto, la ISR debe consultar el registro `S1` para identificar la causa:

#cuadro-ejemplo(titulo:[Estructura Canónica de una ISR de UART])[
  ```c
  void UART0_RX_TX_IRQHandler(void) {
      uint8_t status = UART0->S1;

      // 1. ATENDER RECEPCIÓN (RDRF = 1)
      if (status & UART_S1_RDRF_MASK) {
          uint8_t data = UART0->D; // La lectura de D limpia el flag RDRF de forma automática
          RingBuffer_Put(&rx_queue, data);
      }

      // 2. ATENDER TRANSMISIÓN (TDRE = 1 y TIE habilitado)
      if ((status & UART_S1_TDRE_MASK) && (UART0->C2 & UART_C2_TIE_MASK)) {
          uint8_t tx_data;
          if (RingBuffer_Get(&tx_queue, &tx_data)) {
              UART0->D = tx_data; // La escritura en D limpia el flag TDRE
          } else {
              // Si no quedan datos para enviar, deshabilitar TIE para evitar un loop infinito de IRQs
              UART0->C2 &= ~UART_C2_TIE_MASK;
          }
      }
  }
  ```
]

#v(0.5em)

#cuadro-atencion(titulo:[Regla Crítica: Habilitación Dinámica de `TIE`])[
  A diferencia de la interrupción de recepción (`RIE`), la interrupción por buffer libre (`TIE`) *nunca debe dejarse habilitada de forma permanente*. Dado que el registro `D` permanece vacío la mayor parte del tiempo, si `TIE` se mantiene activo, la CPU caerá en un *bucle infinito de interrupciones de transmisión*.

  *Mecanismo Correcto:* `TIE` solo se activa por software en la función de envío cuando se encola un nuevo dato, y la propia ISR se encarga de apagar `TIE` cuando la cola de transmisión queda vacía.
]

= 5. Colas de Hardware (FIFOs) y Configuración de Watermark

Para aplicaciones con tráfico de datos intensivo a altas velocidades (ej. $1"Mbps"$), la arquitectura del Kinetis K64F incluye *FIFOs de hardware* independientes para TX y RX de hasta 8 bytes de capacidad.

== Concepto de Marca de Agua (Watermark)
La marca de agua (*Watermark*) permite programar el umbral exacto de llenado o vaciado de la FIFO que disparará la interrupción, reduciendo drásticamente la cantidad de llamadas a la ISR:

#grid(
  columns: (1fr, 1fr),
  gutter: 10pt,
[
    #cuadro-concepto(titulo:[Watermark en Recepción (`RWFIFO`)])[
      - Determina cuántos bytes deben acumularse en la FIFO de recepción antes de generar la IRQ.
      - *Ejemplo:* Si `RWFIFO = 4`, la CPU solo es interrumpida cuando la FIFO ha almacenado 4 bytes, procesándolos todos en una sola entrada a la ISR.
    ]
  ],
[
    #cuadro-concepto(titulo:[Watermark en Transmisión (`TWFIFO`)])[
      - Determina cuántas posiciones libres deben quedar en la FIFO de transmisión para solicitar recarga.
      - *Ejemplo:* Permite a la ISR rellenar hasta 8 bytes consecutivos de un tiro mediante una ráfaga (*burst*).
    ]
  ]
)

#v(0.5em)

#cuadro-registro(titulo:[Habilitación de FIFOs en `UARTx->PFIFO`])[
  - *`TXFE` / `RXFE` (Bits 7 y 3):* Habilitan la FIFO de transmisión y recepción respectivamente.
  - *`TXFIFOSIZE` / `RXFIFOSIZE`:* Informan la capacidad física de hardware soportada por el canal de la UART ($2^"SIZE"$ bytes).
]
