// =====================================================================
// CLASE 7: PROTOCOLO CAN (CONTROLLER AREA NETWORK), BIT TIMING Y FILTROS
// =====================================================================
// 
// 
// ==========================================
// FUNCIONES DE CUADROS DIDÁCTICOS (CALLOUTS)
// ==========================================

#let cuadro-concepto(titulo: [Concepto Clave], cuerpo) = block(
  width: 100%, inset: 10pt, radius: 4pt,
  fill: rgb("#e8f4f8"), stroke: (left: 4pt + rgb("#1b6ec2")),
  [
    #text(weight: "bold", fill: rgb("#104e8b"), size: 10.5pt)[💡 #titulo] \
    #v(0.4em)
    #cuerpo
  ]
)

#let cuadro-ejemplo(titulo: [Ejemplo Práctico], cuerpo) = block(
  width: 100%, inset: 10pt, radius: 4pt,
  fill: rgb("#eafaf1"), stroke: (left: 4pt + rgb("#2ecc71")),
  [
    #text(weight: "bold", fill: rgb("#1e8449"), size: 10.5pt)[🛠️ #titulo] \
    #v(0.4em)
    #cuerpo
  ]
)

#let cuadro-atencion(titulo: [¡Atención / Cuidado!], cuerpo) = block(
  width: 100%, inset: 10pt, radius: 4pt,
  fill: rgb("#fdf2e9"), stroke: (left: 4pt + rgb("#e67e22")),
  [
    #text(weight: "bold", fill: rgb("#a04000"), size: 10.5pt)[⚠️ #titulo] \
    #v(0.4em)
    #cuerpo
  ]
)

#let cuadro-registro(titulo: [Detalle Técnico / Registro], cuerpo) = block(
  width: 100%, inset: 10pt, radius: 4pt,
  fill: rgb("#f4ecf7"), stroke: (left: 4pt + rgb("#8e44ad")),
  [
    #text(weight: "bold", fill: rgb("#5b2c6f"), size: 10.5pt)[⚙️ #titulo] \
    #v(0.4em)
    #cuerpo
  ]
)


= Clase 7

== Protocolo CAN (Controller Area Network)

/*
#text(fill: red)[
  #figure(
    image("/images/can-car-ecu.png", width: 75%),
    caption: [Red CAN e interconexión de ECUs en un automóvil moderno]
  )
]
*/

#figure(
    image("/images/CAN-contr.png", width: 75%),
)

#figure(
    image("/images/CAN1.png", width: 75%),
)

=== Arquitectura y Características Principales

CAN es un estándar de bus serie asíncrono, multimaestro y altamente robusto diseñado originalmente por Bosch para aplicaciones automotrices e industriales (ISO 11898). Permite que múltiples Unidades de Control Electrónico (ECUs) se comuniquen sobre un bus común sin necesidad de un nodo maestro central o controlador host.

Características fundamentales del protocolo:
- *Multimaestro / Asíncrono:* Cualquier nodo puede iniciar la transmisión cuando el bus está libre (*Idle*).
- *Orientado a Mensajes:* Los mensajes no contienen direcciones de nodo origen o destino; en su lugar, incorporan un *Identificador (ID)* que define la naturaleza del dato y su prioridad.
- *Inmunidad al Ruido:* Utiliza señalización diferencial sobre par trenzado.
- *Arbitraje No Destructivo:* Resuelve colisiones en tiempo real mediante lógica de bus dominante/recesivo (*Wired-AND*).
- *Detección y Manejo de Errores:* Lógica integrada por hardware para contención y aislamiento de fallas.

=== Capa Física y Señal Diferencial

