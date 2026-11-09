// =====================================================================
// CLASE 9: ADC, CMP, PIT Y DMA EN KINETIS K64F
// =====================================================================

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

#let imagen(desc) = figure(
  rect(width: 100%, height: 6cm, fill: rgb("#f0f0f0"), stroke: 1pt + gray)[
    #align(center + horizon)[#text(fill: gray)[🖼️ #desc]]
  ]
)

// Tabla con encabezado azul y filas alternadas.
// Uso: #tabla((1fr, 2fr), ([Col 1], [Col 2]), [a], [b], [c], [d])
#let tabla(columnas, encabezado, ..filas) = table(
  columns: columnas,
  inset: 6pt,
  stroke: 0.5pt + luma(180),
  fill: (_, y) => if y == 0 { rgb("#1a5fb4") } else if calc.odd(y) { rgb("#f4f7fa") },
  align: left,
  table.header(..encabezado.map(h => text(fill: white, weight: "bold")[#h])),
  ..filas.pos()
)

// ==========================================
// CLASE 9
// ==========================================

= Clase 9

#cuadro-concepto(titulo: [Qué vemos en esta clase])[
Cuatro módulos del Kinetis K64F que, combinados, permiten *adquirir y mover datos sin cargar a la CPU*:
+ *ADC*: convierte una tensión analógica en un número.
+ *CMP*: compara dos tensiones y devuelve un 0 o un 1.
+ *PIT*: timer que marca el ritmo (cada cuánto tiempo pasa algo).
+ *DMA*: mueve datos de un lugar a otro sin intervención de la CPU.

La idea final es una cadena armada *toda por hardware*: *PIT → (trigger) → ADC o DMA → memoria*.
]

// =====================================================================
== ADC: Conversor Analógico–Digital
// =====================================================================

=== 1. Qué es y qué tiene el K64F

Un ADC transforma una tensión (analógica) en un número entero (digital). El K64F tiene *dos módulos ADC de 16 bits* con arquitectura *SAR (Successive Approximation Register)*: el conversor va decidiendo el resultado *un bit por vez, del más significativo al menos significativo*, comparando la entrada contra una tensión generada por un DAC interno (es como una búsqueda binaria).

Cada módulo admite:

- *Hasta 24 canales Single Ended* (`AD[y]`, con `y` = número de canal): se mide la tensión de un pin respecto de masa.
- *4 canales Diferenciales* (`DAD[x][y]`, con `x` = `P` (+) o `M` (−)): se mide la diferencia entre dos pines.

// img: /images/2P/selec.png
#imagen([Entradas del ADC (DADP/DADM/AD), pines del K64F y selección de canal con `ADCH[4:0]` (ADCx_SC1)])

#cuadro-concepto(titulo: [Notación de canales])[
- *Diferencial:* `DAD[x][y]`, con `x` = `M` (−) o `P` (+) e `y` = número de canal.
- *Single Ended:* `AD[y]`, equivalente a `DADP[y]` cuando `DIFF = 0`.

Cuando `DIFF = 0`, el pin `DADP[y]` pasa a funcionar como entrada Single Ended `AD[y]`.
]

=== 2. Pasos para hacer una conversión

#tabla(
  (0.4fr, 2.6fr, 2fr),
  ([\#], [Qué hay que hacer], [Dónde]),
  [1], [Habilitar el clock del módulo ADC.], [`SIM_SCGC6`],
  [2], [Elegir la fuente de reloj y el divisor.], [`ADCx_CFG1` (`ADICLK`, `ADIV`)],
  [3], [Elegir la resolución.], [`ADCx_CFG1` (`MODE`)],
  [4], [Elegir el canal y modo (single/diferencial). *Escribir acá inicia la conversión.*], [`ADCx_SC1[0]` (`ADCH`, `DIFF`, `AIEN`)],
  [5], [Esperar a que termine (polling del flag o interrupción).], [`COCO` en `ADCx_SC1[0]`],
  [6], [Leer el resultado (esto limpia `COCO`).], [`ADCx_R[0]`],
)

=== 3. Reloj del ADC

// img: /images/2P/clk.png
#imagen([Diagrama de clock del ADC: ADICLK, ADIV, Bus clock, ALTCLK, ADACK])

El ADC necesita un reloj de entrada. Se configura en `ADCx_CFG1` con dos campos:

#tabla(
  (1.5fr, 1.5fr, 3fr),
  ([Campo], [Bits], [Descripción]),
  [`ADICLK[1:0]`], [`ADCx_CFG1[1:0]`], [Fuente del reloj: `00` = Bus Clock; `01` = Bus Clock/2; `10` = Alternate Clock (`ALTCLK`); `11` = ADACK (reloj asincrónico del ADC).],
  [`ADIV[1:0]`], [`ADCx_CFG1[6:5]`], [Divisor: `00` = ÷1; `01` = ÷2; `10` = ÷4; `11` = ÷8.],
)

=== 4. Resolución

La resolución se elige en `MODE[1:0]` (`ADCx_CFG1[3:2]`). En modo diferencial se agrega un bit (el signo, en complemento a 2), salvo en 16 bits.

#tabla(
  (1fr, 1.5fr, 1.5fr),
  ([`MODE[1:0]`], [`DIFF = 0` (Single Ended)], [`DIFF = 1` (Diferencial, compl. a 2)]),
  [`00`], [8 bits], [9 bits],
  [`01`], [12 bits], [13 bits],
  [`10`], [10 bits], [11 bits],
  [`11`], [16 bits], [16 bits],
)

#cuadro-atencion(titulo: [Escribir los campos de `CFG1` juntos])[
Si se hacen varias asignaciones seguidas con `=` (una por campo), cada una *pisa* a la anterior. Conviene armar `CFG1` en una sola asignación (o usar `|=`):
```c
SIM->SCGC6 |= SIM_SCGC6_ADC0_MASK;        // clock gate del ADC0

ADC0->CFG1 = ADC_CFG1_ADICLK(0x00)        // Bus Clock como fuente
           | ADC_CFG1_ADIV(0x00)          // sin prescaler (÷1)
           | ADC_CFG1_MODE(0x01);         // 12 bits (single ended)
```
]

=== 5. Inicio de conversión y registro `ADCx_SC1`

El canal y el modo se configuran en `ADCx_SC1[0]` con el campo `ADCH[4:0]`. *Escribir en este registro inicia la conversión.*

#cuadro-registro(titulo: [Registro `ADCx_SC1`: Status and Control 1])[
- `ADCH[4:0]`: canal de entrada. Escribirlo dispara la conversión.
- `DIFF`: `0` = Single Ended; `1` = Diferencial.
- `AIEN`: `1` = genera una interrupción al terminar la conversión (cuando `COCO = 1`).
- `COCO` (solo lectura): *Conversion Complete Flag*. Se pone en `1` al terminar. Se limpia al leer `ADCx_Rn`.
]

```c
// Inicio de conversión por software (con polling o con interrupción)
void ADC_Start(ADC_t adc, ADCChannel_t channel, ADCMux_t mux)
{
    // MUXSEL elige cuál de los dos multiplexores de entrada (a o b) usa el canal
    adc->CFG2 = (adc->CFG2 & ~ADC_CFG2_MUXSEL_MASK) | ADC_CFG2_MUXSEL(mux);

    // AIEN: 1 = interrupción, 0 = polling. Escribir ADCH inicia la conversión.
    adc->SC1[0] = ADC_SC1_AIEN(ADC_interrupt[x]) | ADC_SC1_ADCH(channel);
}
```

=== 6. Lectura del resultado y flag `COCO` (EOC)

Al terminar, el resultado queda en `ADCx_R[0]` y `COCO` pasa a `1`.

```c
// ¿Terminó la conversión? (EOC: End Of Conversion)
bool ADC_IsReady(ADC_t adc)
{
    return adc->SC1[0] & ADC_SC1_COCO_MASK;
}

// Leer el resultado (la lectura limpia COCO)
ADCData_t ADC_getData(ADC_t adc)
{
    return adc->R[0];
}
```

