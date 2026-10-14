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


= Clase 8

== Periféricos de Temporización y Módulo FlexTimer (FTM)

=== Fundamentos y Necesidad de Hardware Dedicado

En sistemas embebidos en tiempo real, el uso de interrupciones periódicas por software para generar o medir pulsos presenta limitaciones críticas cuando los anchos de pulso son muy angostos o cuando se requiere una precisión estricta sin sufrir la latencia de atención de la CPU.

Por esta razón, los microcontroladores incorporan bloques periféricos de *Timer por hardware*. Los dos conceptos fundamentales sobre los que se construyen estos periféricos son:

- *Output Compare (OC):* Permite programar un cambio de estado automático en un pin de salida (Toggle, Set, Clear) cuando el contador alcanza un valor predeterminado en el registro de comparación. Este evento ocurre por hardware de forma determinística, eliminando el impacto del jitter e impredecibilidad causados por la latencia de la ISR.

#figure(image("/images/outputCompare.png", width: 70%))

#figure(image("/images/pwm fijo.png", width: 70%), caption: "Ejemplo de uso con duty cycle constante")

#figure(image("/images/pwm variable.png", width: 70%), caption: "Ejemplo de uso con duty cycle utilizando deltas")

- *Input Capture (IC):* Registra (*latch*) el valor instantáneo del contador principal ante la llegada de un flanco en un pin de entrada. Se utiliza para medir frecuencias, períodos o anchos de pulso extremadamente angostos sin sobrecargar la CPU.

#figure(image("/images/ic.png", width: 70%), caption: "'Se le saca una foto al contador en el instante del flanco de entrada'")

#figure(image("/images/ipc-ex.png", width: 40%), caption:"t_i corresponde al clock de FRC (Free Running Counter).)")

#cuadro-concepto(titulo: [Principio de Funcionamiento por Hardware])[
Ambas técnicas se basan en un contador principal de 16 bits (*Free Running Counter / FTM Counter*) accionado por un reloj del sistema [1, 11, 12]. Tanto el latch de captura como la conmutación de los pines de salida se realizan en el mismo ciclo de reloj del evento físico.
]

=== Arquitectura del Módulo FlexTimer (FTM) en Kinetis K64F

#figure(image("/images/FTMx.png", width: 80%), 
caption: "FTM counter y sus-submodulos."
)

El *FlexTimer Module (FTM)* es un temporizador multicanal de 16 bits integrado en la subfamilia Kinetis K64 (microcontrolador `MK64FN1M0VLL12` montado en la placa FRDM-K64F).

==== Instancias y Distribución de Canales

El microcontrolador K64F dispone de 4 instancias físicas del módulo FTM:

#table(
  columns: (1.2fr, 1.5fr, 3fr),
  inset: 6pt,
  stroke: 0.5pt + luma(180),
  fill: (_, y) => if y == 0 { rgb("#1a5fb4") } else if calc.odd(y) { rgb("#f4f7fa") },
  align: (left, left, left),
  table.header([*Instancia FTM*], [*N° de Canales*], [*Funciones Principales / Usos*]),
  [*FTM0*], [8 canales (CH0..CH7)], [Control de motores trifásicos, PWM general, motores paso a paso.],
  [*FTM1*], [2 canales (CH0..CH1)], [Decodificador en cuadratura (*Quadrature Decoder*) o propósito general.],
  [*FTM2*], [2 canales (CH0..CH1)], [Decodificador en cuadratura o propósito general.],
  [*FTM3*], [8 canales (CH0..CH7)], [Control de motores trifásicos, PWM y medición de señales.]
)

#cuadro-registro(titulo: [Habilitación del Reloj (Clock Gating)])[
Antes de acceder a los registros de cualquier módulo FTM, es obligatorio activar la señal de reloj (*Clock Gate*) en el módulo SIM (*System Integration Module*):
- *FTM0, FTM1, FTM2:* Se habilitan mediante los bits `SIM_SCGC6_FTM0_MASK`, `SIM_SCGC6_FTM1_MASK`, `SIM_SCGC6_FTM2_MASK` en `SIM->SCGC6`.
- *FTM2, FTM3:* Se habilitan mediante los bits `SIM_SCGC3_FTM2_MASK` y `SIM_SCGC3_FTM3_MASK` en `SIM->SCGC3`.
]