A nivel eléctrico, el bus CAN se compone de un par de cables trenzados (*twisted pair*) denominados *CANH* ($"CAN"+$ y *CANL* ($"CAN"-$, acompañados por una referencia común de masa ($"GND"$). Para evitar reflexiones de onda electromagnética en altas frecuencias, el bus exige *resistencias de terminación de $120  Omega$* instaladas en ambos extremos físicos de la línea.

/*
#text(fill: red)[
  #figure(
    image("/images/can-bus-topology.png", width: 80%),
    caption: [Topología del bus CAN diferencial con resistencias terminadoras de 120 Ω]
  )
]
*/

El bus opera bajo dos estados eléctricos distintos que implementan la lógica *Wired-AND*:

#grid(
  columns: (1fr, 1fr),
  gutter: 10pt,
  [
    #cuadro-registro(titulo: [Estado Recesivo ('1' Lógico)])[
      - Transceptores en alta impedancia (apagados).
      - Las líneas descansan pasivamente a través de resistencias *pull-middle*.
      - Voltaje: $V_"CANH" = 2.5 "V"$, $V_"CANL" = 2.5 "V"$.
      - Tensión diferencial: $V_"diff" = V_"CANH" - V_"CANL" = 0 "V"$.
    ]
  ],
  [
    #cuadro-registro(titulo: [Estado Dominante ('0' Lógico)])[
      - Transceptores activos excitando la línea.
      - Se fuerzan niveles de tensión separados.
      - Voltaje: $V_"CANH" = 3.5 "V"$, $V_"CANL" = 1.5 "V"$.
      - Tensión diferencial: $V_"diff" = 2.0 "V"$.
    ]
  ]
)

#cuadro-concepto(titulo: [Lógica Wired-AND y Colisión])[
Al ser un bus cableado en configuración *Wired-AND*, si dos nodos intentan transmitir simultáneamente y uno de ellos impone un estado *Dominante ('0')* mientras el otro envía un *Recesivo ('1')*, el estado dominante sobrescribe físicamente al recesivo en todo el bus. Esto permite resolver colisiones sin destruir el mensaje dominante.
]

/*
#text(fill: red)[
  #figure(
    image("/images/can-differential-signals.png", width: 80%),
    caption: [Formas de onda de CANH, CANL y la tensión diferencial Vdiff (Dominante vs. Recesivo)]
  )
]
*/
=== Estructura de Trama, Arbitraje y Bit Stuffing

==== Trama de Datos Estándar (Standard Data Frame)

Un *Data Frame* Estándar (CAN 2.0A) se compone de los siguientes campos secuenciales:

#table(
  columns: (1.5fr, 1fr, 3fr),
  inset: 6pt,
  stroke: 0.5pt + luma(180),
  fill: (_, y) => if y == 0 { rgb("#1a5fb4") } else if calc.odd(y) { rgb("#f4f7fa") },
  align: (left, left, left),
  table.header([*Campo*], [*Longitud*], [*Descripción*]),
  [*SOF* (Start of Frame)], [1 bit], [Bit dominante ($1 -> 0$) que marca el inicio de trama y sincroniza a todos los nodos.],
  [*Arbitration Field*], [12 bits], [Contiene el *Identificador (ID)* de 11 bits y el bit *RTR* (0 = Data Frame, 1 = Remote Frame).],
  [*Control Field*], [6 bits], [Incluye bits de extensión/reserva (`IDE`, `r0`) y el `DLC` (Data Length Code, 4 bits: $0 .. 8$ bytes).],
  [*Data Field*], [$0 .. 8$ bytes], [Carga útil (*payload*) del mensaje ($0 .. 64$ bits).],
  [*CRC Field*], [16 bits], [Secuencia de verificación de redundancia cíclica de 15 bits + 1 bit `CRC Delimiter` (recesivo).],
  [*ACK Field*], [2 bits], [`ACK Slot` (1 bit, enviado recesivo por el emisor y forzado a dominante por receptores con CRC válido) + `ACK Delimiter` (1 bit recesivo).],
  [*EOF* (End of Frame)], [7 bits], [Fin de trama compuesto por 7 bits recesivos consecutivos.],
  [*ITM* (Intermission)], [3 bits], [Espacio de descanso recesivo obligatorio entre tramas (*Interframe Space*).]
)
/*
#text(fill: red)[
  #figure(
    image("/images/can-standard-frame.png", width: 90%),
    caption: [Estructura del Standard Data Frame en el bus CAN (CAN 2.0A)]
  )
]
*/

