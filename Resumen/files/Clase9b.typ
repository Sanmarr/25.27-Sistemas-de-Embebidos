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

// ==========================================
// CLASE 9
// ==========================================

= Clase 9

== ADC: Conversor Analógico–Digital

=== Arquitectura y Señales de Entrada

El Kinetis K64F incorpora *dos módulos ADC* de 16 bits con arquitectura *SAR (Successive Approximation Register)*. Cada instancia admite:

- *Hasta 24 canales Single Ended* (`AD[y]`, donde `y` es el número de canal).
- *4 canales Diferenciales* (`DAD[x][y]`, con `x = P(+)` o `M(−)`).

#imagen([Selección del canal a convertir con el campo `ADCH[4:0]` del registro `ADCx_SC1`]) <fig:selec>

#cuadro-concepto(titulo: [Notación de Canales ADC])[
- *Diferencial:* `DAD[x][y]` donde `x = M(−)` o `P(+)`, `y = N° de canal`.
- *Single Ended:* `AD[y]`, equivalente a `DADP[y]` cuando `DIFF = 0`.

Al configurar `DIFF = 0`, el pin `DADP[y]` se reasigna como entrada Single Ended `AD[y]`.
]

=== Selección de Canal e Inicio de Conversión

El canal a convertir y el modo de operación se configuran en el registro `ADCx_SC1[0]` mediante el campo `ADCH[4:0]`. Escribir en este registro *inicia la conversión*.

#cuadro-registro(titulo: [Registro ADCx\_SC1 — Status and Control 1])[
- `ADCH[4:0]`: Selección del canal de entrada. Escribir en este campo inicia la conversión.
- `DIFF`: `0` = modo Single Ended; `1` = modo Diferencial.
- `AIEN`: `1` = habilita la interrupción al finalizar la conversión (`COCO = 1`).
- `COCO` (solo lectura): *Conversion Complete Flag*. Se activa cuando la conversión finaliza. Se limpia al leer el registro `ADCx_Rn`.
]

```c
// Inicio de conversión por software (polling o con interrupción)
void ADC_Start(ADC_t adc, ADCChannel_t channel, ADCMux_t mux)
{
    adc->CFG2 = (adc->CFG2 & ~ADC_CFG2_MUXSEL_MASK) | ADC_CFG2_MUXSEL(mux);
    adc->SC1[0] = ADC_SC1_AIEN(ADC_interrupt[x]) | ADC_SC1_ADCH(channel);
}
```

=== Reloj del ADC

El módulo ADC requiere una señal de reloj de entrada. Dicha señal se configura en `ADCx_CFG1` mediante dos campos:

#imagen([Diagrama del reloj del ADC: ADIV (prescaler), ADICLK (selector de fuente), ADACK, Bus Clock ÷2 y ALTCLK]) <fig:clk>

#table(
  columns: (1.5fr, 1.5fr, 3fr),
  inset: 8pt,
  stroke: 0.5pt + luma(180),
  align: left,
  table.header([*Campo*], [*Registro*], [*Descripción*]),
  [`ADICLK[1:0]`], [`ADCx_CFG1[1:0]`], [Selector de fuente de reloj: `00` = Bus Clock; `01` = Bus Clock/2; `10` = Alternate Clock (`ALTCLK`); `11` = ADACK (ADC Asynchronous Clock).],
  [`ADIV[1:0]`], [`ADCx_CFG1[6:5]`], [Prescaler del reloj ADC. Factores de división: `00` = 1; `01` = 2; `10` = 4; `11` = 8.],
)

```c
ADC0->CFG1 = ADC_CFG1_ADICLK(0x00);  // Bus Clock como fuente
ADC0->CFG1 = ADC_CFG1_ADIV(0x00);    // Sin prescaler (dividir por 1)
```

=== Resolución del ADC

La resolución de conversión se configura en el campo `MODE[1:0]` del registro `ADCx_CFG1[3:2]`:

#table(
  columns: (1fr, 1.5fr, 1.5fr),
  inset: 8pt,
  stroke: 0.5pt + luma(180),
  align: center,
  table.header([*MODE\[1:0\]*], [*DIFF = 0 (Single Ended)*], [*DIFF = 1 (Diferencial, 2's Comp.)*]),
  [`00`], [8 bits], [9 bits],
  [`01`], [12 bits], [13 bits],
  [`10`], [10 bits], [11 bits],
  [`11`], [16 bits], [16 bits],
)

=== Lectura del Resultado y Flag EOC

Una vez completada la conversión, el resultado se almacena en `ADCx_R[0]` y el flag `COCO` se pone en `1`.

```c
// Verificar si la conversión finalizó (EOC - End Of Conversion)
bool ADC_IsReady(ADC_t adc)
{
    return adc->SC1[0] & ADC_SC1_COCO_MASK;
}

// Leer el resultado de la conversión (lectura limpia COCO)
ADCData_t ADC_getData(ADC_t adc)
{
    return adc->R[0];
}
```

#cuadro-atencion(titulo: [Limpieza del Flag COCO])[
El flag `COCO` se limpia automáticamente al *leer* el registro `ADCx_Rn`. No es necesario limpiarlo de forma explícita.
]

=== Comparador Analógico (CMP)

El K64F incorpora un *Comparador Analógico (CMP)* integrado que puede usarse en conjunto con el ADC. Sus características principales son:

- *DAC interno de 64 niveles* para generar la tensión de referencia de comparación.

#imagen([Comparador (CMP) con multiplexores PSEL / MSEL y DAC interno de 64 niveles]) <fig:dac-comp>

- *Control de histéresis* configurable por hardware para evitar oscilaciones en la salida.
- *Múltiples modos de operación:*
  - *Continuo:* La salida `COUT` refleja directamente la comparación en modo combinacional (sin reloj).

#imagen([CMP en modo continuo: la salida refleja la comparación sin reloj]) <fig:continuo>

  - *Sampled Non-Filtered:* `COUTA` se muestrea en cada flanco ascendente del reloj del bloque de filtro.

#imagen([CMP en modo Sampled Non-Filtered: muestreo de `COUTA` con el reloj del bloque de filtro]) <fig:sampled>

  - *Windowed:* La salida analógica solo pasa a `COUTA` cuando la señal `WINDOW` está en alto (típicamente proveniente del PDB). El último valor queda latched cuando `WINDOW = 0`.

#imagen([CMP en modo Windowed: estructura del bloque de control de ventana]) <fig:window>

#imagen([CMP en modo Windowed: formas de onda con la señal `WINDOW` proveniente del PDB]) <fig:window2>

#pagebreak()
== PIT: Periodic Interrupt Timer

#imagen([Diagrama de bloques del PIT: reloj desde MCG/SIM, triggers DMA hacia DMA & MUX e interrupciones hacia NVIC]) <fig:PIT>

=== Descripción General y Uso

El módulo *PIT (Periodic Interrupt Timer)* consiste en un conjunto de *4 timers de conteo descendente de 32 bits* cuyas funciones principales son:

- *Generar interrupciones periódicas* a intervalos configurables.
- *Proveer triggers periódicos* para los módulos DMA y ADC.

El PIT puede disparar transferencias DMA (a través del DMAMUX) y disparar conversiones ADC (a través de `SIM_SOPT7`), permitiendo adquisición y transferencia de datos completamente por hardware sin intervención de la CPU.

=== Clock y Habilitación

El *reloj del PIT es el Bus Clock* ($f_"bus" = 50 "MHz"$ en la FRDM-K64F):

```c
SIM->SCGC6 |= SIM_SCGC6_PIT_MASK;  // Habilitar clock gate del PIT
PIT->MCR = 0x00;                     // Encender el módulo PIT (MDIS = 0)
```

=== Registros Principales

#table(
  columns: (1.5fr, 3.5fr),
  inset: 8pt,
  stroke: 0.5pt + luma(180),
  align: left,
  table.header([*Registro*], [*Descripción*]),
  [`PIT_MCR`], [Module Control Register. `MDIS = 0`: módulo activo. `FRZ = 1`: detiene timers en modo debug.],
  [`PIT_LDVALn`], [Timer Load Value Register. Define el período: el timer cuenta desde `LDVALn` hasta `0` y genera la interrupción/trigger.],
  [`PIT_CVALn`], [Current Timer Value Register (solo lectura). Valor actual del contador descendente.],
  [`PIT_TCTRLn`], [Timer Control Register. `TEN = 1`: habilita el timer. `TIE = 1`: habilita la interrupción. `CHN = 1`: encadena el timer $n$ al timer $n-1$ (Chain Mode).],
  [`PIT_TFLGn`], [Timer Flag Register. `TIF = 1`: indica que el timer expiró. Se limpia escribiendo `1` en este bit.],
)

