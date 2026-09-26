// =====================================================================
// FUNCIONES Y HELPERS DIDÁCTICOS (CUADROS Y CAJAS DE COLORES)
// =====================================================================

#let cuadro-concepto(titulo: "Concepto Clave", color-base: rgb("#1a5fb4"), cuerpo) = block(
  width: 100%,
  fill: color-base.lighten(92%),
  stroke: (left: 4pt + color-base),
  inset: (x: 10pt, y: 8pt),
  radius: (right: 4pt),
  above: 1.2em,
  below: 1.2em,
)[
  #text(weight: "bold", fill: color-base.darken(25%))[#titulo] \
  #v(0.3em)
  #cuerpo
]

#let cuadro-ejemplo(titulo: "Ejemplo Práctico", cuerpo) = block(
  width: 100%,
  fill: rgb("#f0fdf4"),
  stroke: (left: 4pt + rgb("#16a34a")),
  inset: (x: 10pt, y: 8pt),
  radius: (right: 4pt),
  above: 1.2em,
  below: 1.2em,
)[
  #text(weight: "bold", fill: rgb("#15803d"))[#titulo] \
  #v(0.3em)
  #cuerpo
]

#let cuadro-atencion(titulo: "¡Atención / Cuidado!", cuerpo) = block(
  width: 100%,
  fill: rgb("#fef2f2"),
  stroke: (left: 4pt + rgb("#dc2626")),
  inset: (x: 10pt, y: 8pt),
  radius: (right: 4pt),
  above: 1.2em,
  below: 1.2em,
)[
  #text(weight: "bold", fill: rgb("#b91c1c"))[#titulo] \
  #v(0.3em)
  #cuerpo
]

#let cuadro-registro(titulo, direccion, cuerpo) = block(
  width: 100%,
  fill: rgb("#f8fafc"),
  stroke: 0.8pt + rgb("#cbd5e1"),
  inset: 10pt,
  radius: 5pt,
  above: 1.2em,
  below: 1.2em,
)[
  #grid(
    columns: (1fr, auto),
    [*#text(fill: rgb("#0f172a"), size: 10.5pt)[#titulo]*],
    [#box(fill: rgb("#e2e8f0"), inset: (x: 6pt, y: 2.5pt), radius: 3pt)[#text(size: 8.5pt, font: "Linux Biolinum O", weight: "bold", fill: rgb("#334155"))[#direccion]]]
  )
  #v(0.3em)
  #line(length: 100%, stroke: 0.5pt + rgb("#cbd5e1"))
  #v(0.4em)
  #cuerpo
]


// =====================================================================
// SECCIÓN 1: BUSES DE DATOS Y DIRECCIONES
// =====================================================================

= Buses de Datos y de Direcciones

Un microcontrolador (MCU) integra la CPU, la memoria y los periféricos en un solo chip (*System on Chip - SoC*). Para coordinar la transferencia de información entre estos bloques internos se utiliza un conjunto de conductores llamados *buses*.

#cuadro-concepto(titulo: "Concepto de Buses de Interconexión")[
  La CPU se comunica con la memoria RAM, Flash y los periféricos mapeados a través de tres conjuntos principales de señales:
  - *Address Bus (Bus de Direcciones):* Unidireccional (proviene de la CPU). Especifica *con qué dispositivo o posición de memoria* se desea comunicar la CPU.
  - *Data Bus (Bus de Datos):* Bidireccional. Transporta *el valor real* que se lee o se escribe.
  - *Control Bus / Lógica de Control (R/W):* Indica el tipo de operación (Lectura: $R\/w = 1$, Escritura: $R\/w = 0$).
]