==== Fuentes de Reloj (Clock Source) y Prescaler

El contador del FTM recibe su señal de reloj desde una llave de selección configurable en el registro de control `FTMx_SC` mediante el campo `CLKS[1:0]`:

- `00`: Sin reloj seleccionado (deshabilita el contador FTM).
- `01`: *System Clock:* Corresponde internamente al *Bus Clock* del microcontrolador ($f_"bus" = 50 "MHz"$ en la placa FRDM-K64F a $100 "MHz"$ de Core).
- `10`: *Fixed Frequency Clock (`MCGFFCLK`):* Reloj de frecuencia fija independiente.
- `11`: *External Clock (`FTM_CLKINx`):* Reloj desde pines externos seleccionados vía `SIM_SOPT4`.

El valor del reloj seleccionado se divide posteriormente mediante un *Prescaler (PS)* de 3 bits (`PS[2:0]` en `FTMx_SC`), el cual soporta factores de división entre $1$ y $128$ ($2^n$ con $n = 0 .. 7$):

$f_"FTM_CNT" = f_"Clock_Source" / "Prescaler"$

#figure(image("/images/clock-source.png", width: 80%), 
caption: "Clock Source"
)

#cuadro-ejemplo(titulo: [Cálculo de Frecuencia y Resolución de Conteo])[
Si se selecciona el *Bus Clock* ($50 "MHz"$) y se configura un prescaler de $4$ (`FTM_PSC_x4`):
$f_"FTM_CNT" = (50 "MHz") / 4 = 12.5 "MHz"$
$"Resolución de conteo (período de tick)" = 1 / (12.5 "MHz") = 80 "ns"$ 

#figure(image("/images/clock-source-ex.png", width: 100%))

]

==== Modos de Conteo del Contador (`FTM Counter`)

El FTM soporta tres modos de conteo configurables mediante los registros `FTMx_SC` y `FTMx_QDCTRL`:

#figure(image("/images/ftm-up.png", width: 80%), 
caption: "FTM: Up Counting")

1. *Up Counting (Conteo Ascendente):*
   - *Configuración:* `QUADEN = 0`, `CPWMS = 0`.
   - *Comportamiento:* El contador se carga con `CNTIN` y se incrementa en cada tick hasta alcanzar `MOD`. Al llegar a `MOD`, se recarga automáticamente con `CNTIN` e impone `TOF = 1` (Timer Overflow Flag).
   - *Período de conteo:*
   $"Período" = ("MOD" - "CNTIN" + 1) times t_"FTM_CNT"$

   #figure(image("/images/ftm-up-up.png", width: 60%), 
caption: "Up Counting, cuenta la cantidad de overflows."
)

2. *Up-Down Counting (Conteo Ascendente/Descendente - Center Aligned):*
   - *Configuración:* `QUADEN = 0`, `CPWMS = 1`.
   - *Comportamiento:* Cuenta desde `CNTIN` hasta `MOD`, y al llegar a `MOD` comienza a decrementar hasta regresar a `CNTIN`. El flag `TOF = 1` se activa al pasar de `MOD` a `MOD - 1`.
   - *Período de conteo:*
   $"Período" = 2 times ("MOD" - "CNTIN") times t_"FTM_CNT"$

   #figure(image("/images/up-down.png", width: 60%), 
caption: "Up-Down Counting"
)

3. *Free Running Counter:*
   - *Comportamiento:* Se obtiene fijando `CNTIN = 0x0000` y `MOD = 0xFFFF`. El contador recorre todo el rango de $16$ bits ($0 .. 65535$) continuamente. `TOF = 1` cuando el contador pasa de 0xFFFF to 0x0000

   #figure(image("/images/free-runn.png", width: 60%), 
caption: "Free Running Counter"
)