#cuadro-atencion(titulo: [Limpieza del flag `COCO`])[
`COCO` se limpia solo al *leer* `ADCx_Rn`. No hay que limpiarlo a mano.
]

#cuadro-ejemplo(titulo: [De número a tensión])[
Con resolución de 12 bits (4096 valores) y una referencia de 3.3 V, la tensión de entrada es aproximadamente $V_"in" approx "código" / 4096 times 3.3 "V"$. Un resultado de `2048` equivale a unos $1.65 "V"$.
]

// =====================================================================
== CMP: Comparador Analógico
// =====================================================================

El comparador *no mide* la tensión: solo dice cuál de las dos entradas es mayor. Compara la entrada positiva (`INP`) contra la negativa (`INM`) y entrega un nivel lógico (`CMPO`/`COUT`). Puede usarse en conjunto con el ADC.

Características principales:

- *DAC interno de 64 niveles*: genera la tensión de referencia contra la que se compara.
- *Histéresis configurable por hardware*: evita que la salida oscile cuando la entrada está muy cerca del umbral.
- *Varios modos de operación* (ver más abajo).

// img: /images/2P/dac-cmp (2).png
#imagen([Diagrama del CMP: multiplexores de entrada (PSEL/MSEL), DAC de 64 niveles, comparador y bloque de control de ventana y filtro])

=== Modos de operación

#tabla(
  (1.4fr, 3.6fr),
  ([Modo], [Qué hace]),
  [*Continuo*], [`COUT` refleja directamente la comparación, en modo combinacional (sin reloj).],
  [*Sampled Non-Filtered*], [`COUTA` se muestrea en cada flanco ascendente del reloj del bloque de filtro.],
  [*Windowed*], [La salida solo pasa a `COUTA` mientras la señal `WINDOW` está en alto (típicamente viene del PDB). Cuando `WINDOW = 0`, `COUTA` queda *latcheada* con el último valor.],
)

// img: /images/2P/continuo.png
#imagen([Modo continuo (COUT sin reloj)])

// img: /images/2P/sampled.png
#imagen([Modo Sampled Non-Filtered])

// img: /images/2P/window.png y /images/2P/window2.png
#imagen([Modo Windowed: la salida solo pasa durante `WINDOW = 1` y se retiene durante `WINDOW = 0`])

// =====================================================================
#pagebreak()
== PIT: Periodic Interrupt Timer
// =====================================================================

// img: /images/2P/PIT.png
#imagen([Diagrama del PIT: clock desde MCG/SIM, 4 triggers hacia DMA y 4 interrupciones hacia el NVIC])

=== 1. Qué es y para qué sirve

El *PIT* es un conjunto de *4 timers de 32 bits de conteo descendente*. Sirve para:

- *Generar interrupciones periódicas* con el intervalo que se configure.
- *Proveer triggers periódicos* para el DMA (vía DMAMUX) y para el ADC (vía `SIM_SOPT7`).

Gracias a esto se puede *adquirir y transferir datos completamente por hardware*, sin que la CPU intervenga en cada muestra.

=== 2. Clock y habilitación

El PIT funciona con el *Bus Clock* ($f_"bus" = 50 "MHz"$ en la FRDM-K64F, o sea $t_"bus" = 20 "ns"$):

```c
SIM->SCGC6 |= SIM_SCGC6_PIT_MASK;  // Habilitar el clock gate del PIT
PIT->MCR = 0x00;                    // Encender el módulo (MDIS = 0)
```

=== 3. Registros principales

#tabla(
  (1.5fr, 3.5fr),
  ([Registro], [Descripción]),
  [`PIT_MCR`], [Module Control. `MDIS = 0`: módulo activo. `FRZ = 1`: los timers se frenan en modo debug.],
  [`PIT_LDVALn`], [Load Value. Define el período: el timer cuenta desde `LDVALn` hasta `0` y ahí genera la interrupción o el trigger.],
  [`PIT_CVALn`], [Current Value (solo lectura). Valor actual del contador descendente.],
  [`PIT_TCTRLn`], [Control. `TEN = 1`: habilita el timer. `TIE = 1`: habilita la interrupción. `CHN = 1`: encadena el timer $n$ al timer $n-1$ (Chain Mode).],
  [`PIT_TFLGn`], [Flag. `TIF = 1`: el timer expiró. Se limpia *escribiendo un `1`* en ese bit.],
)

#cuadro-concepto(titulo: [Cómo calcular `LDVAL`])[
El timer cuenta $"LDVAL" + 1$ ciclos de reloj, por eso se resta 1:

$ "LDVAL" = T_"deseado" / t_"bus" - 1 $

*Ejemplo:* para $T = 5.12 "ms"$ con $t_"bus" = 20 "ns"$:

$ "LDVAL" = (5.12 times 10^(-3)) / (20 times 10^(-9)) - 1 = 256000 - 1 $
]

=== 4. Modo Chain (timers encadenados)

Un solo timer de 32 bits tiene un rango limitado. El *Chain Mode* lo extiende: el timer $n$ *solo decrementa cuando el timer $n-1$ llega a cero*, así que se multiplican los períodos.

#cuadro-ejemplo(titulo: [Timer de 1 minuto con Chain Mode])[
Con $t_"bus" = 20 "ns"$, un minuto se arma como $60 "s" = 6 "s" times 10$:

- *Timer 1:* $T = 6 "s"$ → $"LDVAL1" = (6 "s") / (20 "ns") - 1 = 3 times 10^8 - 1$.
- *Timer 2* (con `CHN = 1`): cuenta 10 vencimientos del Timer 1 → $"LDVAL2" = 10 - 1 = 9$.

```c
PIT->MCR = 0x00;

// Timer 2: encadenado al Timer 1, interrupción al vencer
PIT->CHANNEL[2].LDVAL = 10 - 1;
PIT->CHANNEL[2].TCTRL = PIT_TCTRL_TIE_MASK | PIT_TCTRL_CHN_MASK | PIT_TCTRL_TEN_MASK;

// Timer 1: fuente de clock del Timer 2
PIT->CHANNEL[1].LDVAL = 300000000 - 1;
PIT->CHANNEL[1].TCTRL = PIT_TCTRL_TEN_MASK;
```
]

=== 5. El PIT como trigger de DMA y de ADC

#grid(
  columns: (1fr, 1fr),
  gutter: 10pt,
  [
    #cuadro-registro(titulo: [PIT → DMA (DMAMUX)])[
    Cada canal PIT (0 a 3) puede ser el trigger periódico del canal DMA del mismo número. Se activa poniendo `TRIG = 1` en `DMAMUX_CHCFGn`.
    ]
  ],
  [
    #cuadro-registro(titulo: [PIT → ADC (`SIM_SOPT7`)])[
    El PIT puede disparar conversiones del ADC. Se configura en `SIM_SOPT7`, eligiendo el trigger y habilitando `ADCxALTTRGEN`.
    ]
  ]
)

// =====================================================================
#pagebreak()
== DMA: Direct Memory Access
// =====================================================================

=== 1. Qué es y por qué se usa

// img: /images/2P/dma.png
#imagen([CPU "durmiendo" mientras el DMA transfiere de un periférico a la memoria (diapositiva 1)])

El *DMA* es un controlador de hardware que *mueve datos entre memoria y periféricos* (o entre dos zonas de memoria) *sin que la CPU intervenga en cada dato*. La CPU solo configura la transferencia al principio y, si quiere, recibe un aviso al final. Mientras tanto puede hacer otras cosas.

#cuadro-concepto(titulo: [Idea para quedarse])[
*Sin DMA* (Programmed I/O), la CPU hace *dos operaciones por cada dato*: (1) lee el periférico y (2) escribe en memoria. Si hay mil datos, son mil lecturas y mil escrituras hechas por la CPU.

*Con DMA*, la CPU configura una vez "mové tantos datos de acá hasta allá" y el controlador DMA lo hace solo.
]