#cuadro-concepto(titulo: [Cálculo del Período del PIT])[
Con $f_"bus" = 50 "MHz"$ (período $t_"bus" = 20 "ns"$):

$"LDVALn" = T_"deseado" / t_"bus" - 1$

*Ejemplo:* Para $T = 5.12 "ms"$:
$"LDVAL" = (5.12 times 10^(-3)) / (20 times 10^(-9)) - 1 = 256000 - 1$
]

=== Modo Chain (Timers Encadenados)

El *Chain Mode* permite extender el rango de temporización concatenando dos timers. El timer $n$ solo decrementa cuando el timer $n-1$ llega a cero:

#cuadro-ejemplo(titulo: [Ejemplo: Timer de 1 Minuto con Chain Mode])[
Con $f_"bus" = 50 "MHz"$ ($t_"bus" = 20 "ns"$), para generar un período de 1 minuto ($60 "s" = 6 "s" times 10$):

- *Timer 1:* $T = 6 "s"$ → $"LDVAL1" = 6 / (20 times 10^(-9)) - 1 = 3 times 10^8 - 1$
- *Timer 2:* 10 ciclos del Timer 1 → $"LDVAL2" = 10 - 1 = 9$ (con `CHN = 1`)

```c
PIT->MCR = 0x00;
// Timer 2 (encadenado al Timer 1)
PIT->CHANNEL[2].LDVAL = 10 - 1;
PIT->CHANNEL[2].TCTRL = PIT_TCTRL_TIE_MASK | PIT_TCTRL_CHN_MASK | PIT_TCTRL_TEN_MASK;
// Timer 1 (fuente de clock para Timer 2)
PIT->CHANNEL[1].LDVAL = 300000000 - 1;
PIT->CHANNEL[1].TCTRL = PIT_TCTRL_TEN_MASK;
```
]

=== PIT como Trigger para DMA y ADC

#grid(
  columns: (1fr, 1fr),
  gutter: 10pt,
  [
    #cuadro-registro(titulo: [PIT → DMA (DMAMUX)])[
    Cada canal PIT (0..3) puede actuar como trigger periódico para el DMA MUX. Se configura en el DMAMUX activando `TRIG = 1` en `DMAMUX_CHCFGn`.
    ]
  ],
  [
    #cuadro-registro(titulo: [PIT → ADC (SIM\_SOPT7)])[
    El PIT puede disparar conversiones ADC directamente. Se configura en `SIM_SOPT7` seleccionando el trigger y habilitando `ADCxALTTRGEN`.
    ]
  ]
)

#pagebreak()
== DMA: Direct Memory Access

#imagen([Diagrama conceptual: CPU, periféricos, memoria y flujo directo periférico → memoria por DMA]) <fig:dma>

=== Concepto y Motivación

El *DMA (Direct Memory Access)* es un controlador de hardware que realiza transferencias de datos entre memoria y periféricos (o entre dos zonas de memoria) *sin intervención de la CPU*. Esto libera al procesador para ejecutar otras tareas mientras el DMA opera de forma autónoma sobre el bus del sistema.

#imagen([Programmed I/O Transfer vs. DMA Transfer: en I/O programada la CPU mueve cada dato; con DMA lo hace el controlador]) <fig:dma2>

El flujo de una transferencia DMA sigue estos pasos:

1. *Configuración:* La CPU programa los registros del controlador DMA (dirección origen, destino y cantidad de datos).
2. *Solicitud del Periférico:* El periférico genera un request de DMA cuando está listo para transferir datos.
3. *Arbitraje del bus:* El controlador DMA obtiene acceso al bus compartido para realizar la transferencia.
4. *Transferencia:* El DMA lee desde la dirección de origen y escribe en la dirección de destino; la CPU puede continuar ejecutando instrucciones cuando el bus está disponible.
5. *Fin de transferencia:* El contador del canal llega a cero. Si se habilitó la interrupción de fin de major loop, el DMA notifica a la CPU.