#figure(
  table(
    columns: (1.2fr, 1fr, 2fr),
    inset: 6pt,
    align: (left, center, left),
    stroke: 0.5pt + rgb("#cbd5e1"),
    fill: (_, y) => if y == 0 { rgb("#e2e8f0") } else if calc.even(y) { rgb("#f8fafc") },
    table.header([*Bus / Señal*], [*Dirección*], [*Función Principal*]),
    [*Address Bus*], [CPU $->$ Periférico], [Selecciona la posición de memoria o registro interno a acceder.],
    [*Data Bus*], [CPU $<->$ Periférico], [Transfiere la palabra de datos (8, 16 o 32 bits según la arquitectura).],
    [*Control ($R\/w$)*], [CPU $->$ Periférico], [Establece si se lee ($1$) o si se escribe ($0$) sobre el bus.]
  ),
  caption: [Resumen de los buses de interconexión interna del microcontrolador.]
)

== Buffers Tri-State y Lógica de Decodificación

Dado que múltiples periféricos (RAM, Flash, GPIO, Timers, ADC) comparten el mismo *Data Bus*, se debe evitar que más de un dispositivo intente imponer un nivel lógico simultáneamente, lo cual generaría un cortocircuito (*conflicto de bus*).

#grid(
  columns: (1fr, 1fr),
  gutter: 12pt,
  block(
    fill: rgb("#f1f5f9"),
    inset: 8pt,
    radius: 4pt,
    stroke: 0.5pt + rgb("#cbd5e1")
  )[
    *Estados Lógicos de un Buffer Tri-State:*
    - *Baja Impedancia:* Conectado al bus. Puede imponer nivel $1$ o $0$.
    - *Alta Impedancia ($Z$):* Desconectado eléctricamente del bus. No interfiere con otros dispositivos.
  ],
  block(
    fill: rgb("#f1f5f9"),
    inset: 8pt,
    radius: 4pt,
    stroke: 0.5pt + rgb("#cbd5e1")
  )[
    *Decodificador de Direcciones (Address Decoder):*
    Analiza el *Address Bus* y activa la línea *Chip Select ($"CS"$)* únicamente del periférico correspondiente al rango de direcciones solicitado.
  ]
)

#cuadro-ejemplo(titulo: "Ejemplo de Ciclo de Lectura / Escritura")[
  1. *Lectura:* La CPU ejecuta la instrucción `LDAA $1000`.
     - Pone la dirección `$1000` en el *Address Bus*.
     - El *Address Decoder* activa el *Chip Select* del bloque correspondiente (ej. RAM).
     - La CPU pone $R \/ w = 1$.
     - El dispositivo en `$1000` pone su buffer en baja impedancia y coloca el dato en el *Data Bus*. La CPU lo guarda en el acumulador.
  2. *Escritura:* La CPU ejecuta `STAA $1000`.
     - Pone la dirección `$1000` en el *Address Bus* y $R\/w = 0$.
     - Coloca el valor del acumulador en el *Data Bus*. El periférico latché el dato en su registro interno.

#figure(
  image("/images/dataBus.png", width: 90%)
) <fig:dataBus>

]

// =====================================================================
// SECCIÓN 2: GPIO Y SUS CONCEPTOS CLAVE
// =====================================================================

= GPIO (General Purpose Input/Output)

Un *GPIO* es un periférico modular que permite a la CPU controlar o leer pines físicos del microcontrolador como entradas o salidas digitales.

#cuadro-concepto(titulo: "Mapeo en Memoria (Memory-Mapped I/O)")[
  Los registros que controlan los pines del GPIO están mapeados directamente en el mapa de memoria global del microcontrolador. Escribir o leer un pin digital equivale a realizar un acceso estándar a memoria sobre una dirección específica asignada a ese registro.
]

== Técnica de Readback (Lectura de Salidas)

El *Readback* es la capacidad del hardware de *leer el nivel lógico real* presente en un pin configurado como salida.