// img: /images/2P/dma2.png
#imagen([Programmed I/O Transfer vs. DMA Transfer (CPU, System Bus, Memory, I/O y DMA Controller)])

==== Secuencia de una transferencia DMA

#tabla(
  (0.4fr, 1.8fr, 3.8fr),
  ([\#], [Paso], [Qué pasa]),
  [1], [*Configuración*], [La CPU programa los registros del controlador: dirección de origen (`From`), de destino (`To`) y cantidad de datos (`Count`).],
  [2], [*Request del periférico*], [El periférico avisa que está listo para transferir (`I/O DMA Request`).],
  [3], [*Pedido del bus*], [El controlador DMA le pide el bus a la CPU (`Hold Request`).],
  [4], [*La CPU acepta*], [La CPU contesta (`Hold Acknowledge`) y suelta el bus (alta impedancia, `HI-Z`).],
  [5], [*Transferencia*], [El DMA lee del origen y escribe en el destino.],
  [6], [*Fin*], [El contador llega a cero y el DMA avisa a la CPU con una interrupción.],
)

#cuadro-atencion(titulo: [Los pasos 3 y 4 son un modelo general])[
`Hold Request`, `Hold Acknowledge` y `HI-Z` ilustran el DMA clásico. En el K64F, el *eDMA es un maestro del bus del sistema* y su acceso se arbitra junto con el de la CPU a través del crossbar. No son pines externos del microcontrolador.
]

=== 2. Las piezas del DMA en el K64F

Para entender el DMA del K64F alcanza con recordar *tres bloques* y qué hace cada uno:

#tabla(
  (1.3fr, 3.7fr),
  ([Bloque], [Rol]),
  [*Periféricos* (UART, SPI, I2C, FTM, ADC, DAC, GPIO, etc.)], [*Piden* la transferencia (generan el request).],
  [*DMAMUX*], [*Rutea*: elige cuál de las fuentes (slots) va a cada canal del eDMA. Tiene 3 modos (disabled, normal, periodic trigger).],
  [*eDMA* (controlador, 16 canales)], [*Transfiere*: calcula las direcciones, lee y escribe datos. Cada canal tiene su *TCD* (la "orden de trabajo" de la transferencia).],
)

El eDMA accede a la memoria y a los periféricos a través del *crossbar switch*, y se configura a través del *peripheral bridge*.

// img: /images/2P/edMa.png
#imagen([eDMA Interconnections: crossbar switch, eDMA Controller, DMAMUX, peripheral bridge y periféricos (diapositiva 9)])

#cuadro-ejemplo(titulo: [Camino completo de un request])[
Un ejemplo: el *FTM0 canal 0* pide un dato → el request entra al *DMAMUX* por el slot 20 → el DMAMUX lo conecta al *canal 0 del eDMA* → el eDMA lee el *TCD del canal 0* para saber qué hacer → copia el dato desde la *memoria* hasta el *registro del FTM* a través del *crossbar*.
]

==== Clocks y habilitación (¡no olvidarse!)

Para que el DMA funcione hay que habilitar el clock de *ambos* bloques en el SIM:

#tabla(
  (1fr, 1.3fr, 1.1fr, 1.6fr),
  ([Módulo], [Fuente de reloj], [Gating], [Valor por defecto]),
  [*DMA* (eDMA)], [System clock], [`SIM_SCGC7[DMA]` (bit 1)], [Habilitado (`1`)],
  [*DMAMUX*], [Bus clock], [`SIM_SCGC6[DMAMUX]` (bit 1)], [*Deshabilitado (`0`)*],
)

```c
SIM->SCGC6 |= SIM_SCGC6_DMAMUX_MASK;   // el DMAMUX arranca apagado: hay que prenderlo
SIM->SCGC7 |= SIM_SCGC7_DMA_MASK;      // el eDMA ya viene habilitado, pero conviene ser explícito
```

// img: /images/2P/ (tabla de clocks y registros SIM_SCGC6/SCGC7, diapositivas 10 y 11)
#imagen([Tabla de clock source de DMA y DMAMUX, y registros `SIM_SCGC6` / `SIM_SCGC7` con los bits resaltados (diapositivas 10 y 11)])

=== 3. DMAMUX: el ruteador de requests

El *DMAMUX* conecta hasta *52 slots* (fuentes de periféricos) con los *16 canales* del eDMA. Cada canal se configura con su propio registro `DMAMUX_CHCFGn`.

// img: /images/2P/DMA-MUX.png
#imagen([Diagrama de bloques del DMAMUX: Source, Always y Trigger hacia los 16 canales del eDMA (diapositiva 12)])

==== Tabla de slots (`SOURCE`)

El número de slot es lo que se escribe en el campo `SOURCE`. Los más usados:

#tabla(
  (1fr, 2fr, 2fr),
  ([Slot], [Fuente], [Detalle]),
  [`0`], [—], [Canal deshabilitado.],
  [`2` a `11`], [UART0 a UART5], [`2`/`3` = UART0 RX/TX, `4`/`5` = UART1, `6`/`7` = UART2, `8`/`9` = UART3, `10` = UART4 (TX o RX), `11` = UART5 (TX o RX).],
  [`12`, `13`], [I2S0], [RX / TX.],
  [`14` a `17`], [SPI0, SPI1, SPI2], [`14`/`15` = SPI0 RX/TX, `16` = SPI1 (TX o RX), `17` = SPI2 (TX o RX).],
  [`18`, `19`], [I2C0, I2C1/I2C2], [],
  [`20` a `27`], [FTM0], [Canales 0 a 7.],
  [`28`, `29`], [FTM1], [Canales 0 y 1.],
  [`30`, `31`], [FTM2], [Canales 0 y 1.],
  [`32` a `39`], [FTM3], [Canales 0 a 7.],
  [`40`, `41`], [ADC0, ADC1], [],
  [`42` a `44`], [CMP0, CMP1, CMP2], [],
  [`45`, `46`], [DAC0, DAC1], [],
  [`47`, `48`], [CMT, PDB], [],
  [`49` a `53`], [Port control (Port A a Port E)], [`51` = PORTC.],
  [`54` a `57`], [IEEE 1588 Timers], [Timer 0 a 3.],
  [`58` a `63`], [DMA MUX: *Always enabled*], [Fuentes siempre activas.],
)

#cuadro-atencion(titulo: [Cantidad de slots])[
`SOURCE` tiene 6 bits (`SOURCE[5:0]`), por eso el número de slot puede llegar hasta 63. Las diapositivas hablan de "52 slots" de periféricos y de "10 canales always-enabled"; la tabla del Reference Manual muestra los slots `58` a `63` como always-enabled. Ante la duda, consultar la tabla *DMA request sources* del Reference Manual del K64.
]

==== Modos de operación

#tabla(
  (1.5fr, 1.2fr, 3fr),
  ([Modo], [`ENBL` / `TRIG`], [Comportamiento]),
  [*Disabled*], [`ENBL = 0`], [Canal deshabilitado. Es el estado para *configurar o reconfigurar* el canal antes de cambiar la fuente.],
  [*Normal*], [`ENBL = 1`, `TRIG = 0`], [El slot elegido se conecta directo al canal DMA. La transferencia arranca cuando el periférico genera su request.],
  [*Periodic Trigger*], [`ENBL = 1`, `TRIG = 1`], [El request del periférico queda *bloqueado (gated)* hasta que llega un trigger del PIT. *Solo disponible en los canales 0 a 3.*],
)

#cuadro-registro(titulo: [Registro `DMAMUX_CHCFGn` (8 bits)])[
- `ENBL` (bit 7): `0` = canal deshabilitado (usarlo para deshabilitar o reconfigurar); `1` = canal habilitado.
- `TRIG` (bit 6): habilita la capacidad de trigger periódico.
  - `TRIG = 0` y `ENBL = 1`: el DMAMUX solo rutea la fuente al canal (*modo Normal*).
  - `TRIG = 1` y `ENBL = 1`: modo *Periodic Trigger*.