#cuadro-atencion(titulo: [Diagrama conceptual de bus])[
Las señales `Hold Request`, `Hold Acknowledge` y `HI-Z` del diagrama ilustran un modelo general de DMA. En el K64F, el eDMA es un maestro del bus del sistema y su acceso se arbitra junto con el de la CPU; no se deben interpretar esas señales como pines externos del microcontrolador.
]

=== Arquitectura del eDMA en el K64F

#imagen([Arquitectura del eDMA: crossbar switch, eDMA Controller, DMAMUX y periféricos (UART, I2S, SPI, I2C, FTM, CMP, ADC, DAC, CMT, PDB, GPIO)]) <fig:edMa>

El Kinetis K64F incorpora un módulo *eDMA (Enhanced DMA)* de *16 canales* con las siguientes características:

- *DMAMUX (DMA Multiplexer):* Rutea hasta *52 fuentes de DMA* (slots de periféricos) hacia los 16 canales del eDMA.

#imagen([DMAMUX block diagram: 52 slots de fuentes (Source, Always, Trigger) multiplexados hacia 16 canales del eDMA]) <fig:MUX>

- *TCD Memory:* Cada canal del eDMA tiene un *TCD (Transfer Control Descriptor)* de 32 bytes (8 palabras de 32 bits) que describe completamente la transferencia.

=== DMAMUX: Modos de Operación

El DMAMUX tiene tres modos configurables para cada canal mediante el registro `DMAMUX_CHCFGn`:

#table(
  columns: (1.5fr, 1fr, 3fr),
  inset: 8pt,
  stroke: 0.5pt + luma(180),
  align: left,
  table.header([*Modo*], [*ENBL / TRIG*], [*Comportamiento*]),
  [*Disabled*], [`ENBL=0`], [Canal deshabilitado. Usar para reconfigurar el DMAMUX antes de cambiar la fuente.],
  [*Normal*], [`ENBL=1`, `TRIG=0`], [La fuente del periférico (slot) se rutea directamente al canal DMA. La transferencia se inicia cuando el periférico genera un request.],
  [*Periodic Trigger*], [`ENBL=1`, `TRIG=1`], [El request del periférico queda bloqueado (*gated*) hasta que el PIT genera un trigger. Solo los canales 0..3 soportan este modo.],
)

#imagen([DMAMUX channel triggering: operación normal (arriba) y trigger ignorado con retraso del DMA request (abajo)]) <fig:trigger>

#cuadro-registro(titulo: [Registro DMAMUX\_CHCFGn])[
- `ENBL`: Habilita el canal DMA.
- `TRIG`: Habilita el trigger periódico (modo Periodic Trigger con PIT).
- `SOURCE[5:0]`: Número de slot del periférico fuente (0..63). Ver la tabla de slots del Reference Manual del K64.
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

=== Tipos de Fuentes DMA

#table(
  columns: (1.5fr, 1fr, 3fr),
  inset: 8pt,
  stroke: 0.5pt + luma(180),
  align: left,
  table.header([*Tipo de Fuente*], [*Slots*], [*Características*]),
  [*Gated (Periféricos)*], [Periféricos (resto de los slots)], [Throttled. El request queda gateado hasta que el trigger del PIT lo habilita. Permite trigger periódico con PIT (canales 0..3). Tras atender el request, el periférico lo niega.],
  [*Always-Enabled*], [58..63], [Sin throttling. Transferencias rápidas: memoria→memoria, GPIO rápido, activación por software.],
)

#imagen([Comparación de activación: PIT gated (throttled) vs. PIT only transfer (always enabled)]) <fig:always>

=== TCD: Transfer Control Descriptor

El TCD es la estructura que describe completamente cada transferencia DMA. Cada canal del eDMA tiene su propio TCD de 32 bytes en una memoria local:

```c
typedef struct {
    uint32_t SADDR;          // Source Address (dirección de origen)
    uint16_t SOFF;           // Source Offset (offset por transferencia)
    uint16_t ATTR;           // Transfer Attributes (tamaño, SMOD, DMOD)
    uint32_t NBYTES_MLNO;    // Bytes por minor loop (por cada DMA request)
    uint32_t SLAST;          // Ajuste de SADDR al finalizar el major loop
    uint32_t DADDR;          // Destination Address (dirección de destino)
    uint16_t DOFF;           // Destination Offset (offset por transferencia)
    uint16_t CITER_ELINKNO;  // Contador actual del major loop
    uint32_t DLASTSGA;       // Ajuste de DADDR / puntero al siguiente TCD (S&G)
    uint16_t CSR;            // Control and Status (INTMAJOR, ESG, DREQ, etc.)
    uint16_t BITER_ELINKNO;  // Contador inicial del major loop (= CITER al inicio)
} TCD_t;
```

#cuadro-concepto(titulo: [Major Loop y Minor Loop])[
- *Minor Loop:* Una sola transacción de `NBYTES` bytes. Se ejecuta ante cada request del periférico.
- *Major Loop:* Conjunto de `CITER` minor loops. Al completarse el major loop, el DMA puede:
  - Generar una interrupción (`CSR[INTMAJOR] = 1`).
  - Ajustar `SADDR` sumando `SLAST` (para wrap-around de buffer circular).
  - Cargar un nuevo TCD en modo Scatter-Gather (`CSR[ESG] = 1`).
]

#imagen([Source Address Generation: SMOD/SADDR/SOFF, minor loop (MLOFF, CITER) y major loop (SLAST, BITER → CITER)]) <fig:loops>

#imagen([Ejemplo de minor loop y major loop anidados (NBYTES y CITER)]) <fig:loop3>

#imagen([Transferencia de 4 bytes por minor loop]) <fig:loop2>

==== Campos Principales del TCD

#table(
  columns: (1.5fr, 3.5fr),
  inset: 8pt,
  stroke: 0.5pt + luma(180),
  align: left,
  table.header([*Campo*], [*Descripción*]),
  [`SADDR`], [Dirección de inicio de la fuente de datos.],
  [`SOFF`], [Offset que se suma a `SADDR` después de cada transferencia de origen. `0` = dirección fija (ej. registro de periférico).],
  [`DADDR`], [Dirección de inicio del destino de datos.],
  [`DOFF`], [Offset que se suma a `DADDR` después de cada transferencia de destino. `0` = dirección fija (ej. registro de periférico).],
  [`ATTR`], [`SSIZE`/`DSIZE`: tamaño de dato (`0` = 8 bits, `1` = 16 bits, `2` = 32 bits). `SMOD`/`DMOD`: habilita buffer circular (ver más abajo).],
  [`NBYTES`], [Número de bytes transferidos por minor loop (por cada request del periférico).],
  [`CITER`/`BITER`], [Contador actual e inicial del major loop. *Deben inicializarse con el mismo valor.*],
  [`SLAST`], [Valor sumado a `SADDR` al finalizar el major loop. Negativo para wrap-around: `SLAST = -sizeof(buffer)`.],
  [`DLASTSGA`], [Ajuste de `DADDR` al finalizar el major loop. En modo Scatter-Gather apunta al próximo TCD.],
  [`CSR`], [Control: `INTMAJOR` = interrupción al fin del major loop; `ESG` = scatter-gather; `DREQ` = deshabilitar request al finalizar.],
)

==== Generación de Direcciones y Tamaños de Transferencia

En cada transferencia, el eDMA accede a las direcciones actuales de origen (`SADDR`) y destino (`DADDR`). Después de cada elemento transferido, actualiza cada dirección con su offset:

$"SADDR"_"siguiente" = "SADDR" + "SOFF"$
$"DADDR"_"siguiente" = "DADDR" + "DOFF"$

Un offset igual a cero permite leer repetidamente un registro de periférico o escribir siempre en el mismo registro. Para recorrer una tabla en memoria, el offset suele ser igual al tamaño de cada elemento.

El campo `ATTR` selecciona independientemente el tamaño de los elementos de origen (`SSIZE`) y destino (`DSIZE`): `0` = 8 bits, `1` = 16 bits y `2` = 32 bits. Las direcciones y los tamaños deben ser compatibles con el periférico y con las restricciones de alineación de la memoria.