==== Arbitraje No Destructivo (CSMA/CD + AMP)

Cuando el bus entra en estado pasivo (*Idle*), cualquier nodo con un mensaje pendiente puede emitir el bit `SOF`. Si dos o más nodos inician la transmisión en el mismo instante:

1. Cada nodo transmite los bits de su `ID` mientras monitorea continuamente el nivel físico del bus.
2. Si un nodo envía un bit *recesivo ('1')* en su ID pero lee un nivel *dominante ('0')* en el bus, detecta que otro mensaje en competencia tiene mayor prioridad.
3. El nodo perdedor retira su transmisor inmediatamente, pasa a modo de solo escucha (*listening only*) y aguarda a que el bus vuelva a quedar libre.
4. *Regla de prioridad:* Cuanto *menor sea el valor numérico del ID*, mayor es su prioridad en la red (el bit dominante '0' predomina en las primeras posiciones).

==== Regla de Bit Stuffing

Debido a que CAN es un protocolo asíncrono sin línea física de reloj, los receptores dependen de las transiciones de voltaje ($1 -> 0$) para sincronizar sus relojes internos.

#cuadro-atencion(titulo: [Mecanismo de Bit Stuffing])[
Si el transmisor detecta *5 bits consecutivos de la misma polaridad* en el flujo de datos, el hardware inserta automáticamente *1 bit de relleno (Stuff Bit)* de polaridad opuesta antes de enviar el siguiente bit. Los nodos receptores remueven este bit de relleno de forma transparente antes de procesar la trama.

Esta regla se aplica estrictamente desde el bit `SOF` hasta el final de la secuencia `CRC` (se excluyen el `CRC Delimiter`, el campo `ACK` y el `EOF`).
]

/*
#text(fill: red)[
  #figure(
    image("/images/can-bit-stuffing.png", width: 85%),
    caption: [Inserción de Stuff Bits de polaridad opuesta tras 5 bits consecutivos del mismo nivel]
  )
]
*/

=== Base de Tiempo y Sincronización (Nominal Bit Time)

==== División del Bit en Time Quanta $t\_q$