- `SOURCE[5:0]` (bits 5 a 0): número de slot de la fuente. Ver la tabla de slots del chip.
]

```c
// Canal 0, fuente = SPI (slot 16), con trigger periódico del PIT
DMAMUX->CHCFG[0] = DMAMUX_CHCFG_ENBL_MASK | DMAMUX_CHCFG_SOURCE(16)
                 | DMAMUX_CHCFG_TRIG_MASK;

// Canal 0, fuente = PORTC (slot 51), modo normal (GPIO)
DMAMUX->CHCFG[0] = DMAMUX_CHCFG_ENBL_MASK | DMAMUX_CHCFG_SOURCE(51);

// Canal 0, fuente = Always-enabled (slot 63), con trigger del PIT
DMAMUX->CHCFG[0] = DMAMUX_CHCFG_ENBL_MASK | DMAMUX_CHCFG_TRIG_MASK
                 | DMAMUX_CHCFG_SOURCE(63);
```

=== 4. Trigger periódico: Gated vs. Always-on

Solo los *canales 0 a 3* pueden usar el trigger periódico, y cada uno está atado a un canal del PIT:

#tabla(
  (1fr, 1fr),
  ([Canal DMA], [Canal PIT]),
  [0], [PIT 0],
  [1], [PIT 1],
  [2], [PIT 2],
  [3], [PIT 3],
)

Hay dos tipos de fuente, y se comportan distinto con el trigger:

#tabla(
  (1.4fr, 1.6fr, 3fr),
  ([Tipo de fuente], [Slots], [Cómo se comporta con el PIT]),
  [*Gated* (periféricos)], [Los slots de periféricos], [*Throttled*: el request del periférico queda bloqueado hasta que llega un trigger. La transferencia se activa en el trigger *solo si el periférico está pidiendo*.],
  [*Always-enabled*], [Slots `58` a `63`], [*Sin throttling*: el request siempre está activo, así que *cada trigger del PIT* activa una transferencia. Sirve para memoria→memoria, GPIO rápido y activación por software.],
)

// img: /images/2P/trigger.png
#imagen([DMAMUX triggered channels (Figura 21-19) y temporización del trigger: operación normal y trigger ignorado (Figuras 21-20 y 21-21)])

*Cómo leer las figuras de temporización:*

- *Operación normal* (Fig. 21-20): el request del periférico sube, pero el DMA no lo ve hasta que llega el trigger. Cuando se atiende la solicitud, el periférico baja su request.
- *Trigger ignorado* (Fig. 21-21): si llega un trigger y *el periférico no tiene request activo*, ese trigger se pierde. Cuando el periférico pida de nuevo, el DMA request queda *demorado* hasta el próximo trigger.

// img: /images/2P/always.png
#imagen([Gated (throttled) vs. Always on: Figura 4, PIT gated transfer activation, y Figura 5, PIT only transfer activation (diapositiva 22)])

#cuadro-concepto(titulo: [¿Qué modo uso?])[
#tabla(
  (2.2fr, 2.8fr),
  ([Quiero…], [Configuración]),
  [Transferir *cuando el periférico lo pida* (ej.: llegó un byte por UART).], [Modo *Normal* (`TRIG = 0`) con el slot del periférico.],
  [Transferir *a un ritmo fijo* (ej.: SPI Tx/Rx cada 5 µs).], [*Periodic Trigger* (`TRIG = 1`) con el slot del periférico, canal 0 a 3 y PIT.],
  [Generar formas de onda complejas en un GPIO desde una tabla en memoria.], [Fuente *always-enabled* + *Periodic Trigger* con el PIT: una transferencia por cada tick.],
  [Copiar memoria a memoria lo más rápido posible.], [Fuente *always-enabled*, sin trigger, y arranque por software (`CSR[START]`).],
)
]

==== Ejemplo: un pulsador que dispara el DMA

Se configura el pin `PTC6` (el pulsador SW2) para que genere un *request de DMA en flanco descendente* y se rutea ese request al canal 0:

```c
/* SW2 como fuente de request DMA, en flanco descendente */
PORTC->PCR[6] |= PORT_PCR_MUX(0x01)      // GPIO
              |  PORT_PCR_IRQC(0x02)     // 0010: DMA request en flanco descendente
              |  PORT_PCR_PE_MASK        // habilita pull
              |  PORT_PCR_PS_MASK;       // pull-up

/* Canal 0 del eDMA con PORTC (slot 51) como fuente de request */
DMAMUX->CHCFG[0] |= DMAMUX_CHCFG_ENBL_MASK | DMAMUX_CHCFG_SOURCE(51);
```

El campo `IRQC` de `PORTx_PCRn` decide qué hace el pin ante un evento:

#tabla(
  (1fr, 3fr),
  ([`IRQC`], [Función]),
  [`0000`], [Interrupción/DMA request deshabilitado.],
  [`0001`], [DMA request en flanco ascendente.],
  [`0010`], [DMA request en flanco descendente.],
  [`0011`], [DMA request en ambos flancos.],
  [`1000`], [Interrupción en nivel lógico 0.],
  [`1001`], [Interrupción en flanco ascendente.],
  [`1010`], [Interrupción en flanco descendente.],
  [`1011`], [Interrupción en ambos flancos.],
  [`1100`], [Interrupción en nivel lógico 1.],
)

=== 5. El eDMA y el TCD (la "orden de trabajo")

El eDMA tiene dos partes:

- *eDMA Engine*: hace el trabajo (calcula las direcciones de origen y destino y transfiere los datos).
- *TCD memory* (Transfer Control Descriptor): memoria local que se ve como un *arreglo de estructuras TCD*. *Cada elemento del arreglo corresponde a un canal*. Cada TCD ocupa *32 bytes* (8 palabras de 32 bits) y describe completamente la transferencia de ese canal.

// img: /images/2P/ (diagrama de bloques del eDMA, diapositivas 24 y 25)
#imagen([eDMA block diagram: eDMA Engine y TCD memory (Figura 22-1, diapositiva 24)])

El TCD del canal $i$ está en `0x4000_8000 + 0x1000 + 32 * i` (con $i$ de 0 a 15).

==== Mapa de memoria y estructura del TCD

#tabla(
  (1fr, 1.6fr, 3fr),
  ([Offset], [Campo], [Qué es]),
  [`0x00`], [`SADDR` (32 bits)], [Source Address: dirección de origen.],
  [`0x04`], [`SOFF` (16 bits)], [Source Offset: cuánto se suma a `SADDR` después de cada transferencia.],
  [`0x06`], [`ATTR` (16 bits)], [Transfer Attributes: tamaño de dato (`SSIZE`/`DSIZE`) y módulo (`SMOD`/`DMOD`).],
  [`0x08`], [`NBYTES` (32 bits)], [Minor Byte Count: bytes por cada request.],
  [`0x0C`], [`SLAST` (32 bits)], [Last Source Address Adjustment: ajuste de `SADDR` al terminar el major loop.],
  [`0x10`], [`DADDR` (32 bits)], [Destination Address: dirección de destino.],
  [`0x14`], [`DOFF` (16 bits)], [Destination Offset: cuánto se suma a `DADDR` después de cada transferencia.],
  [`0x16`], [`CITER` (16 bits)], [Current Major Iteration Count (y bits de linking).],
  [`0x18`], [`DLASTSGA` (32 bits)], [Last Destination Address Adjustment / Scatter-Gather Address.],
  [`0x1C`], [`CSR` (16 bits)], [Control and Status.],
  [`0x1E`], [`BITER` (16 bits)], [Beginning Major Iteration Count (y bits de linking).],
)