#cuadro-registro(titulo: [Registro de Filtro de Overflows (NUMTOF)])[
El FTM incluye el registro `NUMTOF[4:0]`, el cual especifica la cantidad de veces que el contador debe sufrir un overflow antes de que el hardware active efectivamente el bit de interrupción `TOF = 1`. Esto permite extender los intervalos de interrupción sin sobrecargar la CPU.
]

=== Modos de Operación y Configuración por Canal

==== Modo Compatibilidad TPM (`FTMEN = 0`) vs. Modo FTM Avanzado (`FTMEN = 1`)

El módulo FTM incluye dos modos globales de operación definidos en el registro `FTMx_MODE`:

- *FTMEN = 0 (TPM Legacy):* Modulo compatible con los timers TPM antiguos (arquitectura HCS08). Solo permite el uso del conjunto básico de registros.
- *FTMEN = 1 (FTM Advanced Functions):* Habilita todas las funciones avanzadas: Combine Mode, Deadtime Insertion, Fault Control, Quadrature Decoder, PWM Synchronization e Inversión de Salidas.

#cuadro-atencion(titulo: [¡Protección de Escritura (WPDIS)!])[
Para escribir en el bit `FTMEN` o en registros avanzados, se debe desactivar primero la protección contra escritura poniendo en `'1'` el bit `WPDIS` (`Write Protection Disable`) en `FTMx_MODE`.
]

==== Modos de Trabajo Individuales y Combinados

#table(
  columns: (1.5fr, 2.2fr, 2.3fr),
  inset: 6pt,
  stroke: 0.5pt + luma(180),
  fill: (_, y) => if y == 0 { rgb("#1a5fb4") } else if calc.odd(y) { rgb("#f4f7fa") },
  align: (left, left, left),
  table.header([*Modo de Canal*], [*Configuración de Bits*], [*Descripción / Comportamiento*]),
  [*Input Capture (IC)*], [
    `DECAPEN=0`, `COMBINE=0`, `CPWMS=0` \
    `MSnB:MSnA = 00` \
    `ELSnB:ELSnA = 01` (Ascendente) \
    `ELSnB:ELSnA = 10` (Descendente) \
    `ELSnB:ELSnA = 11` (Ambos flancos)
  ], [
    Guarda el valor instantáneo del contador `FTM_CNT` en `FTMx_CnV` al detectar el flanco configurado en el pin. Genera interrupción `CHnF = 1`.
  ],
  [*Output Compare (OC)*], [
    `DECAPEN=0`, `COMBINE=0`, `CPWMS=0` \
    `MSnB:MSnA = 01` \
    `ELSnB:ELSnA = 01` (Toggle) \
    `ELSnB:ELSnA = 10` (Clear) \
    `ELSnB:ELSnA = 11` (Set)
  ], [
    Compara `FTM_CNT` con `FTMx_CnV`. Al coincidir (`FTM_CNT == CnV`), conmuta la salida del pin automáticamente y activa `CHnF = 1`.
  ],
  [*Edge-Aligned PWM (EPWM)*], [
    `DECAPEN=0`, `COMBINE=0`, `CPWMS=0` \
    `MSnB:MSnA = 1X` \
    `ELSnB:ELSnA = 10` (High-true) \
    `ELSnB:ELSnA = X1` (Low-true)
  ], [
    PWM alineado al borde con conteo ascendente. La salida cambia al inicio del período y al coincidir con `CnV`. \
    *Ancho de pulso:* $ "CnV" - "CNTIN" $.
  ],
  [*Center-Aligned PWM (CPWM)*], [
    `DECAPEN=0`, `COMBINE=0`, `CPWMS=1` \
    `ELSnB:ELSnA = 10` (High-true)
  ], [
    PWM centrado con conteo Up-Down. \
    *Ancho de pulso:* $ 2 times ("CnV" - "CNTIN") $. \
    *Período:* $ 2 times ("MOD" - "CNTIN") $.
  ],
  [*Combine PWM Mode*], [
    `FTMEN=1`, `COMBINE=1`, `CPWMS=0` \
    Requiere un par de canales ($n$ par y $n+1$).
  ], [
    El canal $n$ define el borde de encendido (`CnV`) y el canal $n+1$ el borde de apagado (`C(n+1)V`). \
    *Ancho de pulso:* $ |"C"(n+1)"V" - "CnV"| $.
  ]
)

 #figure(image("/images/EPWM.png", width: 60%), caption: "EPWM")

  #figure(image("/images/CPWM.png", width: 60%), caption: "CPWM")