En redes CAN, la duración de cada bit (*Nominal Bit Time*) se subdivide en $N$ unidades discretas de tiempo denominadas *Time Quanta* ($t\_q$. La duración de 1 $ t\_q$ se deriva del reloj interno del microcontrolador ($f_"osc"$ mediante el divisor *Baud Rate Prescaler* ($"BRP"$.

/*
#text(fill: red)[
  #figure(
    image("/images/can-nominal-bit-time.png", width: 85%),
    caption: [Estructura interna del Nominal Bit Time en sus cuatro segmentos de Time Quanta]
  )
*/

#figure(
    image("/images/can-time.png", width: 85%),
    caption: [Estructura interna del Nominal Bit Time en sus cuatro segmentos de Time Quanta]
)

El tiempo de bit se divide exactamente en cuatro segmentos configurables:

1. *Sync_Seg (Synchronization Segment):* Fijado siempre en 1 $t\_q$. Es el intervalo donde se espera que ocurra el flanco descendente ($1 -> 0$ que marca el inicio del bit.
2. *Prop_Seg (Propagation Segment):* Configurable de $1$ a 8 $t\_q$. Compensa los retrasos físicos de propagación de las ondas electromagnéticas a lo largo del cable y los retardo internos de los transceptores.
3. *Phase_Seg1 (Phase Buffer Segment 1):* Configurable de $1$ a 8 $t\_q$. Se ubica inmediatamente antes del *Sample Point*. Se alarga en la resincronización si el flanco llega tarde.
4. *Phase_Seg2 (Phase Buffer Segment 2):* Configurable de $1$ a 8 $t\_q$. Se ubica inmediatamente después del *Sample Point*. Se acorta en la resincronización si el flanco llega temprano.

#cuadro-concepto(titulo: [Sample Point (Punto de Muestreo)])[
El *Sample Point* es el instante exacto, situado justo al final de `Phase_Seg1`, en el que el nodo evalúa el estado lógico del bus (dominante o recesivo). Se suele configurar típicamente entre el $75\%$ y el $87.5\%$ de la duración total del bit.
]

=== Casos de Ajuste de Flanco y Resincronización (Nominal Bit Time)

En el protocolo CAN, la resincronización continua de los nodos receptores se realiza exclusivamente sobre los flancos descendentes ($1 -> 0$).

/*
#text(fill: red)[
  #figure(
    image("/images/can-resync-cases.png", width: 90%),
    caption: [Casos de alineación del flanco descendente y ajuste dinámico en el Nominal Bit Time]
  )
]
*/

*Caso 1: Flanco Ideal (Sin Ajuste)*
#figure(image("/images/caso1.png", width: 60%))

- *Ubicación del Flanco:* El flanco descendente ($1 -> 0$) llega exactamente dentro del segmento `Sync_Seg` (de duración fija $1 t\_q$).
- *Estado de Reloj:* El oscilador del nodo receptor está perfectamente sincronizado con el del transmisor.
- *Acción:* No se realiza ningún ajuste en la duración de los segmentos ($Delta t\_q = 0$) y el *Sample Point* permanece en su posición nominal.


*Caso 2: Flanco Tardío (Reloj del Transmisor Más Lento)*
#figure(image("/images/caso2.png", width: 60%))

- *Ubicación del Flanco:* El flanco descendente ($1 -> 0$) llega con retraso, cayendo en los segmentos `Prop_Seg` o `Phase_Seg1` en lugar de `Sync_Seg`.
- *Estado de Reloj:* El reloj del nodo transmisor es *más lento* que el del nodo receptor.
- *Mecanismo de Corrección:*
  - Se *alarga* el segmento `Phase_Seg1` agregando ciclos $t\_q$ adicionales.
  - La cantidad de ciclos agregados es igual al error de fase detectado, acotado por el valor máximo de `SJW` ($+ Delta t\_q <= "SJW"$).
  - *Efecto:* Se desplaza el *Sample Point* hacia la derecha (retrasando el momento de muestreo) para capturar correctamente el dato.


*Caso 3: Flanco Temprano (Reloj del Transmisor Más Rápido)*
#figure(image("/images/caso3.png", width: 60%))

- *Ubicación del Flanco:* El flanco descendente ($1 -> 0$) llega antes de lo esperado, cayendo dentro del segmento `Phase_Seg2` del bit anterior.
- *Estado de Reloj:* El reloj del nodo transmisor es *más rápido* que el del nodo receptor.
- *Mecanismo de Corrección:*
  - Se *acorta* el segmento `Phase_Seg2` substrayendo ciclos $t\_q$ de su duración.
  - La reducción está acotada por el valor máximo configurado en `SJW` ($- Delta t\_q <= "SJW"$).
  - *Efecto:* Adelanta la finalización del bit actual e inicia el próximo ciclo antes de lo nominal para reengancharse con el transmisor rápido.


#table(
  columns: (1fr, 1.2fr, 1.3fr, 1.8fr),
  inset: 6pt,
  stroke: 0.5pt + luma(180),
  fill: (_, y) => if y == 0 { rgb("#1a5fb4") } else if calc.odd(y) { rgb("#f4f7fa") },
  align: (left, left, left, left),
  table.header([*Caso*], [*Ubicación del Flanco*], [*Clock Transmisor*], [*Ajuste de Hardware*]),
  [*Caso 1: Ideal*], [Dentro de `Sync_Seg`], [Sincronizado], [Sin ajuste ($Delta t\_q = 0$).],
  [*Caso 2: Tardío*], [En `Prop_Seg` / `Phase_Seg1`], [Más lento], [Se alarga `Phase_Seg1` \
  ($+ Delta t\_q <= "SJW"$).],
  [*Caso 3: Temprano*], [En `Phase_Seg2` anterior], [Más rápido], [Se acorta `Phase_Seg2` \
  ($- Delta t\_q <= "SJW"$).]
)


/*
#text(fill: red)[
  #figure(
    image("/images/can-resynchronization-cases.png", width: 90%),
    caption: [Ajuste dinámico de Phase_Seg1 y Phase_Seg2 mediante SJW ante flancos tardíos y tempranos]
  )
]
*/

#cuadro-atencion(titulo: [¡Sincronización Solo en Flancos Descendentes!])[
En CAN, la sincronización se realiza *exclusivamente sobre los flancos descendentes ($1 -> 0$, paso a dominante)*. 

Los flancos ascendentes ($0 -> 1$, paso a recesivo) *no se utilizan* debido a que la subida del bus es pasiva (depende de la resistencia *pull-middle* y capacitancias parásitas del cable), generando pendientes lentas e imprecisas.
]