#grid(
  columns: (1.2fr, 0.8fr),
  gutter: 10pt,
  [
    *¿Para qué sirve el Readback?*
    1. *Verificación de Estado:* Confirmar si una salida físicamente cambió de estado o si existe una sobrecarga/falla en el circuito externo.
    2. *Operaciones de Modificación:* Permite leer el estado actual antes de realizar un cambio lógico atómico.
    3. *Diagnóstico:* Un pin de entrada configurado en el mismo nodo puede observar una salida para testear la integridad del circuito.
  ],
  block(
    fill: rgb("#fffbe2"),
    inset: 8pt,
    radius: 4pt,
    stroke: 0.5pt + rgb("#fe0000")
  )[
    *#text(fill: rgb("#b91c1c"))[Regla de Seguridad Electrica:]*
    Nunca se deben configurar dos pines como salidas conectadas al mismo conductor con niveles opuestos ($1$ y $0$), ya que se crea un camino directo a masa produciendo sobrecorriente y daño irreversible.
  ]
)

== Lógica Activa: Active-High vs. Active-Low

El nivel lógico ($1$ ó $0$) no siempre coincide con la función "activa" de un componente.

#figure(
  table(
    columns: (1fr, 1.2fr, 1.2fr, 1.5fr),
    inset: 6pt,
    align: center,
    stroke: 0.5pt + rgb("#cbd5e1"),
    fill: (_, y) => if y == 0 { rgb("#e2e8f0") },
    table.header([*Lógica*], [*Nivel Activo*], [*Simbología*], [*Ejemplo Típico*]),
    [*Active-High*], [HIGH ($V_"DD"$)], [Sin marca o `SIG`], [LED encendido al enviar $1$ a GND.],
    [*Active-Low*], [LOW  ($V_"SS"$)], [Barra `SIG`, `SIG_n`, burbuja en diagramas], [Botonera con Pull-Up o habilitación `LED_EN_n`.]
  ),
  caption: [Comparación entre Lógica Activa por Alto y Lógica Activa por Bajo.]
)

#figure(
  image("/images/active.png", width: 70%),
) <fig:active>

// =====================================================================
// SECCIÓN 3: PROPIEDADES ELÉCTRICAS DE UN PIN
// =====================================================================

= Propiedades Eléctricas de los Pines Digitales

Un pin de I/O no es un simple conductor; contiene circuitos de protección, transistores de conmutación y redes pasivas configurables por software.

#grid(
  columns: (1fr, 1fr),
  gutter: 10pt,
  block(
    fill: rgb("#f8fafc"),
    inset: 8pt,
    radius: 4pt,
    stroke: 0.5pt + rgb("#cbd5e1")
  )[
    *Diodos de Protección (ESD/Overvoltage):*
    Dos diodos clamping conectados entre el pin y $V_"DD"$ / $V_"SS"$. Conducen cuando $V_"pin" > V_"DD" + 0.3 V$ o $V_"pin" < -0.3 V$.
    #text(size: 8.5pt, fill: rgb("#dc2626"))[*Atención:* No deben usarse como reguladores permanentes de tensión.]
  ],
  block(
    fill: rgb("#f8fafc"),
    inset: 8pt,
    radius: 4pt,
    stroke: 0.5pt + rgb("#cbd5e1")
  )[
    *Resistencias de Pull-Up / Pull-Down:*
    Resistencias internas (típicamente $20 k Omega - 50 k Omega$) habilitables por software. Evitan que una entrada quede *flotante* (estado indeterminado sujeto a ruido electromagnético).
  ]
)

#figure(
  image("/images/pin.png", width: 70%),
) <fig:pin>

== Parámetros de Configuración Dinámica de Salida

1. *Drive Strength (Capacidad de Corriente - DSE):*
   - *Low Drive Strength:* Limita la corriente máxima de salida (ej. $2 "mA" $ a $4 "mA" $). Reduce el ruido y el consumo eléctrico.
   - *High Drive Strength:* Entrega mayor corriente (ej. $18 "mA" $ a $20 "mA" $) para manejar cargas mayores (LEDs, buzzers) directamente sin deformar la señal.