#cuadro-ejemplo(titulo: [Recorrer un arreglo de palabras])[
Para copiar palabras de 32 bits desde memoria a un registro fijo:
- `SSIZE = DSIZE = 2` (32 bits).
- `SOFF = 4` avanza al siguiente elemento del arreglo.
- `DOFF = 0` conserva la dirección del registro de destino.
- `NBYTES = 4` transfiere una palabra por cada servicio del canal.
]

==== Minor Loop y Major Loop

Un *minor loop* es la cantidad de bytes indicada por `NBYTES` para un servicio del canal. Puede incluir varias transferencias elementales; por ejemplo, `NBYTES = 64` con elementos de 32 bits mueve 16 elementos por servicio. El número de bytes debe ser compatible con los tamaños y alineaciones configurados.

`CITER` cuenta cuántos minor loops faltan para completar el *major loop*. El eDMA decrementa el contador al completar cada servicio. Al llegar a cero, puede aplicar los ajustes finales de dirección, generar una interrupción, activar otro canal y, si el canal sigue habilitado, recargar `CITER` desde `BITER`. Al configurar inicialmente el TCD, `CITER` y `BITER` deben tener el mismo valor; para un único servicio, ambos valen `1`.

El ancho disponible para el contador depende de `ELINK`: con linking desactivado se dispone de hasta 15 bits para el conteo; al habilitarlo, parte del campo se usa para seleccionar el canal enlazado y quedan 9 bits para el conteo.

==== NBYTES y Minor Loop Mapping

Con el mapeo de minor loop desactivado (`CR[EMLM] = 0`), se usa `NBYTES_MLNO`. Si se activa `EMLM`, se usan `NBYTES_MLOFFNO` (sin offset adicional) o `NBYTES_MLOFFYES` (con offset adicional habilitado).

En `NBYTES_MLOFFYES`, `SMLOE` y `DMLOE` determinan si el offset firmado `MLOFF` se suma a la dirección de origen o de destino al finalizar cada minor loop. Este ajuste es independiente de `SOFF` y `DOFF`, que se aplican después de cada elemento transferido.

#cuadro-atencion(titulo: [Valor de NBYTES])[
No programes `NBYTES = 0` esperando una transferencia vacía: el eDMA interpreta ese valor como una transferencia de $2^(32)$ bytes. Configura un conteo válido para el modo de mapeo de minor loop seleccionado.
]

==== Ajustes al Final del Major Loop y Estado

- `SLAST` se suma a `SADDR` cuando termina el major loop. Un valor negativo puede volver al inicio de una tabla, por ejemplo `SLAST = -sizeof(buffer)`.
- Si `ESG = 0`, `DLASTSGA` se suma a `DADDR` al terminar el major loop.
- Si `ESG = 1`, `DLASTSGA` contiene la dirección del siguiente TCD en memoria. El descriptor debe cumplir la alineación requerida por el hardware.
- `CSR` controla, entre otras funciones, la interrupción de fin de major loop (`INTMAJOR`), Scatter-Gather (`ESG`) y la deshabilitación de solicitudes al finalizar (`DREQ`).

El flag `DONE` indica que el major loop terminó y `ACTIVE` que el canal está ejecutando una transferencia. Estos estados ayudan a comprobar el avance del canal durante la depuración.

==== Habilitación de Solicitudes del Canal

La selección de fuente en `DMAMUX_CHCFGn` y la habilitación de solicitudes del eDMA son pasos distintos. El canal debe tener su request habilitado en `DMA_ERQ` para aceptar solicitudes:

```c
// Habilitar solicitudes del canal 0
DMA0->SERQ = DMA_SERQ_SERQ(0);

// Deshabilitar solicitudes del canal 0
DMA0->CERQ = DMA_CERQ_CERQ(0);
```

`SERQ` y `CERQ` modifican el bit correspondiente de `ERQ` sin requerir una operación de lectura-modificación-escritura sobre todo el registro. La configuración del TCD y del DMAMUX debe estar lista antes de habilitar la solicitud.

==== Buffer Circular con SMOD / DMOD