#cuadro-atencion(titulo: [Ojo con el orden de los campos])[
La tabla de la diapositiva 26 muestra algunos pares de campos de 16 bits intercambiados (`ATTR`/`SOFF`, `DOFF`/`CITER` y `BITER`/`CSR`). El orden correcto es el del diagrama de bits de la diapositiva 27, el de las direcciones de registro (por ejemplo `SOFF` en `+1004h` y `ATTR` en `+1006h`) y el de la estructura en C, que es el que se muestra acá.
]

```c
/* Estructura con los campos del TCD (32 bytes) */
typedef struct {
    uint32_t SADDR;          // Source Address (dirección de origen)
    uint16_t SOFF;           // Source Offset (offset por transferencia)
    uint16_t ATTR;           // Transfer Attributes (tamaño, SMOD, DMOD)
    union {
        uint32_t NBYTES_MLNO;       // Minor loop mapping deshabilitado
        uint32_t NBYTES_MLOFFNO;    // Mapping habilitado, sin offset de minor loop
        uint32_t NBYTES_MLOFFYES;   // Mapping habilitado, con offset de minor loop
    };
    uint32_t SLAST;          // Ajuste de SADDR al finalizar el major loop
    uint32_t DADDR;          // Destination Address (dirección de destino)
    uint16_t DOFF;           // Destination Offset (offset por transferencia)
    union {
        uint16_t CITER_ELINKNO;     // Contador actual del major loop (sin linking)
        uint16_t CITER_ELINKYES;    // Idem, con linking
    };
    uint32_t DLASTSGA;       // Ajuste de DADDR / puntero al siguiente TCD (S&G)
    uint16_t CSR;            // Control and Status (INTMAJOR, ESG, DREQ, etc.)
    union {
        uint16_t BITER_ELINKNO;     // Contador inicial del major loop (sin linking)
        uint16_t BITER_ELINKYES;    // Idem, con linking
    };
} TCD_t;
```

#cuadro-concepto(titulo: [Los campos del TCD, como preguntas])[
Un TCD responde a estas preguntas:
- *¿De dónde saco los datos?* `SADDR`.
- *¿A dónde los llevo?* `DADDR`.
- *¿Cómo avanzo en cada lado después de cada dato?* `SOFF` (origen) y `DOFF` (destino).
- *¿De qué tamaño es cada dato?* `ATTR` (`SSIZE`, `DSIZE`).
- *¿Cuántos bytes muevo por cada request?* `NBYTES`.
- *¿Cuántos requests atiendo en total?* `CITER` y `BITER`.
- *¿Qué hago al terminar todo?* `SLAST`, `DLASTSGA` y `CSR`.
]

=== 6. Generación de direcciones y tamaño de datos

Después de cada dato transferido, el eDMA actualiza cada dirección sumándole su offset:

$ "SADDR"_"siguiente" = "SADDR" + "SOFF" quad quad "DADDR"_"siguiente" = "DADDR" + "DOFF" $

- *Offset = 0*: la dirección *no cambia*. Sirve para leer siempre el mismo registro de un periférico, o para escribir siempre en el mismo registro.
- *Offset = tamaño del dato*: se recorre una tabla en memoria, elemento por elemento.

// img: /images/2P/ (diagramas SADDR + SOFF y DADDR + DOFF, diapositivas 30 y 31)
#imagen([Source Address + Source Offset y Destination Address + Destination Offset (diapositivas 30 y 31)])

El tamaño de cada dato se elige por separado para origen (`SSIZE`) y destino (`DSIZE`) en `ATTR`:

#tabla(
  (1fr, 1.5fr),
  ([`SSIZE` / `DSIZE`], [Tamaño]),
  [`000`], [8 bits],
  [`001`], [16 bits],
  [`010`], [32 bits],
  [`100`], [16 bytes],
  [`101`], [32 bytes],
  [`011`, `110`, `111`], [Reservados],
)

#cuadro-ejemplo(titulo: [Recorrer un arreglo de palabras de 32 bits hacia un registro fijo])[
- `SSIZE = DSIZE = 2` (32 bits).
- `SOFF = 4`: avanza al siguiente elemento del arreglo.
- `DOFF = 0`: el destino (el registro) no cambia.
- `NBYTES = 4`: una palabra por cada request.
]

=== 7. Minor loop y Major loop

Son las dos "vueltas" del DMA, y confunden bastante. Pensalo así:

#cuadro-concepto(titulo: [Minor loop vs. Major loop])[
- *Minor loop* = *lo que se mueve en un solo request* (`NBYTES` bytes). Es *indivisible*: una vez que arranca no se puede interrumpir.
- *Major loop* = *todos los requests de la transferencia* (`CITER` minor loops). Cuando se completa, la transferencia terminó.

Ejemplo: `NBYTES = 4` y `CITER = 3` significa *3 requests de 4 bytes cada uno = 12 bytes en total*.
]

// img: /images/2P/loop2.png
#imagen([Ejemplo de lazo anidado: NBYTES = 4 por request y CITER = 3 minor loops (Figura 17, diapositiva 35)])

==== Qué pasa en cada request (minor loop)

El eDMA recorre los `NBYTES` bytes del request (internamente `NBYTES` va decrementando). Cuando llega a `0`, actualiza el TCD: avanza `SADDR` y `DADDR` y decrementa el contador del major loop (`CITER--`).

#cuadro-ejemplo(titulo: [`NBYTES` es bytes, no cantidad de elementos])[
`NBYTES = K × tamaño del dato`. Con datos de 32 bits (`SSIZE = DSIZE = 2`):
- `NBYTES = 64` → 16 elementos de 32 bits por request.
- `NBYTES = 16` → 4 elementos de 32 bits por request.
]

#cuadro-atencion(titulo: [Valor de `NBYTES`])[
`NBYTES = 0` *no* significa "no transferir nada": el eDMA lo interpreta como una transferencia de *4 GB* ($2^32$ bytes). Programar siempre un valor válido.
]

==== Contadores `CITER` y `BITER`

- `CITER` (*Current* Major Iteration Count): cuántos minor loops *faltan*. Se decrementa al completar cada request.
- `BITER` (*Beginning* Major Iteration Count): el valor *inicial*. Cuando `CITER` llega a `0`, se recarga `CITER` desde `BITER`.

#cuadro-atencion(titulo: [`CITER` y `BITER` deben ser iguales al configurar])[
Al cargar el TCD por primera vez, `CITER` y `BITER` *tienen que tener el mismo valor*. Si el canal va a hacer un único request, ambos valen `1`.
]

#tabla(
  (1.5fr, 3.5fr),
  ([`ELINK`], [Ancho del contador]),
  [`ELINK = 0` (sin channel linking)], [`CITER`/`BITER` usan hasta *15 bits* (bits 14 a 0). El bit 15 es `ELINK`.],
  [`ELINK = 1` (con channel linking en el minor loop)], [Parte del campo se usa como `LINKCH` (canal enlazado) y quedan *9 bits* para el conteo.],
)

==== `NBYTES` y Minor Loop Mapping

La forma del campo `NBYTES` depende del bit `CR[EMLM]` (Enable Minor Loop Mapping) del eDMA:

#tabla(
  (1.4fr, 1.7fr, 3fr),
  ([Variante], [Condición], [Qué contiene]),
  [`NBYTES_MLNO`], [`EMLM = 0`], [Los 32 bits son `NBYTES`.],
  [`NBYTES_MLOFFNO`], [`EMLM = 1`, `SMLOE = 0`, `DMLOE = 0`], [Bits 31 y 30 = `SMLOE`/`DMLOE`; el resto es `NBYTES`. *No se aplica offset* de minor loop.],
  [`NBYTES_MLOFFYES`], [`EMLM = 1` y (`SMLOE` o `DMLOE` = 1)], [Además de `NBYTES` (10 bits) aparece `MLOFF` (offset de minor loop, con signo). *Sí se aplica el offset*.],
)

`MLOFF` se suma a la dirección de origen (si `SMLOE = 1`) o a la de destino (si `DMLOE = 1`) *cada vez que termina un minor loop*. Es independiente de `SOFF` y `DOFF`, que se aplican *después de cada elemento*.