2. *Slew Rate Control (Velocidad de Transición - SRE):*
   - *Slew Rate Enable:* Limita la velocidad de cambio $d V / d t$ de la transición lógico-eléctrica.
   - *Ventaja:* Atenúa picos de alta frecuencia y reduce la Interferencia Electromagnética (EMI) y la diafonía en el PCB.

== Salidas Open-Drain / Drenador Abierto

En la configuración *Open-Drain*, el transistor MOSFET P superior se deshabilita. El pin solo puede conmutar entre *Masa ($0$)* y *Alta Impedancia ($Z$)*.

#cuadro-concepto(titulo: "Aplicaciones de Open-Drain")[
  - *Lógica Colector/Drenador Abierto (Wired-OR):* Permite conectar múltiples salidas al mismo bus (ej. I2C) con un único resistor de Pull-Up externo sin producir cortocircuitos.
  - *Traducción de Niveles de Tensión (Level Shifting):* Permite interfaz con circuitos de mayor voltaje (ej. controlar una línea de $5 V$ alimentando el Pull-Up a $5 V$ desde un microcontrolador de $3.3 V$).
]

#figure(
  image("/images/logica.png", width: 100%),
  caption: "Implementación de lógica digital con MOSFET y elevación de la tensión de salida"
) <fig:logica>

// =====================================================================
// SECCIÓN 4: EL MÓDULO GPIO EN EL KINETIS K64F
// =====================================================================

= El Módulo GPIO en el Microcontrolador NXP Kinetis K64F

El microcontrolador MK64FN1M0VLL12 (ARM Cortex-M4 a $120 "Mhz"$) posee *5 puertos paralelos de 32 bits*: `PORTA`, `PORTB`, `PORTC`, `PORTD` y `PORTE`.

== Registros de Datos CMSIS (Capa MCAL)

Para operar los datos del GPIO, el SDK provee punteros a la estructura `GPIO_Type` (`PTA`, `PTB`, `PTC`, `PTD`, `PTE`). Cada puerto cuenta con registros de 32 bits dedicados (Kinetis K64 - Reference Manual - Chapter 4):

#cuadro-registro("GPIOx_PDDR", "Port Data Direction Register (Offset: 0x14)")[
  Define la dirección del pin.
  - Bit en `0`: Pin configurado como *Entrada Digital (INPUT)*.
  - Bit en `1`: Pin configurado como *Salida Digital (OUTPUT)*.
]

#grid(
  columns: (1fr, 1fr),
  gutter: 10pt,
  cuadro-registro("GPIOx_PSOR", "Offset: 0x04")[
    *Port Set Output Register:*
    Escribir un `1` en el bit $n$ pone la salida en *HIGH ($1$)*. Escribir `0` no produce ningún efecto. Operación atómica sin modificar otros pines.
  ],
  cuadro-registro("GPIOx_PCOR", "Offset: 0x08")[
    *Port Clear Output Register:*
    Escribir un `1` en el bit $n$ fuerza la salida a *LOW ($0$)*. Escribir `0` no produce ningún efecto. Operación atómica.
  ]
)

#grid(
  columns: (1fr, 1fr),
  gutter: 10pt,
  cuadro-registro("GPIOx_PTOR", "Offset: 0x0C")[
    *Port Toggle Output Register:*
    Escribir un `1` en el bit $n$ *invierte el estado* de la salida ($0 -> 1$ ó $1 -> 0$). Operación atómica.
  ],
  cuadro-registro("GPIOx_PDIR", "Offset: 0x10")[
    *Port Data Input Register:*
    Registro de sólo lectura (`__I volatile const`). Retorna el valor lógico real capturado en los pines del puerto.
  ]
)

#figure(
  image("/images/gen.png", width: 80%),
  caption: "Registros de datos de un puerto GPIO"
)