El campo `SMOD` (o `DMOD`) en `ATTR` define un *buffer circular por hardware* de tamaño $M = 2^K$ bytes. El hardware confina las actualizaciones de `SADDR` (o `DADDR`) a esa región. La dirección base debe estar alineada al tamaño del buffer: sus $K$ bits menos significativos deben ser cero.

#imagen([Ejemplo de buffer circular: SADDR alineado a 2^K, con actualización modular `SADDR + [(SADDR + SOFF) MOD 2^K]`]) <fig:buffer>

```c
// Buffer circular de 4 bytes: SMOD=2 → M = 2^2 = 4
DMA0->TCD[0].ATTR = DMA_ATTR_SSIZE(0) | DMA_ATTR_DSIZE(0) | DMA_ATTR_SMOD(2);
```

El tamaño definido por `SMOD`/`DMOD` siempre es potencia de dos. Para un buffer de tamaño arbitrario, por ejemplo 10 elementos, se puede usar Scatter-Gather con varios TCD que procesen segmentos del buffer.

/*
=== Ejemplos Prácticos (pendientes de revisión)

==== DMA + PIT → GPIO (Toggle de Pin)

Generar una señal cuadrada en `PTC0` escribiendo desde una tabla en memoria al registro `PTOR` del puerto C, con el PIT como trigger periódico cada $5.12 "ms"$:

```c
// Tabla de valores a escribir en PTOR (Toggle Output Register)
static uint32_t sourceBuffer[] = {0x0001, 0x0001, 0x0001, 0x0001};

// 1. DMAMUX: canal 0, always-enabled (slot 63), trigger periódico del PIT
DMAMUX->CHCFG[0] |= DMAMUX_CHCFG_ENBL_MASK | DMAMUX_CHCFG_TRIG_MASK
                  | DMAMUX_CHCFG_SOURCE(63);

// 2. TCD0
DMA0->TCD[0].SADDR         = (uint32_t)(sourceBuffer);
DMA0->TCD[0].DADDR         = (uint32_t)(&(PTC->PTOR));
DMA0->TCD[0].SOFF          = 0x04;   // Avanzar 4 bytes por transacción
DMA0->TCD[0].DOFF          = 0x00;   // Destino fijo (siempre PTOR)
DMA0->TCD[0].ATTR          = DMA_ATTR_SSIZE(2) | DMA_ATTR_DSIZE(2);
DMA0->TCD[0].NBYTES_MLNO   = 4;
DMA0->TCD[0].CITER_ELINKNO = DMA_CITER_ELINKNO_CITER(4);
DMA0->TCD[0].BITER_ELINKNO = DMA_BITER_ELINKNO_BITER(4);
DMA0->TCD[0].SLAST         = -(int32_t)sizeof(sourceBuffer);

// 3. PIT canal 0: período = 5.12 ms
PIT->MCR = 0x00;
PIT->CHANNEL[0].LDVAL = 256000 - 1;  // 256000 × 20 ns = 5.12 ms
PIT->CHANNEL[0].TCTRL = PIT_TCTRL_TEN_MASK;

// 4. Habilitar request del canal DMA 0
DMA0->ERQ = DMA_ERQ_ERQ0_MASK;
```

==== DMA + FTM → PWM Variable desde Tabla

Generar una señal PWM cuyo duty cycle varía automáticamente usando una tabla en memoria. El FTM solicita la transferencia DMA en cada coincidencia de canal (`CHnF`):

```c
uint16_t sourceBuffer[] = {1000, 2000, 3000, 4000, 5000, 6000, 7000, 8000};

// DMAMUX: canal 0, fuente FTM0_CH0 (slot 20), modo normal
DMAMUX->CHCFG[0] |= DMAMUX_CHCFG_ENBL_MASK | DMAMUX_CHCFG_SOURCE(20);

// TCD0: tabla de duty cycles → registro CnV del FTM0 CH0
DMA0->TCD[0].SADDR         = (uint32_t)(sourceBuffer);
DMA0->TCD[0].DADDR         = (uint32_t)(&(FTM0->CONTROLS[0].CnV));
DMA0->TCD[0].SOFF          = 0x02;   // Avanzar 2 bytes (uint16_t)
DMA0->TCD[0].DOFF          = 0x00;   // Destino fijo (siempre CnV)
DMA0->TCD[0].ATTR          = DMA_ATTR_SSIZE(1) | DMA_ATTR_DSIZE(1);
DMA0->TCD[0].NBYTES_MLNO   = 0x02;
DMA0->TCD[0].CITER_ELINKNO = DMA_CITER_ELINKNO_CITER(8);
DMA0->TCD[0].BITER_ELINKNO = DMA_BITER_ELINKNO_BITER(8);
DMA0->TCD[0].SLAST         = -(int32_t)sizeof(sourceBuffer);
DMA0->TCD[0].DLASTSGA      = 0x00;

// FTM0: PWM con DMA habilitado en CH0
FTM_SetPrescaler(FTM0, FTM_PSC_x32);          // Prescaler ×32
FTM_SetWorkingMode(FTM0, 0, FTM_mPulseWidthModulation);
FTM_SetPulseWidthModulationLogic(FTM0, 0, FTM_lAssertedHigh);
FTM_SetModulus(FTM0, 10000 - 1);
FTM_SetCounter(FTM0, 0, 5000);
FTM_DmaMode(FTM0, FTM_CH_0, FTM_DMA_ON);      // DMA ON en CH0
FTM_StartClock(FTM0);
```
Con prescaler $32 times$ y Bus Clock $50 "MHz"$:
$T_"PWM" = (1/(50 "MHz")) times 32 times 10000 = 6.4 "ms"$
]
*/