=== 8. Qué pasa al terminar el major loop

Cuando `CITER` llega a `0`, el eDMA hace los ajustes finales:

- Suma `SLAST` a `SADDR`. Es un valor *con signo*: con un valor negativo se vuelve al principio de la tabla (por ejemplo `SLAST = -sizeof(buffer)`). También sirve para pasar a la próxima estructura de datos.
- Si `ESG = 0`, suma `DLASTSGA` a `DADDR` (igual que `SLAST` pero para el destino).
- Si `ESG = 1`, `DLASTSGA` es la *dirección del próximo TCD* (modo Scatter-Gather, más adelante).
- Recarga `CITER` desde `BITER`.
- Marca `DONE`, y puede generar una interrupción y/o activar otro canal.

#cuadro-ejemplo(titulo: [Canal que repite indefinidamente una tabla])[
Si `SLAST = -sizeof(tabla)` y `DREQ = 0`, al terminar el major loop `SADDR` vuelve al inicio de la tabla y el canal sigue atendiendo requests: la tabla se repite una y otra vez.
]

==== Registro `CSR`: Control and Status

#tabla(
  (1.4fr, 3.6fr),
  ([Campo], [Función]),
  [`BWC`], [Band Width Control: puede frenar al eDMA (ninguno, 4 u 8 ciclos de CPU) para repartir el ancho de banda del bus.],
  [`MAJORLINKCH`], [Número del canal a activar *al terminar el major loop* (channel linking).],
  [`MAJORELINK`], [Habilita el channel linking al terminar el major loop.],
  [`DONE`], [Flag: el eDMA completó el major loop (`CITER` llegó a `0`).],
  [`ACTIVE`], [Flag: el canal está ejecutando una transferencia (se limpia cuando termina el minor loop).],
  [`ESG`], [Habilita el modo Scatter-Gather.],
  [`DREQ`], [Disable Request: deshabilita el request del canal al terminar el major loop.],
  [`INTHALF`], [Interrupción cuando `CITER` llega a la mitad del conteo.],
  [`INTMAJOR`], [Interrupción cuando termina el major loop (`CITER` llega a `0`).],
  [`START`], [Arranca el canal explícitamente por *software* (sin esperar un request de periférico).],
)

`DONE` y `ACTIVE` ayudan a verificar el avance del canal durante la depuración.

=== 9. Habilitar el canal: `ERQ`, `SERQ` y `CERQ`

Hay *dos pasos distintos*, y es común olvidarse del segundo:

+ Elegir la fuente en `DMAMUX_CHCFGn` (qué request entra al canal).
+ *Habilitar las solicitudes del canal en el eDMA* (bit del canal en `DMA_ERQ`).

`DMA_ERQ` tiene un bit por canal (`ERQ0` a `ERQ15`): `1` = habilitado, `0` = deshabilitado. Para tocar un solo canal sin hacer lectura-modificación-escritura sobre todo `ERQ`, existen:

#tabla(
  (1fr, 3fr),
  ([Registro], [Para qué]),
  [`DMA_SERQ`], [*Set* Enable Request. Escribir el número de canal en `SERQ` activa su bit en `ERQ`. Con `SAER = 1` activa *todos* los canales.],
  [`DMA_CERQ`], [*Clear* Enable Request. Escribir el número de canal en `CERQ` desactiva su bit. Con `CAER = 1` desactiva *todos*.],
)

(En ambos, `NOP = 1` hace que el registro ignore la escritura.)

```c
DMA0->SERQ = DMA_SERQ_SERQ(0);   // habilita las solicitudes del canal 0
DMA0->CERQ = DMA_CERQ_CERQ(0);   // deshabilita las solicitudes del canal 0
```

#cuadro-atencion(titulo: [Orden de configuración])[
Primero se deja *listo el TCD y el DMAMUX*, y *recién después* se habilita el request en `ERQ`.
]

=== 10. Buffer circular por hardware: `SMOD` y `DMOD`

Los campos `SMOD` (origen) y `DMOD` (destino) de `ATTR` convierten una región de memoria en un *buffer circular por hardware* de tamaño $M = 2^K$ bytes, con $K$ = valor del campo. El hardware deja que cambien *solo los $K$ bits menos significativos* de la dirección; el resto queda fijo, así que la dirección *da la vuelta* dentro del bloque.

- `K = 0` → no hay módulo (la dirección avanza normalmente).
- `K ≠ 0` → buffer circular de $2^K$ bytes.

#cuadro-concepto(titulo: [Requisito: buffer alineado])[
Para que funcione, la dirección base del buffer tiene que ser *múltiplo de $2^K$*: sus $K$ bits menos significativos deben ser *cero*. Por ejemplo, con `SMOD = 2`: $K = 2$, $M = 2^2 = 4$ bytes, y `SADDR` debe terminar en `00` en binario.

El módulo siempre es *potencia de dos*. Para un tamaño arbitrario se usa Scatter-Gather (más adelante).
]

// img: /images/2P/buffer.png
#imagen([Buffer circular con `SMOD = 2` (M = 4): los 2 bits menos significativos de SADDR cambian y el resto queda fijo (diapositiva 33)])

```c
// Buffer circular de 4 bytes en el origen: SMOD = 2  →  M = 2^2 = 4
DMA0->TCD[0].ATTR = DMA_ATTR_SSIZE(0) | DMA_ATTR_DSIZE(0) | DMA_ATTR_SMOD(2);
```

==== Cómo alinear una variable en C

Con GCC se usa el atributo `aligned`: la dirección de inicio de la variable es múltiplo de $L = 2^n$ bytes.

```c
int x __attribute__ ((aligned (16))) = 0;     // n = 4, L = 16 bytes

uint16_t sourceBuffer[10] __attribute__ ((aligned (16)))
                          = {0x1234, 0x6789, 0x1122, 0x2233, 0x5588};
uint8_t  destinationBuffer[10] __attribute__ ((aligned (16)));
```

==== Ejemplo paso a paso: buffer circular de destino de 4 bytes

Se copian bytes de una tabla de `uint16_t` hacia un buffer de destino que "da la vuelta" cada 4 bytes (`DMOD = 2`).

```c
uint16_t sourceBuffer[10] __attribute__ ((aligned (4)))
                          = {0x1234, 0x6789, 0x1122, 0x2233, 0x5588};
uint8_t  destinationBuffer[10] __attribute__ ((aligned (4)));

DMA0->TCD[0].SOFF = 0x01;   // origen: avanza 1 byte por transferencia
DMA0->TCD[0].DOFF = 0x01;   // destino: avanza 1 byte por transferencia

// Datos de 1 byte (8 bits) y destino con módulo 4 (DMOD = 2)
DMA0->TCD[0].ATTR = DMA_ATTR_SSIZE(0) | DMA_ATTR_DSIZE(0) | DMA_ATTR_DMOD(2);

// Bytes por request (2 transferencias de 1 byte)
DMA0->TCD[0].NBYTES_MLNO = 0x02;

// Major loop: 5 requests
DMA0->TCD[0].CITER_ELINKNO = DMA_CITER_ELINKNO_CITER(0x05);
DMA0->TCD[0].BITER_ELINKNO = DMA_BITER_ELINKNO_BITER(0x05);
```

Los bytes de origen (little endian) son `34 12 89 67 22 11 33 22 ...`. Cada request mueve 2 bytes. Con `DADDR` terminando en `...9C` (sus 2 bits bajos en `00`), el destino da la vuelta cada 4 bytes:

#tabla(
  (0.8fr, 1.4fr, 1.3fr, 1.3fr, 0.8fr),
  ([Request], [Bytes escritos], [`DADDR` después], [`SADDR` después], [`CITER`]),
  [Inicio], [—], [`0x1FFF009C`], [`0x1FFF0000`], [5],
  [1], [`0x34`, `0x12` en `dest[0..1]`], [`0x1FFF009E`], [`0x1FFF0002`], [4],
  [2], [`0x89`, `0x67` en `dest[2..3]`], [`0x1FFF009C` (*wrap*)], [`0x1FFF0004`], [3],
  [3], [`0x22`, `0x11` en `dest[0..1]` (pisa)], [`0x1FFF009E`], [`0x1FFF0006`], [2],
  [4], [`0x33`, `0x22` en `dest[2..3]` (pisa)], [`0x1FFF009C` (*wrap*)], [`0x1FFF0008`], [1],
)