#figure(image("/images/Combine PWM.png", width: 60%), caption: "Combine PWM")

==== Filtrado Digital en Captura de Entrada (Input Capture Filter)

El FTM incluye filtros digitales por hardware en los canales de entrada $0, 1, 2, 3$ para suprimir ruido o rebotes de señal.

El filtro exige que la señal permanezca estable durante una ventana temporal configurable en `FTMx_FILTER` mediante el campo `CHnFVAL[3:0]`:

$"Ventana de estabilidad" = 4 + 4 times "CHnFVAL[3:0]"$ (en ciclos de clock del sistema)

==== Inserción de Tiempo Muerto (Deadtime Insertion)

En aplicaciones de electrónica de potencia (como el control de motores DC mediante puentes H o inversores trifásicos con MOSFETs/IGBTs), los dos conmutadores de una misma rama nunca deben conducir simultáneamente para evitar un cortocircuito directo (*shoot-through*) de la fuente de alimentación.

El FTM permite configurar salidas complementarias entre los canales $n$ y $n+1$ (`COMP = 1` en `COMBINE`) e insertar de forma automática un tiempo muerto (*Deadtime*) a través del registro `FTMx_DEADTIME`:

#cuadro-registro(titulo: [Registro FTMx_DEADTIME])[
- `DTPS[1:0]:` Prescaler del reloj de tiempo muerto (divisores $1, 4, 16$).
- `DTVAL[5:0]:` Número de ciclos de reloj del prescaler asignados como retardo de conmutación.
]

==== Control de Falla por Hardware (Fault Control)

El FTM monitorea hasta 4 entradas físicas de falla (`FAULTIN0..3`) para proteger las etapas de potencia. Ante una condición de sobrecorriente o sobretemperatura detectada por hardware, el módulo deshabilita inmediatamente las salidas PWM y las fuerza a un estado seguro sin esperar intervención del software.

=== Fuentes de Interrupción y Vectores NVIC

Cada módulo FTM consolida sus múltiples eventos de interrupción en *un único vector de interrupción* en el controlador NVIC del microcontrolador:

#table(
  columns: (1.5fr, 1.8fr, 2.7fr),
  inset: 6pt,
  stroke: 0.5pt + luma(180),
  fill: (_, y) => if y == 0 { rgb("#1a5fb4") } else if calc.odd(y) { rgb("#f4f7fa") },
  align: (left, left, left),
  table.header([*Fuente de Interrupción*], [*Flags de Habilitación*], [*Registro / Ubicación*]),
  [*Timer Overflow Interrupt*], [`TOIE = 1` y `TOF = 1`], [Registro `FTMx_SC`.],
  [*Channel Interrupt (n)*], [`CHnIE = 1` y `CHnF = 1`], [Registro de canal `FTMx_CnSC`.],
  [*Fault Interrupt*], [`FAULTIE = 1` y `FAULTF = 1`], [Registro `FTMx_MODE`.]
)

#cuadro-registro(titulo: [Vectores IRQ en el Vector Table de K64F])[
- `FTM0_IRQHandler` → Vector #42 en NVIC (`FTM0_IRQn`).
- `FTM1_IRQHandler` → Vector #43 en NVIC (`FTM1_IRQn`).
- `FTM2_IRQHandler` → Vector #44 en NVIC (`FTM2_IRQn`).
- `FTM3_IRQHandler` → Vector #45 en NVIC (`FTM3_IRQn`).
]