=== Modos Avanzados del DMA

==== Scatter-Gather

El modo *Scatter-Gather* permite que un canal use varios TCD. Al finalizar el major loop, el hardware carga el siguiente TCD desde memoria principal sin intervención de la CPU. Los TCD pueden formar una lista circular si cada uno apunta al siguiente y el último vuelve al primero.

Esto se usa para implementar buffers de tamaño arbitrario (no potencia de 2) o esquemas de doble buffer (*ping-pong*):

```c
// ESG = 1 en ambos descriptores; cada dirección debe apuntar a un TCD alineado.
TCD_A.DLASTSGA = (uint32_t)&TCD_B;
TCD_B.DLASTSGA = (uint32_t)&TCD_A;
```

#imagen([Scatter-Gather: lista de TCD enlazados (TCDA → TCDB → TCDC → TCDD) cargados en CH 0 al final de cada major loop]) <fig:sg>

==== Channel-to-Channel Linking

El *Channel Linking* activa otro canal al completar un minor loop (`ELINK`) o un major loop (`MAJORELINK`). El campo `LINKCH` o `MAJORLINKCH` selecciona el canal que se dispara. A diferencia de Scatter-Gather, no se carga un nuevo TCD ni se cambia la configuración del canal enlazado: se activa otro canal que ya fue configurado.

#table(
  columns: (1.5fr, 2fr, 2fr),
  inset: 8pt,
  stroke: 0.5pt + luma(180),
  align: left,
  table.header([*Característica*], [*Scatter-Gather*], [*Channel Linking*]),
  [Qué ocurre], [El canal carga otro TCD y cambia su configuración.], [Se activa otro canal ya configurado.],
  [Canales utilizados], [Un mismo canal puede ejecutar varios TCD.], [Participan varios canales independientes.],
  [Memoria adicional], [Requiere TCD en memoria alineados para los cambios.], [No requiere TCD adicionales para enlazar canales.],
)

==== Ejemplo: Buffer Circular de Tamaño No Potencia de Dos

Para representar un buffer de 10 elementos, el modo `SMOD`/`DMOD` no alcanza porque solo admite tamaños potencia de dos. Una alternativa es dividir la copia en dos major loops de 5 elementos:

1. El primer TCD copia los elementos `0..4` y parte de las direcciones base de origen y destino.
2. Al terminar el primer major loop, Scatter-Gather carga el segundo TCD, que copia los elementos `5..9` desde las direcciones desplazadas cinco elementos.
3. El segundo TCD puede apuntar de vuelta al primero. Al terminar cada mitad, una interrupción de major loop permite que la CPU procese el bloque y agregue nuevos datos al buffer de origen.

Así se implementa una secuencia circular de tamaño arbitrario usando TCDs encadenados y sin tener que mover los datos con la CPU.