#cuadro-atencion(titulo: "Ventaja de PSOR / PCOR / PTOR sobre Read-Modify-Write")[
  En microcontroladores tradicionales de 8 bits, para cambiar un solo bit se requería leer todo el puerto, hacer una máscara `OR`/`AND` y reescribir (`Read-Modify-Write`). Esto consume múltiples ciclos de instrucción y *no es atómico* (es susceptible a interrupciones intermedias). En el K64F, escribir en `PSOR`, `PCOR` o `PTOR` altera *exclusivamente el bit deseado en un único ciclo de reloj de bus*.
]



// =====================================================================
// SECCIÓN 5: PIN CONTROL REGISTER (PCR)
// =====================================================================

= Pin Control Register (PCR) y Configuración Individual

Cada pin físico de cada puerto posee su propio registro de control individual de 32 bits llamado *`PORTX_PCRn`* (donde $X in \{A, B, C, D, E\}$ y $n in \{0 dots 31\}$).

== Campos Clave del Registro `PORTx_PCRn`

#figure(
  table(
    columns: (1fr, 1.2fr, 2.5fr),
    inset: 5pt,
    stroke: 0.5pt + rgb("#cbd5e1"),
    fill: (_, y) => if y == 0 { rgb("#e2e8f0") } else if calc.even(y) { rgb("#f8fafc") },
    table.header([*Campo*], [*Bits*], [*Descripción y Valores*]),
    [*ISF*], [24], [*Interrupt Status Flag:* Se pone en $1$ cuando ocurre el evento de interrupción configurado. Se limpia escribiendo un $1$ (*w1c*).],
    [*IRQC*], [19:16], [*Interrupt Configuration:* Selecciona el modo de interrupción/DMA (`0000` = Deshabilitado; `1001` = Flanco de Subida; `1010` = Flanco de Bajada; `1011` = Ambos Flancos; `1100` = Nivel Lógico $0$).],
    [*LK*], [15], [*Lock Register:* Si se escribe $1$, bloquea los bits $[15:0]$ del PCR hasta el próximo Reset del microcontrolador.],
    [*MUX*], [10:8], [*Pin Mux Control:* Selecciona qué periférico interno se conecta al pin físico. Ver tabla MUX abajo.],
    [*DSE*], [6], [*Drive Strength Enable:* $0$ = Baja capacidad de corriente; $1$ = Alta capacidad de corriente.],
    [*SRE*], [2], [*Slew Rate Enable:* $0$ = Rápido (Fast); $1$ = Lento/Controlado (Slow).],
    [*PE*], [1], [*Pull Enable:* $0$ = Resistencia de Pull deshabilitada; $1$ = Habilitada.],
    [*PS*], [0], [*Pull Select:* $0$ = Internal *Pull-Down*; $1$ = Internal *Pull-Up* (requiere `PE = 1`).]
  ),
  caption: [Distribución de campos en el Pin Control Register (PCR).]
)

== Multiplexación de Pines (Campo MUX)

#grid(
  columns: (1.2fr, 1fr),
  gutter: 12pt,
  table(
    columns: (1fr, 2fr),
    inset: 5pt,
    stroke: 0.5pt + rgb("#cbd5e1"),
    fill: (_, y) => if y == 0 { rgb("#e2e8f0") },
    table.header([*Valor MUX*], [*Función del Pin*]),
    [`000` (ALT0)], [Pin Deshabilitado / Entrada Analógica (ADC/CMP)],
    [*`001` (ALT1)*], [*GPIO (General Purpose I/O)*],
    [`010` (ALT2)], [Periférico dedicado 1 (ej. UART, SPI)],
    [`011` (ALT3)], [Periférico dedicado 2 (ej. FTM / Timer)],
    [`100..111`], [Otras alternativas del Datasheet (ej. Trace, I2S)]
  ),
  block(
    fill: rgb("#f1f5f9"),
    inset: 8pt,
    radius: 4pt,
    stroke: 0.5pt + rgb("#cbd5e1")
  )[
    *Registros Globales de PCR:*
    Para evitar configurar los 32 pines uno por uno en código redundante:
    - *`PORTx_GPCLR`:* Escribe la misma configuración en los bits $[15:0]$ del PCR de múltiples pines.
    - *`PORTx_GPCHR`:* Idem para los bits $[31:16]$.
  ]
)