El destino nunca sale de los 4 bytes (`dest[0..3]`): cuando `DADDR` llegaría a `...A0`, vuelve a `...9C`.

// img: /images/2P/ (captura del debugger con destinationBuffer, TCD0_DADDR, TCD0_SADDR y TCD0_CITER, diapositiva 41)
#imagen([Capturas del debugger para cada request: contenido de `destinationBuffer` y registros `TCD0_DADDR`, `TCD0_SADDR`, `TCD0_CITER` (diapositiva 41)])

=== 11. Ejemplo completo: PWM con duty variable desde una tabla (DMA + FTM)

*Objetivo:* generar una señal PWM cuyo *duty cycle cambia automáticamente* en cada período, tomando los valores de una tabla en memoria, sin que la CPU haga nada.

```c
uint16_t sourceBuffer[] = {1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000};
```

*Cómo funciona:* en cada período del PWM, el FTM genera un request de DMA; el DMA copia el siguiente valor de la tabla al registro `CnV` del canal (el que fija el duty) y se queda esperando el próximo request. Al terminar la tabla, `SLAST` la reinicia.

// img: /images/2P/ (diagrama DMA → FTM0 con la tabla de duty cycles, diapositiva 43)
#imagen([DMA → FTM0: la tabla de duty cycles se copia al registro `CnV` en cada período])

==== Configuración del DMAMUX y del TCD

```c
// DMAMUX: canal 0, fuente FTM0 canal 0 (slot 20), modo normal
DMAMUX->CHCFG[0] |= DMAMUX_CHCFG_ENBL_MASK | DMAMUX_CHCFG_SOURCE(20);

// TCD0
DMA0->TCD[0].SADDR = (uint32_t)(sourceBuffer);                // tabla de duties
DMA0->TCD[0].DADDR = (uint32_t)(&(FTM0->CONTROLS[0].CnV));    // registro que fija el duty

DMA0->TCD[0].SOFF = 0x02;   // origen: avanza 2 bytes (uint16_t)
DMA0->TCD[0].DOFF = 0x00;   // destino: siempre el mismo registro

DMA0->TCD[0].ATTR = DMA_ATTR_SSIZE(1) | DMA_ATTR_DSIZE(1);    // datos de 16 bits
DMA0->TCD[0].NBYTES_MLNO = 0x02;                              // 2 bytes por request

// Major loop: tantos requests como elementos tenga la tabla
DMA0->TCD[0].CITER_ELINKNO = DMA_CITER_ELINKNO_CITER(sizeof(sourceBuffer) / sizeof(sourceBuffer[0]));
DMA0->TCD[0].BITER_ELINKNO = DMA_BITER_ELINKNO_BITER(sizeof(sourceBuffer) / sizeof(sourceBuffer[0]));

// Al terminar el major loop, SADDR vuelve al principio de la tabla
DMA0->TCD[0].SLAST = -sizeof(sourceBuffer);

// Scatter-Gather no se usa
DMA0->TCD[0].DLASTSGA = 0x00;

DMA0->SERQ = DMA_SERQ_SERQ(0);   // ¡habilitar las solicitudes del canal 0!
```

==== Configuración del FTM0

Para que el FTM genere un request de DMA hay que habilitar, en `FTMx_CnSC`, *tanto* el bit `DMA` como `CHnIE`:

#tabla(
  (0.6fr, 0.7fr, 2.5fr, 2.5fr),
  ([`DMA`], [`CHnIE`], [Request de DMA], [Interrupción del canal]),
  [0], [0], [No se genera.], [No se genera.],
  [0], [1], [No se genera.], [Se genera si `CHnF = 1`.],
  [1], [0], [No se genera.], [No se genera.],
  [*1*], [*1*], [*Se genera si `CHnF = 1`.*], [No se genera.],
)

Con `DMA = 1`, el flag `CHnF` lo *limpia la transferencia DMA*, no el software.

```c
uint16_t PWM_modulus = 10000 - 1;
uint16_t PWM_duty    = 5000;

FTM_SetPrescaler(FTM0, FTM_PSC_x32);                              // prescaler ×32
FTM_SetInterruptMode(FTM0, FTM_CH_0, true);                       // CHnIE = 1
FTM_SetWorkingMode(FTM0, 0, FTM_mPulseWidthModulation);           // modo PWM (MSA/MSB)
FTM_SetPulseWidthModulationLogic(FTM0, 0, FTM_lAssertedHigh);     // polaridad (ELSA/ELSB)
FTM_SetModulus(FTM0, PWM_modulus);                                // módulo (período)
FTM_SetCounter(FTM0, 0, PWM_duty);                                // duty inicial
FTM_DmaMode(FTM0, FTM_CH_0, FTM_DMA_ON);                          // DMA = 1
FTM_StartClock(FTM0);                                             // arrancar el timer
```

// img: /images/2P/ (tabla "Channel DMA transfer request" y registro FTMx_CnSC con CHIE y DMA resaltados, diapositiva 44)
#imagen([Tabla de requests de DMA del FTM y registro `FTMx_CnSC` con los bits `CHIE` y `DMA` resaltados (diapositiva 44)])

==== Resultado: cuentas

Con el prescaler en 32 y el reloj del FTM en 50 MHz, cada cuenta dura $32 / (50 "MHz") = 0.64 mu"s"$.

$ T_"PWM" = 1/(50 times 10^6) times 32 times 10000 = 6.40 "ms" quad (approx 156.25 "Hz") $

El ancho del pulso (duty) es $t_"duty" = 0.64 mu"s" times "sourceBuffer[i]"$:

#tabla(
  (0.8fr, 1.2fr, 1.5fr),
  ([Índice], [Valor en la tabla], [Duty (tiempo en alto)]),
  [0], [1000], [640 µs],
  [1], [2000], [1.28 ms],
  [2], [3000], [1.92 ms],
  [3], [4000], [2.56 ms],
  [4], [5000], [3.20 ms],
  [5], [6000], [3.84 ms],
  [6], [7000], [4.48 ms],
  [7], [8000], [5.12 ms],
)

// img: /images/2P/ (captura de osciloscopio del PWM con duty variable, diapositiva 46)
#imagen([Captura de osciloscopio: PWM con el duty cycle cambiando período a período ($Delta X = 6.4 "ms"$, 156.25 Hz)])

=== 12. Modos avanzados: Scatter-Gather y Channel Linking

Ambos sirven para encadenar transferencias, pero de formas muy distintas.

==== Scatter-Gather: un canal, varios TCD

*Scatter-Gather* permite que *un mismo canal use varios TCD*. Cada vez que termina el major loop, el hardware *carga automáticamente* el siguiente TCD desde la memoria principal y lo copia al descriptor del canal, reemplazando al actual. Todo sin intervención de la CPU. El nombre viene de poder *dispersar* (scatter) datos hacia varios destinos o *juntar* (gather) datos desde varios orígenes.

- Se activa con `CSR[ESG] = 1` en los TCD.
- `DLASTSGA` de cada TCD contiene la *dirección del siguiente TCD*.
- Los TCD (`TCDA`, `TCDB`, ...) viven en la *memoria principal* y deben estar *alineados a 32 bytes* (la región es modular de 32 bytes).
- Si el último apunta al primero, forman una *lista circular*.

// img: /images/2P/ (cadena TCDA → TCDB → TCDC → TCDD con "Load Next TCD", diapositivas 52 y 53)
#imagen([Scatter & Gather: el canal 0 carga TCDA, TCDB, TCDC y TCDD, uno por cada major loop, formando una lista enlazada circular])