=== Filtrado por Hardware y Manejo de Errores

==== Filtrado de Mensajes (Filter y Mask)

Para evitar sobrecargar la CPU del microcontrolador analizando mensajes no relevantes, el módulo controlador CAN (como el FlexCAN en el Kinetis K64F) filtra las tramas por hardware mediante dos registros:

- *Filter (Identificador de Filtro):* Contiene el patrón binario de ID específico que el nodo está programado para recibir.
- *Mask (Máscara de Aceptación):* Define qué bits del ID deben coincidir obligatoriamente:
  - Bit de máscara en `'1'`: *Verificación estricta* (el bit del ID entrante debe ser idéntico al bit del filtro).
  - Bit de máscara en `'0'`: *Don't Care* (se ignora la coincidencia de ese bit en particular).


/*
#text(fill: red)[
  #figure(
    image("/images/can-filter-mask.png", width: 80%),
    caption: [Esquema de comparación de hardware entre el ID recibido, la Máscara y el Filtro]
  )
]
*/

==== Estados del Nodo y Manejo de Errores

Cada nodo CAN posee dos contadores internos de error mantenidos por hardware: `TEC` (*Transmit Error Counter*) y `REC` (*Receive Error Counter*). Según sus valores, el nodo transiciona entre tres estados de operación:

#table(
  columns: (1.5fr, 1.5fr, 3fr),
  inset: 6pt,
  stroke: 0.5pt + luma(180),
  fill: (_, y) => if y == 0 { rgb("#1a5fb4") } else if calc.odd(y) { rgb("#f4f7fa") },
  align: (left, left, left),
  table.header([*Estado del Nodo*], [*Condición de Errores*], [*Comportamiento en la Red*]),
  [*Error Active*], [$"TEC" < 128$ y $"REC" < 128$], [Operación normal. Al detectar un error, transmite un *Active Error Flag* (6 bits dominantes), abortando la trama de toda la red.],
  [*Error Passive*], [$"TEC" >= 128$ o $"REC" >= 128$], [El nodo está degradado. Transmite un *Passive Error Flag* (6 bits recesivos), evitando interrumpir la comunicación de otros nodos.],
  [*Bus Off*], [$"TEC" > 255$], [El nodo se desconecta lógicamente del bus. No puede transmitir ni recibir hasta reiniciar el módulo FlexCAN.]
)

/*
#text(fill: red)[
  #figure(
    image("/images/can-error-states.png", width: 75%),
    caption: [Diagrama de transición entre estados de error: Error Active, Error Passive y Bus Off]
  )
]
*/