/*
=== Ejemplos Prácticos de Configuración en FRDM-K64F

A continuación se resumen las configuraciones de los laboratorios prácticos desarrollados sobre la placa FRDM-K64F:

==== Ejemplo 1: Generación de Interrupción por Overflow (`Counter Overflow`)

- *Objetivo:* Configurar `FTM0` en conteo libre (*Up Counting*) para conmutar un pin GPIO (`PTC8`) dentro del manejador de interrupción.
- *Pasos de Configuración:*
  1. Habilitar reloj en `SIM->SCGC6 |= SIM_SCGC6_FTM0_MASK`.
  2. Desactivar reloj de FTM poniendo `CLKS = 00` en `FTM0->SC`.
  3. Fijar `CNTIN = 0` y el módulo deseado `MOD = 49999` (para $10 "ms"$ con $f = 5 "MHz"$).
  4. Activar interrupción por overflow (`TOIE = 1`) y seleccionar reloj (`CLKS = 01`, `PS = 010`).
  5. Habilitar vector `FTM0_IRQn` en el NVIC (`NVIC_EnableIRQ(FTM0_IRQn)`) .
  6. En `FTM0_IRQHandler()`, limpiar el flag escribiendo `'0'` en `TOF` tras haberlo leído.

==== Ejemplo 2: Generador de Onda por Output Compare

- *Objetivo:* Conmutar automáticamente el pin `PTC1` (`FTM0_CH0`) por hardware al coincidir el contador con `FTM0->CONTROLS[0].CnV`.
- *Configuración de Registros:*
  - Pin Mux Control: Configurar PCR de `PTC1` en MUX Alt 3 (`FTM0_CH0`).
  - `FTM0->CONTROLS[0].CnSC = FTM_CnSC_MSA_MASK | FTM_CnSC_ELSA_MASK;` (Output Compare en modo Toggle).

==== Ejemplo 3: Medición de Período mediante Input Capture

- *Objetivo:* Medir el período de una onda generada por `FTM0_CH0` (`PTC1`) conectada externamente al pin de captura `PTC9` (`FTM3_CH5`).
- *Cálculo de Período:*
  - En la ISR de `FTM3`, se leen dos capturas consecutivas $t_1$ y $t_2$ del registro `FTM3->CONTROL.CnV`.
  - $Delta N = (t_2 - t_1) mod 65536$.
  - $"Período medido" = Delta N times t_"FTM3_CNT"$.

==== Ejemplo 4: Modulación PWM y Control de Motores (Puentes H)

- *Concepto de PWM:* Variación del ciclo de trabajo (*Duty Cycle*) para controlar la tensión promedio aplicada a un motor DC o carga inductiva:

$"Duty Cycle (%)" = d / T times 100%$; por lo tanto, $V_"promedio" = "Duty" times V_"CC"$

- *Drivers de Potencia (L293D / L298N):* Integrados de puente H que permiten control bidireccional de motores DC [12, 13]:
  - *Giro Horario (CW):* Entrada `IN1 = PWM`, `IN2 = 0` [13].
  - *Giro Antihorario (CCW):* Entrada `IN1 = 1 - PWM`, `IN2 = 1` [13].
  - *Freno Rápido:* `IN1 = 0`, `IN2 = 0` [13].

#cuadro-ejemplo(titulo: [Resumen de Registros Principales del FTM])[
- `FTMx_SC`: Control general (TOF, TOIE, CPWMS, CLKS, PS).
- `FTMx_CNT`: Valor actual del contador de 16 bits.
- `FTMx_MOD`: Valor del módulo / período final.
- `FTMx_CNTIN`: Valor inicial del contador.
- `FTMx_CnSC`: Control e interrupción del canal $n$ (CHnF, CHnIE, MSnB:MSnA, ELSnB:ELSnA).
- `FTMx_CnV`: Registro de valor / comparación / captura del canal $n$.
- `FTMx_MODE`: Selección de modo avanzado (`FTMEN`, `WPDIS`, `FAULTIE`).
- `FTMx_COMBINE`: Configuración de canales combinados (`COMBINE`, `COMP`, `DECAPEN`).
- `FTMx_DEADTIME`: Prescaler y valor de tiempo muerto (`DTPS`, `DTVAL`).
- `FTMx_SWOCTRL`: Control directo de salidas por software (`CHnOC`, `CHnOCV`).
]

*/