```c
/* Dos TCD en memoria principal, alineados a 32 bytes */
TCD_t tcd[TCDs_AMOUNT] __attribute__ ((aligned (32)));

enum { TCD0 = 0, TCD1, TCDs_AMOUNT };

tcd[TCD0].DLASTSGA = (uint32_t)&tcd[TCD1];   // TCD0 → el siguiente es TCD1
tcd[TCD1].DLASTSGA = (uint32_t)&tcd[TCD0];   // TCD1 → vuelve a TCD0 (circular)

DMA_TCD0_DLASTSGA = tcd[TCD0].DLASTSGA;      // el canal arranca apuntando al siguiente
```

Aplicaciones típicas: *buffers de tamaño arbitrario* (que no son potencia de 2) y esquemas de *doble buffer (ping-pong)*.

==== Channel-to-Channel Linking: un canal dispara a otro

El *Channel Linking* hace que, al completar un minor loop o un major loop, *se active otro canal que ya está configurado*. No se carga ningún TCD nuevo ni se cambia la configuración.

#tabla(
  (1.5fr, 1.8fr, 3.2fr),
  ([Cuándo se enlaza], [Campo del TCD], [Descripción]),
  [Al final del *minor loop*], [`CITER[E_LINK]`], [Habilita el linking al completar el minor loop.],
  [], [`CITER[LINKCH]`], [Número del canal a activar.],
  [Al final del *major loop*], [`CSR[MAJOR_E_LINK]`], [Habilita el linking al completar el major loop.],
  [], [`CSR[MAJOR_LINKCH]`], [Número del canal a activar.],
)

#cuadro-atencion(titulo: [`E_LINK` en `CITER` y en `BITER`])[
Los bits `TCDn_CITER[E_LINK]` y `TCDn_BITER[E_LINK]` *deben ser iguales*; si no, se reporta un error de configuración. Además, el ancho de `CITER` y `BITER` debe ser el mismo para calcular el punto de interrupción de mitad del major loop.
]

==== Comparación

#tabla(
  (1.6fr, 2.2fr, 2.2fr),
  ([Característica], [Scatter-Gather], [Channel Linking]),
  [Canales involucrados], [*Un solo canal* que va cambiando su configuración.], [*Varios canales* independientes que se disparan entre sí.],
  [¿Qué cambia?], [Se reemplaza el TCD completo (origen, destino, tamaño), copiándolo desde la RAM.], [No cambia ninguna configuración: solo se activa el trigger de otro canal ya configurado.],
  [Uso de memoria], [Requiere guardar estructuras TCD de 32 bytes en la SRAM.], [No consume RAM adicional; se maneja con los registros de control del eDMA.],
)

=== 13. Ejemplo: buffer circular de 10 elementos (no potencia de 2)

`SMOD`/`DMOD` solo admiten tamaños potencia de dos, así que para un buffer de *10 elementos* hay que usar Scatter-Gather. El ejemplo está basado en la nota de aplicación _What is and how to configure the eDMA scatter-gather feature_.

*Planteo:*

- Hay 2 buffers circulares de 10 elementos: `src` (origen) y `dst` (destino).
- El DMA copia de `src` a `dst` en *2 etapas*, cada una un major loop de 5 elementos.
- *TCD A* copia los primeros 5 (`SADDR = src`, `DADDR = dst`, `CITER = 5`). *TCD B* copia los 5 restantes (`SADDR = src + 5`, `DADDR = dst + 5`, `CITER = 5`). Cada uno apunta al otro con `DLASTSGA`.
- Al terminar cada major loop se produce una *interrupción*: la CPU ingresa 5 elementos nuevos en `src` (para simular una nueva adquisición de datos) mientras el DMA continúa con la otra mitad.

#tabla(
  (1fr, 1fr, 2.4fr, 2.4fr),
  ([Major loop], [TCD], [`src` después], [`dst` después]),
  [Inicio], [A], [`0 1 2 3 4 5 6 7 8 9`], [`0 0 0 0 0 0 0 0 0 0`],
  [1], [A], [`A B C D E 5 6 7 8 9` (nuevos A a E)], [`0 1 2 3 4 0 0 0 0 0`],
  [2], [B], [`A B C D E F 10 11 12 13` (nuevos F a 13)], [`0 1 2 3 4 5 6 7 8 9`],
  [3], [A], [`14 15 16 17 18 F 10 11 12 13` (nuevos 14 a 18)], [`A B C D E 5 6 7 8 9`],
  [4], [B], [(sigue igual)], [`A B C D E F 10 11 12 13`],
)

Los valores nuevos son números consecutivos escritos en hexadecimal (`A` = 10, `F` = 15, `10` = 16, etc.). Después del major loop 4 se vuelve a cargar TCD A y el ciclo continúa.

// img: /images/2P/ (diagrama "Simulación" con SRC, DST, TCD A y TCD B, diapositiva 55)
#imagen([Simulación: `src` y `dst` en cada major loop, alternando TCD A y TCD B, con los datos nuevos que carga la CPU en la interrupción])

=== 14. Herramienta de depuración: EmbSysRegView

Para *depurar y aprender* el DMA es muy útil poder ver los registros del eDMA (TCD, `ERQ`, etc.) mientras el programa corre. *EmbSysRegView* (_Embedded Systems Register View_) es una vista de Eclipse que muestra todos los registros del micro (en este caso de la familia MK64F12), con sus valores en hexa y binario, su dirección y una descripción de cada campo.

=== 15. Resumen y checklist de configuración

#cuadro-concepto(titulo: [Receta para configurar un canal DMA])[
+ *Clocks:* habilitar `SIM_SCGC6[DMAMUX]` (y `SIM_SCGC7[DMA]`).
+ *Periférico:* configurarlo para que genere el request de DMA (por ejemplo, `IRQC` en un pin, o `DMA` y `CHnIE` en el FTM).
+ *DMAMUX:* configurar `CHCFGn` con `SOURCE`, `ENBL` y, si hace falta, `TRIG` (canales 0 a 3 con el PIT).
+ *TCD:* cargar `SADDR`, `DADDR`, `SOFF`, `DOFF`, `ATTR`, `NBYTES`, `CITER` = `BITER`, `SLAST`, `DLASTSGA` y `CSR`.
+ *PIT* (si se usa trigger periódico): configurar `LDVAL` y habilitar el timer (`TEN`).
+ *Habilitar el canal:* `DMA0->SERQ = DMA_SERQ_SERQ(n)`.
]

#cuadro-atencion(titulo: [Errores típicos])[
- Olvidarse de habilitar el clock del *DMAMUX* (arranca apagado).
- Olvidarse de habilitar el request del canal en `ERQ` (`SERQ`).
- `CITER` distinto de `BITER` al inicializar el TCD.
- `NBYTES = 0` (se interpreta como 4 GB).
- No poner `SLAST` negativo cuando se quiere repetir una tabla.
- Buffer circular (`SMOD`/`DMOD`) *sin alinear* a su tamaño.
- Usar trigger periódico (`TRIG = 1`) en un canal *mayor a 3*.
- Confundir *minor loop* (lo de un request) con *major loop* (todos los requests).
]

#cuadro-ejemplo(titulo: [Cadena completa por hardware])[
*PIT* (marca el ritmo) → *trigger* → *DMAMUX* (rutea) → *eDMA* (transfiere según el TCD) → *memoria o periférico*. La CPU solo configura al principio y atiende una interrupción al final de cada major loop (si se habilitó `INTMAJOR`).
]

==== Referencias

- _K64 Sub-Family Reference Manual_, Rev. 2, January 2014.
- _Using the DMA module in Kinetis devices_, Freescale Semiconductor.
- _What is and how to configure the eDMA scatter-gather feature_ (nota de aplicación).
- _How to Add Register Details View in Eclipse (The EmbSysRegView project)_, https:\/\/mcuoneclipse.com/2014/05/29/how-to-add-register-details-view-in-eclipse/