// =====================================================================
// SECCIÓN 6: SECUENCIA DE CONFIGURACIÓN Y CÓDIGO C
// =====================================================================

= Secuencia Paso a Paso para Configurar un Pin como GPIO

#cuadro-atencion(titulo: "REGLA DE ORO: System Clock Gating Control (SCGC)")[
  Por defecto, tras un Reset, *los relojes de todos los puertos están deshabilitados* para minimizar el consumo. Intenta leer o escribir cualquier registro de un puerto (`PCR` o `GPIO`) sin haber habilitado primero su reloj en `SIM->SCGC5` provocará una excepción de hardware inmediata (*HardFault*).
]

#figure(
  image("/images/gate2.png", width: 100%)
) 

== Algoritmo de Inicialización Estándar

1. *Habilitar el Clock del Puerto:* Setear el bit correspondiente en `SIM->SCGC5` (ej. `SIM_SCGC5_PORTB_MASK`).
2. *Configurar el Registro PCR (`PORTx_PCRn`):*
   - Asignar `MUX = 1` (`ALT1`) para operar como GPIO.
   - Configurar resistores de Pull-Up/Pull-Down, Drive Strength y Slew Rate según la necesidad eléctrica del circuito.
3. *Definir Dirección en `GPIOx_PDDR`:*
   - Setear bit en $0$ para Entrada (INPUT).
   - Setear bit en $1$ para Salida (OUTPUT).
4. *Operación de Lectura / Escritura:* Operar sobre los registros de datos (`PSOR`, `PCOR`, `PTOR`, `PDIR`).

== Ejemplo en Código C (Capas MCAL y Driver)

El siguiente código ilustra la inicialización y uso de un LED (Salida en `PTB21`) y un Pulsador con Pull-Up (Entrada en `PTA4`):

```c
#include "MK64F12.h"
#include <stdbool.h>

void App_Init(void) {
    // 1. GATING: Habilitar relójes de los puertos A y B en la SIM. Operacion OR
    SIM->SCGC5 |= SIM_SCGC5_PORTA_MASK | SIM_SCGC5_PORTB_MASK;

    // 2. CONFIGURACIÓN DE SALIDA (LED Rojo en PTB21)
    // Limpiar PCR y seleccionar MUX = ALT1 (GPIO) + High Drive Strength
    PORTB->PCR[21] = PORT_PCR_MUX(1) | PORT_PCR_DSE_MASK;
    
    // Configurar dirección como Salida en PDDR
    PTB->PDDR |= (1 << 21);

    // Estado inicial: Apagar LED (Supóngase Active-Low, se envía HIGH con PSOR)
    PTB->PSOR = (1 << 21);

    // 3. CONFIGURACIÓN DE ENTRADA (Pulsador SW3 en PTA4)
    // MUX = ALT1 (GPIO) + Habilitar Pull-Up interno (PE=1, PS=1)
    PORTA->PCR[4] = PORT_PCR_MUX(1) | PORT_PCR_PE_MASK | PORT_PCR_PS_MASK;

    // Configurar dirección como Entrada en PDDR (bit en 0)
    PTA->PDDR &= ~(1 << 4);
}

void App_Run(void) {
    // Leer estado del pulsador desde PDIR
    bool sw3_presionado = !(PTA->PDIR & (1 << 4)); // Active-Low

    if (sw3_presionado) {
        // Si se presiona, encender LED (forzar a LOW con PCOR)
        PTB->PCOR = (1 << 21);
    } else {
        // De lo contrario, apagar LED (forzar a HIGH con PSOR)
        PTB->PSOR = (1 << 21);
    }
}
```

// =====================================================================
// FIN DEL DOCUMENTO
// =====================================================================
